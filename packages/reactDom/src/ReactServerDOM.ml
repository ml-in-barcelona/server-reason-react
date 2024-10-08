type json = Yojson.Basic.t

module Stream = struct
  let create () =
    let stream, push_into = Lwt_stream.create () in
    let push v = push_into @@ Some v in
    let close () = push_into @@ None in
    (stream, push, close)
end

type chunk_type = Chunk_value of json | Chunk_component_ref of json

type payload_context = {
  push : int -> chunk_type -> unit;
  close : unit -> unit;
  mutable pending : int;
  mutable chunk_id : int;
}

let get_id context =
  context.chunk_id <- context.chunk_id + 1;
  context.chunk_id

(* https://github.com/facebook/react/blob/493f72b0a7111b601c16b8ad8bc2649d82c184a0/packages/react-dom-bindings/src/server/fizz-instruction-set/ReactDOMFizzInstructionSetShared.js#L46 *)
let complete_boundary_script =
  {|function $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if("/$"===d)if(0===e)break;else e--;else"$"!==d&&"$?"!==d&&"$!"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data="$";a._reactRetry&&a._reactRetry()}}|}

let inline_complete_boundary_script =
  Html.node "script" [] [ Html.raw complete_boundary_script ]

let rsc_start_script =
  Html.node "script" []
    [
      Html.raw
        {|
          let enc = new TextEncoder();
          let srr_stream = (window.srr_stream = {});
          srr_stream.push = (payload) => {
            srr_stream._c.enqueue(enc.encode(payload))
          };
          srr_stream.close = () => {
            srr_stream._c.close();
          };
          srr_stream.readable_stream = new ReadableStream({ start(c) { srr_stream._c = c; } });
        |};
    ]

let render_inline_rc_replacement replacements =
  let rc_payload =
    replacements
    |> List.map (fun (b, s) ->
           Html.raw (Printf.sprintf "$RC('B:%i','S:%i')" b s))
    |> Html.list ~separator:";"
  in
  Html.node "script" [] [ rc_payload ]

let prop_to_json (prop : React.JSX.prop) =
  (* TODO: Add promises/sets *)
  match prop with
  | React.JSX.Bool (key, value) -> (key, `Bool value)
  | React.JSX.String (key, value) -> (key, `String value)
  | React.JSX.Style value -> ("style", `String value)
  | React.JSX.DangerouslyInnerHtml html ->
      ("dangerouslySetInnerHTML", `Assoc [ ("__html", `String html) ])
  | React.JSX.Ref _ -> failwith "TODO ref"
  | React.JSX.Event _ -> failwith "TODO event"

let node ~tag ?(key = None) ~props children : json =
  let key = match key with None -> `Null | Some key -> `String key in
  let props =
    match children with
    | [] -> props
    | [ one_children ] -> ("children", one_children) :: props
    | childrens -> ("children", `List childrens) :: props
  in
  `List [ `String "$"; `String tag; key; `Assoc props ]

(* Not reusing node because we need to add fallback prop as model directly *)
let suspense_node ~key ~fallback children : json =
  let fallback_prop = ("fallback", fallback) in
  let children_prop =
    match children with
    | [ one ] -> ("children", one)
    | _ -> ("children", `List children)
  in
  let props = [ fallback_prop; children_prop ] in
  node ~tag:"$Sreact.suspense" ~key ~props []

let component_ref ~module_ ~name =
  `List
    [ `String module_ (* id *); `List [] (* chunks *); `String name (* name *) ]

let lazy_value id = Printf.sprintf "$L%x" id
let promise_value id = Printf.sprintf "$@%x" id

let payload_to_chunk id model =
  let buf = Buffer.create (4 * 1024) in
  Buffer.add_string buf (Printf.sprintf "%x:" id);
  Yojson.Basic.write_json buf model;
  Buffer.add_char buf '\n';
  Buffer.contents buf

let client_reference_to_chunk id ref =
  let buf = Buffer.create 256 in
  Buffer.add_string buf (Printf.sprintf "%x:I" id);
  Yojson.Basic.write_json buf ref;
  Buffer.add_char buf '\n';
  Buffer.contents buf

(* TODO: Add key on Lower_case_element ? *)
let element_to_model ~context index element =
  let rec to_payload element =
    match (element : React.element) with
    | Empty -> `Null
    (* TODO: Do we need to encode this? *)
    | Text t -> `String t
    | Lower_case_element { tag; attributes; children } ->
        let props = List.map prop_to_json attributes in
        node ~key:None ~tag ~props (List.map to_payload children)
    | Fragment children -> to_payload children
    | List children -> `List (Array.map to_payload children |> Array.to_list)
    | InnerHtml _text ->
        (* TODO: Don't have failwith *)
        failwith
          "It does not exist in RSC, this is a bug in server-reason-react or a \
           wrong construction of JSX manually"
    | Upper_case_component component -> to_payload (component ())
    | Async_component component -> (
        match Lwt.state (component ()) with
        | Lwt.Return element -> to_payload element
        | Lwt.Fail exn -> raise exn
        | Lwt.Sleep -> failwith "TODO")
    | Suspense { children; fallback } ->
        (* TODO: Store key in the tree and use it here ? *)
        let key = Some "0" in
        let fallback = to_payload fallback in
        suspense_node ~key ~fallback [ to_payload children ]
    | Client_component { import_module; import_name; props; children = _ } ->
        let id = get_id context in
        let ref = component_ref ~module_:import_module ~name:import_name in
        context.push id (Chunk_component_ref ref);
        let props = client_props_to_json props in
        node ~tag:(Printf.sprintf "$%x" id) ~key:None ~props []
    (* TODO: Dow we need to do anything with Provider and Consumer? *)
    | Provider children -> to_payload children
    | Consumer children -> to_payload children
  and client_props_to_json props =
    List.map
      (fun (name, value) ->
        match (name, (value : React.client_prop)) with
        | name, Json json -> (name, json)
        | name, Element element ->
            (* TODO: Probably a silly question, but do I need to push this client_ref? (What if it's a client_ref?) In case of server, no need to do anything I guess *)
            (name, to_payload element)
        | name, Promise (promise, value_to_json) -> (
            match Lwt.state promise with
            | Return value ->
                let chunk_id = get_id context in
                let json = value_to_json value in
                (* TODO: Make sure why we need a chunk here *)
                context.push context.chunk_id (Chunk_value json);
                (name, `String (promise_value chunk_id))
            | Sleep ->
                let chunk_id = get_id context in
                context.pending <- context.pending + 1;
                Lwt.async (fun () ->
                    let%lwt value = promise in
                    let json = value_to_json value in
                    context.pending <- context.pending - 1;
                    context.push chunk_id (Chunk_value json);
                    if context.pending = 0 then context.close ();
                    Lwt.return ());
                (name, `String (promise_value chunk_id))
            | Fail exn ->
                (* TODO: Can we check if raise is good heres? *)
                raise exn))
      props
  in
  context.push index (Chunk_value (to_payload element));
  if context.pending = 0 then context.close ()

let html_model index model =
  let chunk = payload_to_chunk index model in
  Html.node "script" []
    [ Html.raw (Printf.sprintf "window.srr_stream.push(%s);" chunk) ]

let to_model ?subscribe element : string Lwt_stream.t Lwt.t =
  let stream, push, close = Stream.create () in
  let push_chunk id chunk =
    match chunk with
    | Chunk_value json -> push (payload_to_chunk id json)
    | Chunk_component_ref json -> push (client_reference_to_chunk id json)
  in
  let context : payload_context =
    { push = push_chunk; close; chunk_id = 0; pending = 0 }
  in
  element_to_model ~context context.chunk_id element;
  (* TODO: Currently returns the stream because of testing, in the future we can use subscribe to capture all chunks *)
  match subscribe with
  | None -> Lwt.return stream
  | Some subscribe ->
      let%lwt _ = Lwt_stream.iter_s subscribe stream in
      Lwt.return stream

(* TODO: Add scripts and links to the output, also all options from renderToReadableStream *)
(* TODO: Add Shell_render and Render_async return types *)
(* let render element =
   let stream, push, close = Stream.create () in
   let push_html id x = push (Html.to_string (html_model id x)) in
   let _push_chunk id x = push (payload_to_chunk id x) in
   let context =
     {
       push = push_html;
       close;
       waiting = 0;
       chunk_id = 0;
       boundary_id = 0;
       suspense_id = 0;
     }
   in
   let json = element_to_model ~context element in
   push (Html.to_string rsc_start_script);
   push_html context.chunk_id json;
   if context.waiting = 0 then close ();
   let abort () =
     (* TODO: Needs to flush the remaining loading fallbacks as HTML, and React.js will try to render the rest on the client. *)
     (* Lwt_stream.closed stream |> Lwt.ignore_result *)
     failwith "abort() isn't supported yet"
   in
   Lwt.return (stream, abort) *)

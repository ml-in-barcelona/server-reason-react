type json = Yojson.Basic.t

module Stream = struct
  let make () =
    let stream, push_into = Lwt_stream.create () in
    let push v = push_into (Some v) in
    let close () = push_into None in
    (stream, push, close)
end

module Model = struct
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

  let prop_to_json (prop : React.JSX.prop) =
    (* TODO: Add promises/sets/others ??? *)
    match prop with
    | React.JSX.Bool (key, value) -> (key, `Bool value)
    | React.JSX.String (key, value) -> (key, `String value)
    | React.JSX.Style value -> ("style", `String value)
    | React.JSX.DangerouslyInnerHtml html ->
        ("dangerouslySetInnerHTML", `Assoc [ ("__html", `String html) ])
    (* TODO: What does ref mean *)
    | React.JSX.Ref _ -> ("ref", `Null)
    (* TODO: What does event even mean *)
    | React.JSX.Event (key, _) -> (key, `Null)

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
    let id = `String module_ in
    let chunks = `List [] in
    let component_name = `String name in
    `List [ id; chunks; component_name ]

  let lazy_value id = Printf.sprintf "$L%x" id
  let promise_value id = Printf.sprintf "$@%x" id

  let payload_to_chunk id model =
    let buf = Buffer.create (4 * 1024) in
    Buffer.add_string buf (Printf.sprintf "%x:" id);
    Yojson.Basic.write_json buf model;
    (* Buffer.add_char buf '\n'; *)
    Buffer.contents buf

  let client_reference_to_chunk id ref =
    let buf = Buffer.create 256 in
    Buffer.add_string buf (Printf.sprintf "%x:I" id);
    Yojson.Basic.write_json buf ref;
    (* Buffer.add_char buf '\n'; *)
    Buffer.contents buf

  let element_to_model ~context index element =
    let rec to_payload element =
      match (element : React.element) with
      | Empty -> `Null
      (* TODO: Do we need to encode this? *)
      | Text t -> `String t
      (* TODO: Add key here on the element type "" ? *)
      | Lower_case_element { tag; attributes; children } ->
          let props = List.map prop_to_json attributes in
          node ~key:None ~tag ~props (List.map to_payload children)
      | Fragment children -> to_payload children
      | List children -> `List (Array.map to_payload children |> Array.to_list)
      | InnerHtml _text ->
          (* TODO: Don't have failwith *)
          failwith
            "It does not exist in RSC, this is a bug in server-reason-react or \
             a wrong construction of JSX manually"
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

  let render ?subscribe element : string Lwt_stream.t Lwt.t =
    let stream, push, close = Stream.make () in
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
end

module Html = struct
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

  (* Copied from ReactDOM.ml, TODO: Move somewhere common? *)
  (* https://github.com/facebook/react/blob/493f72b0a7111b601c16b8ad8bc2649d82c184a0/packages/react-dom-bindings/src/server/fizz-instruction-set/ReactDOMFizzInstructionSetShared.js#L46 *)
  let rc_function_definition =
    {|function $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if("/$"===d)if(0===e)break;else e--;else"$"!==d&&"$?"!==d&&"$!"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data="$";a._reactRetry&&a._reactRetry()}}|}

  let rc_function_script =
    Html.node "script" [] [ Html.raw rc_function_definition ]

  let chunk_model_script index model =
    let chunk = Model.payload_to_chunk index model in
    Html.node "script" []
      [ Html.raw (Printf.sprintf "window.srr_stream.push('%s');" chunk) ]

  let chunk_stream_end_script =
    Html.node "script" [] [ Html.raw "window.srr_stream.close();" ]

  let rc_replacement b s =
    Html.node "script" []
      [ Html.raw (Printf.sprintf "<script>$RC('B:%x', 'S:%x')</script>" b s) ]

  let chunk_html_script index html =
    Html.list ~separator:"\n"
      [
        Html.node "div"
          [
            Html.attribute "hidden" "true";
            Html.attribute "id" (Printf.sprintf "S:%x" index);
          ]
          [ html ];
        rc_replacement index index;
      ]

  let html_suspense inner =
    Html.list [ Html.raw "<!--$?-->"; inner; Html.raw "<!--/$-->" ]

  let html_suspense_placeholder element id =
    Html.list
      [
        Html.raw "<!--$?-->";
        Html.node "template"
          [ Html.attribute "id" (Printf.sprintf "B:%i" id) ]
          [];
        element;
        Html.raw "<!--/$-->";
      ]

  (* TODO: Push is to be used for streaming, when implementing async components, suspense, etc. *)
  let rec to_html ~push (element : React.element) : (Html.element * json) Lwt.t
      =
    (* TODO: Add key into Lower_case elements? *)
    let key = Some "00" in
    match element with
    | Empty -> Lwt.return (Html.null, `Null)
    | Text s -> Lwt.return (Html.string s, if not true then `Null else `String s)
    | Fragment children -> to_html ~push children
    | Upper_case_component component -> to_html ~push (component ())
    | Lower_case_element { tag; attributes; _ }
      when Html.is_self_closing_tag tag ->
        let html_props = List.map ReactDOM.attribute_to_html attributes in
        let json_props = List.map Model.prop_to_json attributes in
        Lwt.return
          ( Html.node tag html_props [],
            Model.node ~tag ~key ~props:json_props [] )
    | List list -> elements_to_html ~push (Array.to_list list)
    | Lower_case_element { tag; attributes; children } ->
        let html_props = List.map ReactDOM.attribute_to_html attributes in
        let json_props = List.map Model.prop_to_json attributes in
        let%lwt html, model = elements_to_html ~push children in
        Lwt.return
          ( Html.node tag html_props [ html ],
            Model.node ~tag ~key ~props:json_props [ model ] )
    | _ -> failwith "todo!"

  and elements_to_html ~push elements =
    let%lwt html_and_models = elements |> Lwt_list.map_p (to_html ~push) in
    let htmls, model = List.split html_and_models in
    Lwt.return (Html.list htmls, `List model)

  type rendering =
    | Done of Html.element
    | Async of {
        shell : Html.element;
        subscribe : (Html.element -> unit Lwt.t) -> unit Lwt.t;
      }

  (* TODO: Add Async for async/suspense/etc. *)
  (* TODO: Do we need to disable streaming based on some timeout? *)
  (* TODO: Do we need to disable the model rendering? Can we do something better than a boolean? *)
  (* TODO: Add scripts and links to the output, also all options from renderToReadableStream *)
  let render element =
    let _stream, push, _ = Stream.make () in
    let index = 0 in
    let%lwt html, model = to_html ~push element in
    let shell =
      let initial_model_element = chunk_model_script index model in
      Html.list [ rsc_start_script; initial_model_element; html ]
    in
    (* let html_iter fn =
         let%lwt () = Lwt_stream.iter_s fn stream in
         fn chunk_stream_end_script
       in
       let html_shell =
         if not true then Html.list [ rc_function_script; shell ]
         else Html.list [ rsc_start_script; rc_function_script; shell ]
       in
       Lwt.return (Async { shell = html_shell; subscribe = html_iter }) *)
    Lwt.return (Done shell)
end

let render_to_model = Model.render
let render_to_html = Html.render

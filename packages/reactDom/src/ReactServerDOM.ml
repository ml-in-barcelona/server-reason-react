module Stream = struct
  let create () =
    let stream, push_to_stream = Lwt_stream.create () in
    let push v = push_to_stream @@ Some v in
    let close () = push_to_stream @@ None in
    (stream, push, close)
end

type context_state = {
  push : int -> Yojson.Basic.t -> unit;
  close : unit -> unit;
  mutable chunk_id : int;
  (* mutable pending_chunks : int; *)
  mutable boundary_id : int;
  mutable suspense_id : int;
  mutable waiting : int;
}

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
          srr_stream.push = () => {
            let el = document.currentScript;
            srr_stream._c.enqueue(enc.encode(el.dataset.payload))
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
  match prop with
  | React.JSX.Bool (key, value) -> (key, `Bool value)
  | React.JSX.String (key, value) -> (key, `String value)
  | React.JSX.Style value -> ("style", `String value)
  | React.JSX.DangerouslyInnerHtml html ->
      ("dangerouslySetInnerHTML", `Assoc [ ("__html", `String html) ])
  | React.JSX.Ref _ -> failwith "TODO ref"
  | React.JSX.Event _ -> failwith "TODO event"

let props_to_json props = List.map prop_to_json props

let node ~tag ?(key = None) ~props children : Yojson.Basic.t =
  let key = match key with None -> `Null | Some key -> `String key in
  let props =
    match children with
    | [] -> props_to_json props
    | [ one_children ] -> ("children", one_children) :: props_to_json props
    | childrens -> ("children", `List childrens) :: props_to_json props
  in
  `List [ `String "$"; `String tag; key; `Assoc props ]

(* TODO: Add key on Lower_case_element ? *)
let element_to_payload ~context_state:_ element : Yojson.Basic.t =
  let rec to_payload element =
    match element with
    | React.Empty -> `Null
    (* TODO: Should we html encode this? *)
    | React.Text t -> `String t
    | React.Lower_case_element { tag; attributes; children } ->
        node ~key:None ~tag ~props:attributes (List.map to_payload children)
    | React.Fragment children -> to_payload children
    | React.List children ->
        `List (Array.map to_payload children |> Array.to_list)
    | React.InnerHtml _text ->
        failwith
          "It does not exist in RSC, this is a bug in server-reason-react or \
           wrongly construction of the JSX manually"
    | React.Upper_case_component component -> to_payload (component ())
    | React.Async_component component -> (
        match Lwt.state (component ()) with
        | Lwt.Return element -> to_payload element
        | Lwt.Fail exn -> raise exn
        | Lwt.Sleep -> failwith "TODO")
    | React.Suspense { children; fallback } ->
        (* TODO: Store key in tree and use it here *)
        let key = Some "00" in
        let _fallback = to_payload fallback in
        (* TODO: Pass fallback as prop *)
        node ~tag:"$Sreact.suspense" ~key ~props:[] [ to_payload children ]
    | React.Provider children -> to_payload children
    | React.Consumer children -> to_payload children
  in
  to_payload element

let chunk_to_string idx model =
  let buf = Buffer.create (4 * 1024) in
  Buffer.add_string buf (Printf.sprintf "%x:" idx);
  Yojson.Basic.write_json buf model;
  Buffer.add_char buf '\n';
  Buffer.contents buf

let html_model index model =
  let chunk = chunk_to_string index model in
  Html.node "script"
    [ Html.attribute "data-payload" chunk ]
    [ Html.raw "window.srr_stream.push();" ]

(* TODO: Add scripts and links to the output *)
let render element =
  let stream, push, close = Stream.create () in
  let _push_html id x = push (Html.to_string (html_model id x)) in
  let push_chunk id x = push (chunk_to_string id x) in
  let context_state =
    {
      push = push_chunk;
      close;
      waiting = 0;
      chunk_id = 0;
      boundary_id = 0;
      suspense_id = 0;
    }
  in
  let json = element_to_payload ~context_state element in
  (* push (Html.to_string rsc_start_script); *)
  push_chunk context_state.chunk_id json;
  if context_state.waiting = 0 then close ();
  let abort () =
    (* TODO: Needs to flush the remaining loading fallbacks as HTML, and React.js will try to render the rest on the client. *)
    (* Lwt_stream.closed stream |> Lwt.ignore_result *)
    failwith "abort() isn't supported yet"
  in
  Lwt.return (stream, abort)

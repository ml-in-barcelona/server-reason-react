type json = Yojson.Basic.t
type env = [ `Dev | `Prod ]

let is_dev = function `Dev -> true | `Prod -> false

let create_stack_trace () =
  let stack = Printexc.backtrace_slots (Printexc.get_raw_backtrace ()) |> Option.value ~default:[||] in
  `List
    (Array.map
       (fun slot ->
         let location = Printexc.Slot.location slot in
         let name = Printexc.Slot.name slot in
         match (location, name) with
         | Some location, Some name ->
             `List
               [
                 `String (Printf.sprintf "[SERVER] %s" name);
                 `String location.Printexc.filename;
                 `Int location.Printexc.line_number;
                 `Int location.Printexc.start_char;
               ]
         | _, _ -> `List [ `String "Unknown function name"; `String "Unknown filename"; `Int 0; `Int 0 ])
       stack
    |> Array.to_list)

let exn_to_error exn =
  let message = Printexc.to_string exn in
  let stack = create_stack_trace () in
  (* TODO: digest could be a UUID, but in react.js those errors point to the documentation. We don't have a setup like theirs for this. Maybe we should use their codes.json? *)
  let digest = stack |> Yojson.Basic.to_string |> Hashtbl.hash |> Int.to_string in
  React.Error { message; stack; env = "Server"; digest }

module Fiber = struct
  type[@warning "-69"] context = {
    mutable index : int;
    mutable pending : int;
    push : Html.element -> unit;
    close : unit -> unit;
    env : env;
    debug : bool;
  }

  (* TODO: What should we do with all captured attributes, merge them? keep last? ignore them? Right now we just capture one head element, but we need to capture all of them *)
  type hoisted_head = Html.attribute_list * Html.element list

  type t = {
    context : context;
    finished : unit Lwt.t;
    is_root_html_node : bool;
    mutable hoisted_head : hoisted_head option;
    mutable hoisted_head_childrens : Html.element list;
    (* QUESTION: Why do I need emit_html to be mutable? *)
    mutable emit_html : Html.element -> unit;
  }

  let push_hoisted_head ~fiber html_attributes children = fiber.hoisted_head <- Some (html_attributes, children)

  let push_hoisted_head_childrens ~fiber children =
    fiber.hoisted_head_childrens <- children :: fiber.hoisted_head_childrens

  let use_index t =
    t.context.index <- t.context.index + 1;
    t.context.index

  let get_context t = t.context
end

module Model = struct
  type chunk_type = Chunk_value of json | Chunk_component_ref of json | Debug_info_map of json | Chunk_error of json

  type stream_context = {
    push : int -> chunk_type -> unit;
    close : unit -> unit;
    mutable pending : int;
    mutable chunk_id : int;
    env : env;
    debug : bool;
  }

  let use_chunk_id context =
    context.chunk_id <- context.chunk_id + 1;
    context.chunk_id

  let get_chunk_id context = context.chunk_id
  let style_to_json style = `Assoc (List.map (fun (_, jsxKey, value) -> (jsxKey, `String value)) style)

  let error_to_json ~env (error : React.error) =
    match is_dev env with
    | true ->
        `Assoc
          [
            ("message", `String error.message);
            ("stack", error.stack);
            ("env", `String error.env);
            ("digest", `String error.digest);
          ]
    (*
      In prod we don't emit any information about this Error object to avoid
      unintentional leaks. Use the digest to identify the registered error.
      REF: https://github.com/facebook/react/blob/e81fcfe3f201a8f626e892fb52ccbd0edba627cb/packages/react-client/src/ReactFlightClient.js#L2086-L2101
    *)
    | false -> `Assoc [ ("digest", `String error.digest) ]

  let lazy_value id = Printf.sprintf "$L%x" id
  let promise_value id = Printf.sprintf "$@%x" id
  let ref_value id = Printf.sprintf "$%x" id
  let error_value id = Printf.sprintf "$Z%x" id
  let action_value id = Printf.sprintf "$F%x" id

  let prop_to_json (prop : React.JSX.prop) =
    match prop with
    (* We ignore the HTML name, and only use the JSX name *)
    | Bool (_, key, value) -> Some (key, `Bool value)
    (* We exclude 'key' from props, since it's outside of the props object *)
    | React.JSX.String (_, key, _) when key = "key" -> None
    | React.JSX.String (_, key, value) -> Some (key, `String value)
    | React.JSX.Style value -> Some ("style", style_to_json value)
    | React.JSX.DangerouslyInnerHtml html -> Some ("dangerouslySetInnerHTML", `Assoc [ ("__html", `String html) ])
    | React.JSX.Ref _ -> None
    | React.JSX.Event _ -> None

  let props_to_json props = List.filter_map prop_to_json props

  let node ~tag ?(key = None) ~props ?(source = None) ?(debugId = None) ?(owner = None) children : json =
    let key = match key with None -> `Null | Some key -> `String key in
    let debugId = match debugId with None -> `Null | Some debugId -> `String debugId in
    let source = match source with None -> `List [] | Some source -> `List source in
    let owner =
      match owner with
      | None -> `Assoc []
      (* TODO: debugOwner is a ReactComponentInfo itself *)
      | Some owner -> `Assoc [ ("name", `String owner) ]
    in
    let props =
      match children with
      | [] -> props
      | [ one_children ] -> ("children", one_children) :: props
      | childrens -> ("children", `List childrens) :: props
    in
    `List [ `String "$"; `String tag; key; `Assoc props; debugId; source; owner ]

  let suspense_node ~key ~fallback children : json =
    let fallback_prop = ("fallback", fallback) in
    let props =
      match children with
      | [] -> [ fallback_prop; ("children", `List []) ]
      | [ one ] -> [ fallback_prop; ("children", one) ]
      | _ -> [ fallback_prop; ("children", `List children) ]
    in
    node ~tag:"$Sreact.suspense" ~key ~props []

  let suspense_placeholder ~key ~fallback index = suspense_node ~key ~fallback [ `String (lazy_value index) ]

  let component_ref ~module_ ~name =
    let id = `String module_ in
    let chunks = `List [] in
    let component_name = `String name in
    `List [ id; chunks; component_name ]

  let model_to_chunk id json =
    let buf = Buffer.create (4 * 1024) in
    Buffer.add_string buf (Printf.sprintf "%x:" id);
    Yojson.Basic.write_json buf json;
    Buffer.add_string buf "\n";
    Buffer.contents buf

  let debug_info_to_chunk id json =
    let buf = Buffer.create (4 * 1024) in
    Buffer.add_string buf (Printf.sprintf "%x:D" id);
    Yojson.Basic.write_json buf json;
    Buffer.add_string buf "\n";
    Buffer.contents buf

  let client_reference_to_chunk id ref =
    let buf = Buffer.create 256 in
    Buffer.add_string buf (Printf.sprintf "%x:I" id);
    Yojson.Basic.write_json buf ref;
    Buffer.add_string buf "\n";
    Buffer.contents buf

  let error_to_chunk id error =
    let buf = Buffer.create 256 in
    Buffer.add_string buf (Printf.sprintf "%x:E" id);
    Yojson.Basic.write_json buf error;
    Buffer.add_string buf "\n";
    Buffer.contents buf

  (* TODO: currently it's implemented only `ReactComponentInfo` from https://github.com/facebook/react/blob/152080276c61873fdfc88db7f5856332742ddb02/packages/react-server/src/ReactFlightServer.js#L3208-L3216, it lacks other types *)
  (* TODO: Add props, stack and parentName *)
  let make_debug_info ?ownerName name =
    let owner = match ownerName with Some owner -> `String owner | None -> `Null in
    `Assoc
      [
        ("name", `String name);
        ("env", `String "Server");
        ("key", `Null);
        ("owner", owner);
        ("stack", `List []);
        (* We don't have access to the props of uppercase components, since we treat it as a closure and don't encode the props and pass an empty object *)
        ("props", `Assoc []);
      ]

  let rec element_to_payload ~context element =
    let is_root = ref true in
    let rec turn_element_into_payload ~context element =
      match (element : React.element) with
      | Empty -> `Null
      (* TODO: Do we need to html encode the model or only the html? *)
      | Text t -> `String t
      | Lower_case_element { key; tag; attributes; children } ->
          let props = props_to_json attributes in
          node ~key ~tag ~props (List.map (turn_element_into_payload ~context) children)
      | Fragment children ->
          if is_root.contents then is_root := false;
          turn_element_into_payload ~context children
      | List children ->
          if is_root.contents then is_root := false;
          `List (List.map (turn_element_into_payload ~context) children)
      | Array children ->
          if is_root.contents then is_root := false;
          `List (Array.map (turn_element_into_payload ~context) children |> Array.to_list)
      | InnerHtml _text ->
          raise
            (Invalid_argument
               "InnerHtml does not exist in RSC, this is a bug in server-reason-react.ppx or a wrong construction of \
                JSX manually")
      | Upper_case_component (name, component) ->
          let element = component () in
          if context.debug then (
            let index = get_chunk_id context in
            let debug_info_index = use_chunk_id context in
            let debug_info_ref : json = `String (ref_value debug_info_index) in
            context.push debug_info_index (Chunk_value (make_debug_info name));
            context.push index (Debug_info_map debug_info_ref);
            ());

          if is_root.contents then (
            is_root := false;
            turn_element_into_payload ~context element)
          else
            let index = use_chunk_id context in
            (* Instead of returning the payload directly, we push the result into the stream, and return the reference directly. This is how `react-server-dom-xxx/server` renderToPipeableStream works *)
            context.push index (Chunk_value (turn_element_into_payload ~context element));
            `String (ref_value index)
      | Async_component (_, component) -> (
          (* TODO: Need to check for is_root? *)
          let promise = component () in
          match Lwt.state promise with
          | Fail exn -> raise exn
          | Return element -> turn_element_into_payload ~context element
          | Sleep ->
              let index = use_chunk_id context in
              context.pending <- context.pending + 1;
              Lwt.async (fun () ->
                  let%lwt element = promise in
                  context.pending <- context.pending - 1;
                  context.push index (Chunk_value (turn_element_into_payload ~context element));
                  if context.pending = 0 then context.close ();
                  Lwt.return ());
              `String (lazy_value index))
      | Suspense { key; children; fallback } -> (
          (* TODO: There's suttle difference between Suspense being at the root and not, probably need to handle it. Not very common case, though *)
          (* TODO: Maybe we need to push suspense index and suspense node separately *)
          (* TODO: Add try catch for fallback *)
          let fallback = turn_element_into_payload ~context fallback in
          try suspense_node ~key ~fallback [ turn_element_into_payload ~context children ]
          with _exn ->
            let index = use_chunk_id context in
            let error : React.error = { message = "Error"; stack = `List []; env = "Server"; digest = "" } in
            let error_json = error_to_json ~env:context.env error in
            context.push index (Chunk_error error_json);
            suspense_placeholder ~key ~fallback index)
      | Client_component { import_module; import_name; props; client = _ } ->
          let id = use_chunk_id context in
          let ref = component_ref ~module_:import_module ~name:import_name in
          context.push id (Chunk_component_ref ref);
          let client_props = client_values_to_json ~context props in
          node ~tag:(ref_value id) ~key:None ~props:client_props []
      (* TODO: Dow we need to do anything with Provider and Consumer? *)
      | Provider children -> turn_element_into_payload ~context children
      | Consumer children -> turn_element_into_payload ~context children
    in
    turn_element_into_payload ~context element

  and client_value_to_json ~context value =
    match (value : React.client_value) with
    | Json json -> json
    | Error error ->
        let chunk_id = use_chunk_id context in
        let error_json = error_to_json ~env:context.env error in
        context.push chunk_id (Chunk_error error_json);
        `String (error_value context.chunk_id)
    | Element element ->
        (* TODO: Probably a silly question, but do I need to push this client_ref? (What if it's a client_ref?) In case of server, no need to do anything I guess *)
        element_to_payload ~context element
    | Promise (promise, value_to_json) -> (
        match Lwt.state promise with
        | Return value ->
            let chunk_id = use_chunk_id context in
            let json = value_to_json value in
            (* TODO: Make sure why we need a chunk here *)
            context.push context.chunk_id (Chunk_value json);
            `String (promise_value chunk_id)
        | Sleep ->
            let chunk_id = use_chunk_id context in
            context.pending <- context.pending + 1;
            Lwt.async (fun () ->
                let%lwt value = promise in
                let json = value_to_json value in
                context.pending <- context.pending - 1;
                context.push chunk_id (Chunk_value json);
                if context.pending = 0 then context.close ();
                Lwt.return ());
            `String (promise_value chunk_id)
        | Fail exn ->
            (* TODO: Can we check if raise is good heres? *)
            raise exn)
    | Function action ->
        let chunk_id = use_chunk_id context in
        context.push chunk_id (Chunk_value (`Assoc [ ("id", `String action.id); ("bound", `Null) ]));
        `String (action_value chunk_id)

  and client_values_to_json ~context props =
    List.map
      (fun (name, value) ->
        let jsonValue = client_value_to_json ~context value in
        (name, jsonValue))
      props

  let render ?(env = `Dev) ?(debug = false) ?subscribe element =
    let initial_chunk_id = 0 in
    let stream, push, close = Push_stream.make () in
    let push_chunk id chunk =
      match chunk with
      | Chunk_value json -> push (model_to_chunk id json)
      | Debug_info_map json -> push (debug_info_to_chunk id json)
      | Chunk_component_ref json -> push (client_reference_to_chunk id json)
      | Chunk_error json -> push (error_to_chunk id json)
    in
    let context : stream_context = { push = push_chunk; close; chunk_id = initial_chunk_id; pending = 0; debug; env } in
    let initial_chunk_id = get_chunk_id context in
    context.push initial_chunk_id (Chunk_value (element_to_payload ~context element));
    if context.pending = 0 then context.close ();
    (* TODO: Currently returns the stream because of testing *)
    match subscribe with
    | None -> Lwt.return ()
    | Some subscribe ->
        let%lwt _ = Lwt_stream.iter_s subscribe stream in
        Lwt.return ()

  let create_action_response ?(env = `Dev) ?(debug = false) ?subscribe response =
    let%lwt response = try%lwt response with exn -> Lwt.return (exn_to_error exn) in
    let initial_chunk_id = 0 in
    let stream, push, close = Push_stream.make () in
    let push_chunk id chunk =
      match chunk with
      | Chunk_value json -> push (model_to_chunk id json)
      | Debug_info_map json -> push (debug_info_to_chunk id json)
      | Chunk_component_ref json -> push (client_reference_to_chunk id json)
      | Chunk_error json -> push (error_to_chunk id json)
    in
    let context = { push = push_chunk; close; chunk_id = initial_chunk_id; pending = 0; debug; env } in
    let initial_chunk_id = get_chunk_id context in
    let json = client_value_to_json ~context response in
    context.push initial_chunk_id (Chunk_value json);
    if context.pending = 0 then context.close ();
    match subscribe with
    | None -> Lwt.return ()
    | Some subscribe ->
        let%lwt _ = Lwt_stream.iter_s subscribe stream in
        Lwt.return ()
end

let rsc_start_script =
  Html.node "script" []
    [
      Html.raw
        {|
let enc = new TextEncoder();
let srr_stream = (window.srr_stream = {});
srr_stream.push = () => {
  srr_stream._c.enqueue(enc.encode(document.currentScript.dataset.payload));
};
srr_stream.close = () => {
  srr_stream._c.close();
};
srr_stream.readable_stream = new ReadableStream({ start(c) { srr_stream._c = c; } });
|};
    ]

let rc_function_definition =
  {|function $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if("/$"===d)if(0===e)break;else e--;else"$"!==d&&"$?"!==d&&"$!"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data="$";a._reactRetry&&a._reactRetry()}}|}

let rc_function_script = Html.node "script" [] [ Html.raw rc_function_definition ]

let chunk_script script =
  Html.raw
    (Printf.sprintf "<script data-payload='%s'>window.srr_stream.push()</script>" (Html.single_quote_escape script))

let client_reference_chunk_script index json = chunk_script (Model.client_reference_to_chunk index json)
let client_value_chunk_script index json = chunk_script (Model.model_to_chunk index json)
let error_chunk_script index json = chunk_script (Model.error_to_chunk index json)
let chunk_stream_end_script = Html.node "script" [] [ Html.raw "window.srr_stream.close()" ]
let rc_replacement b s = Html.node "script" [] [ Html.raw (Printf.sprintf "$RC('B:%x', 'S:%x')" b s) ]

let chunk_html_script index html =
  Html.list ~separator:"\n"
    [
      Html.node "div" [ Html.attribute "hidden" "true"; Html.attribute "id" (Printf.sprintf "S:%x" index) ] [ html ];
      rc_replacement index index;
    ]

let html_suspense_immediate inner = Html.list [ Html.raw "<!--$-->"; inner; Html.raw "<!--/$-->" ]

(* let html_suspense_error ~fallback ~exn:_ =
  (* exn could be used for data-msg if client JS uses it *)
  Html.list [ Html.raw "<!--$!-->"; fallback; Html.raw "<!--/$-->" ] *)

let html_suspense_placeholder ~fallback id =
  Html.list
    [
      Html.raw "<!--$?-->";
      Html.node "template" [ Html.attribute "id" (Printf.sprintf "B:%i" id) ] [];
      fallback;
      Html.raw "<!--/$-->";
    ]

let rec client_to_html ~fiber (element : React.element) =
  match element with
  | Empty -> Lwt.return Html.null
  | Text text -> Lwt.return (Html.string text)
  | Fragment children -> client_to_html ~fiber children
  | List childrens ->
      let%lwt html = Lwt_list.map_p (client_to_html ~fiber) childrens in
      Lwt.return (Html.list html)
  | Array childrens ->
      let%lwt html = childrens |> Array.to_list |> Lwt_list.map_p (client_to_html ~fiber) in
      Lwt.return (Html.list html)
  | Lower_case_element { key; tag; attributes; children } -> render_lower_case ~fiber ~key ~tag ~attributes ~children
  | Upper_case_component (_name, component) ->
      let rec wait_for_suspense_to_resolve () =
        match component () with
        | exception React.Suspend (Any_promise promise) ->
            let%lwt _ = promise in
            wait_for_suspense_to_resolve ()
        | exception _exn -> Lwt.return Html.null
        | output ->
            (* TODO: Do we need to care about batching? *)
            client_to_html ~fiber output
      in
      wait_for_suspense_to_resolve ()
  | Async_component (_, _component) ->
      (* async components can't be interleaved in client components, for now *)
      raise
        (Invalid_argument
           "async components can't be part of a client component. This should never raise, the ppx should catch it")
  | Suspense { key = _; children; fallback } ->
      (* TODO: Do we need to care if there's Any_promise raising ? *)
      let%lwt fallback = client_to_html ~fiber fallback in
      let context = Fiber.get_context fiber in
      let _finished, parent_done = Lwt.wait () in
      let index = Fiber.use_index fiber in
      let async = children |> client_to_html ~fiber |> Lwt.map (chunk_html_script index) in
      let sync = html_suspense_placeholder ~fallback index in
      context.pending <- context.pending + 1;
      fiber.emit_html <- (fun html -> context.push html);
      Lwt.async (fun () ->
          let%lwt () = fiber.finished in
          let%lwt html = async in
          context.push html;
          Lwt.wakeup_later parent_done ();
          context.pending <- context.pending - 1;
          if context.pending = 0 then context.close ();
          Lwt.return ());
      Lwt.return sync
  | Client_component { import_module = _; import_name = _; props = _; client } -> client_to_html ~fiber client
  (* TODO: Need to do something for those? *)
  | Provider children -> client_to_html ~fiber children
  | Consumer children -> client_to_html ~fiber children
  | InnerHtml innerHtml -> Lwt.return (Html.raw innerHtml)

and render_lower_case ~fiber ~key:_ ~tag ~attributes ~children =
  if Html.is_self_closing_tag tag then
    let html_props = List.map ReactDOM.attribute_to_html attributes in
    Lwt.return (Html.node tag html_props [])
  else
    let html_props = List.map ReactDOM.attribute_to_html attributes in
    let children = ReactDOM.moveDangerouslyInnerHtmlAsChildren attributes children in
    let%lwt html = children |> Lwt_list.map_p (client_to_html ~fiber) in
    Lwt.return (Html.node tag html_props html)

(* TODO: Complete this list *)
let is_a_head_child_tag tag = tag = "title" || tag = "meta" || tag = "link" || tag = "style"

let rec to_html ~(fiber : Fiber.t) (element : React.element) : (Html.element * json) Lwt.t =
  match element with
  | Empty -> Lwt.return (Html.null, `Null)
  | Text s -> Lwt.return (Html.string s, `String s)
  | Fragment children -> to_html ~fiber children
  | List list -> elements_to_html ~fiber list
  | Array arr -> elements_to_html ~fiber (Array.to_list arr)
  | Upper_case_component (_name, component) ->
      (* if debug then (
        let debug_info_index = Fiber.use_index fiber in
        let debug_info_ref : json = `String (Printf.sprintf "$%x" debug_info_index) in
        (* TODO: Chunks might need to be pushed in the same row *)
        context.push debug_info_index (Model.Chunk_value (Model.make_debug_info name));
        context.push debug_info_index (Model.Debug_info_map debug_info_ref);
        ()); *)
      to_html ~fiber (component ())
  | Lower_case_element { key; tag; attributes; children } ->
      if fiber.is_root_html_node && tag = "head" then (
        (* in case of finding a head element, we need to hoist it to the top of the document, and avoid rendering it in the current node *)
        let html_attributes = List.map ReactDOM.attribute_to_html attributes in
        let%lwt html_and_json = children |> Lwt_list.map_p (to_html ~fiber) in
        let html = List.map (fun (html, _) -> html) html_and_json in
        Fiber.push_hoisted_head ~fiber html_attributes html;
        Lwt.return (Html.null, `Null))
      else if fiber.is_root_html_node && is_a_head_child_tag tag then (
        (* in case of finding a head-like element, we need to hoist it to the top of the document, and avoid rendering it in the current node *)
        let html_props = List.map ReactDOM.attribute_to_html attributes in
        let%lwt children, _ = elements_to_html ~fiber children in
        let html = Html.node tag html_props [ children ] in
        Fiber.push_hoisted_head_childrens ~fiber html;
        Lwt.return (Html.null, `Null))
      else if fiber.is_root_html_node && tag = "html" then
        (* Since we want to reconstruct the document outside of to_html (in case of root being the html tag), we keep rendering the childrens and avoid rendering html element *)
        to_html ~fiber (React.List children)
      else
        let children = ReactDOM.moveDangerouslyInnerHtmlAsChildren attributes children in
        if Html.is_self_closing_tag tag then
          let html_props = List.map ReactDOM.attribute_to_html attributes in
          let json_props = Model.props_to_json attributes in
          let empty_children = (* there's no children for self closing tags *) [] in
          Lwt.return (Html.node tag html_props empty_children, Model.node ~tag ~key ~props:json_props empty_children)
        else
          let html_props = List.map ReactDOM.attribute_to_html attributes in
          let json_props = Model.props_to_json attributes in
          let%lwt html, model = elements_to_html ~fiber children in
          Lwt.return (Html.node tag html_props [ html ], Model.node ~tag ~key ~props:json_props [ model ])
  | Async_component (_, component) ->
      let%lwt element = component () in
      to_html ~fiber element
  | Client_component { import_module; import_name; props; client } ->
      let context = Fiber.get_context fiber in
      fiber.emit_html <- (fun html -> context.push html);
      let lwt_props =
        Lwt_list.map_p
          (fun (name, value) ->
            match (value : React.client_value) with
            | Element element ->
                let%lwt _html, model = to_html ~fiber element in
                Lwt.return (name, model)
            | Promise (promise, value_to_json) ->
                let context = Fiber.get_context fiber in
                let _finished, parent_done = Lwt.wait () in
                let index = Fiber.use_index fiber in
                let sync = (name, `String (Model.promise_value index)) in
                let async : Html.element Lwt.t =
                  let%lwt value = promise in
                  let json = value_to_json value in
                  let ret = chunk_script (Model.model_to_chunk index json) in
                  Lwt.return ret
                in
                context.pending <- context.pending + 1;
                Lwt.async (fun () ->
                    let%lwt () = fiber.finished in
                    let%lwt html = async in
                    context.push html;
                    Lwt.wakeup_later parent_done ();
                    context.pending <- context.pending - 1;
                    if context.pending = 0 then context.close ();
                    Lwt.return ());
                Lwt.return sync
            | Json json -> Lwt.return (name, json)
            | Error error ->
                let context = Fiber.get_context fiber in
                let index = Fiber.use_index fiber in
                let error_json = Model.error_to_json ~env:context.env error in
                context.push (error_chunk_script index error_json);
                Lwt.return (name, `String (Model.error_value index))
            | Function action ->
                let context = Fiber.get_context fiber in
                let index = Fiber.use_index fiber in
                let html =
                  chunk_script (Model.model_to_chunk index (`Assoc [ ("id", `String action.id); ("bound", `Null) ]))
                in
                context.push html;
                Lwt.return (name, `String (Model.action_value index)))
          props
      in
      let lwt_html = client_to_html ~fiber client in
      let%lwt () = Lwt.pause () in
      let index = Fiber.use_index fiber in
      let ref : json = Model.component_ref ~module_:import_module ~name:import_name in
      fiber.emit_html (client_reference_chunk_script index ref);
      let%lwt html, props = Lwt.both lwt_html lwt_props in
      let model = Model.node ~tag:(Model.ref_value index) ~key:None ~props [] in
      Lwt.return (html, model)
  | Suspense { key; children; fallback } -> (
      let%lwt html_fallback, model_fallback = to_html ~fiber fallback in
      let context = fiber.context in
      let _finished, parent_done = Lwt.wait () in
      let promise = to_html ~fiber children in
      match Lwt.state promise with
      | Lwt.Sleep ->
          let index = Fiber.use_index fiber in
          context.pending <- context.pending + 1;
          fiber.emit_html <- (fun html -> context.push html);
          Lwt.async (fun () ->
              let%lwt () = fiber.finished in
              let%lwt html, model = promise in
              context.push (chunk_html_script index html);
              context.push (client_value_chunk_script index model);
              Lwt.wakeup_later parent_done ();
              context.pending <- context.pending - 1;
              if context.pending = 0 then context.close ();
              Lwt.return ());
          Lwt.return
            ( html_suspense_placeholder ~fallback:html_fallback index,
              Model.suspense_placeholder ~key ~fallback:model_fallback index )
      | Lwt.Return (html, model) ->
          let model = Model.suspense_node ~key ~fallback:model_fallback [ model ] in
          Lwt.wakeup_later parent_done ();
          Lwt.return (html_suspense_immediate html, model)
      | Lwt.Fail exn -> Lwt.fail exn)
  | Provider children -> to_html ~fiber children
  | Consumer children -> to_html ~fiber children
  (* TODO: There's a task to remove InnerHtml in ReactDOM and use Html.raw directly. Here is still unclear what do to since we assing dangerouslySetInnerHTML to the right prop on the model. Also, should this model be `Null? *)
  | InnerHtml innerHtml -> Lwt.return (Html.raw innerHtml, `Null)

and elements_to_html ~fiber elements =
  let%lwt html_and_models = elements |> Lwt_list.map_p (to_html ~fiber) in
  (* TODO: List.split is not tail recursive *)
  let htmls, model = List.split html_and_models in
  Lwt.return (Html.list htmls, `List model)

let is_root_html_node element =
  match (element : React.element) with
  | Lower_case_element { tag; _ } -> tag = "html"
  | React.Fragment (React.List [ Lower_case_element { tag = "html"; _ }; _ ]) -> true
  | _ -> false

let is_body element =
  match (element : Html.element) with
  | Html.Node { tag = "body"; _ } -> true
  (* TODO: Look where we set Html.List for one element? *)
  | Html.List (_, [ Html.Node { tag = "body"; _ } ]) -> true
  | _ -> false

let push_children_into html new_children =
  match html with
  | Html.Node { tag; children; attributes } -> Html.Node { tag; attributes; children = children @ new_children }
  (* TODO: Look where we set Html.List for one element? *)
  | Html.List (separator, [ Html.Node { tag; children; attributes } ]) ->
      Html.List (separator, [ Html.Node { tag; attributes; children = children @ new_children } ])
  | _ -> html

(* TODO: Do we need to stop streaming based on some timeout? abortion? *)
(* TODO: Do we need to ensure chunks are of a certain minimum size but also maximum? Saw react caring about this *)
(* TODO: Do we want to add a flag to disable ssr? Do we need to disable the model rendering or can we do it outside? *)
(* TODO: Add all options from renderToReadableStream *)
let render_html ?(env = `Dev) ?(debug = false) ?bootstrapScriptContent ?bootstrapScripts ?bootstrapModules element =
  let initial_index = 0 in
  let htmls = ref [] in
  (* TODO: Cleanup emit_html and use the push function directly? *)
  let emit_html chunk = htmls := chunk :: !htmls in
  let stream, push, close = Push_stream.make () in
  let context : Fiber.context = { push; close; pending = 1; index = initial_index; debug; env } in
  let finished, parent_done = Lwt.wait () in
  let is_root_html_node = is_root_html_node element in
  let fiber : Fiber.t =
    { context; emit_html; finished; hoisted_head = None; hoisted_head_childrens = []; is_root_html_node }
  in
  let%lwt root_html, root_model = to_html ~fiber element in
  let root_chunk = client_value_chunk_script initial_index root_model in
  Lwt.wakeup_later parent_done ();
  context.pending <- context.pending - 1;
  (* In case of not having any task pending, we can close the stream *)
  (match context.pending = 0 with
  | true -> context.close ()
  | false -> ());
  let bootstrap_script_content =
    match bootstrapScriptContent with
    | None -> Html.null
    | Some bootstrapScriptContent -> Html.node "script" [] [ Html.raw bootstrapScriptContent ]
  in
  let scripts =
    match bootstrapScripts with
    | None -> Html.null
    | Some scripts ->
        scripts
        |> List.map (fun script -> Html.node "script" [ Html.attribute "src" script; Html.attribute "async" "" ] [])
        |> Html.list
  in
  let modules =
    match bootstrapModules with
    | None -> Html.null
    | Some modules ->
        modules
        |> List.map (fun script ->
               Html.node "script"
                 [ Html.attribute "src" script; Html.attribute "async" ""; Html.attribute "type" "module" ]
                 [])
        |> Html.list
  in
  let user_scripts =
    if context.pending <> 0 then
      (* TODO: Where rc_function and start_script and start should be? *)
      [ rc_function_script; rsc_start_script; root_chunk; bootstrap_script_content; scripts; modules ]
    else [ bootstrap_script_content; scripts; modules ]
  in
  let html =
    if is_root_html_node then
      let body =
        match is_body root_html with
        | true -> push_children_into root_html user_scripts
        | false -> Html.list (root_html :: user_scripts)
      in
      let hoisted_head_childrens = List.rev fiber.hoisted_head_childrens in
      match fiber.hoisted_head with
      | Some (attribute_list, children) ->
          let head = Html.node "head" attribute_list (children @ hoisted_head_childrens) in
          Html.node "html" [] [ head; body ]
      | None -> Html.node "html" [] [ Html.node "head" [] hoisted_head_childrens; body ]
    else Html.list (root_html :: user_scripts)
  in
  let subscribe fn =
    let fn_with_to_string v = fn (Html.to_string v) in
    let%lwt () = Push_stream.subscribe ~fn:fn_with_to_string stream in
    fn_with_to_string chunk_stream_end_script
  in
  Lwt.return (Html.to_string html, subscribe)

let render_model = Model.render
let create_action_response = Model.create_action_response

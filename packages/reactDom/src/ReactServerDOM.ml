type json = Yojson.Basic.t
type env = [ `Dev | `Prod ]

let is_dev = function `Dev -> true | `Prod -> false

let create_stack_trace () =
  let slots = Printexc.backtrace_slots (Printexc.get_raw_backtrace ()) |> Option.value ~default:[||] in
  let make_locations slot =
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
    | _, _ -> `List [ `String "Unknown function name"; `String "Unknown filename"; `Int 0; `Int 0 ]
  in
  `List (Array.to_list (Array.map make_locations slots))

module Fiber = struct
  type context = {
    mutable index : int;
    mutable pending : int;
    push : Html.element -> unit;
    close : unit -> unit;
    env : env;
  }

  (* TODO: What should we do with captured attributes, merge them? ignore them? Right now we just capture one head element *)
  type hoisted_head = Html.attribute_list * Html.element list

  type t = {
    context : context;
    is_root_element_a_html_node : bool;
    mutable hoisted_head : hoisted_head option;
    mutable hoisted_head_childrens : Html.element list;
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
  let style_to_json style = `Assoc (List.map (fun (_, jsx_key, value) -> (jsx_key, `String value)) style)

  let make_error_json ~env ~message ~stack ~digest : json =
    match is_dev env with
    | true ->
        `Assoc [ ("message", `String message); ("stack", stack); ("env", `String "Server"); ("digest", `String digest) ]
    (*
      In prod we don't emit any information about this Error object to avoid
      unintentional leaks. Use the digest to identify the registered error.
      REF: https://github.com/facebook/react/blob/e81fcfe3f201a8f626e892fb52ccbd0edba627cb/packages/react-client/src/ReactFlightClient.js#L2086-L2101
    *)
    | false -> `Assoc [ ("digest", `String digest) ]

  let exn_to_error ~env exn =
    let message = Printexc.to_string exn in
    let stack = create_stack_trace () in
    make_error_json ~env ~message ~stack ~digest:""

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
    | React.JSX.Action _ -> None

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
      | [ `Null ] -> props
      | [ one_children ] -> ("children", one_children) :: props
      | childrens -> ("children", `List childrens) :: props
    in
    `List [ `String "$"; `String tag; key; `Assoc props; debugId; source; owner ]

  (* Not using `node` because we need to add fallback prop as json directly *)
  let suspense_node ~key ~fallback children : json =
    let fallback_prop = ("fallback", fallback) in
    let props =
      match children with
      | [] -> [ fallback_prop ]
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
          let attributes =
            List.map
              (fun prop ->
                match prop with
                | React.JSX.Action (_, key, f) ->
                    let id = use_chunk_id context in
                    context.push id (Chunk_value (`Assoc [ ("id", `String f.id); ("bound", `Null) ]));
                    React.JSX.String (key, key, action_value id)
                | _ -> prop)
              attributes
          in
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
      | Upper_case_component (name, component) -> (
          match component () with
          | element ->
              if context.debug then (
                let index = get_chunk_id context in
                let debug_info_index = use_chunk_id context in
                let debug_info_ref : json = `String (Printf.sprintf "$%x" debug_info_index) in
                context.push debug_info_index (Chunk_value (make_debug_info name));
                context.push index (Debug_info_map debug_info_ref);
                ());

              (* TODO: Can we remove the is_root difference. It currently align with react.js behavior, but it's not clear what is the purpose of it *)
              if is_root.contents then (
                is_root := false;
                turn_element_into_payload ~context element)
              else
                let index = use_chunk_id context in
                context.push index (Chunk_value (turn_element_into_payload ~context element));
                `String (ref_value index)
          | exception exn ->
              let index = use_chunk_id context in
              let error_json = exn_to_error ~env:context.env exn in
              context.push index (Chunk_error error_json);
              `String (lazy_value index))
      | Async_component (_, component) -> (
          (* TODO: Need to check for is_root? *)
          let promise = component () in
          match Lwt.state promise with
          | Fail exn ->
              let index = use_chunk_id context in
              let message = Printexc.to_string exn in
              let stack = create_stack_trace () in
              let error_json = make_error_json ~env:context.env ~message ~stack ~digest:"" in
              context.push index (Chunk_error error_json);
              `String (lazy_value index)
          | Return element -> turn_element_into_payload ~context element
          | Sleep ->
              let index = use_chunk_id context in
              context.pending <- context.pending + 1;
              Lwt.async (fun () ->
                  try%lwt
                    let%lwt element = promise in
                    context.pending <- context.pending - 1;
                    context.push index (Chunk_value (turn_element_into_payload ~context element));
                    if context.pending = 0 then context.close ();
                    Lwt.return ()
                  with exn ->
                    let message = Printexc.to_string exn in
                    let stack = create_stack_trace () in
                    let error_json = make_error_json ~env:context.env ~message ~stack ~digest:"" in
                    context.push index (Chunk_error error_json);
                    context.pending <- context.pending - 1;
                    Lwt.return ());
              `String (lazy_value index))
      | Suspense { key; children; fallback } ->
          (* TODO: Need to check is_root? *)
          (* TODO: Maybe we need to push suspense index and suspense node separately *)
          let fallback = turn_element_into_payload ~context fallback in
          suspense_node ~key ~fallback [ turn_element_into_payload ~context children ]
      | Client_component { import_module; import_name; props; client = _ } ->
          let id = use_chunk_id context in
          let ref = component_ref ~module_:import_module ~name:import_name in
          context.push id (Chunk_component_ref ref);
          let client_props = client_values_to_json ~context props in
          node ~tag:(ref_value id) ~key:None ~props:client_props []
      (* TODO: Do we need to do anything with Provider and Consumer? *)
      | Provider children -> turn_element_into_payload ~context children
      | Consumer children -> turn_element_into_payload ~context children
    in
    turn_element_into_payload ~context element

  and client_value_to_json ~context value =
    match (value : React.client_value) with
    | Json json -> json
    | Error error ->
        let chunk_id = use_chunk_id context in
        let error_json =
          make_error_json ~env:context.env ~message:error.message ~stack:error.stack ~digest:error.digest
        in
        context.push chunk_id (Chunk_error error_json);
        `String (error_value context.chunk_id)
    | Element element ->
        let chunk_id = use_chunk_id context in
        context.push chunk_id (Chunk_value (element_to_payload ~context element));
        `String (ref_value chunk_id)
    | Promise (promise, value_to_json) -> (
        match Lwt.state promise with
        | Return value ->
            let chunk_id = use_chunk_id context in
            let json = value_to_json value in
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
            (* TODO: https://github.com/ml-in-barcelona/server-reason-react/issues/251 *)
            raise exn)
    | Function action ->
        let chunk_id = use_chunk_id context in
        context.push chunk_id (Chunk_value (`Assoc [ ("id", `String action.id); ("bound", `Null) ]));
        `String (action_value chunk_id)

  and client_values_to_json ~context props =
    List.map (fun (name, value) -> (name, client_value_to_json ~context value)) props

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
    match subscribe with None -> Lwt.return () | Some subscribe -> Lwt_stream.iter_s subscribe stream

  let create_action_response ?(env = `Dev) ?(debug = false) ?subscribe response =
    let%lwt response =
      try%lwt response
      with exn ->
        let message = Printexc.to_string exn in
        let stack = create_stack_trace () in
        (* TODO: Improve it to be an UUID *)
        let digest = stack |> Yojson.Basic.to_string |> Hashtbl.hash |> Int.to_string in
        Lwt.return (React.Error { message; stack; env = "Server"; digest })
    in
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
    match subscribe with None -> Lwt.return () | Some subscribe -> Lwt_stream.iter_s subscribe stream
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
  | InnerHtml innerHtml -> Lwt.return (Html.raw innerHtml)
  | Fragment children -> client_to_html ~fiber children
  | List childrens ->
      let%lwt html = Lwt_list.map_p (client_to_html ~fiber) childrens in
      Lwt.return (Html.list html)
  | Array childrens ->
      let%lwt html = childrens |> Array.to_list |> Lwt_list.map_p (client_to_html ~fiber) in
      Lwt.return (Html.list html)
  | Lower_case_element { key; tag; attributes; children } ->
      let context = Fiber.get_context fiber in
      let attributes =
        List.map
          (fun prop ->
            match prop with
            | React.JSX.Action (_, key, f) ->
                let index = Fiber.use_index fiber in
                let html =
                  chunk_script (Model.model_to_chunk index (`Assoc [ ("id", `String f.id); ("bound", `Null) ]))
                in
                context.push html;
                React.JSX.String (key, key, Model.action_value index)
            | _ -> prop)
          attributes
      in
      render_lower_case ~fiber ~key ~tag ~attributes ~children
  | Upper_case_component (_name, component) ->
      let rec wait_for_suspense_to_resolve () =
        match component () with
        | exception React.Suspend (Any_promise promise) ->
            let%lwt _ = promise in
            wait_for_suspense_to_resolve ()
        | exception _exn -> Lwt.return Html.null
        | output -> client_to_html ~fiber output
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
      let index = Fiber.use_index fiber in
      let sync = html_suspense_placeholder ~fallback index in
      let async = children |> client_to_html ~fiber |> Lwt.map (chunk_html_script index) in
      context.pending <- context.pending + 1;
      Lwt.async (fun () ->
          let%lwt html = async in
          context.push html;
          context.pending <- context.pending - 1;
          if context.pending = 0 then context.close ();
          Lwt.return ());
      Lwt.return sync
  | Client_component { import_module = _; import_name = _; props = _; client } -> client_to_html ~fiber client
  | Provider children -> client_to_html ~fiber children
  | Consumer children -> client_to_html ~fiber children

and render_lower_case ~fiber ~key:_ ~tag ~attributes ~children =
  let html_props = ReactDOM.attributes_to_html attributes in
  if Html.is_self_closing_tag tag then Lwt.return (Html.node tag html_props [])
  else
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
  | Upper_case_component (_name, component) -> (
      (* if debug then (
        let debug_info_index = Fiber.use_index fiber in
        let debug_info_ref : json = `String (Printf.sprintf "$%x" debug_info_index) in
        (* TODO: Chunks might need to be pushed in the same row *)
        context.push debug_info_index (Model.Chunk_value (Model.make_debug_info name));
        context.push debug_info_index (Model.Debug_info_map debug_info_ref);
        ()); *)
      match component () with
      | element -> to_html ~fiber element)
  | Lower_case_element { key; tag; attributes; children } ->
      if fiber.is_root_element_a_html_node && tag = "head" then (
        (* in case of a head element, we hoist it to the top of the document, and avoid rendering it in the current node *)
        let html_attributes = ReactDOM.attributes_to_html attributes in
        let%lwt html_and_json = children |> Lwt_list.map_p (to_html ~fiber) in
        let html, model = List.split html_and_json in
        Fiber.push_hoisted_head ~fiber html_attributes html;
        let json = Model.node ~tag:"head" ~key:None ~props:(Model.props_to_json attributes) model in
        Lwt.return (Html.null, json))
      else if fiber.is_root_element_a_html_node && is_a_head_child_tag tag then (
        let children = ReactDOM.moveDangerouslyInnerHtmlAsChildren attributes children in
        let html_props = ReactDOM.attributes_to_html attributes in
        let%lwt children_html, children_model = elements_to_html ~fiber children in
        (* TODO: Could we improve this to avoid the need of normalizing the children model? *)
        (* elements_to_html always returns a list, and meta/link cannot have children,
           if any tag has dangerouslySetInnerHTML, the returned of the moveDangerouslyInnerHtmlAsChildren will be [ InnerHtml innerHtml ]
           which is `List [ `Null ] for the model, so we normalize it all `Null *)
        let normalized_children_model =
          match children_model with `List [ `Null ] | `List [] -> `Null | _ -> children_model
        in
        let html = Html.node tag html_props [ children_html ] in
        Fiber.push_hoisted_head_childrens ~fiber html;
        let json = Model.node ~tag ~key:None ~props:(Model.props_to_json attributes) [ normalized_children_model ] in
        Lwt.return (Html.null, json))
      else if fiber.is_root_element_a_html_node && tag = "html" then
        (* Since we want to reconstruct the document outside of to_html (in case of root being the html tag), we keep rendering the childrens and avoid rendering html element *)
        to_html ~fiber (React.List children)
      else
        let children = ReactDOM.moveDangerouslyInnerHtmlAsChildren attributes children in
        let context = Fiber.get_context fiber in
        let html_props = ReactDOM.attributes_to_html attributes in
        let json_attributes =
          List.map
            (fun prop ->
              match prop with
              | React.JSX.Action (_, key, f) ->
                  let index = Fiber.use_index fiber in
                  let html =
                    chunk_script (Model.model_to_chunk index (`Assoc [ ("id", `String f.id); ("bound", `Null) ]))
                  in
                  context.push html;
                  React.JSX.String (key, key, Model.action_value index)
              | _ -> prop)
            attributes
        in
        let json_props = Model.props_to_json json_attributes in
        if Html.is_self_closing_tag tag then
          let empty_children = (* there's no children for self closing tags *) [] in
          Lwt.return (Html.node tag html_props empty_children, Model.node ~tag ~key ~props:json_props empty_children)
        else
          let%lwt html, model = elements_to_html ~fiber children in
          Lwt.return (Html.node tag html_props [ html ], Model.node ~tag ~key ~props:json_props [ model ])
  | Async_component (_, component) ->
      let%lwt element = component () in
      to_html ~fiber element
  | Client_component { import_module; import_name; props; client } ->
      let context = Fiber.get_context fiber in
      let lwt_props =
        Lwt_list.map_p
          (fun (name, value) ->
            match (value : React.client_value) with
            | Element element ->
                let%lwt _html, model = to_html ~fiber element in
                Lwt.return (name, model)
            | Promise (promise, value_to_json) ->
                let index = Fiber.use_index fiber in
                let async : Html.element Lwt.t =
                  let%lwt value = promise in
                  let json = value_to_json value in
                  let ret = chunk_script (Model.model_to_chunk index json) in
                  Lwt.return ret
                in
                context.pending <- context.pending + 1;
                Lwt.async (fun () ->
                    let%lwt html = async in
                    context.push html;
                    context.pending <- context.pending - 1;
                    if context.pending = 0 then context.close ();
                    Lwt.return ());
                Lwt.return (name, `String (Model.promise_value index))
            | Json json -> Lwt.return (name, json)
            | Error error ->
                let index = Fiber.use_index fiber in
                let error_json =
                  Model.make_error_json ~env:context.env ~stack:error.stack ~message:error.message ~digest:error.digest
                in
                context.push (error_chunk_script index error_json);
                Lwt.return (name, `String (Model.error_value index))
            | Function action ->
                let index = Fiber.use_index fiber in
                let html =
                  chunk_script (Model.model_to_chunk index (`Assoc [ ("id", `String action.id); ("bound", `Null) ]))
                in
                context.push html;
                Lwt.return (name, `String (Model.action_value index)))
          props
      in
      let lwt_html = client_to_html ~fiber client in
      let index = Fiber.use_index fiber in
      let ref : json = Model.component_ref ~module_:import_module ~name:import_name in
      context.push (client_reference_chunk_script index ref);
      let%lwt html, props = Lwt.both lwt_html lwt_props in
      let model = Model.node ~tag:(Model.ref_value index) ~key:None ~props [] in
      Lwt.return (html, model)
  | Suspense { key; children; fallback } -> (
      let context = Fiber.get_context fiber in
      let index = Fiber.use_index fiber in
      let%lwt html_fallback, model_fallback = to_html ~fiber fallback in
      try%lwt
        let promise = to_html ~fiber children in
        match Lwt.state promise with
        | Sleep ->
            context.pending <- context.pending + 1;
            Lwt.async (fun () ->
                try%lwt
                  let%lwt html, model = promise in
                  context.push (chunk_html_script index html);
                  context.push (client_value_chunk_script index model);
                  context.pending <- context.pending - 1;
                  if context.pending = 0 then context.close ();
                  Lwt.return ()
                with exn ->
                  context.pending <- context.pending - 1;
                  let error_json = Model.exn_to_error ~env:context.env exn in
                  context.push (error_chunk_script index error_json);
                  context.push (chunk_html_script index Html.null);
                  Lwt.return ());
            Lwt.return
              ( html_suspense_placeholder ~fallback:html_fallback index,
                Model.suspense_placeholder ~key ~fallback:model_fallback index )
        | Return (html, model) ->
            let model = Model.suspense_node ~key ~fallback:model_fallback [ model ] in
            Lwt.return (html_suspense_immediate html, model)
        | Fail exn -> Lwt.reraise exn
      with exn ->
        let context = Fiber.get_context fiber in
        let error_json = Model.exn_to_error ~env:context.env exn in
        let html = html_suspense_placeholder ~fallback:html_fallback index in
        context.push (error_chunk_script index error_json);
        context.push (chunk_html_script index Html.null);
        Lwt.return (html, Model.suspense_placeholder ~key ~fallback:model_fallback index))
  | Provider children -> to_html ~fiber children
  | Consumer children -> to_html ~fiber children
  (* TODO: There's a task to remove InnerHtml in ReactDOM and use Html.raw directly. Here is still unclear what do to since we assing dangerouslySetInnerHTML to the right prop on the model. Also, should this model be `Null? *)
  | InnerHtml innerHtml -> Lwt.return (Html.raw innerHtml, `Null)

and elements_to_html ~fiber elements =
  let%lwt html_and_models = elements |> Lwt_list.map_p (to_html ~fiber) in
  (* TODO: List.split is not tail recursive *)
  let htmls, model = List.split html_and_models in
  Lwt.return (Html.list htmls, `List model)

let rec is_root_element_a_html_node element =
  match (element : React.element) with
  | Lower_case_element { tag = "html"; _ } -> true
  | Upper_case_component (_, component) -> is_root_element_a_html_node (component ())
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
let render_html ?(skipRoot = false) ?(env = `Dev) ?debug:(_ = false) ?bootstrapScriptContent ?bootstrapScripts
    ?bootstrapModules element =
  let initial_index = 0 in
  let stream, push, close = Push_stream.make () in
  let context : Fiber.context = { push; close; pending = 1; index = initial_index; env } in
  let is_root_element_a_html_node = is_root_element_a_html_node element in
  let fiber : Fiber.t = { context; hoisted_head = None; hoisted_head_childrens = []; is_root_element_a_html_node } in
  let%lwt root_html, root_model = to_html ~fiber element in
  let root_chunk = client_value_chunk_script initial_index root_model in
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
  let user_scripts = [ rc_function_script; rsc_start_script; root_chunk; bootstrap_script_content; scripts; modules ] in
  let html =
    if is_root_element_a_html_node then
      let body =
        match (is_body root_html, skipRoot) with
        | true, false -> push_children_into root_html user_scripts
        | true, true -> Html.list user_scripts
        | false, _ -> Html.list (root_html :: user_scripts)
      in
      let hoisted_head_childrens = List.rev fiber.hoisted_head_childrens in
      match fiber.hoisted_head with
      | Some (attribute_list, children) ->
          let head = Html.node "head" attribute_list (children @ hoisted_head_childrens) in
          Html.node "html" [] [ head; body ]
      | None -> Html.node "html" [] [ Html.node "head" [] hoisted_head_childrens; body ]
    else if skipRoot then Html.list user_scripts
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

type server_function =
  | FormData of (Yojson.Basic.t array -> Js.FormData.t -> React.client_value Lwt.t)
  | Body of (Yojson.Basic.t array -> React.client_value Lwt.t)

type model = Reference of string | FormData of string | Undefined | Json of json

let parseModel model =
  match model with
  | `String value when String.starts_with ~prefix:"$" value -> (
      let prefix = String.sub value 1 1 in
      match prefix with
      | "u" -> Undefined
      | "K" -> FormData (String.sub value 2 (String.length value - 2))
      | _ -> Reference (String.sub value 1 (String.length value - 1)))
  | `String value -> Json (`String value)
  | _ -> Json model

let decodeReply body =
  match Yojson.Basic.from_string body with
  | `List args ->
      args
      |> List.filter_map (fun arg ->
             match parseModel arg with
             (* For now we only support json args *)
             | Json json -> Some json
             | _ -> None)
      |> Array.of_list
  | _ -> raise (Invalid_argument "Invalid args, this request was not created by server-reason-react")

let decodeFormDataReply formData =
  let input_prefix = ref None in
  let decodeArgs body =
    match Yojson.Basic.from_string body with
    | `List args -> args |> List.map (fun arg -> parseModel arg)
    | _ -> raise (Invalid_argument "Invalid args, this request was not created by server-reason-react")
  in

  let formDataEntries = Js.FormData.entries formData in
  let args =
    Js.FormData.get formData "0" |> function
    | `String model ->
        decodeArgs model
        |> List.filter_map (function
             (* For now we only support json args *)
             | Json json -> Some json
             | FormData id ->
                 input_prefix := Some id;
                 None
             | _ -> None)
        |> Array.of_list
  in
  let rec aux acc = function
    | [] -> acc
    | (key, value) :: entries -> (
        if key = "0" then aux acc entries
        else
          match !input_prefix with
          | Some id ->
              let form_prefix = id ^ "_" in
              let key = String.sub key (String.length form_prefix) (String.length key - String.length form_prefix) in
              Js.FormData.append acc key value;
              aux acc entries
          | None ->
              Js.FormData.append acc key value;
              aux acc entries)
  in
  (args, aux (Js.FormData.make ()) formDataEntries)

module type FunctionReferences = sig
  type t

  val registry : t
  val register : string -> server_function -> unit
  val get : string -> server_function option
end

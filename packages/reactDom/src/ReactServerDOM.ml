type json = Yojson.Basic.t
type env = [ `Dev | `Prod ]

let is_dev = function `Dev -> true | `Prod -> false
let make_error ~message ~stack ~digest = { React.message; stack; env = "Server"; digest }

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

module Stream = struct
  type 'a t = { push : 'a -> unit; close : unit -> unit; mutable index : int; mutable pending : int }

  let push to_chunk ~context =
    let index = context.index in
    context.index <- context.index + 1;
    context.push (to_chunk index);
    index

  let push_async promise_to_chunk ~context =
    let index = context.index in
    context.index <- context.index + 1;
    context.pending <- context.pending + 1;
    Lwt.async (fun () ->
        let%lwt to_chunk = promise_to_chunk in
        context.pending <- context.pending - 1;
        context.push (to_chunk index);
        if context.pending = 0 then context.close ();
        Lwt.return ());
    index

  let make ~initial_index =
    let stream, push, close = Push_stream.make () in
    (stream, { push; close; pending = 0; index = initial_index })
end

(* Resources module maintains insertion order while deduplicating based on src/href *)
module Resources = struct
  let get_attribute ~key:key_to_get (attributes : Html.attribute_list) =
    List.find_map
      (fun attr -> match attr with `Value (key, value) when String.equal key key_to_get -> Some value | _ -> None)
      attributes

  let resource_key item =
    match (item : Html.node) with
    | { tag = "script"; attributes; _ } -> get_attribute ~key:"src" attributes
    | { tag = "link"; attributes; _ } -> get_attribute ~key:"href" attributes
    | _ -> None

  let add resource resources =
    match resource_key resource with
    | None -> resources @ [ Html.Node resource ]
    | Some key ->
        (* Ensure if this resource already exists, it gets deduplicated *)
        let exists = List.exists (function Html.Node node -> resource_key node = Some key | _ -> false) resources in
        if exists then resources else resources @ [ Html.Node resource ]
end

module Fiber = struct
  type t = {
    context : Html.element Stream.t;
    env : env;
    (* visited_first_lower_case stores the tag of the first lower case element visited, useful to know if the root element is an html tag *)
    mutable visited_first_lower_case : string option;
    (* hoisted_head stores the <head> element's attributes and direct children *)
    mutable hoisted_head : Html.node option;
    (* hoisted_head_childrens collects elements that should be in the document's <head> (title, meta, link, style) even if they weren't originally inside a <head> element *)
    mutable hoisted_head_childrens : Html.element list;
    (* resources collects link, script that should preload, prefetch to be in the document's <head> and deduplicates them based on "src" or "href" attributes, respectively *)
    mutable resources : Html.element list;
    (* inside_head tracks whether we're currently processing elements inside a <head> element *)
    mutable inside_head : bool;
    (* inside_body tracks whether we're currently processing elements inside a <body> element *)
    mutable inside_body : bool;
    (* As we reconstruct the html tag, html_tag_attributes collects the attributes of the <html> tag *)
    mutable html_tag_attributes : Html.attribute_list;
  }

  let model_to_chunk model index =
    Html.raw
      (Printf.sprintf "<script data-payload='%s'>window.srr_stream.push()</script>"
         (Html.single_quote_escape (Model.to_chunk model index)))

  let boundary_to_chunk html index =
    let rc_replacement b s = Html.node "script" [] [ Html.raw (Printf.sprintf "$RC('B:%x', 'S:%x')" b s) ] in
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
        Html.node "template" [ Html.attribute "id" (Printf.sprintf "B:%x" id) ] [];
        fallback;
        Html.raw "<!--/$-->";
      ]

  let chunk_stream_end_script = Html.node "script" [] [ Html.raw "window.srr_stream.close()" ]
  let set_html_tag_attributes ~fiber html_attributes = fiber.html_tag_attributes <- html_attributes
  let push_hoisted_head ~fiber head = fiber.hoisted_head <- Some head
  let push_resource ~fiber resource = fiber.resources <- Resources.add resource fiber.resources

  let push_hoisted_head_childrens ~fiber children =
    fiber.hoisted_head_childrens <- fiber.hoisted_head_childrens @ [ Node children ]

  let visited_first_lower_case ~fiber = fiber.visited_first_lower_case
  let set_visited_first_lower_case ~fiber value = fiber.visited_first_lower_case <- Some value
end

module Model = struct
  type chunk = Value of json | Debug_ref of json | Component_ref of json | Error of env * React.error

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

  let exn_to_error exn =
    let message = Printexc.to_string exn in
    let stack = create_stack_trace () in
    { React.message; stack; env = "Server"; digest = "" }

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

  let value_to_chunk id value =
    let buf = Buffer.create (4 * 1024) in
    Buffer.add_string buf (Printf.sprintf "%x:" id);
    Yojson.Basic.write_json buf value;
    Buffer.add_string buf "\n";
    Buffer.contents buf

  let debug_info_to_chunk id debug_info =
    let buf = Buffer.create (4 * 1024) in
    Buffer.add_string buf (Printf.sprintf "%x:D" id);
    Yojson.Basic.write_json buf debug_info;
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

  let to_chunk value id =
    match value with
    | Value value -> value_to_chunk id value
    | Debug_ref debug_info -> debug_info_to_chunk id debug_info
    | Component_ref ref -> client_reference_to_chunk id ref
    | Error (env, error) ->
        let error_json = make_error_json ~env ~message:error.message ~stack:error.stack ~digest:error.digest in
        error_to_chunk id error_json

  (* TODO: currently it's implemented only `ReactComponentInfo` from https://github.com/facebook/react/blob/152080276c61873fdfc88db7f5856332742ddb02/packages/react-server/src/ReactFlightServer.js#L3208-L3216, it lacks other types *)
  (* TODO: Add props, stack *)
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

  let push_debug_info ~context ~to_chunk ~env ~index ~ownerName =
    let current_index = index in
    if is_dev env then
      let index = Stream.push ~context (to_chunk (Value (make_debug_info ownerName))) in
      let debug_info_ref = Printf.sprintf "$%x" index in
      (* 
            React pushes the debug ref in the same level as the Upper_case_component payload 
            So we don't use Stream.push here
            Instead we use context.push directly
          *)
      context.push (to_chunk (Debug_ref (`String debug_info_ref)) current_index) |> ignore
    else ()

  let rec element_to_payload ~context ?(debug = false) ~to_chunk ~env element =
    let is_root = ref true in

    let rec turn_element_into_payload element =
      match (element : React.element) with
      | Empty -> `Null
      | DangerouslyInnerHtml _ ->
          raise
            (Invalid_argument
               "InnerHtml does not exist in RSC, this is a bug in server-reason-react.ppx or a wrong construction of \
                JSX manually")
      (* TODO: Do we need to html encode the model or only the html? *)
      | Text t -> `String t
      | Lower_case_element { key; tag; attributes; children } ->
          let attributes =
            List.map
              (fun prop ->
                match prop with
                | React.JSX.Action (_, key, f) ->
                    let index =
                      Stream.push ~context (to_chunk (Value (`Assoc [ ("id", `String f.id); ("bound", `Null) ])))
                    in
                    React.JSX.String (key, key, action_value index)
                | _ -> prop)
              attributes
          in
          let props = props_to_json attributes in
          node ~key ~tag ~props (List.map turn_element_into_payload children)
      | Fragment children ->
          if is_root.contents then is_root := false;
          turn_element_into_payload children
      | List children ->
          if is_root.contents then is_root := false;
          `List (List.map turn_element_into_payload children)
      | Array children ->
          if is_root.contents then is_root := false;
          `List (Array.map turn_element_into_payload children |> Array.to_list)
      (* TODO: Get the stack info from component as well *)
      | Upper_case_component (name, component) -> (
          match component () with
          | element ->
              (* TODO: Can we remove the is_root difference. It currently align with react.js behavior, but it's not clear what is the purpose of it *)
              if is_root.contents then (
                is_root := false;
                (*
                  If it's the root element, React returns the element payload instead of a reference value. 
                  Root is a special case: https://github.com/facebook/react/blob/f3a803617ec4ba9d14bf5205ffece28ed1496a1d/packages/react-server/src/ReactFlightServer.js#L756-L766 
                *)
                if debug then push_debug_info ~context ~to_chunk ~env ~index:0 ~ownerName:name else ();
                turn_element_into_payload element)
              else
                (* If it's not the root React push the element to the stream and return the reference value *)
                let element_index =
                  Stream.push ~context (fun index ->
                      if debug then push_debug_info ~context ~to_chunk ~env ~index ~ownerName:name else ();
                      let payload = turn_element_into_payload element in
                      to_chunk (Value payload) index)
                in
                `String (ref_value element_index)
          | exception exn ->
              let error = exn_to_error exn in
              let index = Stream.push ~context (to_chunk (Error (env, error))) in
              `String (lazy_value index))
      (* TODO: Get the stack info from component *)
      | Async_component (_, component) -> (
          let promise = component () in
          match Lwt.state promise with
          | Fail exn ->
              let message = Printexc.to_string exn in
              let stack = create_stack_trace () in
              let error = make_error ~message ~stack ~digest:"" in
              let index = Stream.push ~context (to_chunk (Error (env, error))) in
              `String (lazy_value index)
          | Return element -> turn_element_into_payload element
          | Sleep ->
              let promise =
                try%lwt
                  let%lwt element = promise in
                  Lwt.return (to_chunk (Value (turn_element_into_payload element)))
                with exn ->
                  let message = Printexc.to_string exn in
                  let stack = create_stack_trace () in
                  let error = make_error ~message ~stack ~digest:"" in
                  Lwt.return (to_chunk (Error (env, error)))
              in
              let index = Stream.push_async promise ~context in
              `String (lazy_value index))
      | Suspense { key; children; fallback } ->
          (* TODO: Need to check is_root? *)
          (* TODO: Maybe we need to push suspense index and suspense node separately *)
          (* Suspense boundaries should not be treated as root for their children *)
          let was_root = is_root.contents in
          is_root := false;
          let fallback = turn_element_into_payload fallback in
          let children_payload = turn_element_into_payload children in
          is_root := was_root;
          suspense_node ~key ~fallback [ children_payload ]
      | Client_component { import_module; import_name; props; client = _ } ->
          let ref = component_ref ~module_:import_module ~name:import_name in
          let index = Stream.push ~context (to_chunk (Component_ref ref)) in
          let client_props = client_values_to_json ~context ~to_chunk ~env props in
          node ~tag:(ref_value index) ~props:client_props []
      (* TODO: Do we need to do anything with Provider and Consumer? *)
      | Provider children -> turn_element_into_payload children
      | Consumer children -> turn_element_into_payload children
    in
    turn_element_into_payload element

  and client_value_to_json ~context ?debug ~to_chunk ~env value =
    match (value : React.client_value) with
    | Json json -> json
    | Error error ->
        let index = Stream.push ~context (to_chunk (Error (env, error))) in
        `String (error_value index)
    | Element element -> element_to_payload ~context ?debug ~to_chunk ~env element
    | Promise (promise, value_to_json) -> (
        match Lwt.state promise with
        | Return value ->
            let json = value_to_json value in
            let index = Stream.push ~context (to_chunk (Value json)) in
            `String (promise_value index)
        | Sleep ->
            let promise =
              try%lwt
                let%lwt value = promise in
                Lwt.return (to_chunk (Value (value_to_json value)))
              with exn ->
                let message = Printexc.to_string exn in
                let stack = create_stack_trace () in
                let error = make_error ~message ~stack ~digest:"" in
                Lwt.return (to_chunk (Error (env, error)))
            in
            let index = Stream.push_async promise ~context in
            `String (promise_value index)
        | Fail exn ->
            (* TODO: https://github.com/ml-in-barcelona/server-reason-react/issues/251 *)
            raise exn)
    | Function action ->
        let index = Stream.push ~context (to_chunk (Value (`Assoc [ ("id", `String action.id); ("bound", `Null) ]))) in
        `String (action_value index)

  and client_values_to_json ~context ~to_chunk ~env props =
    List.map (fun (name, value) -> (name, client_value_to_json ~context ~to_chunk ~env value)) props

  let render ?(env = `Dev) ?(debug = false) ?subscribe element =
    let stream, context = Stream.make ~initial_index:0 in
    let to_root_chunk element id =
      let payload = element_to_payload ~debug ~context ~to_chunk ~env element in
      to_chunk (Value payload) id
    in
    Stream.push ~context (to_root_chunk element) |> ignore;
    if context.pending = 0 then context.close ();
    match subscribe with None -> Lwt.return () | Some subscribe -> Lwt_stream.iter_s subscribe stream

  let create_action_response ?(env = `Dev) ?(debug = false) ?subscribe response =
    let%lwt response =
      try%lwt response
      with exn ->
        let message = Printexc.to_string exn in
        let stack = create_stack_trace () in
        (* TODO: Improve it to be an UUID *)
        let digest = stack |> Hashtbl.hash |> Int.to_string in
        Lwt.return (React.Error { message; stack; env = "Server"; digest })
    in
    let stream, context = Stream.make ~initial_index:0 in
    let to_root_chunk value id =
      let payload = client_value_to_json ~debug ~context ~to_chunk ~env value in
      to_chunk (Value payload) id
    in
    Stream.push ~context (to_root_chunk response) |> ignore;
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

let rec client_to_html ~(fiber : Fiber.t) (element : React.element) =
  match element with
  | Empty -> Lwt.return Html.null
  | DangerouslyInnerHtml html -> Lwt.return (Html.raw html)
  | Text text -> Lwt.return (Html.string text)
  | Fragment children -> client_to_html ~fiber children
  | List childrens ->
      let%lwt html = Lwt_list.map_p (client_to_html ~fiber) childrens in
      Lwt.return (Html.list html)
  | Array childrens ->
      let%lwt html = childrens |> Array.to_list |> Lwt_list.map_p (client_to_html ~fiber) in
      Lwt.return (Html.list html)
  | Lower_case_element { key; tag; attributes; children } ->
      let context = fiber.context in
      let attributes =
        List.map
          (fun prop ->
            match prop with
            | React.JSX.Action (_, key, f) ->
                let json = `Assoc [ ("id", `String f.id); ("bound", `Null) ] in
                let index = Stream.push ~context (Fiber.model_to_chunk (Value json)) in
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
      let context = fiber.context in
      let async =
        let%lwt html = children |> client_to_html ~fiber in
        Lwt.return (Fiber.boundary_to_chunk html)
      in
      let index = Stream.push_async ~context async in
      let sync = Fiber.html_suspense_placeholder ~fallback index in
      Lwt.return sync
  | Client_component { import_module = _; import_name = _; props = _; client } -> client_to_html ~fiber client
  | Provider children -> client_to_html ~fiber children
  | Consumer children -> client_to_html ~fiber children

and render_lower_case ~fiber ~key:_ ~tag ~attributes ~children =
  let html_props = ReactDOM.attributes_to_html attributes in
  match ReactDOM.getDangerouslyInnerHtml attributes with
  | Some inner_html -> Lwt.return (Html.node tag html_props [ Html.raw inner_html ])
  | None ->
      let%lwt html = Lwt_list.map_p (client_to_html ~fiber) children in
      Lwt.return (Html.node tag html_props html)

let is_async props =
  let open React.JSX in
  let has_async prop = match prop with Bool ("async", _, value) -> value | _ -> false in
  List.exists has_async props

let has_precedence_and_rel_stylesheet props =
  let open React.JSX in
  let has_precedence prop = match prop with String ("precedence", _, _) -> true | _ -> false in
  let has_rel_stylesheet prop = match prop with String ("rel", _, "stylesheet") -> true | _ -> false in
  List.exists has_precedence props && List.exists has_rel_stylesheet props

let rec render_element_to_html ~(fiber : Fiber.t) (element : React.element) : (Html.element * json) Lwt.t =
  match element with
  | Empty -> Lwt.return (Html.null, `Null)
  (* Should the DangerouslyInnerHtml model be `Null? *)
  | DangerouslyInnerHtml html -> Lwt.return (Html.raw html, `Null)
  | Text s -> Lwt.return (Html.string s, `String s)
  | Fragment children -> render_element_to_html ~fiber children
  | List list -> elements_to_html ~fiber list
  | Array arr -> elements_to_html ~fiber (Array.to_list arr)
  | Upper_case_component (_name, component) -> (
      (* if debug then (
          let debug_info_index = Fiber.use_index fiber in
          let debug_info_ref : json = `String (Printf.sprintf "$%x" debug_info_index) in
          (* TODO: Chunks might need to be pushed in the same row *)
          context.push debug_info_index (Model.Value (Model.make_debug_info name));
          context.push debug_info_index (Model.Debug_ref debug_info_ref);
          ()); *)
      match component () with
      | element -> render_element_to_html ~fiber element)
  | Async_component (_, component) ->
      let%lwt element = component () in
      render_element_to_html ~fiber element
  | Client_component { import_module; import_name; props; client } ->
      let context = fiber.context in
      let env = fiber.env in
      let props = Model.client_values_to_json ~context ~to_chunk:Fiber.model_to_chunk ~env props in
      let%lwt html = client_to_html ~fiber client in
      let ref : json = Model.component_ref ~module_:import_module ~name:import_name in
      let index = Stream.push ~context (Fiber.model_to_chunk (Component_ref ref)) in
      let model = Model.node ~tag:(Model.ref_value index) ~props [] in
      Lwt.return (html, model)
  | Suspense { key; children; fallback } -> (
      let context = fiber.context in
      let%lwt html_fallback, model_fallback = render_element_to_html ~fiber fallback in
      try%lwt
        let promise = render_element_to_html ~fiber children in
        match Lwt.state promise with
        | Sleep ->
            let promise =
              try%lwt
                let%lwt html, model = promise in
                let to_chunk index =
                  Html.list [ Fiber.boundary_to_chunk html index; Fiber.model_to_chunk (Value model) index ]
                in
                Lwt.return to_chunk
              with exn ->
                let message = Printexc.to_string exn in
                let stack = create_stack_trace () in
                let error = make_error ~message ~stack ~digest:"" in
                let to_chunk index = Fiber.model_to_chunk (Error (fiber.env, error)) index in
                Lwt.return to_chunk
            in
            let index = Stream.push_async ~context promise in
            Lwt.return
              ( Fiber.html_suspense_placeholder ~fallback:html_fallback index,
                Model.suspense_placeholder ~key ~fallback:model_fallback index )
        | Return (html, model) ->
            let model = Model.suspense_node ~key ~fallback:model_fallback [ model ] in
            Lwt.return (Fiber.html_suspense_immediate html, model)
        | Fail exn -> Lwt.reraise exn
      with exn ->
        let context = fiber.context in
        let error = Model.exn_to_error exn in
        let to_chunk index =
          Html.list [ Fiber.model_to_chunk (Error (fiber.env, error)) index; Fiber.boundary_to_chunk Html.null index ]
        in
        let index = Stream.push ~context to_chunk in
        let html = Fiber.html_suspense_placeholder ~fallback:html_fallback index in
        Lwt.return (html, Model.suspense_placeholder ~key ~fallback:model_fallback index))
  | Provider children -> render_element_to_html ~fiber children
  | Consumer children -> render_element_to_html ~fiber children
  | Lower_case_element { key; tag; attributes; children } ->
      render_lower_case_element ~fiber ~key ~tag ~attributes ~children ()

and render_lower_case_element ~fiber ~key ~tag ~attributes ~children () =
  (* Head hoisting mechanism:
       Head elements (meta, style, title, etc) might be scattered throughout the component tree but need to be rendered in the <head> section. Also, if there's no head element, we need to create one and hoist its possible children. *)
  let inner_html = ReactDOM.getDangerouslyInnerHtml attributes in

  (* only set the first element visited true, the first time *)
  (match Fiber.visited_first_lower_case ~fiber with
  | Some _ -> ()
  | None -> Fiber.set_visited_first_lower_case ~fiber tag);

  if fiber.inside_head && not fiber.inside_body then
    render_regular_element ~fiber ~key ~tag ~attributes ~children ~inner_html ()
  else
    match tag with
    | "html" -> (
        match Fiber.visited_first_lower_case ~fiber with
        (* If the first visited lower case is an html element -> skip rendering the html tag itself, just process children. That's because we will reconstuct the html element at the "render_html" *)
        | Some "html" ->
            Fiber.set_html_tag_attributes ~fiber (ReactDOM.attributes_to_html attributes);
            let%lwt html, model = render_regular_element ~fiber ~key ~tag ~attributes ~children ~inner_html () in
            let html_children = match html with Html.Node { children; _ } -> Html.list children | _ -> html in
            Lwt.return (html_children, model)
        (* In case of rendering html tag as not the first visited lower case element, means that something is wrapping this html tag (like a div or other element) which is invalid HTML, but we keep rendering as a regular element, as React.js' DOM renderer does *)
        | _ -> render_regular_element ~fiber ~key ~tag ~attributes ~children ~inner_html ())
    | "body" ->
        fiber.inside_body <- true;
        let%lwt value = render_regular_element ~fiber ~key ~tag ~attributes ~children ~inner_html () in
        fiber.inside_body <- false;
        Lwt.return value
    | "head" ->
        fiber.inside_head <- true;
        (* push the head element to the hoisted_head *)
        let%lwt value =
          handle_hoistable_element ~fiber ~key ~tag ~attributes ~children ~inner_html ~on_push:Fiber.push_hoisted_head
            ()
        in
        fiber.inside_head <- false;
        Lwt.return value
    | tag when (tag = "script" && is_async attributes) || (tag = "link" && has_precedence_and_rel_stylesheet attributes)
      ->
        handle_hoistable_element ~fiber ~key ~tag ~attributes ~children ~inner_html ~on_push:Fiber.push_resource ()
    | tag when tag = "title" || tag = "meta" || tag = "link" ->
        handle_hoistable_element ~fiber ~key ~tag ~attributes ~children ~inner_html
          ~on_push:Fiber.push_hoisted_head_childrens ()
    | _ -> render_regular_element ~fiber ~key ~tag ~attributes ~children ~inner_html ()

and handle_hoistable_element ~fiber ~key ~tag ~attributes ~children ~inner_html ~on_push () =
  let props = Model.props_to_json attributes in
  let create_model children =
    (* In case of the model, we don't care about inner_html as a children since we need it as a prop. This is the opposite from html rendering *)
    match (Html.is_self_closing_tag tag, inner_html) with
    | _, Some _ | true, _ -> Model.node ~tag ~key ~props []
    | false, None -> Model.node ~tag ~key ~props [ children ]
  in
  let create_html_node ~html_props ~children_html =
    match inner_html with
    | Some inner_html -> Html.{ tag; attributes = html_props; children = [ Html.raw inner_html ] }
    | None -> Html.{ tag; attributes = html_props; children = [ children_html ] }
  in

  let html_props = ReactDOM.attributes_to_html attributes in
  let%lwt children_html, children_model = elements_to_html ~fiber children in
  let html = create_html_node ~html_props ~children_html in
  on_push ~fiber html;
  Lwt.return (Html.null, create_model children_model)

and render_regular_element ~fiber ~key ~tag ~attributes ~children ~inner_html () =
  let context = fiber.context in
  let html_props = ReactDOM.attributes_to_html attributes in
  let json_attributes =
    List.map
      (fun prop ->
        match prop with
        | React.JSX.Action (_, key, f) ->
            let html = Fiber.model_to_chunk (Value (`Assoc [ ("id", `String f.id); ("bound", `Null) ])) in
            let index = Stream.push ~context html in
            React.JSX.String (key, key, Model.action_value index)
        | _ -> prop)
      attributes
  in

  let json_props = Model.props_to_json json_attributes in

  match (Html.is_self_closing_tag tag, inner_html) with
  | true, _ ->
      (* Self-closing tags have no children, so inner_html is not relevant *)
      Lwt.return (Html.node tag html_props [], Model.node ~tag ~key ~props:json_props [])
  | false, Some inner_html ->
      (* elements with dangerouslySetInnerHTML *)
      Lwt.return (Html.node tag html_props [ Html.raw inner_html ], Model.node ~tag ~key ~props:json_props [])
  | false, None ->
      let%lwt html, model = elements_to_html ~fiber children in
      Lwt.return (Html.node tag html_props [ html ], Model.node ~tag ~key ~props:json_props [ model ])

and elements_to_html ~fiber elements =
  let%lwt html_and_models = elements |> Lwt_list.map_p (render_element_to_html ~fiber) in
  (* TODO: List.split is not tail recursive *)
  let htmls, model = List.split html_and_models in
  Lwt.return (Html.list htmls, `List model)

let is_body_node element =
  match (element : Html.element) with
  | Html.Node { tag = "body"; _ } -> true
  (* TODO: Look where we set Html.List for one element? *)
  | Html.List (_, [ Html.Node { tag = "body"; _ } ]) -> true
  | _ -> false

let push_children_into ~children:new_children html =
  let open Html in
  match html with
  | Node { tag; children; attributes } -> Node { tag; attributes; children = children @ new_children }
  (* TODO: Look where we set Html.List for one element? *)
  | List (separator, [ Node { tag; children; attributes } ]) ->
      List (separator, [ Node { tag; attributes; children = children @ new_children } ])
  | _ -> html

(* TODO: Implement abortion, based on a timeout? *)
(* TODO: Ensure chunks are of a certain minimum size but also maximum? Saw react caring about this *)
let render_html ?(skipRoot = false) ?(env = `Dev) ?debug:(_ = false) ?bootstrapScriptContent ?bootstrapScripts
    ?bootstrapModules element =
  let initial_resources =
    match bootstrapScripts with
    | Some scripts ->
        List.map
          (fun script ->
            Html.Node
              {
                tag = "link";
                attributes =
                  [
                    Html.attribute "rel" "modulepreload";
                    Html.attribute "fetchPriority" "low";
                    Html.attribute "href" script;
                    (* Html.attribute "as" "script"; *)
                  ];
                children = [];
              })
          scripts
    | None -> (
        match bootstrapModules with
        | Some modules ->
            List.map
              (fun script ->
                Html.Node
                  {
                    tag = "link";
                    attributes =
                      [
                        Html.attribute "rel" "modulepreload";
                        Html.attribute "fetchPriority" "low";
                        Html.attribute "href" script;
                        (* Html.attribute "as" "script"; *)
                      ];
                    children = [];
                  })
              modules
        | None -> [])
  in
  (* Since we don't push the root_data_payload to the stream but return it immediately with the initial HTML, 
     the stream's initial index starts at 1, with index 0 reserved for the root_data_payload. *)
  let stream, context = Stream.make ~initial_index:1 in
  let fiber : Fiber.t =
    {
      context;
      env;
      hoisted_head = None;
      hoisted_head_childrens = [];
      html_tag_attributes = [];
      resources = initial_resources;
      visited_first_lower_case = None;
      inside_head = false;
      inside_body = false;
    }
  in
  let%lwt root_html, root_model = render_element_to_html ~fiber element in
  (* To return the model value immediately, we don't push it to the stream but return it as a payload script together with the user_scripts *)
  let root_data_payload = Fiber.model_to_chunk (Value root_model) 0 in
  (* In case of not having any task pending, we can close the stream *)
  (match context.pending = 0 with true -> context.close () | false -> ());
  let bootstrap_script_content =
    match bootstrapScriptContent with
    | None -> Html.null
    | Some bootstrapScriptContent -> Html.node "script" [] [ Html.raw bootstrapScriptContent ]
  in
  let bootstrap_scripts_nodes =
    match bootstrapScripts with
    | None -> Html.null
    | Some scripts ->
        scripts
        |> List.map (fun script -> Html.node "script" [ Html.attribute "src" script; Html.attribute "async" "" ] [])
        |> Html.list
  in
  let bootstrap_modules_nodes =
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
    [
      rc_function_script;
      rsc_start_script;
      root_data_payload;
      bootstrap_script_content;
      bootstrap_scripts_nodes;
      bootstrap_modules_nodes;
    ]
  in
  let root_element_is_html_tag =
    match Fiber.visited_first_lower_case ~fiber with Some tag -> tag = "html" | None -> false
  in
  let html =
    (* We reconstruct the final HTML document structure with the hoisted elements from `to_html` traversal *)
    if root_element_is_html_tag then
      let body =
        match (is_body_node root_html, skipRoot) with
        | true, false -> push_children_into ~children:user_scripts root_html
        | true, true | false, true -> Html.list user_scripts
        | false, false -> Html.list (root_html :: user_scripts)
      in
      let resources = fiber.resources @ fiber.hoisted_head_childrens in
      match fiber.hoisted_head with
      | Some node ->
          (* If we found a <head> element, use its attributes and combine all children *)
          let head = Html.Node { node with children = node.children @ resources } in
          Html.node "html" fiber.html_tag_attributes [ head; body ]
      | None ->
          (* If no explicit <head> was found, create one with the hoisted children *)
          Html.node "html" fiber.html_tag_attributes [ Html.node "head" [] resources; body ]
    else if skipRoot then Html.list user_scripts
    else Html.list (root_html :: user_scripts)
  in
  let subscribe fn =
    let fn_with_to_string v = fn (Html.to_string v) in
    let%lwt () = Push_stream.subscribe ~fn:fn_with_to_string stream in
    fn_with_to_string Fiber.chunk_stream_end_script
  in
  Lwt.return (Html.to_string html, subscribe)

let render_model = Model.render
let create_action_response = Model.create_action_response

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

type server_function =
  | FormData of (Yojson.Basic.t array -> Js.FormData.t -> React.client_value Lwt.t)
  | Body of (Yojson.Basic.t array -> React.client_value Lwt.t)

module type FunctionReferences = sig
  type t

  val registry : t
  val register : string -> server_function -> unit
  val get : string -> server_function option
end

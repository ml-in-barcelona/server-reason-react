type json = Yojson.Basic.t

module Fiber = struct
  type context = {
    mutable index : int;
    mutable pending : int;
    push : Html.element -> unit;
    close : unit -> unit;
  }

  type t = {
    context : context;
    finished : unit Lwt.t;
    (* QUESTION: Why do I need emit_html as mutable? I see parent, but why overriding? *)
    mutable emit_html : Html.element -> unit;
  }

  let use_index t =
    t.context.index <- t.context.index + 1;
    t.context.index

  let emit_html t html = t.emit_html html

  let root fn =
    let stream, push, close = Push_stream.make () in
    let initial_index = 0 in
    let context = { push; close; pending = 1; index = initial_index } in
    let htmls = ref [] in
    let finished, parent_done = Lwt.wait () in
    let emit_html chunk = htmls := chunk :: !htmls in
    let%lwt html = fn ({ context; emit_html; finished }, initial_index) in
    let shell = Html.list [ Html.list !htmls; html ] in
    Lwt.wakeup_later parent_done ();
    context.pending <- context.pending - 1;
    match context.pending = 0 with
    | true ->
        context.close ();
        Lwt.return (shell, None)
    | false -> Lwt.return (shell, Some stream)

  let task parent fn =
    let context = parent.context in
    let finished, parent_done = Lwt.wait () in
    match fn { context; emit_html = parent.emit_html; finished } with
    | `Fork (async, sync) ->
        context.pending <- context.pending + 1;
        parent.emit_html <- (fun html -> context.push html);
        Lwt.async (fun () ->
            let%lwt () = parent.finished in
            let%lwt html = async in
            context.push html;
            Lwt.wakeup_later parent_done ();
            context.pending <- context.pending - 1;
            if context.pending = 0 then context.close ();
            Lwt.return ());
        Lwt.return sync
    | `Sync sync ->
        Lwt.wakeup_later parent_done ();
        Lwt.return sync
    | `Fail exn -> Lwt.fail exn
end

module Model = struct
  type chunk_type = Chunk_value of json | Chunk_component_ref of json

  type stream_context = {
    push : int -> chunk_type -> unit;
    close : unit -> unit;
    mutable pending : int;
    mutable chunk_id : int;
  }

  let use_index context =
    context.chunk_id <- context.chunk_id + 1;
    context.chunk_id

  let prop_to_json (prop : React.JSX.prop) =
    (* TODO: Add promises/sets/others ??? *)
    match prop with
    (* We ignore the HTML name, and only use the JSX name *)
    | React.JSX.Bool (_, key, value) -> (key, `Bool value)
    | React.JSX.String (_, key, value) -> (key, `String value)
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

  let lazy_value id = Printf.sprintf "$L%x" id
  let promise_value id = Printf.sprintf "$@%x" id
  let ref_value id = Printf.sprintf "$%x" id

  (* Not reusing node because we need to add fallback prop as json directly *)
  let suspense_node ~key ~fallback children : json =
    let fallback_prop = ("fallback", fallback) in
    let props =
      match children with
      | [] -> [ fallback_prop; ("children", `List []) ]
      | [ one ] -> [ fallback_prop; ("children", one) ]
      | _ -> [ fallback_prop; ("children", `List children) ]
    in
    node ~tag:"$Sreact.suspense" ~key ~props []

  let suspense_placeholder ~key ~fallback index =
    suspense_node ~key ~fallback [ `String (lazy_value index) ]

  let component_ref ~module_ ~name =
    let id = `String module_ in
    (* chunks is a webpack thing, we don't need it for now *)
    let chunks = `List [] in
    let component_name = `String name in
    `List [ id; chunks; component_name ]

  let model_to_chunk id json =
    let buf = Buffer.create (4 * 1024) in
    Buffer.add_string buf (Printf.sprintf "%x:" id);
    Yojson.Basic.write_json buf json;
    Buffer.add_string buf "\n";
    Buffer.contents buf

  let client_reference_to_chunk id ref =
    let buf = Buffer.create 256 in
    Buffer.add_string buf (Printf.sprintf "%x:I" id);
    Yojson.Basic.write_json buf ref;
    Buffer.add_string buf "\n";
    Buffer.contents buf

  let element_to_model ~context index element =
    let rec to_payload element =
      match (element : React.element) with
      | Empty -> `Null
      (* TODO: Do we need to html encode this? *)
      | Text t -> `String t
      (* TODO: Add key on the element type? *)
      | Lower_case_element { key; tag; attributes; children } ->
          let props = List.map prop_to_json attributes in
          node ~key ~tag ~props (List.map to_payload children)
      | Fragment children -> to_payload children
      | List children -> `List (Array.map to_payload children |> Array.to_list)
      | InnerHtml _text ->
          (* TODO: Don't have failwith *)
          failwith
            "It does not exist in RSC, this is a bug in server-reason-react or \
             a wrong construction of JSX manually"
      | Upper_case_component component ->
          let element = component () in
          (* Instead of returning the payload directly, we push it, and return a reference to it.
             This is how `react-server-dom-webpack/server` renderToPipeableStream works *)
          let index = use_index context in
          context.push index (Chunk_value (to_payload element));
          `String (ref_value index)
      | Async_component component -> (
          let promise = component () in
          match Lwt.state promise with
          | Fail exn -> raise exn
          | Return element -> to_payload element
          | Sleep ->
              let index = use_index context in
              context.pending <- context.pending + 1;
              Lwt.async (fun () ->
                  let%lwt element = promise in
                  context.pending <- context.pending - 1;
                  context.push index (Chunk_value (to_payload element));
                  if context.pending = 0 then context.close ();
                  Lwt.return ());
              `String (lazy_value index))
      | Suspense { key; children; fallback } ->
          (* TODO: Maybe we need to push suspense index and suspense node separately *)
          let fallback = to_payload fallback in
          suspense_node ~key ~fallback [ to_payload children ]
      | Client_component { import_module; import_name; props; client = _ } ->
          let id = use_index context in
          let ref = component_ref ~module_:import_module ~name:import_name in
          context.push id (Chunk_component_ref ref);
          let client_props = client_props_to_json props in
          node ~tag:(ref_value id) ~key:None ~props:client_props []
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
                  let chunk_id = use_index context in
                  let json = value_to_json value in
                  (* TODO: Make sure why we need a chunk here *)
                  context.push context.chunk_id (Chunk_value json);
                  (name, `String (promise_value chunk_id))
              | Sleep ->
                  let chunk_id = use_index context in
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
    let stream, push, close = Push_stream.make () in
    let push_chunk id chunk =
      match chunk with
      | Chunk_value json -> push (model_to_chunk id json)
      | Chunk_component_ref json -> push (client_reference_to_chunk id json)
    in
    let context : stream_context =
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

let rsc_start_script =
  Html.node "script" []
    [
      Html.raw
        {|
let enc = new TextEncoder();
let srr_stream = (window.srr_stream = {});
srr_stream.push = (value) => {
  srr_stream._c.enqueue(enc.encode(value))
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

let chunk_script script =
  Html.node "script"
    [ Html.attribute "data-payload" (Html.single_quote_escape script) ]
    [
      Html.raw "window.srr_stream.push(document.currentScript.dataset.payload);";
    ]

let client_reference_chunk_script index json =
  chunk_script (Model.client_reference_to_chunk index json)

let client_value_chunk_script index json =
  chunk_script (Model.model_to_chunk index json)

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
      let%lwt html =
        childrens |> Array.to_list |> Lwt_list.map_p (client_to_html ~fiber)
      in
      Lwt.return (Html.list html)
  | Lower_case_element { tag; attributes; _ } when Html.is_self_closing_tag tag
    ->
      let html_props = List.map ReactDOM.attribute_to_html attributes in
      Lwt.return (Html.node tag html_props [])
  | Lower_case_element { key = _; tag; attributes; children } ->
      let html_props = List.map ReactDOM.attribute_to_html attributes in
      let%lwt html = children |> Lwt_list.map_p (client_to_html ~fiber) in
      Lwt.return (Html.node tag html_props html)
  | Upper_case_component component ->
      let rec wait_for_suspense_to_resolve () =
        match component () with
        | exception React.Suspend (Any_promise promise) ->
            let%lwt _ = promise in
            wait_for_suspense_to_resolve ()
        | output ->
            (* TODO: Do we need to care about batching? *)
            client_to_html ~fiber output
      in
      wait_for_suspense_to_resolve ()
  | Async_component _component ->
      (* async components can't be interleaved in client components, for now *)
      (* TODO: Remove failwith *)
      failwith
        "async components can't be part of a client component. This should \
         never raise, the ppx should catch it"
  | Suspense { key = _; children; fallback } ->
      (* TODO: Do we need to care if there's Any_promise raising ? *)
      let%lwt fallback = client_to_html ~fiber fallback in
      Fiber.task fiber (fun fiber ->
          let index = Fiber.use_index fiber in
          let async =
            children |> client_to_html ~fiber
            |> Lwt.map (chunk_html_script index)
          in
          let fallback_as_placeholder =
            html_suspense_placeholder ~fallback index
          in
          `Fork (async, fallback_as_placeholder))
  | Client_component { import_module = _; import_name = _; props = _; client }
    ->
      client_to_html ~fiber client
  (* TODO: Need to do something for those? *)
  | Provider children -> client_to_html ~fiber children
  | Consumer children -> client_to_html ~fiber children
  | InnerHtml innerHtml -> Lwt.return (Html.raw innerHtml)

let rec to_html ~fiber (element : React.element) : (Html.element * json) Lwt.t =
  match element with
  | Empty -> Lwt.return (Html.null, `Null)
  | Text s -> Lwt.return (Html.string s, if not true then `Null else `String s)
  | Fragment children -> to_html ~fiber children
  | List list -> elements_to_html ~fiber (Array.to_list list)
  | Upper_case_component component -> to_html ~fiber (component ())
  | Lower_case_element { key; tag; attributes; _ }
    when Html.is_self_closing_tag tag ->
      let html_props = List.map ReactDOM.attribute_to_html attributes in
      let json_props = List.map Model.prop_to_json attributes in
      Lwt.return
        (Html.node tag html_props [], Model.node ~tag ~key ~props:json_props [])
  | Lower_case_element { key; tag; attributes; children } ->
      let html_props = List.map ReactDOM.attribute_to_html attributes in
      let json_props = List.map Model.prop_to_json attributes in
      let%lwt html, model = elements_to_html ~fiber children in
      Lwt.return
        ( Html.node tag html_props [ html ],
          Model.node ~tag ~key ~props:json_props [ model ] )
  | Async_component component ->
      let%lwt element = component () in
      to_html ~fiber element
  | Client_component { import_module; import_name; props; client } ->
      let lwt_props =
        Lwt_list.map_p
          (fun ((name : string), value) ->
            match (value : React.client_prop) with
            | Element element ->
                let%lwt _html, model = to_html ~fiber element in
                Lwt.return (name, model)
            | Promise (promise, value_to_json) ->
                Fiber.task fiber @@ fun fiber ->
                let index = Fiber.use_index fiber in
                let sync = (name, `String (Model.promise_value index)) in
                let async : Html.element Lwt.t =
                  let%lwt value = promise in
                  let json = value_to_json value in
                  let ret =
                    chunk_script (Model.client_reference_to_chunk index json)
                  in
                  Lwt.return ret
                in
                `Fork (async, sync)
            | Json json -> Lwt.return (name, json))
          props
      in
      let lwt_html = client_to_html ~fiber client in
      (* NOTE: this Lwt.pause () is important as we resolve client component in
         an async way we need to suspend above, otherwise React.js runtime won't work *)
      let%lwt () = Lwt.pause () in
      let%lwt html, props = Lwt.both lwt_html lwt_props in
      let model =
        let index = Fiber.use_index fiber in
        let ref : json =
          Model.component_ref ~module_:import_module ~name:import_name
        in
        fiber.emit_html (client_reference_chunk_script index ref);
        Model.node ~tag:(Model.ref_value index) ~key:None ~props []
      in
      Lwt.return (html, model)
  | Suspense { key; children; fallback } ->
      let%lwt html_fallback, model_fallback = to_html ~fiber fallback in
      Fiber.task fiber (fun fiber ->
          let promise = to_html ~fiber children in
          match Lwt.state promise with
          | Sleep ->
              let index = Fiber.use_index fiber in
              let async_html =
                let%lwt html, model = promise in
                Lwt.return
                  (Html.list
                     [
                       chunk_html_script index html;
                       client_value_chunk_script index model;
                     ])
              in
              let sync_html =
                ( html_suspense_placeholder ~fallback:html_fallback index,
                  Model.suspense_placeholder ~key ~fallback:model_fallback index
                )
              in
              `Fork (async_html, sync_html)
          | Return (html, model) ->
              let model =
                Model.suspense_node ~key ~fallback:model_fallback [ model ]
              in
              `Sync (html_suspense html, model)
          | Fail exn -> `Fail exn)
  | Provider children -> to_html ~fiber children
  | Consumer children -> to_html ~fiber children
  (* TODO: There's a task to remove InnerHtml in ReactDOM and use Html.raw directly. Here is still unclear what do to since we assing dangerouslySetInnerHTML to the right prop on the model. Also, should this model be `Null? *)
  | InnerHtml innerHtml -> Lwt.return (Html.raw innerHtml, `Null)

and elements_to_html ~fiber elements =
  let%lwt html_and_models = elements |> Lwt_list.map_p (to_html ~fiber) in
  let htmls, model = List.split html_and_models in
  Lwt.return (Html.list htmls, `List model)

type rendering =
  | Done of Html.element
  | Async of {
      shell : Html.element;
      subscribe : (Html.element -> unit Lwt.t) -> unit Lwt.t;
    }

(* TODO: Do we need to disable streaming based on some timeout? abortion? *)
(* TODO: Do we need to disable the model rendering? Can we do something better than a boolean? *)
(* TODO: Add scripts and links to the output, also all options from renderToReadableStream *)
let render_to_html element =
  let%lwt html_shell, html_async =
    Fiber.root (fun (fiber, index) ->
        let%lwt html, model = to_html ~fiber element in
        let first_chunk = client_value_chunk_script index model in
        Lwt.return (Html.list [ first_chunk; html ]))
  in
  match html_async with
  | None ->
      let sync_shell =
        Html.list [ rsc_start_script; html_shell; chunk_stream_end_script ]
      in
      Lwt.return (Done sync_shell)
  | Some stream ->
      let html_iter fn =
        let%lwt () = Push_stream.subscribe ~fn stream in
        fn chunk_stream_end_script
      in
      let html_shell =
        Html.list [ rsc_start_script; rc_function_script; html_shell ]
      in
      Lwt.return (Async { shell = html_shell; subscribe = html_iter })

let render_to_model = Model.render

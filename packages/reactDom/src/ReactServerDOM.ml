type json = Yojson.Basic.t

module Fiber
(* : sig
     type t

     val root :
       (t * int -> Html.element Lwt.t) ->
       (Html.element * Html.element Lwt_stream.t option) Lwt.t

     val fork :
       t ->
       (t -> [ `Fail of exn | `Fork of Html.element Lwt.t * 'a | `Sync of 'a ]) ->
       'a Lwt.t

     val update_ctx : t -> 'a React_model.context -> 'a -> t
     val with_ctx : t -> (unit -> 'a) -> 'a * Remote.Context.batch

     val with_ctx_async :
       t -> (unit -> 'a Lwt.t) -> ('a * Remote.Context.batch) Lwt.t

     val use_idx : t -> int
     val emit_html : t -> Html.element -> unit
     val emit_batch : t -> Remote.Context.batch -> unit Lwt.t
   end *) =
struct
  type context = {
    mutable index : int;
    mutable pending : int;
    push : Html.element -> unit; (* remote_ctx : Remote.Context.t; *)
    close : unit -> unit;
  }

  type t = {
    context : context;
    (* react_ctx : Hmap.t; *)
    finished : unit Lwt.t;
    (* QUESTION: Why do I need emit_html as mutable? I see parent  *)
    mutable emit_html : Html.element -> unit;
  }

  let update_ctx _t _ctx _v =
    (* let react_ctx = Hmap.add ctx.React_model.key v t.react_ctx in
       { t with react_ctx } *)
    failwith "TODO"

  let with_ctx _t _f =
    (* let f () = React_model.with_context t.react_ctx f in
       Remote.Context.with_ctx t.ctx.remote_ctx f *)
    failwith "TODO"

  let with_ctx_async _t _f =
    (* let f () = React_model.with_context t.react_ctx f in
       Remote.Context.with_ctx_async t.ctx.remote_ctx f *)
    failwith "TODO"

  let use_idx t =
    t.context.index <- t.context.index + 1;
    t.context.index

  let emit_html t html = t.emit_html html

  let emit_batch _t _batch =
    (* Remote.Context.batch_to_html t.ctx.remote_ctx batch >|= fun html ->
       emit_html t html *)
    failwith "TODO"

  let root fn =
    let stream, push, close = Push_stream.make () in
    let initial_index = 0 in
    let context = { push; close; pending = 1; index = initial_index } in
    let htmls = ref (Some []) in
    let finished, parent_done = Lwt.wait () in
    let emit_html chunk =
      match !htmls with
      | Some chunks -> htmls := Some (chunk :: chunks)
      | None -> failwith "invariant violation: root computation finished"
    in
    let%lwt html =
      fn
        ( { context; emit_html; finished (* react_ctx = Hmap.empty *) },
          initial_index )
    in
    let htmls =
      match !htmls with
      | Some chunks ->
          htmls := None;
          chunks
      | None -> assert false
    in
    let shell = Html.list [ Html.list htmls; html ] in
    Lwt.wakeup_later parent_done ();
    context.pending <- context.pending - 1;
    match context.pending = 0 with
    | true ->
        context.close ();
        Lwt.return (shell, None)
    | false -> Lwt.return (shell, Some stream)

  let fork parent fn =
    let context = parent.context in
    let finished, parent_done = Lwt.wait () in
    let t =
      {
        context;
        emit_html = parent.emit_html;
        (* react_ctx = parent.react_ctx; *)
        finished;
      }
    in
    match fn t with
    | `Fork (async, sync) ->
        context.pending <- context.pending + 1;
        t.emit_html <- (fun html -> context.push html);
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

  let lazy_value idx = Printf.sprintf "$L%x" idx
  let promise_value id = Printf.sprintf "$@%x" id

  (* Not reusing node because we need to add fallback prop as json directly *)
  let suspense_node ~key ~fallback children : json =
    let fallback_prop = ("fallback", fallback) in
    let props =
      match children with
      | [] -> [ fallback_prop ]
      | [ one ] -> [ fallback_prop; ("children", one) ]
      | _ -> [ fallback_prop; ("children", `List children) ]
    in
    node ~tag:"$Sreact.suspense" ~key ~props []

  let suspense_placeholder ~key ~fallback index =
    suspense_node ~key ~fallback [ `String (lazy_value index) ]

  let component_ref ~chunks ~module_ ~name =
    let id = `String module_ in
    let chunks = `List chunks in
    let component_name = `String name in
    `List [ id; chunks; component_name ]

  let payload_to_chunk id json =
    let buf = Buffer.create (4 * 1024) in
    Buffer.add_string buf (Printf.sprintf "%x:" id);
    Yojson.Basic.write_json buf json;
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
      (* TODO: Do we need to html encode this? *)
      | Text t -> `String t
      (* TODO: Add key on the element type? *)
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
          (* TODO: Add chunks *)
          let ref =
            component_ref ~chunks:[] ~module_:import_module ~name:import_name
          in
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
    let stream, push, close = Push_stream.make () in
    let push_chunk id chunk =
      match chunk with
      | Chunk_value json -> push (payload_to_chunk id json)
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

let chunk_script script =
  Html.node "script" []
    [ Html.raw (Printf.sprintf "window.srr_stream.push('%s');" script) ]

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
  | Lower_case_element { tag; attributes; children } ->
      let html_props = List.map ReactDOM.attribute_to_html attributes in
      let%lwt html = children |> Lwt_list.map_p (client_to_html ~fiber) in
      Lwt.return (Html.node tag html_props html)
  (* | El_html { tag_name; key = _; props; children = None } ->
         Lwt.return (Htmlgen.node tag_name props [])
     | El_html
         { tag_name; key = _; props; children = Some (Html_children children) } ->
         client_to_html t children >|= fun children ->
         Htmlgen.node tag_name props [ children ]
     | El_html
         {
           tag_name;
           key = _;
           props;
           children = Some (Html_children_raw { __html });
         } ->
         Lwt.return (Htmlgen.node tag_name props [ Htmlgen.unsafe_raw __html ]) *)
  | Upper_case_component _component ->
      (* TODO: Add support for upper case components *)
      failwith "TODO"
  | Async_component _component ->
      (* async components can't be interleaved in client components *)
      assert false
  | Suspense { children = _; fallback } ->
      let%lwt _fallback = client_to_html ~fiber fallback in
      (* let%lwt children = client_to_html ~push children in *)
      failwith "TODO"
      (* Fiber.fork t @@ fun t ->
         let idx = Fiber.use_idx t in
         let async = client_to_html t children >|= Emit_html.html_chunk idx in
         `Fork (async, Emit_html.html_suspense_placeholder fallback idx) *)
  | Client_component { import_module = _; import_name = _; props = _; children }
    ->
      client_to_html ~fiber children
  (* TODO: Need to do something for those? *)
  | Provider children -> client_to_html ~fiber children
  | Consumer children -> client_to_html ~fiber children
  | InnerHtml innerHtml -> Lwt.return (Html.raw innerHtml)

(* TODO: Push is to be used for streaming, when implementing async components, suspense, etc. *)
let rec to_html ~(fiber : Fiber.t) (element : React.element) :
    (Html.element * json) Lwt.t =
  (* TODO: Add key into Lower_case elements? *)
  let key = Some "0" in
  match element with
  | Empty -> Lwt.return (Html.null, `Null)
  | Text s -> Lwt.return (Html.string s, if not true then `Null else `String s)
  | Fragment children -> to_html ~fiber children
  | List list -> elements_to_html ~fiber (Array.to_list list)
  | Upper_case_component component -> to_html ~fiber (component ())
  | Lower_case_element { tag; attributes; _ } when Html.is_self_closing_tag tag
    ->
      let html_props = List.map ReactDOM.attribute_to_html attributes in
      let json_props = List.map Model.prop_to_json attributes in
      Lwt.return
        (Html.node tag html_props [], Model.node ~tag ~key ~props:json_props [])
  | Lower_case_element { tag; attributes; children } ->
      let html_props = List.map ReactDOM.attribute_to_html attributes in
      let json_props = List.map Model.prop_to_json attributes in
      let%lwt html, model = elements_to_html ~fiber children in
      Lwt.return
        ( Html.node tag html_props [ html ],
          Model.node ~tag ~key ~props:json_props [ model ] )
  | Async_component component ->
      let%lwt element = component () in
      to_html ~fiber element
  | Client_component { import_module; import_name; props = _; children } ->
      (* TODO: Transform props to json *)
      let lwt_props = Lwt.return [] in
      (* let props =
           Lwt_list.map_p
             (fun (name, jsony) ->
               match jsony with
               | React_model.Element element ->
                   server_to_html ~render_model t element
                   >|= fun (_html, model) -> name, model
               | Promise (promise, value_to_json) ->
                   Fiber.fork t @@ fun t ->
                   let idx = Fiber.use_idx t in
                   let sync =
                     ( name,
                       if not render_model then Render_to_model.null
                       else Render_to_model.promise_value idx )
                   in
                   let async =
                     promise >|= fun value ->
                     let json = value_to_json value in
                     Emit_model.html_model (idx, C_value json)
                   in
                   `Fork (async, sync)
               | Json json -> Lwt.return (name, json))
             props
         in *)
      let lwt_html = client_to_html ~fiber children in
      (* NOTE: this Lwt.pause () is important as we resolve client component in
               an async way we need to suspend above, otherwise React.js runtime won't work *)
      let%lwt () = Lwt.pause () in
      let%lwt html, props = Lwt.both lwt_html lwt_props in
      let model =
        let index = 0 in
        let ref : json =
          Model.component_ref ~chunks:[] ~module_:import_module
            ~name:import_name
        in
        fiber.emit_html
          (chunk_script (Model.client_reference_to_chunk index ref));
        Model.node ~tag:(Printf.sprintf "$%x" index) ~key:None ~props []
      in
      Lwt.return (html, model)
  | Suspense { children; fallback } -> (
      let%lwt _html_fallback, model_fallback = to_html ~fiber fallback in
      (* FORK *)
      let promise = to_html ~fiber children in
      match Lwt.state promise with
      | Lwt.Return (html, model) ->
          let model =
            Model.suspense_node ~key ~fallback:model_fallback [ model ]
          in
          Lwt.return (html_suspense html, model)
      | Lwt.Fail _exn -> failwith "TODO"
      | Lwt.Sleep -> failwith "TODO")
  | Provider children -> to_html ~fiber children
  | Consumer children -> to_html ~fiber children
  (* TODO: There's a task to remove InnerHtml in ReactDOM  and use Html.raw directly. Here is still unclear what do to since we assing dangerouslySetInnerHTML to the right prop on the model. Also, should this model be `Null? *)
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

(* TODO: Add Async for async/suspense/client components *)
(* TODO: Do we need to disable streaming based on some timeout? abortion? *)
(* TODO: Do we need to disable the model rendering? Can we do something better than a boolean? *)
(* TODO: Add scripts and links to the output, also all options from renderToReadableStream *)
let render_to_html element =
  let _stream, _push, _ = Push_stream.make () in
  let%lwt html_shell, html_async =
    Fiber.root (fun (fiber, index) ->
        let%lwt html, model = to_html ~fiber element in
        let first_chunk =
          chunk_script (Model.client_reference_to_chunk index model)
        in
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
        let%lwt () = Lwt_stream.iter_s fn stream in
        fn chunk_stream_end_script
      in
      let html_shell =
        Html.list [ rsc_start_script; rc_function_script; html_shell ]
      in
      Lwt.return (Async { shell = html_shell; subscribe = html_iter })

let render_to_model = Model.render

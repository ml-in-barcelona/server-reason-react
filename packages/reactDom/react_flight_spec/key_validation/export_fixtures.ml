let span ?key text = React.createElementWithKey ?key "span" [] [ React.string text ]
let pair () = [ span "a"; span "b" ]
let keyed_pair () = [ span ~key:"a" "a"; span ~key:"b" "b" ]
let host children = React.createElement "div" [] children
let no_release () = ()

let client ?key ?(props = []) children =
  React.Client_component
    {
      key;
      import_module = "key-validation-client";
      import_name = "default";
      props = ("children", React.Model.Element children) :: props;
      client =
        React.createElement "section"
          [ React.JSX.String ("data-client", "data-client", "true") ]
          [ children; React.createElement "button" [] [ React.string "count:0" ] ];
    }

let suspense children =
  React.Suspense.make
    (React.Suspense.makeProps ~children
       ~fallback:(React.createElement "p" [ React.JSX.String ("id", "id", "pending") ] [ React.string "pending" ])
       ())

let document children =
  React.createElement "html" []
    [
      React.createElement "head" [] [ React.createElement "title" [] [ React.string "Flight key validation" ] ];
      React.createElement "body" []
        [ React.createElement "main" [ React.JSX.String ("id", "id", "result") ] [ children ] ];
    ]

type fixture = {
  name : string;
  missing : bool;
  duplicate : bool;
  text : string;
  pending : bool;
  document : bool;
  hydration : bool;
  debug : bool;
  error : bool;
  make : unit -> React.element * (unit -> unit);
}

let case ?(missing = false) ?(duplicate = false) ?(text = "ab") ?(pending = false) ?(document = false)
    ?(hydration = false) ?(debug = false) ?(error = false) name make =
  { name; missing; duplicate; text; pending; document; hydration; debug; error; make }

let sync make () = (make (), no_release)

let extracted () =
  match host [ span "a" ] with
  | React.Lower_case_element { children; _ } -> React.Children.only (React.list children)
  | _ -> failwith "host constructor must retain its children"

let forward render children = React.Upper_case_component ("Forward", fun () -> render children)

let async_collection ~ready ~keyed () =
  let value = React.list (if keyed then keyed_pair () else pair ()) in
  let promise, release =
    if ready then (Lwt.return value, no_release)
    else
      let promise, resolver = Lwt.wait () in
      (promise, fun () -> Lwt.wakeup resolver value)
  in
  (suspense (React.Async_component ("AsyncCollection", fun () -> promise)), release)

let promise_props ~ready ~keyed ~reverse () =
  let value =
    React.Model.List (List.map (fun el -> React.Model.Element el) (if keyed then keyed_pair () else pair ()))
  in
  let promise, release =
    if ready then (Lwt.return value, no_release)
    else
      let promise, resolver = Lwt.wait () in
      (promise, fun () -> Lwt.wakeup resolver value)
  in
  let shared = React.Model.Promise (promise, Fun.id) in
  let props = [ ("promise", shared); ("other", shared) ] in
  (suspense (client ~props:(if reverse then List.rev props else props) React.null), release)

let hydration ~pending ~dynamic () =
  let content () = client (host (if dynamic then [ React.list (pair ()) ] else pair ())) in
  if pending then
    let promise, resolver = Lwt.wait () in
    ( document
        (suspense
           (React.Async_component
              ( "PendingDocument",
                fun () ->
                  let%lwt () = promise in
                  Lwt.return (content ()) ))),
      fun () -> Lwt.wakeup resolver () )
  else (document (content ()), no_release)

let fixtures =
  [
    case "static-host" (sync (fun () -> host (pair ())));
    case "jsx-host" (sync Jsx_cases.host);
    case "jsx-fragment" (sync Jsx_cases.fragment);
    case "jsx-component" (sync Jsx_cases.component);
    case ~text:"a" "jsx-singleton" (sync Jsx_cases.singleton);
    case ~missing:true "jsx-dynamic-component" (sync Jsx_cases.dynamic);
    case ~missing:true "jsx-dynamic-fragment" (sync Jsx_cases.fragment_dynamic);
    case ~missing:true ~text:"fixedab" "jsx-mixed" (sync Jsx_cases.mixed);
    case ~missing:true "unkeyed-list" (sync (fun () -> host [ React.list (pair ()) ]));
    case ~missing:true "unkeyed-array" (sync (fun () -> host [ React.array (Array.of_list (pair ())) ]));
    case ~missing:true ~text:"a" "singleton-list" (sync (fun () -> host [ React.list [ span "a" ] ]));
    case ~missing:true ~text:"a" "singleton-array" (sync (fun () -> host [ React.array [| span "a" |] ]));
    case "keyed-list" (sync (fun () -> host [ React.list (keyed_pair ()) ]));
    case "keyed-array" (sync (fun () -> host [ React.array (Array.of_list (keyed_pair ())) ]));
    case ~duplicate:true "duplicate-keys"
      (sync (fun () -> host [ React.list [ span ~key:"same" "a"; span ~key:"same" "b" ] ]));
    case ~missing:true ~text:"a" "extracted-static" (sync (fun () -> host [ React.list [ extracted () ] ]));
    case ~missing:true ~text:"a" "cloned-static"
      (sync (fun () -> host [ React.array [| React.cloneElement (extracted ()) [] |] ]));
    case ~text:"a" "forwarded-host-slot" (sync (fun () -> forward (fun children -> host [ children ]) (span "a")));
    case ~missing:true ~text:"a" "forwarded-list"
      (sync (fun () -> forward (fun children -> host [ React.list [ children ] ]) (span "a")));
    case ~missing:true ~text:"aa" "shared-static-first"
      (sync (fun () ->
           let shared = span "a" in
           host [ host [ shared ]; host [ React.list [ shared ] ] ]));
    case ~missing:true ~text:"aa" "shared-dynamic-first"
      (sync (fun () ->
           let shared = span "a" in
           host [ host [ React.list [ shared ] ]; host [ shared ] ]));
    case ~text:"abcount:0" "client-static" (sync (fun () -> client (Jsx_cases.fragment ())));
    case ~missing:true ~text:"abcount:0" "client-list" (sync (fun () -> client (React.list (pair ()))));
    case ~missing:true ~text:"acount:0" "client-extracted" (sync (fun () -> client (React.list [ extracted () ])));
    case ~missing:true ~text:"abcount:0" "client-model-list"
      (sync (fun () ->
           client
             ~props:[ ("items", React.Model.List (List.map (fun el -> React.Model.Element el) (pair ()))) ]
             React.null));
    case ~text:"abcount:0" "client-model-keyed-list"
      (sync (fun () ->
           client
             ~props:[ ("items", React.Model.List (List.map (fun el -> React.Model.Element el) (keyed_pair ()))) ]
             React.null));
    case ~missing:true ~text:"abcount:0" "client-model-assoc"
      (sync (fun () ->
           client
             ~props:
               [
                 ( "data",
                   React.Model.Assoc
                     [ ("items", React.Model.List (List.map (fun el -> React.Model.Element el) (pair ()))) ] );
               ]
             React.null));
    case ~missing:true "async-ready" (async_collection ~ready:true ~keyed:false);
    case ~missing:true ~pending:true "async-pending" (async_collection ~ready:false ~keyed:false);
    case ~pending:true "async-keyed" (async_collection ~ready:false ~keyed:true);
    case ~missing:true ~debug:true ~pending:true "async-debug" (async_collection ~ready:false ~keyed:false);
    case ~missing:true ~text:"abcount:0" "promise-ready" (promise_props ~ready:true ~keyed:false ~reverse:false);
    case ~missing:true ~text:"abcount:0" "promise-ready-reversed" (promise_props ~ready:true ~keyed:false ~reverse:true);
    case ~missing:true ~text:"abcount:0" ~pending:true "promise-pending"
      (promise_props ~ready:false ~keyed:false ~reverse:false);
    case ~missing:true ~text:"abcount:0" ~pending:true "promise-pending-reversed"
      (promise_props ~ready:false ~keyed:false ~reverse:true);
    case ~text:"abcount:0" ~pending:true "promise-keyed" (promise_props ~ready:false ~keyed:true ~reverse:false);
    case ~document:true "document-mount" (sync (fun () -> document (host (pair ()))));
    case ~document:true ~hydration:true ~text:"abcount:0" "document-hydration" (hydration ~pending:false ~dynamic:false);
    case ~document:true ~hydration:true ~pending:true ~text:"abcount:0" "document-pending-hydration"
      (hydration ~pending:true ~dynamic:false);
    case ~document:true ~hydration:true ~missing:true ~text:"abcount:0" "document-unkeyed-hydration"
      (hydration ~pending:false ~dynamic:true);
    case ~document:true ~hydration:true ~pending:true ~missing:true ~text:"abcount:0"
      "document-unkeyed-pending-hydration" (hydration ~pending:true ~dynamic:true);
    case ~error:true "server-error-redaction"
      (sync (fun () -> React.Upper_case_component ("Failure", fun () -> failwith "private-key-validation-error")));
  ]

let strings values = `List (List.map (fun value -> `String value) values)

let export env_name env fixture =
  let element, release = fixture.make () in
  let chunks = ref [] in
  let subscribe chunk =
    chunks := chunk :: !chunks;
    Lwt.return ()
  in
  let%lwt shell, initial_chunks =
    if fixture.hydration then (
      let%lwt shell, stream =
        ReactServerDOM.render_html ?env ~debug:fixture.debug ~progressive_chunk_size:1
          ~bootstrapModules:[ "./browser.js" ] element
      in
      let finished = stream subscribe in
      let initial_chunks = List.length !chunks in
      release ();
      let%lwt () = finished in
      Lwt.return (shell, initial_chunks))
    else
      let finished = ReactServerDOM.render_model ?env ~debug:fixture.debug ~subscribe element in
      let initial_chunks = List.length !chunks in
      release ();
      let%lwt () = finished in
      Lwt.return ("", initial_chunks)
  in
  Lwt.return
    (`Assoc
       [
         ("name", `String fixture.name);
         ("env", `String env_name);
         ("missing", `Bool fixture.missing);
         ("duplicate", `Bool fixture.duplicate);
         ("text", `String fixture.text);
         ("pending", `Bool fixture.pending);
         ("document", `Bool fixture.document);
         ("hydration", `Bool fixture.hydration);
         ("debug", `Bool fixture.debug);
         ("error", if fixture.error then `String "decode" else `Null);
         ("shell", `String shell);
         ("initialChunks", `Int initial_chunks);
         ("chunks", strings (List.rev !chunks));
       ])

let () =
  let all =
    Lwt_main.run
      (Lwt_list.map_s
         (fun (name, env) -> Lwt_list.map_s (export name env) fixtures)
         [ ("default", None); ("Prod", Some `Prod); ("Dev", Some `Dev) ])
  in
  Yojson.Basic.to_channel stdout (`List (List.concat all));
  output_char stdout '\n'

let test title fn = Alcotest.test_case title `Quick fn
let fallback ~context:_ ~search:_ ~error = RouterEngine.Plan.failure ~scopes:[] ~error ()

let contains ~needle value =
  let limit = String.length value - String.length needle in
  let rec loop index =
    index <= limit && (String.equal (String.sub value index (String.length needle)) needle || loop (index + 1))
  in
  loop 0

let registry seen : ((React.element, string) RouterEngine.Plan.t, string, unit) RouterEngine.EndpointRegistry.t =
  let endpoint =
    let metadata =
      RouterEngine.Plan.Scope.make ~metadata:(fun () -> Lwt.return (RouterRuntime.Metadata.make ~title:"Item" ())) ()
    in
    RouterEngine.Endpoint.make ~id:"item" ~path:"/item"
      ~activeRoutes:[ ("item", []) ]
      ~fingerprint:"item"
      ~decode:(fun _input ->
        seen := DreamRouter.get_header "X-Test";
        Ok
          (RouterEngine.Endpoint.prepared ~branch:[] ~execution:(fun () ->
               RouterEngine.Execution.done_
                 (RouterEngine.Plan.success ~scopes:[ metadata ]
                    ~page:(React.createElement "main" [] [ React.string "item" ])))))
  in
  RouterEngine.EndpointRegistry.makeExn [ endpoint ]

let server ?(basePath = "/app") registry =
  RouterEngine.Server.make ~basePath ~registry ~fallback
    ~applicationStatus:(fun _ -> RouterRuntime.Status.InternalServerError)
    ()

let document ~head children =
  React.createElement "html" []
    [
      React.createElement "head" []
        [ React.createElement "meta" [ React.JSX.String ("name", "name", "router-shell") ] []; head ];
      React.createElement "body" [] [ children ];
    ]

let ssr request = match Dream.query request "ssr" with Some "false" -> false | Some "true" | Some _ | None -> true

let handler seen request =
  let routes =
    DreamRouter.routes
      ~context:(fun _ -> ())
      ~server:(server (registry seen))
      ~actionHandler:(fun _ -> Dream.empty `OK)
      ~diagnosticId:(fun _ -> "diagnostic")
      ~revision:(fun () -> "revision")
      ~ssr ~document ()
  in
  Dream.router routes request

let rsc_request_uses_context_and_headers () =
  let seen = ref None in
  let request =
    Dream.request ~target:"/app/item?tag=one"
      ~headers:[ ("Accept", "application/react.component"); ("X-Test", "context") ]
      ""
  in
  let response = Dream.test (handler seen) request in
  Alcotest.(check int) "status" 200 (Dream.status response |> Dream.status_to_int);
  Alcotest.(check (option string))
    "content type" (Some "application/react.component") (Dream.header response "Content-Type");
  Alcotest.(check (option string)) "response kind" (Some "full") (Dream.header response "Router-Response");
  Alcotest.(check (option string)) "cache control" (Some "private, no-store") (Dream.header response "Cache-Control");
  Alcotest.(check (option string)) "context" (Some "context") !seen

let document_request_uses_html () =
  let seen = ref None in
  let request = Dream.request ~target:"/app/item" "" in
  let response = Dream.test (handler seen) request in
  Alcotest.(check int) "status" 200 (Dream.status response |> Dream.status_to_int);
  Alcotest.(check (option string))
    "content type" (Some "text/html; charset=utf-8") (Dream.header response "Content-Type");
  let body = Lwt_main.run (Dream.body response) in
  Alcotest.(check bool) "metadata title" true (contains ~needle:"<title>Item</title>" body);
  Alcotest.(check bool) "ssr marker" true (contains ~needle:"id=\"ssr-query-param\"" body);
  Alcotest.(check bool) "routed markup" true (contains ~needle:"<main>item</main>" body);
  Alcotest.(check bool)
    "client props" true
    (contains ~needle:{|"routes":["/item"],"interceptLinks":true,"viewTransitions":false|} body);
  Alcotest.(check bool) "default page cache" true (contains ~needle:{|"pageCacheCapacity":30,|} body)

let document_request_can_disable_ssr () =
  let seen = ref None in
  let request = Dream.request ~target:"/app/item?ssr=false" "" in
  let response = Dream.test (handler seen) request in
  Alcotest.(check int) "status" 200 (Dream.status response |> Dream.status_to_int);
  let body = Lwt_main.run (Dream.body response) in
  Alcotest.(check bool) "document shell" true (contains ~needle:"<meta name=\"router-shell\" />" body);
  Alcotest.(check bool) "ssr marker" false (contains ~needle:"id=\"ssr-query-param\"" body);
  Alcotest.(check bool) "routed markup" false (contains ~needle:"<main>item</main>" body);
  Alcotest.(check bool) "RSC payload" true (contains ~needle:"item" body)

let document_request_can_enable_ssr () =
  let seen = ref None in
  let request = Dream.request ~target:"/app/item?ssr=true" "" in
  let response = Dream.test (handler seen) request in
  Alcotest.(check int) "status" 200 (Dream.status response |> Dream.status_to_int);
  let body = Lwt_main.run (Dream.body response) in
  Alcotest.(check bool) "routed markup" true (contains ~needle:"<main>item</main>" body)

let check_accept ~rsc accept =
  let seen = ref None in
  let request = Dream.request ~target:"/app/item" ~headers:[ ("Accept", accept) ] "" in
  let response = Dream.test (handler seen) request in
  Alcotest.(check int) "status" 200 (Dream.status response |> Dream.status_to_int);
  let expected = if rsc then "application/react.component" else "text/html; charset=utf-8" in
  Alcotest.(check (option string)) accept (Some expected) (Dream.header response "Content-Type")

let rejects_other_accept_values () =
  [
    "text/html";
    "APPLICATION/REACT.COMPONENT";
    "application/react.component; charset=utf-8";
    "application/react.component; q=0";
    "text/html, application/react.component";
    "application/react.componentish";
    "application/*";
  ]
  |> List.iter (check_accept ~rsc:false)

let unicode_base_path_is_routed () =
  let routes =
    DreamRouter.routes
      ~context:(fun _ -> ())
      ~server:(server ~basePath:"/m%C3%BCnchen" (registry (ref None)))
      ~actionHandler:(fun _ -> Dream.empty `OK)
      ~document:(fun ~head:_ children -> children)
      ()
  in
  let request = Dream.request ~target:"/m%C3%BCnchen/item" "" in
  let response = Dream.test (Dream.router routes) request in
  Alcotest.(check int) "status" 200 (Dream.status response |> Dream.status_to_int)

let root_base_path_handler () =
  Dream.router
    (DreamRouter.routes
       ~context:(fun _ -> ())
       ~server:(server ~basePath:"/" (registry (ref None)))
       ~actionHandler:(fun _ -> Dream.empty `OK)
       ~document:(fun ~head:_ children -> children)
       ())

let root_base_path_is_routed () =
  let response = Dream.test (root_base_path_handler ()) (Dream.request ~target:"/item" "") in
  Alcotest.(check int) "status" 200 (Dream.status response |> Dream.status_to_int)

let root_base_path_never_redirects_off_origin () =
  List.iter
    (fun target ->
      let response = Dream.test (root_base_path_handler ()) (Dream.request ~target "") in
      match Dream.header response "Location" with
      | Some location when String.starts_with ~prefix:"//" location ->
          Alcotest.failf "%s redirected to %s" target location
      | _ -> ())
    [ "//evil.example/"; "//h//evil.example/"; "/item/" ]

let shared_action_dispatcher_handles_mount () =
  let calls = ref 0 in
  let action _request =
    incr calls;
    Dream.empty `OK
  in
  let router =
    Dream.router
      (DreamRouter.routes
         ~context:(fun _ -> ())
         ~server:(server (registry (ref None)))
         ~actionHandler:action
         ~document:(fun ~head:_ children -> children)
         ())
  in
  let same_origin = [ ("Host", "example.com"); ("Origin", "http://example.com") ] in
  let nested = Dream.request ~method_:`POST ~target:"/app/nested/route" ~headers:same_origin "" in
  let root = Dream.request ~method_:`POST ~target:"/app" ~headers:same_origin "" in
  let _response = Dream.test router nested in
  let _response = Dream.test router root in
  Alcotest.(check int) "calls" 2 !calls

let action_timeout_bounds_execution () =
  let action, _resolve_action = Lwt.task () in
  let canceled = ref false in
  Lwt.on_cancel action (fun () -> canceled := true);
  let lookup = function
    | "hang" ->
        Some
          (ReactServerDOM.Body
             (fun _args -> Lwt.bind action (fun () -> Lwt.return (React.Model.Element (React.string "Too late")))))
    | _ -> None
  in
  let request =
    Dream.request ~method_:`POST ~target:"/app"
      ~headers:[ ("ACTION_ID", "hang"); ("Content-Type", "application/json") ]
      "[]"
  in
  let response =
    Lwt_main.run
      (Lwt.pick
         [
           DreamRouter.streamFunctionResponse ~timeout:0.01 ~lookup request;
           Lwt.bind (Lwt_unix.sleep 0.2) (fun () -> Alcotest.fail "the action exceeded its response timeout");
         ])
  in
  let body = Lwt_main.run (Dream.body response) in
  Alcotest.(check bool) "action canceled" true !canceled;
  Alcotest.(check string)
    "timeout row" "0:E{\"message\":\"The render timed out.\",\"stack\":null,\"env\":\"Server\",\"digest\":\"\"}\n" body

let successful_action_preserves_cookie_and_wire_output () =
  let lookup = function
    | "save" ->
        Some
          (ReactServerDOM.Body
             (fun _args ->
               Lwt.bind (Lwt.pause ()) (fun () ->
                   DreamRouter.set_cookie ~path:"/app" ~http_only:true ~same_site:`Lax "session" "saved";
                   Lwt.return (React.Model.Element (React.string "Saved")))))
    | _ -> None
  in
  let request =
    Dream.request ~method_:`POST ~target:"/app"
      ~headers:[ ("ACTION_ID", "save"); ("Content-Type", "application/json") ]
      "[]"
  in
  let response = Dream.test (DreamRouter.streamFunctionResponse ~timeout:0.1 ~lookup) request in
  let body = Lwt_main.run (Dream.body response) in
  Alcotest.(check (option string))
    "content type" (Some "application/react.action") (Dream.header response "Content-Type");
  Alcotest.(check (option string))
    "cookie" (Some "session=saved; Path=/app; HttpOnly; SameSite=Lax") (Dream.header response "Set-Cookie");
  Alcotest.(check string) "wire output" "0:\"Saved\"\n" body

let action_shares_request_cache () =
  let runs = ref 0 in
  let viewer = React.Cache.make ~name:"viewer" () in
  let load () =
    React.Cache.run viewer ~key:"1" (fun () ->
        incr runs;
        Lwt.return "viewer")
  in
  let lookup = function
    | "load" ->
        Some
          (ReactServerDOM.Body
             (fun _args ->
               Lwt.bind (load ()) (fun _ -> Lwt.map (fun name -> React.Model.Element (React.string name)) (load ()))))
    | _ -> None
  in
  let call () =
    let request =
      Dream.request ~method_:`POST ~target:"/app"
        ~headers:[ ("ACTION_ID", "load"); ("Content-Type", "application/json") ]
        "[]"
    in
    Lwt_main.run (Dream.body (Dream.test (DreamRouter.streamFunctionResponse ~timeout:0.1 ~lookup) request))
  in
  Alcotest.(check string) "wire output" "0:\"viewer\"\n" (call ());
  Alcotest.(check int) "one run per action" 1 !runs;
  ignore (call ());
  Alcotest.(check int) "no sharing between actions" 2 !runs

let rejected_action_discards_cookie_and_streams_error () =
  let lookup = function
    | "reject" ->
        Some
          (ReactServerDOM.Body
             (fun _args ->
               DreamRouter.set_cookie "discarded" "yes";
               Lwt.fail (Failure "Action failed")))
    | _ -> None
  in
  let request =
    Dream.request ~method_:`POST ~target:"/app"
      ~headers:[ ("ACTION_ID", "reject"); ("Content-Type", "application/json") ]
      "[]"
  in
  let response = Dream.test (DreamRouter.streamFunctionResponse ~timeout:0.1 ~lookup) request in
  let body = Lwt_main.run (Dream.body response) in
  Alcotest.(check (option string)) "cookie discarded" None (Dream.header response "Set-Cookie");
  Alcotest.(check bool) "error reference" true (contains ~needle:"0:\"$Z1\"" body);
  Alcotest.(check bool) "error message" true (contains ~needle:"Failure(\\\"Action failed\\\")" body)

let registry_mismatch_returns_reload_required () =
  let seen = ref None in
  let request =
    Dream.request ~target:"/app/item"
      ~headers:
        [
          ("Accept", "application/react.component");
          ("Router-Registry", "1.wrong");
          ("Router-Navigation-From", "/app");
          ("Router-Base-Revision", "base");
        ]
      ""
  in
  let response = Dream.test (handler seen) request in
  Alcotest.(check int) "status" 409 (Dream.status response |> Dream.status_to_int);
  Alcotest.(check (option string)) "response kind" (Some "reload-required") (Dream.header response "Router-Response");
  Alcotest.(check (option string)) "endpoint skipped" None !seen

let patch_registry () : ((React.element, string) RouterEngine.Plan.t, string, unit) RouterEngine.EndpointRegistry.t =
  let root_branch = RouterEngine.Branch.Scope.make ~id:"root" ~parameters:[] ~search:[] ~reusable:true in
  let route_branch id = RouterEngine.Branch.Scope.make ~id ~parameters:[] ~search:[] ~reusable:true in
  let root_scope =
    RouterEngine.Plan.Scope.make ~layout:(fun child -> React.array [| React.string (String.make 2000 'x'); child |]) ()
  in
  let endpoint ~id ~path ~page =
    RouterEngine.Endpoint.make ~id ~path
      ~activeRoutes:[ (id, []) ]
      ~fingerprint:(id ^ path)
      ~decode:(fun _ ->
        Ok
          (RouterEngine.Endpoint.prepared
             ~branch:[ root_branch; route_branch ("route:" ^ id) ]
             ~execution:(fun () ->
               RouterEngine.Execution.done_ (RouterEngine.Plan.success ~scopes:[ root_scope ] ~page))))
  in
  RouterEngine.EndpointRegistry.makeExn
    [
      endpoint ~id:"home" ~path:"/" ~page:(React.string "home");
      endpoint ~id:"detail" ~path:"/detail" ~page:(React.string "detail");
    ]

let patch_handler registry request =
  let routes =
    DreamRouter.routes
      ~context:(fun _ -> ())
      ~server:(server registry)
      ~actionHandler:(fun _ -> Dream.empty `OK)
      ~diagnosticId:(fun _ -> "diagnostic")
      ~revision:(fun () -> "revision")
      ~document:(fun ~head:_ children -> children)
      ()
  in
  Dream.router routes request

let patch_payload_is_smaller_than_full () =
  let registry = patch_registry () in
  let full_request = Dream.request ~target:"/app/detail" ~headers:[ ("Accept", "application/react.component") ] "" in
  let fingerprint = RouterEngine.EndpointRegistry.fingerprint registry in
  let patch_request =
    Dream.request ~target:"/app/detail"
      ~headers:
        [
          ("Accept", "application/react.component");
          ("Router-Registry", "1." ^ fingerprint);
          ("Router-Navigation-From", "/app");
          ("Router-Base-Revision", "base");
        ]
      ""
  in
  let full_response = Dream.test (patch_handler registry) full_request in
  let patch_response = Dream.test (patch_handler registry) patch_request in
  let full_body = Lwt_main.run (Dream.body full_response) in
  let patch_body = Lwt_main.run (Dream.body patch_response) in
  Alcotest.(check bool) "smaller" true (String.length patch_body < String.length full_body);
  Alcotest.(check (option string)) "patch" (Some "patch") (Dream.header patch_response "Router-Response")

let empty_query_keeps_the_patch () =
  let registry = patch_registry () in
  let request =
    Dream.request ~target:"/app/detail?"
      ~headers:
        [
          ("Accept", "application/react.component");
          ("Router-Registry", "1." ^ RouterEngine.EndpointRegistry.fingerprint registry);
          ("Router-Navigation-From", "/app");
          ("Router-Base-Revision", "base");
        ]
      ""
  in
  let response = Dream.test (patch_handler registry) request in
  Alcotest.(check (option string)) "patch" (Some "patch") (Dream.header response "Router-Response");
  Alcotest.(check (option string)) "location" (Some "/app/detail") (Dream.header response "X-Location")

let rsc_redirect_uses_navigation_envelope () =
  let endpoint =
    RouterEngine.Endpoint.make ~id:"redirect" ~path:"/redirect"
      ~activeRoutes:[ ("redirect", []) ]
      ~fingerprint:"redirect"
      ~decode:(fun _ ->
        Ok
          (RouterEngine.Endpoint.prepared ~branch:[] ~execution:(fun () ->
               RouterEngine.Execution.load
                 (fun () -> Lwt.return (RouterRuntime.Loader.Redirect (RouterRuntime.destination ~path:"/outside")))
                 (fun (_ : unit) ->
                   RouterEngine.Execution.done_ (RouterEngine.Plan.success ~scopes:[] ~page:React.null)))))
  in
  let registry = RouterEngine.EndpointRegistry.makeExn [ endpoint ] in
  let fingerprint = RouterEngine.EndpointRegistry.fingerprint registry in
  let request =
    Dream.request ~target:"/app/redirect"
      ~headers:
        [
          ("Accept", "application/react.component");
          ("Router-Registry", "1." ^ fingerprint);
          ("Router-Navigation-From", "/app");
          ("Router-Base-Revision", "base");
        ]
      ""
  in
  let response = Dream.test (patch_handler registry) request in
  Alcotest.(check int) "status" 200 (Dream.status response |> Dream.status_to_int);
  Alcotest.(check (option string)) "kind" (Some "redirect") (Dream.header response "Router-Response");
  Alcotest.(check (option string))
    "content type" (Some "application/react.component") (Dream.header response "Content-Type");
  Alcotest.(check (option string)) "cache control" (Some "private, no-store") (Dream.header response "Cache-Control")

let loader_permanent_redirect_answers_308_and_rsc_envelope () =
  let endpoint =
    RouterEngine.Endpoint.make ~id:"redirect" ~path:"/redirect"
      ~activeRoutes:[ ("redirect", []) ]
      ~fingerprint:"redirect"
      ~decode:(fun _ ->
        Ok
          (RouterEngine.Endpoint.prepared ~branch:[] ~execution:(fun () ->
               RouterEngine.Execution.load
                 (fun () ->
                   Lwt.return (RouterRuntime.Loader.PermanentRedirect (RouterRuntime.destination ~path:"/outside")))
                 (fun (_ : unit) ->
                   RouterEngine.Execution.done_ (RouterEngine.Plan.success ~scopes:[] ~page:React.null)))))
  in
  let registry = RouterEngine.EndpointRegistry.makeExn [ endpoint ] in
  let document = Dream.test (patch_handler registry) (Dream.request ~target:"/app/redirect" "") in
  Alcotest.(check int) "document status" 308 (Dream.status document |> Dream.status_to_int);
  Alcotest.(check (option string)) "location" (Some "/outside") (Dream.header document "Location");
  let fingerprint = RouterEngine.EndpointRegistry.fingerprint registry in
  let rsc =
    Dream.test (patch_handler registry)
      (Dream.request ~target:"/app/redirect"
         ~headers:
           [
             ("Accept", "application/react.component");
             ("Router-Registry", "1." ^ fingerprint);
             ("Router-Navigation-From", "/app");
             ("Router-Base-Revision", "base");
           ]
         "")
  in
  Alcotest.(check int) "rsc status" 200 (Dream.status rsc |> Dream.status_to_int);
  Alcotest.(check (option string)) "rsc kind" (Some "redirect") (Dream.header rsc "Router-Response")

let trailing_slash_document_redirects_permanently () =
  let seen = ref None in
  let request = Dream.request ~target:"/app/item/?tag=one" "" in
  let response = Dream.test (handler seen) request in
  Alcotest.(check int) "status" 308 (Dream.status response |> Dream.status_to_int);
  Alcotest.(check (option string)) "location" (Some "/app/item?tag=one") (Dream.header response "Location");
  Alcotest.(check (option string)) "decode skipped" None !seen

let trailing_slash_rsc_uses_navigation_envelope () =
  let seen = ref None in
  let request = Dream.request ~target:"/app/item/" ~headers:[ ("Accept", "application/react.component") ] "" in
  let response = Dream.test (handler seen) request in
  Alcotest.(check int) "status" 200 (Dream.status response |> Dream.status_to_int);
  Alcotest.(check (option string)) "kind" (Some "redirect") (Dream.header response "Router-Response");
  let body = Lwt_main.run (Dream.body response) in
  Alcotest.(check bool) "location" true (contains ~needle:"/app/item" body)

let trailing_slash_reject_returns_not_found () =
  let seen = ref None in
  let router =
    RouterEngine.Server.make ~basePath:"/app" ~registry:(registry seen) ~trailingSlash:RouterEngine.TrailingSlash.Reject
      ~fallback
      ~applicationStatus:(fun _ -> RouterRuntime.Status.InternalServerError)
      ()
  in
  let routes =
    DreamRouter.routes
      ~context:(fun _ -> ())
      ~server:router
      ~actionHandler:(fun _ -> Dream.empty `OK)
      ~diagnosticId:(fun _ -> "diagnostic")
      ~revision:(fun () -> "revision")
      ~ssr ~document ()
  in
  let request = Dream.request ~target:"/app/item/" "" in
  let response = Dream.test (fun request -> Dream.router routes request) request in
  Alcotest.(check int) "status" 404 (Dream.status response |> Dream.status_to_int)

let head_request_has_no_body () =
  let seen = ref None in
  let response = Dream.test (handler seen) (Dream.request ~method_:`HEAD ~target:"/app/item" "") in
  Alcotest.(check int) "status" 200 (Dream.status response |> Dream.status_to_int);
  Alcotest.(check (option string))
    "content type" (Some "text/html; charset=utf-8") (Dream.header response "Content-Type");
  Alcotest.(check string) "body" "" (Lwt_main.run (Dream.body response));
  let missing = Dream.test (handler seen) (Dream.request ~method_:`HEAD ~target:"/app/missing" "") in
  Alcotest.(check int) "missing status" 404 (Dream.status missing |> Dream.status_to_int)

let other_methods_answer_with_allow () =
  let seen = ref None in
  let check method_ target status =
    let response = Dream.test (handler seen) (Dream.request ~method_ ~target "") in
    let name = Dream.method_to_string method_ ^ " " ^ target in
    Alcotest.(check int) name status (Dream.status response |> Dream.status_to_int);
    Alcotest.(check (option string)) (name ^ " allow") (Some "GET, HEAD, OPTIONS, POST") (Dream.header response "Allow")
  in
  check `OPTIONS "/app/item" 204;
  check `OPTIONS "/app" 204;
  check `PUT "/app/item" 405;
  check `DELETE "/app" 405;
  Alcotest.(check (option string)) "decode skipped" None !seen

let default_ids_do_not_use_the_global_generator () =
  let routes =
    DreamRouter.routes
      ~context:(fun _ -> ())
      ~server:(server (registry (ref None)))
      ~actionHandler:(fun _ -> Dream.empty `OK)
      ~document:(fun ~head:_ children -> children)
      ()
  in
  let body () =
    Random.init 7;
    let request = Dream.request ~target:"/app/item" ~headers:[ ("Accept", "application/react.component") ] "" in
    Lwt_main.run (Dream.body (Dream.test (Dream.router routes) request))
  in
  Alcotest.(check bool) "revisions differ" false (String.equal (body ()) (body ()))

let action_routes_check_origin () =
  let calls = ref 0 in
  let action _request =
    incr calls;
    Dream.empty `OK
  in
  let router =
    Dream.router
      (DreamRouter.routes
         ~context:(fun _ -> ())
         ~server:(server (registry (ref None)))
         ~actionHandler:action
         ~document:(fun ~head:_ children -> children)
         ())
  in
  let post headers =
    Dream.test router (Dream.request ~method_:`POST ~target:"/app/item" ~headers "")
    |> Dream.status |> Dream.status_to_int
  in
  Alcotest.(check int) "same origin" 200 (post [ ("Host", "example.com"); ("Origin", "http://example.com") ]);
  Alcotest.(check int)
    "same origin referer" 200
    (post [ ("Host", "example.com"); ("Referer", "http://example.com/app") ]);
  Alcotest.(check int) "cross origin" 400 (post [ ("Host", "example.com"); ("Origin", "http://evil.example") ]);
  Alcotest.(check int) "missing origin" 400 (post [ ("Host", "example.com") ]);
  Alcotest.(check int) "calls" 2 !calls

let rsc_request ?(headers = []) target =
  Dream.request ~target ~headers:(("Accept", "application/react.component") :: headers) ""

let prefetch_matches_navigation () =
  let seen = ref None in
  let navigation = Dream.test (handler seen) (rsc_request "/app/item") in
  let prefetch = Dream.test (handler seen) (rsc_request ~headers:[ ("Router-Prefetch", "intent") ] "/app/item") in
  Alcotest.(check int) "status" 200 (Dream.status prefetch |> Dream.status_to_int);
  Alcotest.(check string) "body" (Lwt_main.run (Dream.body navigation)) (Lwt_main.run (Dream.body prefetch));
  Alcotest.(check (option string)) "navigation vary" (Some "Accept, Router-Prefetch") (Dream.header navigation "Vary");
  Alcotest.(check (option string)) "prefetch vary" (Some "Accept, Router-Prefetch") (Dream.header prefetch "Vary")

let prefetch_above_route_level_is_refused () =
  let seen = ref None in
  let response = Dream.test (handler seen) (rsc_request ~headers:[ ("Router-Prefetch", "viewport") ] "/app/item") in
  Alcotest.(check int) "status" 204 (Dream.status response |> Dream.status_to_int);
  Alcotest.(check (option string)) "level" (Some "intent") (Dream.header response "Router-Prefetch-Refused");
  Alcotest.(check (option string)) "vary" (Some "Accept, Router-Prefetch") (Dream.header response "Vary");
  Alcotest.(check string) "body" "" (Lwt_main.run (Dream.body response))

let loaders_read_the_context () =
  let endpoint =
    RouterEngine.Endpoint.make ~id:"item" ~path:"/item" ~activeRoutes:[] ~fingerprint:"item" ~decode:(fun _ ->
        Ok
          (RouterEngine.Endpoint.prepared ~branch:[] ~execution:(fun context ->
               RouterEngine.Execution.load
                 (fun () -> Lwt.return (RouterRuntime.Loader.Data context))
                 (fun viewer ->
                   RouterEngine.Execution.done_
                     (RouterEngine.Plan.success ~scopes:[] ~page:(React.string ("viewer:" ^ viewer)))))))
  in
  let server =
    RouterEngine.Server.make ~basePath:"/app"
      ~registry:(RouterEngine.EndpointRegistry.makeExn [ endpoint ])
      ~fallback:(fun ~context:_ ~search:_ ~error -> RouterEngine.Plan.failure ~scopes:[] ~error ())
      ~applicationStatus:(fun _ -> RouterRuntime.Status.InternalServerError)
      ()
  in
  let router =
    Dream.router
      (DreamRouter.routes ~server
         ~context:(fun request -> Option.value (Dream.header request "X-Viewer") ~default:"anonymous")
         ~actionHandler:(fun _ -> Dream.empty `OK)
         ~document ())
  in
  let body headers = Lwt_main.run (Lwt.bind (router (Dream.request ~target:"/app/item" ~headers "")) Dream.body) in
  Alcotest.(check bool) "from the request" true (contains ~needle:"viewer:ada" (body [ ("X-Viewer", "ada") ]));
  Alcotest.(check bool) "default" true (contains ~needle:"viewer:anonymous" (body []))

let options_builds_no_context () =
  let built = ref 0 in
  let router =
    Dream.router
      (DreamRouter.routes
         ~server:(server (registry (ref None)))
         ~context:(fun _ -> incr built)
         ~actionHandler:(fun _ -> Dream.empty `OK)
         ~document ())
  in
  let status method_ =
    Dream.status_to_int (Dream.status (Lwt_main.run (router (Dream.request ~method_ ~target:"/app/item" ""))))
  in
  Alcotest.(check int) "options" 204 (status `OPTIONS);
  Alcotest.(check int) "no context for options" 0 !built;
  Alcotest.(check int) "get" 200 (status `GET);
  Alcotest.(check int) "one context for get" 1 !built

let loaders_see_their_own_request () =
  let target () = match DreamRouter.request () with Some request -> Dream.target request | None -> "none" in
  let seen = ref [] in
  let record label = seen := (label, target ()) :: !seen in
  let endpoint =
    let scope =
      RouterEngine.Plan.Scope.make
        ~metadata:(fun () ->
          Lwt.bind (Lwt.pause ()) (fun () ->
              record "metadata";
              Lwt.return (RouterRuntime.Metadata.make ~title:(target ()) ())))
        ()
    in
    let streamed =
      React.Async_component
        ( "Streamed",
          fun () ->
            Lwt.bind (Lwt.pause ()) (fun () ->
                Lwt.bind (Lwt.pause ()) (fun () ->
                    record "stream";
                    Lwt.return (React.string ("streamed:" ^ target ())))) )
    in
    RouterEngine.Endpoint.make ~id:"item" ~path:"/item" ~activeRoutes:[] ~fingerprint:"item" ~decode:(fun _ ->
        Ok
          (RouterEngine.Endpoint.prepared ~branch:[] ~execution:(fun () ->
               RouterEngine.Execution.load
                 (fun () ->
                   Lwt.bind (Lwt.pause ()) (fun () ->
                       record "loader";
                       Lwt.return (RouterRuntime.Loader.Data (target ()))))
                 (fun loaded ->
                   RouterEngine.Execution.done_
                     (RouterEngine.Plan.success ~scopes:[ scope ]
                        ~page:(React.list [ React.string ("loaded:" ^ loaded); streamed ]))))))
  in
  let router =
    Dream.router
      (DreamRouter.routes
         ~context:(fun _ -> ())
         ~server:(server (RouterEngine.EndpointRegistry.makeExn [ endpoint ]))
         ~actionHandler:(fun _ -> Dream.empty `OK)
         ~document ())
  in
  let body target = Lwt.bind (router (Dream.request ~target "")) Dream.body in
  let first, second = Lwt_main.run (Lwt.both (body "/app/item?n=1") (body "/app/item?n=2")) in
  List.iter
    (fun (body, target) ->
      Alcotest.(check bool) (target ^ " loader") true (contains ~needle:("loaded:" ^ target) body);
      Alcotest.(check bool) (target ^ " metadata") true (contains ~needle:("<title>" ^ target ^ "</title>") body);
      Alcotest.(check bool) (target ^ " stream") true (contains ~needle:("streamed:" ^ target) body))
    [ (first, "/app/item?n=1"); (second, "/app/item?n=2") ];
  List.iter
    (fun label ->
      Alcotest.(check (list string))
        label [ "/app/item?n=1"; "/app/item?n=2" ]
        (List.filter_map (fun (current, target) -> if current = label then Some target else None) !seen
        |> List.sort_uniq compare))
    [ "loader"; "metadata"; "stream" ];
  Alcotest.(check bool) "outside a request" true (Option.is_none (DreamRouter.request ()))

let form_page_registry () =
  let form id =
    React.createElement "form"
      [ React.JSX.Action ("action", "action", { Runtime.id; call = (fun () -> Lwt.return (React.string "")) }) ]
      [ React.createElement "input" [ React.JSX.String ("name", "name", "title") ] [] ]
  in
  let page = React.list [ form "save"; form "move"; form "fail" ] in
  let boundary error =
    let status =
      RouterRuntime.Status.toInt (RouterServer.statusOfError ~application:(fun _ -> InternalServerError) error)
    in
    React.createElement "p" [] [ React.string ("boundary " ^ string_of_int status) ]
  in
  let endpoint =
    RouterEngine.Endpoint.make ~id:"item" ~path:"/item" ~activeRoutes:[] ~fingerprint:"item" ~decode:(fun _ ->
        Ok
          (RouterEngine.Endpoint.prepared ~branch:[] ~execution:(fun () ->
               RouterEngine.Execution.done_
                 (RouterEngine.Plan.withFailure (RouterEngine.Plan.success ~scopes:[] ~page) (fun error ->
                      RouterEngine.Plan.failure ~scopes:[] ~error ~errorBoundary:boundary ())))))
  in
  RouterEngine.EndpointRegistry.makeExn [ endpoint ]

let multipart fields =
  let part (name, value) = "--b\r\nContent-Disposition: form-data; name=\"" ^ name ^ "\"\r\n\r\n" ^ value ^ "\r\n" in
  String.concat "" (List.map part fields) ^ "--b--\r\n"

let form_post ?(origin = "http://example.com") ?(headers = []) target fields =
  Dream.request ~method_:`POST ~target
    ~headers:
      ([ ("Host", "example.com"); ("Origin", origin); ("Content-Type", "multipart/form-data; boundary=b") ] @ headers)
    (multipart fields)

let action_input_names body =
  let prefix = {|name="$ACTION_ID_|} in
  let rec find index names =
    if index + String.length prefix > String.length body then List.rev names
    else if String.sub body index (String.length prefix) = prefix then
      let start = index + String.length {|name="|} in
      let stop = String.index_from body start '"' in
      find stop (String.sub body start (stop - start) :: names)
    else find (index + 1) names
  in
  find 0 []

type form_fixture = {
  router : Dream.handler;
  saved : string list ref;
  actions : int ref;
  failures : int ref;
  handled_bodies : string list ref;
  names : string list;
}

let form_fixture () =
  let saved = ref [] in
  let actions = ref 0 in
  let failures = ref 0 in
  let handled_bodies = ref [] in
  let lookup = function
    | "save" ->
        Some
          (ReactServerDOM.FormData
             (fun _ form ->
               (match Js.FormData.get form "title" with `String title -> saved := title :: !saved);
               DreamRouter.set_cookie ~path:"/app" "saved" "yes";
               Lwt.return (React.Model.Element (React.string "saved"))))
    | "move" ->
        Some
          (ReactServerDOM.FormData
             (fun _ _ -> RouterServer.redirect (RouterRuntime.destination ~path:"/app/other?from=form")))
    | "fail" ->
        Some
          (ReactServerDOM.FormData
             (fun _ _ ->
               incr failures;
               DreamRouter.set_cookie "discarded" "yes";
               Lwt.fail (Failure "save failed")))
    | "escape" ->
        Some
          (ReactServerDOM.FormData
             (fun _ _ -> RouterServer.redirect (RouterRuntime.destination ~path:"javascript:alert(1)")))
    | _ -> None
  in
  let router =
    Dream.router
      (DreamRouter.routes
         ~context:(fun _ -> ())
         ~server:(server (form_page_registry ()))
         ~actionHandler:(fun request ->
           incr actions;
           Lwt.bind (Dream.body request) (fun body ->
               handled_bodies := body :: !handled_bodies;
               Dream.empty `OK))
         ~lookup
         ~diagnosticId:(fun _ -> "diagnostic")
         ~document ())
  in
  let page = Lwt_main.run (Dream.body (Dream.test router (Dream.request ~target:"/app/item?tab=a" ""))) in
  { router; saved; actions; failures; handled_bodies; names = action_input_names page }

let location response = Dream.header response "Location"
let status response = Dream.status response |> Dream.status_to_int

let no_js_form_post_redirects_to_the_page () =
  let fixture = form_fixture () in
  Alcotest.(check (list string)) "page forms" [ "$ACTION_ID_save"; "$ACTION_ID_move"; "$ACTION_ID_fail" ] fixture.names;
  let response =
    Dream.test fixture.router (form_post "/app/item?tab=a" [ (List.hd fixture.names, ""); ("title", "hello") ])
  in
  Alcotest.(check int) "status" 303 (status response);
  Alcotest.(check (option string)) "location" (Some "/app/item?tab=a") (location response);
  Alcotest.(check (option string)) "cookie" (Some "saved=yes; Path=/app") (Dream.header response "Set-Cookie");
  Alcotest.(check (list string)) "saved" [ "hello" ] !(fixture.saved);
  Alcotest.(check int) "action handler unused" 0 !(fixture.actions)

let no_js_form_redirect_follows_the_server_function () =
  let fixture = form_fixture () in
  let response = Dream.test fixture.router (form_post "/app/item" [ ("$ACTION_ID_move", "") ]) in
  Alcotest.(check int) "status" 303 (status response);
  Alcotest.(check (option string)) "location" (Some "/app/other?from=form") (location response)

let no_js_form_failure_renders_the_boundary () =
  let fixture = form_fixture () in
  let response = Dream.test fixture.router (form_post "/app/item" [ ("$ACTION_ID_fail", "") ]) in
  let body = Lwt_main.run (Dream.body response) in
  Alcotest.(check int) "status" 500 (status response);
  Alcotest.(check bool) "boundary" true (contains ~needle:"<p>boundary 500</p>" body);
  Alcotest.(check bool) "no error detail" false (contains ~needle:"save failed" body);
  Alcotest.(check (option string)) "cookie discarded" None (Dream.header response "Set-Cookie")

let no_js_form_failure_honours_render_signals () =
  let form =
    React.createElement "form"
      [
        React.JSX.Action ("action", "action", { Runtime.id = "fail"; call = (fun () -> Lwt.return (React.string "")) });
      ]
      []
  in
  let endpoint path boundary =
    RouterEngine.Endpoint.make ~id:path ~path ~activeRoutes:[] ~fingerprint:path ~decode:(fun _ ->
        Ok
          (RouterEngine.Endpoint.prepared ~branch:[] ~execution:(fun () ->
               RouterEngine.Execution.done_
                 (RouterEngine.Plan.withFailure (RouterEngine.Plan.success ~scopes:[] ~page:form) (fun error ->
                      RouterEngine.Plan.failure ~scopes:[] ~error
                        ~notFound:(fun _ -> React.createElement "p" [] [ React.string "gone" ])
                        ~errorBoundary:(fun _ -> React.Upper_case_component ("Boundary", boundary))
                        ())))))
  in
  let registry =
    RouterEngine.EndpointRegistry.makeExn
      [
        endpoint "/moved" (fun () -> RouterServer.redirect (RouterRuntime.destination ~path:"/app/login"));
        endpoint "/gone" (fun () -> RouterServer.notFound ());
      ]
  in
  let lookup = function
    | "fail" -> Some (ReactServerDOM.FormData (fun _ _ -> Lwt.fail (Failure "save failed")))
    | _ -> None
  in
  let router =
    Dream.router
      (DreamRouter.routes
         ~context:(fun _ -> ())
         ~server:(server registry)
         ~actionHandler:(fun _ -> Dream.empty `OK)
         ~lookup
         ~diagnosticId:(fun _ -> "diagnostic")
         ~document ())
  in
  let response = Dream.test router (form_post "/app/moved" [ ("$ACTION_ID_fail", "") ]) in
  Alcotest.(check int) "redirect status" 303 (status response);
  Alcotest.(check (option string)) "redirect location" (Some "/app/login") (location response);
  let response = Dream.test router (form_post "/app/gone" [ ("$ACTION_ID_fail", "") ]) in
  let body = Lwt_main.run (Dream.body response) in
  Alcotest.(check int) "not found status" 404 (status response);
  Alcotest.(check bool) "not-found boundary" true (contains ~needle:"<p>gone</p>" body)

let no_js_form_post_checks_origin () =
  let fixture = form_fixture () in
  let response =
    Dream.test fixture.router
      (form_post ~origin:"http://evil.example" "/app/item" [ ("$ACTION_ID_save", ""); ("title", "evil") ])
  in
  Alcotest.(check int) "status" 400 (status response);
  Alcotest.(check (list string)) "not saved" [] !(fixture.saved)

let js_server_function_call_is_unchanged () =
  let fixture = form_fixture () in
  let response =
    Dream.test fixture.router (form_post ~headers:[ ("ACTION_ID", "save") ] "/app/item" [ ("1_title", "hello") ])
  in
  Alcotest.(check int) "status" 200 (status response);
  Alcotest.(check int) "action handler" 1 !(fixture.actions);
  Alcotest.(check (list string)) "router did not run it" [] !(fixture.saved)

let page_cache_can_be_turned_off () =
  let routes =
    DreamRouter.routes
      ~context:(fun _ -> ())
      ~server:(server (registry (ref None)))
      ~actionHandler:(fun _ -> Dream.empty `OK)
      ~pageCacheCapacity:0 ~document ()
  in
  let body = Lwt_main.run (Dream.body (Dream.test (Dream.router routes) (Dream.request ~target:"/app/item" ""))) in
  Alcotest.(check bool) "cache off" true (contains ~needle:{|"pageCacheCapacity":0,|} body)

let js_action_redirect_sets_header () =
  let lookup = function
    | "go" ->
        Some
          (ReactServerDOM.Body
             (fun _args ->
               Lwt.bind (Lwt.pause ()) (fun () ->
                   DreamRouter.set_cookie ~path:"/app" "moved" "yes";
                   RouterServer.redirect (RouterRuntime.destination ~path:"/app/next?from=action"))))
    | _ -> None
  in
  let request =
    Dream.request ~method_:`POST ~target:"/app"
      ~headers:[ ("ACTION_ID", "go"); ("Content-Type", "application/json") ]
      "[]"
  in
  let response = Dream.test (DreamRouter.streamFunctionResponse ~timeout:0.5 ~lookup) request in
  let body = Lwt_main.run (Dream.body response) in
  Alcotest.(check int) "status" 200 (Dream.status response |> Dream.status_to_int);
  Alcotest.(check (option string)) "redirect" (Some "/app/next?from=action") (Dream.header response "Router-Redirect");
  Alcotest.(check (option string))
    "content type" (Some "application/react.action") (Dream.header response "Content-Type");
  Alcotest.(check (option string)) "cookie" (Some "moved=yes; Path=/app") (Dream.header response "Set-Cookie");
  Alcotest.(check string) "non-error body" "0:null\n" body

let server_links_see_the_location () =
  let page =
    React.Upper_case_component
      ( "ServerPage",
        fun () ->
          RouterReact.Link.make
            (RouterReact.Link.makeProps
               ~destination:(RouterRuntime.destination ~path:"/app/item")
               ~children:(React.string "item") ()) )
  in
  let endpoint =
    RouterEngine.Endpoint.make ~id:"item" ~path:"/item" ~activeRoutes:[] ~fingerprint:"item" ~decode:(fun _ ->
        Ok
          (RouterEngine.Endpoint.prepared ~branch:[] ~execution:(fun () ->
               RouterEngine.Execution.done_ (RouterEngine.Plan.success ~scopes:[] ~page))))
  in
  let routes =
    DreamRouter.routes
      ~context:(fun _ -> ())
      ~server:(server (RouterEngine.EndpointRegistry.makeExn [ endpoint ]))
      ~actionHandler:(fun _ -> Dream.empty `OK)
      ~document ()
  in
  let body request = Lwt_main.run (Dream.body (Dream.test (Dream.router routes) request)) in
  let document = body (Dream.request ~target:"/app/item" "") in
  let navigation = body (Dream.request ~target:"/app/item" ~headers:[ ("Accept", "application/react.component") ] "") in
  Alcotest.(check bool) "html" true (contains ~needle:{|aria-current="page"|} document);
  Alcotest.(check bool) "document payload" true (contains ~needle:{|"aria-current":"page"|} document);
  Alcotest.(check bool) "navigation payload" true (contains ~needle:{|"aria-current":"page"|} navigation);
  Alcotest.(check bool) "keyed client root" true (contains ~needle:{|"router:root",{"initial":|} document)

let no_js_form_post_never_answers_a_method_preserving_redirect () =
  List.iter
    (fun (field, target) ->
      let fixture = form_fixture () in
      let response = Dream.test fixture.router (form_post target [ (field, ""); ("title", "hello") ]) in
      let code = status response in
      if code = 307 || code = 308 then Alcotest.failf "%s to %s answered %d" field target code;
      Alcotest.(check bool) (field ^ " " ^ target ^ " ran at most once") true (!(fixture.failures) <= 1))
    [
      ("$ACTION_ID_fail", "/app/item/");
      ("$ACTION_ID_save", "/app/item/");
      ("$ACTION_ID_move", "/app/item/");
      ("$ACTION_ID_fail", "/app/item");
    ];
  let fixture = form_fixture () in
  let response = Dream.test fixture.router (form_post "/app/item/" [ ("$ACTION_ID_fail", "") ]) in
  Alcotest.(check int) "failed action on a trailing slash" 303 (status response);
  Alcotest.(check (option string)) "canonical page" (Some "/app/item") (location response);
  Alcotest.(check int) "failed action ran once" 1 !(fixture.failures)

let plain_multipart_post_reaches_the_action_handler () =
  let fixture = form_fixture () in
  let body = multipart [ ("title", "hello"); ("file", "content") ] in
  let response = Dream.test fixture.router (form_post "/app/item" [ ("title", "hello"); ("file", "content") ]) in
  Alcotest.(check int) "status" 200 (status response);
  Alcotest.(check int) "action handler" 1 !(fixture.actions);
  Alcotest.(check (list string)) "body intact" [ body ] !(fixture.handled_bodies)

let no_js_form_unsafe_redirect_is_refused () =
  let fixture = form_fixture () in
  let response = Dream.test fixture.router (form_post "/app/item" [ ("$ACTION_ID_escape", "") ]) in
  Alcotest.(check int) "status" 500 (status response);
  Alcotest.(check (option string)) "no location" None (location response)

let js_action_unsafe_redirect_is_refused () =
  let lookup = function
    | "go" ->
        Some
          (ReactServerDOM.Body
             (fun _args -> RouterServer.redirect (RouterRuntime.destination ~path:"javascript:alert(1)")))
    | _ -> None
  in
  let request =
    Dream.request ~method_:`POST ~target:"/app"
      ~headers:[ ("ACTION_ID", "go"); ("Content-Type", "application/json") ]
      "[]"
  in
  let response = Dream.test (DreamRouter.streamFunctionResponse ~timeout:0.5 ~lookup) request in
  let body = Lwt_main.run (Dream.body response) in
  Alcotest.(check (option string)) "no redirect header" None (Dream.header response "Router-Redirect");
  Alcotest.(check bool) "error row" true (contains ~needle:":E{" body || contains ~needle:"$Z" body)

let rsc_redirect_varies_on_prefetch () =
  let seen = ref None in
  let response = Dream.test (handler seen) (rsc_request "/app/item/") in
  Alcotest.(check (option string)) "kind" (Some "redirect") (Dream.header response "Router-Response");
  Alcotest.(check (option string)) "vary" (Some "Accept, Router-Prefetch") (Dream.header response "Vary")

let () =
  Alcotest.run "dream router adapter"
    [
      ( "adapter",
        [
          test "RSC request uses context and headers" rsc_request_uses_context_and_headers;
          test "document request uses HTML" document_request_uses_html;
          test "page cache can be turned off" page_cache_can_be_turned_off;
          test "document request can disable SSR" document_request_can_disable_ssr;
          test "document request can enable SSR" document_request_can_enable_ssr;
          test "rejects other Accept values" rejects_other_accept_values;
          test "routes Unicode base paths" unicode_base_path_is_routed;
          test "root base path is routed" root_base_path_is_routed;
          test "root base path never redirects off origin" root_base_path_never_redirects_off_origin;
          test "shared action dispatcher handles mount" shared_action_dispatcher_handles_mount;
          test "action routes check origin" action_routes_check_origin;
          test "action timeout bounds execution" action_timeout_bounds_execution;
          test "successful action preserves cookie and wire output" successful_action_preserves_cookie_and_wire_output;
          test "action shares one request cache" action_shares_request_cache;
          test "rejected action discards cookie and streams error" rejected_action_discards_cookie_and_streams_error;
          test "registry mismatch returns reload-required" registry_mismatch_returns_reload_required;
          test "patch payload is smaller than full" patch_payload_is_smaller_than_full;
          test "empty query keeps the patch" empty_query_keeps_the_patch;
          test "RSC redirect uses navigation envelope" rsc_redirect_uses_navigation_envelope;
          test "loader permanent redirect answers 308 and rsc envelope"
            loader_permanent_redirect_answers_308_and_rsc_envelope;
          test "trailing slash document redirects permanently" trailing_slash_document_redirects_permanently;
          test "trailing slash RSC uses navigation envelope" trailing_slash_rsc_uses_navigation_envelope;
          test "trailing slash reject returns not found" trailing_slash_reject_returns_not_found;
          test "HEAD request has no body" head_request_has_no_body;
          test "other methods answer with Allow" other_methods_answer_with_allow;
          test "default ids do not use the global generator" default_ids_do_not_use_the_global_generator;
          test "prefetch matches navigation" prefetch_matches_navigation;
          test "prefetch above route level is refused" prefetch_above_route_level_is_refused;
          test "loaders see their own request" loaders_see_their_own_request;
          test "loaders read the context" loaders_read_the_context;
          test "OPTIONS builds no context" options_builds_no_context;
          test "no-JS form post redirects to the page" no_js_form_post_redirects_to_the_page;
          test "no-JS form redirect follows the server function" no_js_form_redirect_follows_the_server_function;
          test "no-JS form failure renders the boundary" no_js_form_failure_renders_the_boundary;
          test "no-JS form failure honours render signals" no_js_form_failure_honours_render_signals;
          test "no-JS form post checks origin" no_js_form_post_checks_origin;
          test "JS server function call is unchanged" js_server_function_call_is_unchanged;
          test "JS action redirect sets header" js_action_redirect_sets_header;
          test "server links see the location" server_links_see_the_location;
          test "no-JS form post never answers a method-preserving redirect"
            no_js_form_post_never_answers_a_method_preserving_redirect;
          test "plain multipart POST reaches the action handler" plain_multipart_post_reaches_the_action_handler;
          test "no-JS form unsafe redirect is refused" no_js_form_unsafe_redirect_is_refused;
          test "JS action unsafe redirect is refused" js_action_unsafe_redirect_is_refused;
          test "RSC redirect varies on prefetch" rsc_redirect_varies_on_prefetch;
        ] );
    ]

let test title fn = Alcotest.test_case title `Quick fn
let fallback ~search:_ ~error = RouterServer.Plan.failure ~scopes:[] ~error ()

let contains ~needle value =
  let limit = String.length value - String.length needle in
  let rec loop index =
    index <= limit && (String.equal (String.sub value index (String.length needle)) needle || loop (index + 1))
  in
  loop 0

let registry seen : ((React.element, string) RouterServer.Plan.t, string) RouterServer.EndpointRegistry.t =
  let endpoint =
    let metadata =
      RouterServer.Plan.Scope.make ~metadata:(fun () -> Lwt.return (RouterRuntime.Metadata.make ~title:"Item" ())) ()
    in
    RouterServer.Endpoint.make ~id:"item" ~path:"/item"
      ~activeRoutes:[ ("item", []) ]
      ~fingerprint:"item"
      ~decode:(fun _input ->
        seen := DreamRouter.get_header "X-Test";
        Ok
          (RouterServer.Endpoint.prepared ~branch:[] ~execution:(fun () ->
               RouterServer.Execution.done_
                 (RouterServer.Plan.success ~scopes:[ metadata ]
                    ~page:(React.createElement "main" [] [ React.string "item" ])))))
  in
  RouterServer.EndpointRegistry.makeExn [ endpoint ]

let server ?(basePath = "/app") registry =
  RouterServer.Server.make ~basePath ~registry ~fallback
    ~applicationStatus:(fun _ -> RouterRuntime.Status.InternalServerError)
    ()

let document children =
  React.createElement "html" []
    [
      React.createElement "head" []
        [ React.createElement "meta" [ React.JSX.String ("name", "name", "router-shell") ] [] ];
      React.createElement "body" [] [ children ];
    ]

let ssr request = match Dream.query request "ssr" with Some "false" -> false | Some "true" | Some _ | None -> true

let handler seen request =
  let routes =
    DreamRouter.routes
      ~router:(server (registry seen))
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
  Alcotest.(check bool) "routed markup" true (contains ~needle:"<main>item</main>" body)

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
      ~router:(server ~basePath:"/m%C3%BCnchen" (registry (ref None)))
      ~actionHandler:(fun _ -> Dream.empty `OK)
      ~document:Fun.id ()
  in
  let request = Dream.request ~target:"/m%C3%BCnchen/item" "" in
  let response = Dream.test (Dream.router routes) request in
  Alcotest.(check int) "status" 200 (Dream.status response |> Dream.status_to_int)

let shared_action_dispatcher_handles_mount () =
  let calls = ref 0 in
  let action _request =
    incr calls;
    Dream.empty `OK
  in
  let router =
    Dream.router (DreamRouter.routes ~router:(server (registry (ref None))) ~actionHandler:action ~document:Fun.id ())
  in
  let nested = Dream.request ~method_:`POST ~target:"/app/nested/route" "" in
  let root = Dream.request ~method_:`POST ~target:"/app" "" in
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

let patch_registry () : ((React.element, string) RouterServer.Plan.t, string) RouterServer.EndpointRegistry.t =
  let root_branch = RouterServer.Branch.Scope.make ~id:"root" ~parameters:[] ~reusable:true in
  let route_branch id = RouterServer.Branch.Scope.make ~id ~parameters:[] ~reusable:true in
  let root_scope =
    RouterServer.Plan.Scope.make ~layout:(fun child -> React.array [| React.string (String.make 2000 'x'); child |]) ()
  in
  let endpoint ~id ~path ~page =
    RouterServer.Endpoint.make ~id ~path
      ~activeRoutes:[ (id, []) ]
      ~fingerprint:(id ^ path)
      ~decode:(fun _ ->
        Ok
          (RouterServer.Endpoint.prepared
             ~branch:[ root_branch; route_branch ("route:" ^ id) ]
             ~execution:(fun () ->
               RouterServer.Execution.done_ (RouterServer.Plan.success ~scopes:[ root_scope ] ~page))))
  in
  RouterServer.EndpointRegistry.makeExn
    [
      endpoint ~id:"home" ~path:"/" ~page:(React.string "home");
      endpoint ~id:"detail" ~path:"/detail" ~page:(React.string "detail");
    ]

let patch_handler registry request =
  let routes =
    DreamRouter.routes ~router:(server registry)
      ~actionHandler:(fun _ -> Dream.empty `OK)
      ~diagnosticId:(fun _ -> "diagnostic")
      ~revision:(fun () -> "revision")
      ~document:Fun.id ()
  in
  Dream.router routes request

let patch_payload_is_smaller_than_full () =
  let registry = patch_registry () in
  let full_request = Dream.request ~target:"/app/detail" ~headers:[ ("Accept", "application/react.component") ] "" in
  let fingerprint = RouterServer.EndpointRegistry.fingerprint registry in
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

let rsc_redirect_uses_navigation_envelope () =
  let endpoint =
    RouterServer.Endpoint.make ~id:"redirect" ~path:"/redirect"
      ~activeRoutes:[ ("redirect", []) ]
      ~fingerprint:"redirect"
      ~decode:(fun _ ->
        Ok
          (RouterServer.Endpoint.prepared ~branch:[] ~execution:(fun () ->
               RouterServer.Execution.load
                 (fun () -> Lwt.return (RouterRuntime.Loader.Redirect (RouterRuntime.destination ~path:"/outside")))
                 (fun (_ : unit) ->
                   RouterServer.Execution.done_ (RouterServer.Plan.success ~scopes:[] ~page:React.null)))))
  in
  let registry = RouterServer.EndpointRegistry.makeExn [ endpoint ] in
  let fingerprint = RouterServer.EndpointRegistry.fingerprint registry in
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
    RouterServer.Server.make ~basePath:"/app" ~registry:(registry seen) ~trailingSlash:RouterServer.TrailingSlash.Reject
      ~fallback
      ~applicationStatus:(fun _ -> RouterRuntime.Status.InternalServerError)
      ()
  in
  let routes =
    DreamRouter.routes ~router
      ~actionHandler:(fun _ -> Dream.empty `OK)
      ~diagnosticId:(fun _ -> "diagnostic")
      ~revision:(fun () -> "revision")
      ~ssr ~document ()
  in
  let request = Dream.request ~target:"/app/item/" "" in
  let response = Dream.test (fun request -> Dream.router routes request) request in
  Alcotest.(check int) "status" 404 (Dream.status response |> Dream.status_to_int)

let () =
  Alcotest.run "dream router adapter"
    [
      ( "adapter",
        [
          test "RSC request uses context and headers" rsc_request_uses_context_and_headers;
          test "document request uses HTML" document_request_uses_html;
          test "document request can disable SSR" document_request_can_disable_ssr;
          test "document request can enable SSR" document_request_can_enable_ssr;
          test "rejects other Accept values" rejects_other_accept_values;
          test "routes Unicode base paths" unicode_base_path_is_routed;
          test "shared action dispatcher handles mount" shared_action_dispatcher_handles_mount;
          test "action timeout bounds execution" action_timeout_bounds_execution;
          test "successful action preserves cookie and wire output" successful_action_preserves_cookie_and_wire_output;
          test "rejected action discards cookie and streams error" rejected_action_discards_cookie_and_streams_error;
          test "registry mismatch returns reload-required" registry_mismatch_returns_reload_required;
          test "patch payload is smaller than full" patch_payload_is_smaller_than_full;
          test "RSC redirect uses navigation envelope" rsc_redirect_uses_navigation_envelope;
          test "trailing slash document redirects permanently" trailing_slash_document_redirects_permanently;
          test "trailing slash RSC uses navigation envelope" trailing_slash_rsc_uses_navigation_envelope;
          test "trailing slash reject returns not found" trailing_slash_reject_returns_not_found;
        ] );
    ]

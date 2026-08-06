let test title fn = Alcotest.test_case title `Quick fn
let fallback ~search:_ ~error = RouterServer.Plan.failure ~scopes:[] ~error ()

let registry seen : ((React.element, string) RouterServer.Plan.t, string) RouterServer.EndpointRegistry.t =
  let endpoint =
    RouterServer.Endpoint.make ~id:"item" ~path:"/item"
      ~activeRoutes:[ ("item", []) ]
      ~fingerprintParts:[ "item" ]
      ~project:(fun _ -> Ok [])
      ~prepare:(fun _input ->
        seen := DreamRouter.RequestContext.get_header "X-Test";
        Ok (RouterServer.Execution.done_ (RouterServer.Plan.success ~scopes:[] ~page:(React.string "item"))))
  in
  RouterServer.EndpointRegistry.makeExn [ endpoint ]

let full_element (response : (React.element, string) RouterServer.ServerEngine.full) =
  match response.RouterServer.ServerEngine.resolved.element with Some element -> element | None -> React.null

let patch_element (response : (React.element, string) RouterServer.ServerEngine.patch) =
  match response.RouterServer.ServerEngine.resolved.element with Some element -> element | None -> React.null

let handler seen request =
  DreamRouter.handler ~registry:(registry seen) ~basePath:"/app" ~fallback
    ~applicationStatus:(fun _ -> RouterRuntime.Status.InternalServerError)
    ~diagnosticId:(fun _ -> "diagnostic")
    ~revision:(fun () -> "revision")
    ~protocolVersion:1 ~document:full_element
    ~rscModel:(fun response -> React.Model.Element (full_element response))
    ~rscPatch:(fun response -> React.Model.Element (patch_element response))
    ~rscRedirect:(fun _ -> React.Model.Element React.null)
    request

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
  Alcotest.(check (option string)) "response kind" (Some "full") (Dream.header response "SRR-Response");
  Alcotest.(check (option string)) "context" (Some "context") !seen

let document_request_uses_html () =
  let seen = ref None in
  let request = Dream.request ~target:"/app/item" "" in
  let response = Dream.test (handler seen) request in
  Alcotest.(check int) "status" 200 (Dream.status response |> Dream.status_to_int);
  Alcotest.(check (option string))
    "content type" (Some "text/html; charset=utf-8") (Dream.header response "Content-Type")

let shared_action_dispatcher_handles_mount () =
  let calls = ref 0 in
  let action _request =
    incr calls;
    Dream.empty `OK
  in
  let get _request = Dream.empty `OK in
  let router = Dream.router (DreamRouter.routes ~basePath:"/app" ~actionHandler:action get) in
  let nested = Dream.request ~method_:`POST ~target:"/app/nested/route" "" in
  let root = Dream.request ~method_:`POST ~target:"/app" "" in
  let _response = Dream.test router nested in
  let _response = Dream.test router root in
  Alcotest.(check int) "calls" 2 !calls

let registry_mismatch_returns_reload_required () =
  let seen = ref None in
  let request =
    Dream.request ~target:"/app/item"
      ~headers:
        [
          ("Accept", "application/react.component");
          ("SRR-Registry", "1.wrong");
          ("SRR-Navigation-From", "/app");
          ("SRR-Base-Revision", "base");
        ]
      ""
  in
  let response = Dream.test (handler seen) request in
  Alcotest.(check int) "status" 409 (Dream.status response |> Dream.status_to_int);
  Alcotest.(check (option string)) "response kind" (Some "reload-required") (Dream.header response "SRR-Response");
  Alcotest.(check (option string)) "endpoint skipped" None !seen

let patch_registry () : ((React.element, string) RouterServer.Plan.t, string) RouterServer.EndpointRegistry.t =
  let root_branch = RouterServer.Branch.Scope.make ~id:"root" ~parameters:[] ~reusable:true in
  let route_branch id = RouterServer.Branch.Scope.make ~id ~parameters:[] ~reusable:true in
  let root_scope =
    RouterServer.Plan.Scope.make ~id:"root"
      ~instanceKey:(RouterServer.Branch.Scope.instanceKey root_branch)
      ~reusable:true
      ~layout:(fun child -> React.array [| React.string (String.make 2000 'x'); child |])
      ()
  in
  let endpoint ~id ~path ~page =
    RouterServer.Endpoint.make ~id ~path
      ~activeRoutes:[ (id, []) ]
      ~fingerprintParts:[ id; path ]
      ~project:(fun _ -> Ok [ root_branch; route_branch ("route:" ^ id) ])
      ~prepare:(fun _ -> Ok (RouterServer.Execution.done_ (RouterServer.Plan.success ~scopes:[ root_scope ] ~page)))
  in
  RouterServer.EndpointRegistry.makeExn
    [
      endpoint ~id:"home" ~path:"/" ~page:(React.string "home");
      endpoint ~id:"detail" ~path:"/detail" ~page:(React.string "detail");
    ]

let patch_handler registry request =
  DreamRouter.handler ~registry ~basePath:"/app" ~fallback
    ~applicationStatus:(fun _ -> RouterRuntime.Status.InternalServerError)
    ~diagnosticId:(fun _ -> "diagnostic")
    ~revision:(fun () -> "revision")
    ~protocolVersion:1 ~document:full_element
    ~rscModel:(fun response -> React.Model.Element (full_element response))
    ~rscPatch:(fun response -> React.Model.Element (patch_element response))
    ~rscRedirect:(fun _ -> React.Model.Element React.null)
    request

let patch_payload_is_smaller_than_full () =
  let registry = patch_registry () in
  let full_request = Dream.request ~target:"/app/detail" ~headers:[ ("Accept", "application/react.component") ] "" in
  let fingerprint = RouterServer.EndpointRegistry.fingerprint registry in
  let patch_request =
    Dream.request ~target:"/app/detail"
      ~headers:
        [
          ("Accept", "application/react.component");
          ("SRR-Registry", "1." ^ fingerprint);
          ("SRR-Navigation-From", "/app");
          ("SRR-Base-Revision", "base");
        ]
      ""
  in
  let full_response = Dream.test (patch_handler registry) full_request in
  let patch_response = Dream.test (patch_handler registry) patch_request in
  let full_body = Lwt_main.run (Dream.body full_response) in
  let patch_body = Lwt_main.run (Dream.body patch_response) in
  Alcotest.(check bool) "smaller" true (String.length patch_body < String.length full_body);
  Alcotest.(check (option string)) "patch" (Some "patch") (Dream.header patch_response "SRR-Response")

let rsc_redirect_uses_navigation_envelope () =
  let endpoint =
    RouterServer.Endpoint.make ~id:"redirect" ~path:"/redirect"
      ~activeRoutes:[ ("redirect", []) ]
      ~fingerprintParts:[ "redirect" ]
      ~project:(fun _ -> Ok [])
      ~prepare:(fun _ ->
        Ok
          (RouterServer.Execution.load
             (fun () -> Lwt.return (RouterRuntime.Loader.Redirect (RouterRuntime.destination ~path:"/outside")))
             (fun (_ : unit) -> RouterServer.Execution.done_ (RouterServer.Plan.success ~scopes:[] ~page:React.null))))
  in
  let registry = RouterServer.EndpointRegistry.makeExn [ endpoint ] in
  let fingerprint = RouterServer.EndpointRegistry.fingerprint registry in
  let request =
    Dream.request ~target:"/app/redirect"
      ~headers:
        [
          ("Accept", "application/react.component");
          ("SRR-Registry", "1." ^ fingerprint);
          ("SRR-Navigation-From", "/app");
          ("SRR-Base-Revision", "base");
        ]
      ""
  in
  let response = Dream.test (patch_handler registry) request in
  Alcotest.(check int) "status" 200 (Dream.status response |> Dream.status_to_int);
  Alcotest.(check (option string)) "kind" (Some "redirect") (Dream.header response "SRR-Response")

let () =
  Alcotest.run "dream router adapter"
    [
      ( "adapter",
        [
          test "RSC request uses context and headers" rsc_request_uses_context_and_headers;
          test "document request uses HTML" document_request_uses_html;
          test "shared action dispatcher handles mount" shared_action_dispatcher_handles_mount;
          test "registry mismatch returns reload-required" registry_mismatch_returns_reload_required;
          test "patch payload is smaller than full" patch_payload_is_smaller_than_full;
          test "RSC redirect uses navigation envelope" rsc_redirect_uses_navigation_envelope;
        ] );
    ]

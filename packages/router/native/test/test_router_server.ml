let test title fn = Alcotest.test_case title `Quick fn
let route ~id ~path = RouterServer.Route.make ~id ~path

let registry routes =
  match RouterServer.Registry.make routes with
  | Ok registry -> registry
  | Error _ -> Alcotest.fail "expected valid registry"

let static_precedes_dynamic () =
  let registry = registry [ route ~id:"note" ~path:"/:id<NoteId.t>"; route ~id:"new" ~path:"/new" ] in
  match RouterServer.Match.find registry ~pathname:"/new" with
  | Ok (Some matched) -> Alcotest.(check string) "route" "new" (RouterServer.Route.id matched.route)
  | _ -> Alcotest.fail "expected static match"

let decoded_parameters () =
  let registry = registry [ route ~id:"note" ~path:"/notes/:slug<Slug.t>" ] in
  match RouterServer.Match.find registry ~pathname:"/notes/caf%C3%A9" with
  | Ok (Some matched) -> Alcotest.(check (list (pair string string))) "params" [ ("slug", "café") ] matched.parameters
  | _ -> Alcotest.fail "expected decoded match"

let duplicate_paths () =
  match RouterServer.Registry.make [ route ~id:"left" ~path:"/notes"; route ~id:"right" ~path:"/notes" ] with
  | Error (DuplicatePath "/notes") -> ()
  | _ -> Alcotest.fail "expected duplicate path"

let ambiguous_patterns () =
  match
    RouterServer.Registry.make [ route ~id:"note" ~path:"/:id<NoteId.t>"; route ~id:"slug" ~path:"/:slug<Slug.t>" ]
  with
  | Error (AmbiguousPattern _) -> ()
  | _ -> Alcotest.fail "expected ambiguous pattern"

let overlapping_patterns () =
  match
    RouterServer.Registry.make
      [ route ~id:"left" ~path:"/foo/:id<string>"; route ~id:"right" ~path:"/:slug<string>/bar" ]
  with
  | Error (AmbiguousPattern _) -> ()
  | _ -> Alcotest.fail "expected overlapping pattern diagnostic"

let malformed_escape () =
  let registry = registry [ route ~id:"note" ~path:"/:id<NoteId.t>" ] in
  match RouterServer.Match.find registry ~pathname:"/%ZZ" with
  | Error (MalformedEscape "%ZZ") -> ()
  | _ -> Alcotest.fail "expected malformed escape"

let encoded_slash () =
  let registry = registry [ route ~id:"note" ~path:"/:id<NoteId.t>" ] in
  match RouterServer.Match.find registry ~pathname:"/a%2Fb" with
  | Error (EncodedSlash "a%2Fb") -> ()
  | _ -> Alcotest.fail "expected encoded slash error"

let destination_segment_encoding () =
  let destination =
    RouterRuntime.destinationFromPattern ~pattern:"/notes/:id<string>" ~parameters:[ ("id", "a+b") ] ~search:[]
  in
  Alcotest.(check string) "path" "/notes/a%2Bb" (RouterRuntime.href destination)

let repeated_search () =
  match RouterServer.Search.parse "?tag=one&tag=two&empty=&flag" with
  | Ok search ->
      Alcotest.(check (list string)) "tags" [ "one"; "two" ] (RouterServer.Search.values search "tag");
      Alcotest.(check (list string)) "empty" [ "" ] (RouterServer.Search.values search "empty");
      Alcotest.(check (list string)) "flag" [ "" ] (RouterServer.Search.values search "flag")
  | Error _ -> Alcotest.fail "expected valid search"

let decoded_search () =
  match RouterServer.Search.parse "filter=caf%C3%A9%2Fopen&utm_source=test&q=a+b" with
  | Ok search ->
      Alcotest.(check (list string)) "filter" [ "café/open" ] (RouterServer.Search.values search "filter");
      Alcotest.(check (list string)) "plus" [ "a b" ] (RouterServer.Search.values search "q");
      Alcotest.(check (list (pair string (list string))))
        "unknown"
        [ ("utm_source", [ "test" ]) ]
        (RouterServer.Search.unknown search ~owned:[ "filter"; "q" ])
  | Error _ -> Alcotest.fail "expected decoded search"

let malformed_search () =
  match RouterServer.Search.parse "filter=%ZZ" with
  | Error (MalformedEscape "%ZZ") -> ()
  | _ -> Alcotest.fail "expected malformed search"

let oversized_search () =
  match RouterServer.Search.parse (String.make 8193 'x') with
  | Error RouterServer.Search.QueryTooLong -> ()
  | _ -> Alcotest.fail "expected oversized search rejection"

let loader_sequence () =
  let events = ref [] in
  let execution =
    RouterServer.Execution.load
      (fun () ->
        events := "parent" :: !events;
        Lwt.return (RouterRuntime.Loader.Data 2))
      (fun parent ->
        RouterServer.Execution.load
          (fun () ->
            events := "child" :: !events;
            Lwt.return (RouterRuntime.Loader.Data (parent + 3)))
          (fun child -> RouterServer.Execution.done_ (child * 2)))
  in
  match Lwt_main.run (RouterServer.Execution.run execution) with
  | RouterRuntime.Loader.Data 10 -> Alcotest.(check (list string)) "order" [ "parent"; "child" ] (List.rev !events)
  | _ -> Alcotest.fail "expected loader data"

let loader_short_circuit () =
  let child_ran = ref false in
  let execution =
    RouterServer.Execution.load
      (fun () -> Lwt.return RouterRuntime.Loader.NotFound)
      (fun (_ : int) ->
        child_ran := true;
        RouterServer.Execution.done_ ())
  in
  (match Lwt_main.run (RouterServer.Execution.run execution) with
  | RouterRuntime.Loader.NotFound -> ()
  | _ -> Alcotest.fail "expected loader not found");
  Alcotest.(check bool) "child skipped" false !child_ran

let error_status () =
  let open RouterRuntime in
  Alcotest.(check int)
    "invalid path" 400
    (RouterServer.statusOfError ~application:(fun _ -> Status.Forbidden) (Error.InvalidPathParameter { name = "id" })
    |> Status.toInt);
  Alcotest.(check int)
    "application" 403
    (RouterServer.statusOfError ~application:(fun _ -> Status.Forbidden) (Error.Application "denied") |> Status.toInt)

let metadata_composition () =
  let open RouterRuntime.Metadata in
  let parent = make ~title:"Parent" ~entries:[ { key = "robots"; name = "robots"; content = "index" } ] () in
  let child = make ~description:"Child" ~entries:[ { key = "robots"; name = "robots"; content = "noindex" } ] () in
  let merged = merge parent child in
  Alcotest.(check (option string)) "title" (Some "Parent") merged.title;
  Alcotest.(check (option string)) "description" (Some "Child") merged.description;
  Alcotest.(check int) "deduplicated" 1 (List.length merged.entries)

let header_composition () =
  let open RouterRuntime.Headers in
  let get = function Ok headers -> headers | Error _ -> Alcotest.fail "unexpected header error" in
  let parent = get (make [ ("Cache-Control", "private"); ("Vary", "Accept") ]) in
  let child = get (make [ ("cache-control", "no-store") ]) in
  Alcotest.(check (list (pair string string)))
    "headers"
    [ ("cache-control", "no-store"); ("Vary", "Accept") ]
    (toList (merge parent child));
  (match make [ ("Content-Length", "10") ] with
  | Error (ForbiddenHeader "Content-Length") -> ()
  | _ -> Alcotest.fail "expected forbidden header");
  (match make [ ("X-Test", "safe\r\nSet-Cookie: injected=1") ] with
  | Error (InvalidHeaderValue _) -> ()
  | _ -> Alcotest.fail "expected invalid header value");
  (match make [ ("Bad Header", "value") ] with
  | Error (InvalidHeaderName _) -> ()
  | _ -> Alcotest.fail "expected invalid header name");
  let parent = get (make [ ("Vary", "Cookie") ]) in
  let child = get (make [ ("Vary", "Accept") ]) in
  Alcotest.(check (list (pair string string))) "vary" [ ("Vary", "Cookie, Accept") ] (toList (merge parent child))

let location key pathname search = RouterRuntime.Navigation.{ pathname; search; hash = ""; key }

let initial_commit revision pathname =
  RouterRuntime.Navigation.
    {
      location = location revision pathname "";
      matches = [ { routeId = pathname; parameters = [] } ];
      layouts = [];
      revision;
    }

let latest_navigation_wins () =
  let open RouterRuntime.Navigation in
  let state = make (initial_commit "r1" "/") in
  let state, first = start state ~to_:(location "first" "/one" "") ~action:Push in
  let state, second = start state ~to_:(location "second" "/two" "") ~action:Push in
  (match commit state ~requestId:first ~baseRevision:"r1" ~next:(initial_commit "r2" "/one") with
  | Error Superseded -> ()
  | _ -> Alcotest.fail "expected superseded first navigation");
  match commit state ~requestId:second ~baseRevision:"r1" ~next:(initial_commit "r3" "/two") with
  | Ok state -> Alcotest.(check string) "committed" "/two" (committed state).location.pathname
  | Error _ -> Alcotest.fail "expected latest navigation commit"

let stale_revision_rejected () =
  let open RouterRuntime.Navigation in
  let state = make (initial_commit "r1" "/") in
  let state, requestId = start state ~to_:(location "next" "/next" "") ~action:Push in
  match commit state ~requestId ~baseRevision:"old" ~next:(initial_commit "r2" "/next") with
  | Error StaleRevision -> ()
  | _ -> Alcotest.fail "expected stale revision"

let shallow_location_commit () =
  let open RouterRuntime.Navigation in
  let state = make (initial_commit "r1" "/notes") in
  let state = shallow state ~location:(location "search" "/notes" "?q=cat") ~action:Replace in
  let committed = committed state in
  Alcotest.(check string) "search" "?q=cat" committed.location.search;
  Alcotest.(check string) "revision" "r1" committed.revision

let valid_full_navigation_response () =
  let open RouterRuntime.NavigationResponse in
  let response =
    Full
      {
        protocolVersion = 1;
        registryFingerprint = "registry";
        canonicalUrl = "/notes?page=2";
        status = 200;
        matches =
          [ { RouterRuntime.Navigation.routeId = "root"; parameters = [] }; { routeId = "notes"; parameters = [] } ];
        layouts = [];
        targetRevision = "r2";
        payload = "payload";
      }
  in
  match
    validate ~expectedProtocolVersion:1 ~expectedRegistryFingerprint:"registry" ~activeRequestId:7
      ~committedRevision:"r1"
      ~canonicalUrlAllowed:(fun url -> String.equal url "/notes?page=2")
      {
        requestId = 7;
        baseRevision = "r1";
        status = 200;
        contentType = Some "application/react.component; charset=utf-8";
        kind = FullResponse;
      }
      response
  with
  | Ok validated -> Alcotest.(check int) "request" 7 validated.requestId
  | Error _ -> Alcotest.fail "expected valid full response"

let superseded_navigation_response_is_canceled () =
  let open RouterRuntime.NavigationResponse in
  let response = ReloadRequired in
  match
    validate ~expectedProtocolVersion:1 ~expectedRegistryFingerprint:"registry" ~activeRequestId:8
      ~committedRevision:"r1"
      ~canonicalUrlAllowed:(fun _ -> true)
      { requestId = 7; baseRevision = "r1"; status = 409; contentType = None; kind = ReloadRequiredResponse }
      response
  with
  | Error SupersededResponse -> ()
  | _ -> Alcotest.fail "expected superseded response"

let stale_navigation_response_is_rejected () =
  let open RouterRuntime.NavigationResponse in
  match
    validate ~expectedProtocolVersion:1 ~expectedRegistryFingerprint:"registry" ~activeRequestId:7
      ~committedRevision:"r2"
      ~canonicalUrlAllowed:(fun _ -> true)
      { requestId = 7; baseRevision = "r1"; status = 409; contentType = None; kind = ReloadRequiredResponse }
      ReloadRequired
  with
  | Error StaleResponse -> ()
  | _ -> Alcotest.fail "expected stale response"

let stale_patch_base_is_rejected () =
  let open RouterRuntime.NavigationResponse in
  let response =
    Patch
      {
        protocolVersion = 1;
        registryFingerprint = "registry";
        baseRevision = "old";
        targetRevision = "r2";
        replaceFrom = "root";
        canonicalUrl = "/notes/2";
        status = 200;
        matches = [];
        layouts = [];
        payload = "payload";
      }
  in
  match
    validate ~expectedProtocolVersion:1 ~expectedRegistryFingerprint:"registry" ~activeRequestId:7
      ~committedRevision:"r1"
      ~canonicalUrlAllowed:(fun _ -> true)
      {
        requestId = 7;
        baseRevision = "r1";
        status = 200;
        contentType = Some "application/react.component";
        kind = PatchResponse;
      }
      response
  with
  | Error StaleResponse -> ()
  | _ -> Alcotest.fail "expected stale patch response"

let redirect_and_reload_response_kinds () =
  let open RouterRuntime.NavigationResponse in
  Alcotest.(check bool) "redirect" true (kindOfString "redirect" = Some RedirectResponse);
  Alcotest.(check bool) "reload" true (kindOfString "reload-required" = Some ReloadRequiredResponse)

let redirect_and_reload_navigation_responses () =
  let open RouterRuntime.NavigationResponse in
  let validateResponse facts response =
    validate ~expectedProtocolVersion:1 ~expectedRegistryFingerprint:"registry" ~activeRequestId:7
      ~committedRevision:"r1"
      ~canonicalUrlAllowed:(fun _ -> true)
      facts response
  in
  let facts kind contentType = { requestId = 7; baseRevision = "r1"; status = 200; contentType; kind } in
  let redirect =
    Redirect { protocolVersion = 1; registryFingerprint = "registry"; location = "https://example.com"; status = 200 }
  in
  (match validateResponse (facts RedirectResponse (Some "application/react.component")) redirect with
  | Ok _ -> ()
  | Error _ -> Alcotest.fail "expected valid redirect response");
  match validateResponse (facts ReloadRequiredResponse None) ReloadRequired with
  | Ok _ -> ()
  | Error _ -> Alcotest.fail "expected valid reload response"

let history_action_selects_mutation () =
  let open RouterRuntime.Navigation in
  Alcotest.(check bool) "push" true (historyMutation Push = PushEntry);
  Alcotest.(check bool) "replace" true (historyMutation Replace = ReplaceEntry);
  Alcotest.(check bool) "pop fallback replaces" true (historyMutation Pop = ReplaceEntry)

let hash_only_location_commit () =
  let open RouterRuntime.Navigation in
  let state = make (initial_commit "r1" "/notes") in
  let location = { (location "hash" "/notes" "?q=cat") with hash = "#details" } in
  let state = hashOnly state ~location ~action:Push in
  let committed = committed state in
  Alcotest.(check string) "hash" "#details" committed.location.hash;
  Alcotest.(check string) "revision" "r1" committed.revision

let active_match_uses_route_and_parameters () =
  let open RouterRuntime.Navigation in
  let note = { routeId = "Note"; parameters = [ ("id", "1") ] } in
  let edit = { routeId = "EditNote"; parameters = [ ("id", "1") ] } in
  let committed =
    { location = location "r1" "/notes/1/edit" ""; matches = [ note; edit ]; layouts = []; revision = "r1" }
  in
  Alcotest.(check bool)
    "ancestor" true
    (isActive committed ~routeId:"Note" ~parameters:[ ("id", "1") ] ~includeDescendants:true);
  Alcotest.(check bool)
    "different params" false
    (isActive committed ~routeId:"Note" ~parameters:[ ("id", "2") ] ~includeDescendants:true);
  Alcotest.(check bool)
    "exact" true
    (isActive committed ~routeId:"EditNote" ~parameters:[ ("id", "1") ] ~includeDescendants:false)

let typed_search_decoding () =
  let open RouterRuntime.Search in
  let values = [ ("page", [ "2" ]); ("tag", [ "one"; "two" ]) ] in
  Alcotest.(check int) "defaulted" 2 (default ~name:"page" ~parse:parseInt ~fallback:1 values);
  Alcotest.(check (option string)) "optional" None (optional ~name:"filter" ~parse:parseString values);
  Alcotest.(check (list string)) "many" [ "one"; "two" ] (many ~name:"tag" ~parse:parseString values)

let shallow_search_preserves_unowned_values () =
  let open RouterRuntime.Search in
  let current = [ ("searchText", [ "old" ]); ("utm_source", [ "test" ]) ] in
  Alcotest.(check (list (pair string (list string))))
    "search"
    [ ("searchText", [ "next" ]); ("utm_source", [ "test" ]) ]
    (update ~owned:[ "searchText" ] ~values:[ ("searchText", [ "next" ]) ] current)

let pop_navigation_kind () =
  let open RouterRuntime.Navigation in
  let committed = initial_commit "r1" "/notes" in
  let hashTarget = { committed.location with hash = "#details" } in
  let searchTarget = { committed.location with search = "?q=cat" } in
  Alcotest.(check bool) "hash" true (classifyPop committed ~target:hashTarget ~targetRevision:(Some "r1") = HashOnly);
  Alcotest.(check bool) "search" true (classifyPop committed ~target:searchTarget ~targetRevision:(Some "r1") = Shallow);
  Alcotest.(check bool) "stale" true (classifyPop committed ~target:searchTarget ~targetRevision:(Some "old") = Content)

let typed_endpoint_decoding () =
  let endpoint =
    RouterServer.Endpoint.make ~id:"note" ~path:"/notes/:id<NoteId.t>" ~activeRoutes:[] ~fingerprintParts:[ "note" ]
      ~project:(fun _ -> Ok [])
      ~prepare:(fun input ->
        match
          ( RouterServer.Decode.path ~input ~name:"id" ~parse:(fun value ->
                match int_of_string_opt value with Some value -> Ok value | None -> Error "expected integer"),
            RouterServer.Decode.searchDefault ~input ~name:"page" ~parse:RouterRuntime.Search.parseInt ~fallback:1 )
        with
        | Ok id, Ok page -> Ok (RouterServer.Execution.done_ (id + page))
        | Error error, _ | _, Error error -> Error error)
  in
  let registry = RouterServer.EndpointRegistry.makeExn [ endpoint ] in
  let search =
    match RouterServer.Search.parse "?page=2" with Ok search -> search | Error _ -> Alcotest.fail "expected search"
  in
  match RouterServer.EndpointRegistry.find registry ~pathname:"/notes/40" with
  | Ok (Some matched) -> (
      match RouterServer.EndpointRegistry.prepare matched ~search with
      | Ok execution -> (
          match Lwt_main.run (RouterServer.Execution.run execution) with
          | RouterRuntime.Loader.Data value -> Alcotest.(check int) "decoded" 42 value
          | _ -> Alcotest.fail "expected data")
      | Error _ -> Alcotest.fail "expected prepared endpoint")
  | _ -> Alcotest.fail "expected endpoint match"

let typed_endpoint_decode_error () =
  let endpoint =
    RouterServer.Endpoint.make ~id:"note" ~path:"/notes/:id<NoteId.t>" ~activeRoutes:[] ~fingerprintParts:[ "note" ]
      ~project:(fun _ -> Ok [])
      ~prepare:(fun input ->
        match RouterServer.Decode.path ~input ~name:"id" ~parse:(fun _ -> Error "invalid") with
        | Ok (_ : int) -> Ok (RouterServer.Execution.done_ ())
        | Error error -> Error error)
  in
  let registry = RouterServer.EndpointRegistry.makeExn [ endpoint ] in
  let search =
    match RouterServer.Search.parse "" with Ok search -> search | Error _ -> Alcotest.fail "expected search"
  in
  match RouterServer.EndpointRegistry.find registry ~pathname:"/notes/nope" with
  | Ok (Some matched) -> (
      match RouterServer.EndpointRegistry.prepare matched ~search with
      | Error (RouterRuntime.Error.InvalidPathParameter { name = "id" }) -> ()
      | _ -> Alcotest.fail "expected invalid path parameter")
  | _ -> Alcotest.fail "expected endpoint match"

let full_plan_composition () =
  let open RouterRuntime in
  let headers values = match Headers.make values with Ok headers -> headers | Error _ -> Alcotest.fail "headers" in
  let root =
    RouterServer.Plan.Scope.make ~id:"root" ~instanceKey:"root" ~reusable:true
      ~layout:(fun child -> "root(" ^ child ^ ")")
      ~metadata:(fun () -> Lwt.return (Metadata.make ~title:"Root" ()))
      ~headers:(fun () -> Lwt.return (headers [ ("Vary", "Accept") ]))
      ()
  in
  let child =
    RouterServer.Plan.Scope.make ~id:"child" ~instanceKey:"child" ~reusable:true
      ~layout:(fun child -> "child(" ^ child ^ ")")
      ~metadata:(fun () -> Lwt.return (Metadata.make ~description:"Child" ()))
      ~headers:(fun () -> Lwt.return (headers [ ("Cache-Control", "private") ]))
      ()
  in
  let plan = RouterServer.Plan.success ~scopes:[ root; child ] ~page:"page" in
  let resolved = Lwt_main.run (RouterServer.Plan.resolve plan ~applicationStatus:(fun _ -> Status.Forbidden)) in
  Alcotest.(check (option string)) "element" (Some "root(child(page))") resolved.element;
  Alcotest.(check (option string)) "title" (Some "Root") resolved.metadata.title;
  Alcotest.(check (option string)) "description" (Some "Child") resolved.metadata.description;
  Alcotest.(check (list (pair string string)))
    "headers"
    [ ("Cache-Control", "private"); ("Vary", "Accept") ]
    (Headers.toList resolved.headers);
  Alcotest.(check int) "status" 200 (Status.toInt resolved.status)

let failure_plan_selects_not_found_boundary () =
  let open RouterRuntime in
  let error = Error.NotFound { reason = Error.LoaderNotFound } in
  let plan =
    RouterServer.Plan.failure ~scopes:[] ~error ~notFound:(fun _ -> "not-found") ~errorBoundary:(fun _ -> "error") ()
  in
  let resolved = Lwt_main.run (RouterServer.Plan.resolve plan ~applicationStatus:(fun _ -> Status.Forbidden)) in
  Alcotest.(check (option string)) "boundary" (Some "not-found") resolved.element;
  Alcotest.(check int) "status" 404 (Status.toInt resolved.status)

let shared_layout_prefix_uses_canonical_identity () =
  let scope = RouterServer.Branch.Scope.make in
  let root = scope ~id:"root" ~parameters:[] ~reusable:true in
  let note = scope ~id:"group:note" ~parameters:[ ("id", "1") ] ~reusable:true in
  let same = scope ~id:"group:note" ~parameters:[ ("id", "1") ] ~reusable:true in
  let other = scope ~id:"group:note" ~parameters:[ ("id", "2") ] ~reusable:true in
  let loaded = scope ~id:"group:note" ~parameters:[ ("id", "1") ] ~reusable:false in
  Alcotest.(check int) "same" 2 (RouterServer.Branch.sharedPrefix [ root; note ] [ root; same ]);
  Alcotest.(check int) "different params" 1 (RouterServer.Branch.sharedPrefix [ root; note ] [ root; other ]);
  Alcotest.(check int) "loader scope" 1 (RouterServer.Branch.sharedPrefix [ root; note ] [ root; loaded ])

let suffix_plan_omits_shared_layouts () =
  let open RouterRuntime in
  let root =
    RouterServer.Plan.Scope.make ~id:"root" ~instanceKey:"root" ~reusable:true
      ~layout:(fun child -> "root(" ^ child ^ ")")
      ()
  in
  let child =
    RouterServer.Plan.Scope.make ~id:"child" ~instanceKey:"child" ~reusable:true
      ~layout:(fun child -> "child(" ^ child ^ ")")
      ()
  in
  let plan = RouterServer.Plan.success ~scopes:[ root; child ] ~page:"page" in
  let resolved =
    Lwt_main.run
      (RouterServer.Plan.resolve plan
         ~render:(RouterServer.Plan.Suffix { omitted_scopes = 1 })
         ~applicationStatus:(fun _ -> Status.InternalServerError))
  in
  Alcotest.(check (option string)) "suffix" (Some "child(page)") resolved.element

let () =
  Alcotest.run "router server"
    [
      ( "registry and matching",
        [
          test "static precedes dynamic" static_precedes_dynamic;
          test "decoded parameters" decoded_parameters;
          test "duplicate paths" duplicate_paths;
          test "ambiguous patterns" ambiguous_patterns;
          test "overlapping patterns" overlapping_patterns;
          test "malformed escape" malformed_escape;
          test "encoded slash" encoded_slash;
          test "destination segment encoding" destination_segment_encoding;
          test "repeated search" repeated_search;
          test "decoded search" decoded_search;
          test "malformed search" malformed_search;
          test "oversized search" oversized_search;
          test "loader sequence" loader_sequence;
          test "loader short circuit" loader_short_circuit;
          test "error status" error_status;
          test "metadata composition" metadata_composition;
          test "header composition" header_composition;
          test "latest navigation wins" latest_navigation_wins;
          test "stale revision rejected" stale_revision_rejected;
          test "shallow location commit" shallow_location_commit;
          test "valid full navigation response" valid_full_navigation_response;
          test "superseded navigation response is canceled" superseded_navigation_response_is_canceled;
          test "stale navigation response is rejected" stale_navigation_response_is_rejected;
          test "stale patch base is rejected" stale_patch_base_is_rejected;
          test "redirect and reload response kinds" redirect_and_reload_response_kinds;
          test "redirect and reload navigation responses" redirect_and_reload_navigation_responses;
          test "history action selects mutation" history_action_selects_mutation;
          test "hash-only location commit" hash_only_location_commit;
          test "active match uses route and parameters" active_match_uses_route_and_parameters;
          test "typed search decoding" typed_search_decoding;
          test "shallow search preserves unowned values" shallow_search_preserves_unowned_values;
          test "pop navigation kind" pop_navigation_kind;
          test "typed endpoint decoding" typed_endpoint_decoding;
          test "typed endpoint decode error" typed_endpoint_decode_error;
          test "full plan composition" full_plan_composition;
          test "failure plan selects not-found boundary" failure_plan_selects_not_found_boundary;
          test "shared layout prefix uses canonical identity" shared_layout_prefix_uses_canonical_identity;
          test "suffix plan omits shared layouts" suffix_plan_omits_shared_layouts;
        ] );
    ]

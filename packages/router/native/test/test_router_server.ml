let test title fn = Alcotest.test_case title `Quick fn

let contains ~needle value =
  let limit = String.length value - String.length needle in
  let rec loop index =
    index <= limit && (String.equal (String.sub value index (String.length needle)) needle || loop (index + 1))
  in
  loop 0

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

let total_specificity_precedes_earlier_static () =
  let registry =
    registry
      [
        route ~id:"more-static" ~path:"/:first<string>/b/c";
        route ~id:"earlier-static" ~path:"/a/:second<string>/:third<string>";
      ]
  in
  match RouterServer.Match.find registry ~pathname:"/a/b/c" with
  | Ok (Some matched) ->
      Alcotest.(check string) "route" "more-static" (RouterServer.Route.id matched.route);
      Alcotest.(check (list (pair string string))) "params" [ ("first", "a") ] matched.parameters
  | _ -> Alcotest.fail "expected most-specific match"

let failed_static_branch_backtracks_to_parameter () =
  let registry = registry [ route ~id:"static" ~path:"/a/b/z"; route ~id:"parameter" ~path:"/a/:value<string>/c" ] in
  match RouterServer.Match.find registry ~pathname:"/a/b/c" with
  | Ok (Some matched) -> Alcotest.(check string) "route" "parameter" (RouterServer.Route.id matched.route)
  | _ -> Alcotest.fail "expected parameter fallback"

let encoded_static_segment () =
  let registry = registry [ route ~id:"cafe" ~path:"/notes/café" ] in
  match RouterServer.Match.find registry ~pathname:"/notes/caf%C3%A9" with
  | Ok (Some matched) -> Alcotest.(check string) "route" "cafe" (RouterServer.Route.id matched.route)
  | _ -> Alcotest.fail "expected encoded static match"

let decoded_parameters () =
  let registry = registry [ route ~id:"note" ~path:"/notes/:slug<Slug.t>" ] in
  match RouterServer.Match.find registry ~pathname:"/notes/caf%C3%A9" with
  | Ok (Some matched) -> Alcotest.(check (list (pair string string))) "params" [ ("slug", "café") ] matched.parameters
  | _ -> Alcotest.fail "expected decoded match"

let catch_all_precedence_and_capture () =
  let registry =
    registry
      [
        route ~id:"asset" ~path:"/assets/:parts<string...>";
        route ~id:"named" ~path:"/assets/:name<string>";
        route ~id:"static" ~path:"/assets/logo";
        route ~id:"deep" ~path:"/assets/img/:name<string>";
      ]
  in
  let find pathname = RouterServer.Match.find registry ~pathname in
  (match find "/assets/logo" with
  | Ok (Some matched) -> Alcotest.(check string) "static wins" "static" (RouterServer.Route.id matched.route)
  | _ -> Alcotest.fail "expected static match");
  (match find "/assets/one" with
  | Ok (Some matched) -> Alcotest.(check string) "parameter wins" "named" (RouterServer.Route.id matched.route)
  | _ -> Alcotest.fail "expected parameter match");
  (match find "/assets/img/logo" with
  | Ok (Some matched) -> Alcotest.(check string) "deeper finite wins" "deep" (RouterServer.Route.id matched.route)
  | _ -> Alcotest.fail "expected deeper finite match");
  (match find "/assets/one/two/caf%C3%A9" with
  | Ok (Some matched) ->
      Alcotest.(check string) "catch-all" "asset" (RouterServer.Route.id matched.route);
      Alcotest.(check (list (pair string string))) "captured" [ ("parts", "one/two/café") ] matched.parameters
  | _ -> Alcotest.fail "expected catch-all match");
  match find "/assets" with Ok None -> () | _ -> Alcotest.fail "expected no match without a captured segment"

let less_specific_route_below_a_more_specific_subtree () =
  let registry =
    registry
      [
        route ~id:"docs" ~path:"/docs/:rest<string...>";
        route ~id:"changes" ~path:"/docs/:version<string>/changes";
        route ~id:"page" ~path:"/:lang<string>/:page<string>";
        route ~id:"edit" ~path:"/:lang<string>/:page<string>/edit";
      ]
  in
  match RouterServer.Match.find registry ~pathname:"/docs/intro" with
  | Ok (Some matched) -> Alcotest.(check string) "more statics wins" "docs" (RouterServer.Route.id matched.route)
  | _ -> Alcotest.fail "expected catch-all match"

let ambiguous_catch_all_patterns () =
  match
    RouterServer.Registry.make
      [ route ~id:"left" ~path:"/assets/:a<string...>"; route ~id:"right" ~path:"/assets/:b<string...>" ]
  with
  | Error (AmbiguousPattern _) -> ()
  | _ -> Alcotest.fail "expected ambiguous catch-all patterns"

let crossing_catch_all_patterns_are_order_independent () =
  let left = route ~id:"left" ~path:"/foo/:left<string...>" in
  let right = route ~id:"right" ~path:"/:scope<string>/bar/:right<string...>" in
  let check routes expected =
    match RouterServer.Registry.make routes with
    | Error (AmbiguousPattern (left, right)) -> Alcotest.(check (pair string string)) "patterns" expected (left, right)
    | _ -> Alcotest.fail "expected crossing catch-all ambiguity"
  in
  check [ left; right ] ("/foo/:left<string...>", "/:scope<string>/bar/:right<string...>");
  check [ right; left ] ("/:scope<string>/bar/:right<string...>", "/foo/:left<string...>")

let catch_all_endpoint_decoding () =
  let endpoint =
    RouterServer.Endpoint.make ~id:"asset" ~path:"/assets/:parts<string...>" ~activeRoutes:[] ~fingerprint:"asset"
      ~decode:(fun input ->
        match RouterServer.Decode.path ~input ~name:"parts" ~parse:RouterRuntime.CatchAll.parse with
        | Ok parts ->
            Ok (RouterServer.Endpoint.prepared ~branch:[] ~execution:(fun () -> RouterServer.Execution.done_ parts))
        | Error error -> Error error)
  in
  let registry = RouterServer.EndpointRegistry.makeExn [ endpoint ] in
  let search =
    match RouterServer.Search.parse "" with Ok search -> search | Error _ -> Alcotest.fail "expected search"
  in
  match RouterServer.EndpointRegistry.find registry ~pathname:"/assets/a%2Bb/c" with
  | Ok (Some matched) -> (
      match RouterServer.EndpointRegistry.decode matched ~search with
      | Ok prepared -> (
          match Lwt_main.run (RouterServer.Execution.run (RouterServer.Endpoint.execution prepared)) with
          | RouterRuntime.Loader.Data parts -> Alcotest.(check (list string)) "decoded" [ "a+b"; "c" ] parts
          | _ -> Alcotest.fail "expected data")
      | Error _ -> Alcotest.fail "expected prepared endpoint")
  | _ -> Alcotest.fail "expected endpoint match"

let catch_all_to_string_validation () =
  Alcotest.(check string) "joined" "a/b" (RouterRuntime.CatchAll.toString [ "a"; "b" ]);
  List.iter
    (fun segments ->
      let rejected =
        try
          ignore (RouterRuntime.CatchAll.toString segments);
          false
        with Invalid_argument _ -> true
      in
      Alcotest.(check bool) "rejected" true rejected)
    [ []; [ "" ]; [ "." ]; [ ".." ]; [ "a/b" ] ]

let destination_catch_all_encoding () =
  let destination =
    RouterRuntime.destinationFromPattern
      ~pattern:(RouterRuntime.pattern "/assets/:parts<string...>")
      ~parameters:[ ("parts", RouterRuntime.CatchAll.toString [ "a+b"; "café" ]) ]
      ~search:[]
  in
  Alcotest.(check string) "path" "/assets/a%2Bb/caf%C3%A9" (RouterRuntime.href destination)

let duplicate_paths () =
  match RouterServer.Registry.make [ route ~id:"left" ~path:"/notes"; route ~id:"right" ~path:"/notes" ] with
  | Error (DuplicatePath "/notes") -> ()
  | _ -> Alcotest.fail "expected duplicate path"

let duplicate_ids () =
  match RouterServer.Registry.make [ route ~id:"note" ~path:"/notes"; route ~id:"note" ~path:"/archive" ] with
  | Error (DuplicateId "note") -> ()
  | _ -> Alcotest.fail "expected duplicate id"

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

let malformed_escape_reports_leftmost_segment () =
  let registry = registry [ route ~id:"route" ~path:"/:first<string>/:second<string>" ] in
  match RouterServer.Match.find registry ~pathname:"/%ZZ/%GG" with
  | Error (MalformedEscape "%ZZ") -> ()
  | _ -> Alcotest.fail "expected leftmost malformed escape"

let encoded_slash () =
  let registry = registry [ route ~id:"note" ~path:"/:id<NoteId.t>" ] in
  match RouterServer.Match.find registry ~pathname:"/a%2Fb" with
  | Error (EncodedSlash "a%2Fb") -> ()
  | _ -> Alcotest.fail "expected encoded slash error"

let dot_segments () =
  let dynamic_registry = registry [ route ~id:"note" ~path:"/:id<NoteId.t>" ] in
  List.iter
    (fun pathname ->
      match RouterServer.Match.find dynamic_registry ~pathname with
      | Error (InvalidPath _) -> ()
      | _ -> Alcotest.failf "expected invalid path for %s" pathname)
    [ "/."; "/.."; "/%2e"; "/%2E%2e" ];
  let registry = registry [ route ~id:"note" ~path:"/:id<NoteId.t>/expected" ] in
  match RouterServer.Match.find registry ~pathname:"/%2e%2e/other" with
  | Error (InvalidPath _) -> ()
  | _ -> Alcotest.fail "expected dot segment rejection before route matching"

let invalid_utf8_path () =
  let registry = registry [ route ~id:"note" ~path:"/:id<string>" ] in
  List.iter
    (fun pathname ->
      match RouterServer.Match.find registry ~pathname with
      | Error (InvalidPath _) -> ()
      | _ -> Alcotest.fail "expected invalid UTF-8 path")
    [ "/\255"; "/%FF"; "/%00"; "/%1F"; "/%7F" ];
  let rejected_route =
    try
      ignore (route ~id:"invalid" ~path:"/\255");
      false
    with Invalid_argument _ -> true
  in
  Alcotest.(check bool) "invalid route pattern" true rejected_route

let destination_segment_encoding () =
  let destination =
    RouterRuntime.destinationFromPattern
      ~pattern:(RouterRuntime.pattern "/notes/:id<string>")
      ~parameters:[ ("id", "a+b") ]
      ~search:[]
  in
  Alcotest.(check string) "path" "/notes/a%2Bb" (RouterRuntime.href destination)

let scalar_destinations_round_trip () =
  let pattern = RouterRuntime.pattern "/notes/:id<string>" in
  let registry = registry [ route ~id:"note" ~path:"/notes/:id<string>" ] in
  List.iter
    (fun (value, expected) ->
      let destination = RouterRuntime.destinationFromPattern ~pattern ~parameters:[ ("id", value) ] ~search:[] in
      let href = RouterRuntime.href destination in
      Alcotest.(check string) value expected href;
      match RouterServer.Match.find registry ~pathname:href with
      | Ok (Some matched) -> Alcotest.(check (list (pair string string))) "decoded" [ ("id", value) ] matched.parameters
      | _ -> Alcotest.failf "generated destination did not match: %s" href)
    [
      ("café", "/notes/caf%C3%A9");
      ("東京", "/notes/%E6%9D%B1%E4%BA%AC");
      ("!$&'()*+,:;=@_~-", "/notes/!%24%26'()*%2B%2C%3A%3B%3D%40_~-");
    ]

let invalid_scalar_destinations () =
  let pattern = RouterRuntime.pattern "/notes/:id<string>" in
  List.iter
    (fun value ->
      let rejected =
        try
          ignore (RouterRuntime.destinationFromPattern ~pattern ~parameters:[ ("id", value) ] ~search:[]);
          false
        with Invalid_argument _ -> true
      in
      Alcotest.(check bool) "rejected" true rejected)
    [ ""; "."; ".."; "a/b"; "\000"; "\031"; "\127"; "\255" ]

let repeated_search () =
  match RouterServer.Search.parse "?tag=one&tag=two&empty=&flag" with
  | Ok search ->
      Alcotest.(check (list string)) "tags" [ "one"; "two" ] (RouterServer.Search.values search "tag");
      Alcotest.(check (list string)) "empty" [ "" ] (RouterServer.Search.values search "empty");
      Alcotest.(check (list string)) "flag" [ "" ] (RouterServer.Search.values search "flag")
  | Error _ -> Alcotest.fail "expected valid search"

let large_search_index () =
  match RouterServer.Search.parse "?a=1&b=2&c=3&d=4&e=5&f=6&g=7&h=8&a=9&i=10" with
  | Ok search ->
      Alcotest.(check (list string)) "repeated" [ "1"; "9" ] (RouterServer.Search.values search "a");
      Alcotest.(check (list string))
        "order"
        [ "a"; "b"; "c"; "d"; "e"; "f"; "g"; "h"; "i" ]
        (RouterServer.Search.unknown search ~owned:[] |> List.map fst)
  | Error _ -> Alcotest.fail "expected valid large search"

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
  match RouterServer.Search.parse "?a=1&filter=%ZZ&b=2&%ZZ=x&t=1&t=ab%4&t=%&t=2" with
  | Ok search ->
      Alcotest.(check (list (pair string (list string))))
        "pairs"
        [ ("a", [ "1" ]); ("b", [ "2" ]); ("t", [ "1"; "2" ]) ]
        (RouterServer.Search.unknown search ~owned:[])
  | Error _ -> Alcotest.fail "expected malformed pairs to be dropped"

let oversized_search () =
  match RouterServer.Search.parse (String.make 8193 'x') with
  | Error RouterServer.Search.QueryTooLong -> ()
  | _ -> Alcotest.fail "expected oversized search rejection"

let search_skips_empty_pairs () =
  match RouterServer.Search.parse "?&a=1&&b=2&" with
  | Ok search ->
      Alcotest.(check (list (pair string (list string))))
        "pairs"
        [ ("a", [ "1" ]); ("b", [ "2" ]) ]
        (RouterServer.Search.unknown search ~owned:[])
  | Error _ -> Alcotest.fail "expected valid search"

let invalid_utf8_search () =
  List.iter
    (fun search ->
      match RouterServer.Search.parse ("a=1&" ^ search) with
      | Ok parsed ->
          Alcotest.(check (list (pair string (list string))))
            search
            [ ("a", [ "1" ]) ]
            (RouterServer.Search.unknown parsed ~owned:[])
      | Error _ -> Alcotest.failf "expected %S to be dropped" search)
    [ "q=%FF"; "q=%C3"; "%C3=1"; "q=\xff"; "q=%ED%A0%80"; "q=%C0%80"; "q=%E0%80%80"; "q=%F4%90%80%80"; "q=%E2%82" ];
  List.iter
    (fun (search, expected) ->
      match RouterServer.Search.parse search with
      | Ok parsed -> Alcotest.(check (list string)) search [ expected ] (RouterServer.Search.values parsed "q")
      | Error _ -> Alcotest.failf "expected %S to be accepted" search)
    [
      ("q=%F0%9F%98%80", "\xF0\x9F\x98\x80");
      ("q=\xC3\xA9", "\xC3\xA9");
      ("q=%E2%82%AC", "\xE2\x82\xAC");
      ("q=%EF%BF%BF", "\xEF\xBF\xBF");
      ("q=%F4%8F%BF%BF", "\xF4\x8F\xBF\xBF");
    ]

let search_input query =
  match RouterServer.Search.parse query with
  | Ok search -> RouterServer.Input.forSearch search
  | Error _ -> Alcotest.failf "expected %S to parse" query

let search_result = Alcotest.(result (option int) reject)

let search_decoders_by_kind () =
  let parse = RouterRuntime.Search.parseInt in
  let input = search_input "?page=nope&n=1&n=x&n=3&n=&o=nope" in
  let check_error label = function
    | Error (RouterRuntime.Error.InvalidSearchParameter { name }) -> Alcotest.(check string) label "r" name
    | Ok _ | Error _ -> Alcotest.failf "%s: expected InvalidSearchParameter" label
  in
  Alcotest.check search_result "optional" (Ok None) (RouterServer.Decode.searchOptional ~input ~name:"o" ~parse);
  Alcotest.(check (result int reject))
    "default" (Ok 1)
    (RouterServer.Decode.searchDefault ~input ~name:"page" ~parse ~fallback:1);
  Alcotest.(check (result (list int) reject))
    "many"
    (Ok [ 1; 3 ])
    (RouterServer.Decode.searchMany ~input ~name:"n" ~parse);
  check_error "required missing" (RouterServer.Decode.searchRequired ~input ~name:"r" ~parse);
  check_error "required bad" (RouterServer.Decode.searchRequired ~input:(search_input "?r=nope") ~name:"r" ~parse);
  Alcotest.(check (result int reject))
    "required good" (Ok 4)
    (RouterServer.Decode.searchRequired ~input:(search_input "?r=4") ~name:"r" ~parse)

let base_path_matches_segments () =
  let strip ~basePath pathname = RouterServer.Path.stripBasePath ~basePath pathname in
  let check ~basePath pathname expected =
    Alcotest.(check (option string)) (basePath ^ " " ^ pathname) expected (strip ~basePath pathname)
  in
  check ~basePath:"/app" "/app" (Some "/");
  check ~basePath:"/app" "/app/x" (Some "/x");
  check ~basePath:"/app" "/app/x/y" (Some "/x/y");
  check ~basePath:"/app" "/apple" None;
  check ~basePath:"/app" "/apple/x" None;
  check ~basePath:"/app" "/ap" None;
  check ~basePath:"/app" "/" None;
  check ~basePath:"/app" "/app%2Fx" None;
  check ~basePath:"/app" "/%61pp/x" (Some "/x");
  check ~basePath:"/a/b" "/a/b/c" (Some "/c");
  check ~basePath:"/a/b" "/a/bc" None;
  check ~basePath:"/m%C3%BCnchen" "/m%c3%bcnchen/item" (Some "/item");
  check ~basePath:"/m%C3%BCnchen" "/m%C3%BCnchen" (Some "/");
  check ~basePath:"/m%C3%BCnchen" "/m%C3%BCnchenx" None;
  check ~basePath:"/" "/x" (Some "/x")

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

let rejected_loader_uses_nearest_boundary () =
  let fallback_called = ref false in
  let boundary name = function
    | RouterRuntime.Error.Internal { diagnosticId } -> name ^ ":" ^ diagnosticId
    | _ -> name ^ ":wrong-error"
  in
  let endpoint : ((string, string) RouterServer.Plan.t, string, unit) RouterServer.Endpoint.t =
    RouterServer.Endpoint.make ~id:"root" ~path:"/" ~activeRoutes:[] ~fingerprint:"root" ~decode:(fun _ ->
        Ok
          (RouterServer.Endpoint.prepared ~branch:[] ~execution:(fun () ->
               RouterServer.Execution.loadWithBoundary
                 ~run:(fun () -> Lwt.return (RouterRuntime.Loader.Data ()))
                 ~failure:(fun error ->
                   RouterServer.Plan.failure ~scopes:[] ~error ~errorBoundary:(boundary "outer") ())
                 ~next:(fun () ->
                   RouterServer.Execution.loadWithBoundary
                     ~run:(fun () -> Lwt.fail (Failure "private loader detail"))
                     ~failure:(fun error ->
                       RouterServer.Plan.failure ~scopes:[] ~error ~errorBoundary:(boundary "inner") ())
                     ~next:(fun (_ : unit) ->
                       RouterServer.Execution.done_ (RouterServer.Plan.success ~scopes:[] ~page:"loaded"))))))
  in
  let registry = RouterServer.EndpointRegistry.makeExn [ endpoint ] in
  let request : RouterServer.ServerEngine.request =
    { pathname = "/"; search = ""; hash = ""; kind = Document; navigation = None }
  in
  let outcome =
    Lwt_main.run
      (RouterServer.ServerEngine.run ~registry ~basePath:"/" ~trailingSlash:RouterServer.TrailingSlash.Redirect
         ~fallback:(fun ~search:_ ~error ->
           fallback_called := true;
           RouterServer.Plan.failure ~scopes:[] ~error ~errorBoundary:(boundary "fallback") ())
         ~applicationStatus:(fun _ -> RouterRuntime.Status.InternalServerError)
         ~diagnosticId:(fun _ -> "diagnostic-1")
         ~protocolVersion:1 request)
  in
  match outcome with
  | RouterServer.ServerEngine.Full full ->
      Alcotest.(check bool) "root fallback skipped" false !fallback_called;
      Alcotest.(check (option string)) "nearest boundary" (Some "inner:diagnostic-1") full.resolved.element
  | _ -> Alcotest.fail "expected full boundary response"

let fatal_loader_exceptions_propagate () =
  let propagates expected =
    let execution =
      RouterServer.Execution.loadWithBoundary
        ~run:(fun () -> Lwt.fail expected)
        ~failure:(fun _ -> ())
        ~next:(fun (_ : unit) -> RouterServer.Execution.done_ ())
    in
    match
      Lwt_main.run
        (Lwt.catch
           (fun () -> Lwt.map Result.ok (RouterServer.Execution.run execution))
           (fun error -> Lwt.return (Error error)))
    with
    | Error actual -> Alcotest.(check string) "exception" (Printexc.to_string expected) (Printexc.to_string actual)
    | Ok _ -> Alcotest.fail "expected exception to propagate"
  in
  propagates Lwt.Canceled;
  propagates Sys.Break

let started_loader_exceptions_use_boundary () =
  let execution failure =
    RouterServer.Execution.start
      ~run:(fun () -> raise failure)
      ~next:(fun started ->
        RouterServer.Execution.loadWithBoundary
          ~run:(fun () -> Lwt.return (RouterRuntime.Loader.Data ()))
          ~failure:(fun _ -> "parent")
          ~next:(fun () ->
            RouterServer.Execution.loadWithBoundary ~run:(RouterServer.Execution.await started)
              ~failure:(function
                | RouterRuntime.Error.Internal { diagnosticId } -> "child:" ^ diagnosticId | _ -> "child:wrong-error")
              ~next:(fun (_ : unit) -> RouterServer.Execution.done_ "loaded")))
  in
  let run failure =
    Lwt_main.run
      (Lwt.catch
         (fun () -> Lwt.map Result.ok (RouterServer.Execution.run ~diagnosticId:Printexc.to_string (execution failure)))
         (fun error -> Lwt.return (Error error)))
  in
  (match run (Failure "detail") with
  | Ok (RouterRuntime.Loader.Data result) -> Alcotest.(check string) "boundary" "child:Failure(\"detail\")" result
  | _ -> Alcotest.fail "expected the boundary");
  match run Sys.Break with
  | Error actual -> Alcotest.(check string) "fatal" (Printexc.to_string Sys.Break) (Printexc.to_string actual)
  | Ok _ -> Alcotest.fail "expected exception to propagate"

let request_memo_runs_once_per_request () =
  let key : int RouterServer.Request.key = RouterServer.Request.key () in
  let other : int RouterServer.Request.key = RouterServer.Request.key () in
  let runs = ref [] in
  let fetch key argument =
    RouterServer.Request.memo key argument (fun () ->
        runs := !runs @ [ argument ];
        Lwt.bind (Lwt.pause ()) (fun () -> Lwt.return (List.length !runs)))
  in
  let request () =
    RouterServer.Request.scope (fun () ->
        let first = fetch key "a" in
        let again = fetch key "a" in
        let different = fetch key "b" in
        let other_key = fetch other "a" in
        let nested = RouterServer.Request.scope (fun () -> fetch key "a") in
        Lwt.all [ first; again; different; other_key; nested ])
  in
  let int_list = Alcotest.(list int) in
  Alcotest.check int_list "first request" [ 4; 4; 4; 4; 4 ] (Lwt_main.run (request ()));
  Alcotest.(check (list string))
    "one run per key and argument, a nested scope starts empty" [ "a"; "b"; "a"; "a" ] !runs;
  runs := [];
  let both = Lwt_main.run (Lwt.both (request ()) (request ())) in
  Alcotest.(check int) "each request runs its own" 8 (List.length !runs);
  Alcotest.(check bool) "results kept per request" true (List.for_all (fun value -> value = 8) (fst both @ snd both));
  runs := [];
  let outside = Lwt_main.run (Lwt.all [ fetch key "a"; fetch key "a" ]) in
  Alcotest.check int_list "outside a request" [ 2; 2 ] outside;
  Alcotest.(check (list string)) "no cache outside a request" [ "a"; "a" ] !runs

let error_status () =
  let open RouterRuntime in
  Alcotest.(check int)
    "invalid path" 400
    (RouterServer.statusOfError ~application:(fun _ -> Status.Forbidden) (Error.InvalidPathParameter { name = "id" })
    |> Status.toInt);
  Alcotest.(check int)
    "application" 403
    (RouterServer.statusOfError ~application:(fun _ -> Status.Forbidden) (Error.Application "denied") |> Status.toInt);
  List.iter
    (fun (status, code) ->
      Alcotest.(check int)
        (string_of_int code) code
        (RouterServer.statusOfError ~application:(fun _ -> status) (Error.Application "denied") |> Status.toInt))
    [ (Status.Unauthorized, 401); (Status.Gone, 410); (Status.TooManyRequests, 429); (Status.ServiceUnavailable, 503) ]

let metadata_composition () =
  let open RouterRuntime.Metadata in
  let parent = make ~title:"Parent" ~entries:[ meta ~name:"robots" "index"; link ~rel:"canonical" "/a" ] () in
  let child = make ~description:"Child" ~entries:[ meta ~name:"robots" "noindex"; meta ~name:"extra" "x" ] () in
  let merged = merge parent child in
  Alcotest.(check (option string)) "title" (Some "Parent") merged.title;
  Alcotest.(check (option string)) "description" (Some "Child") merged.description;
  Alcotest.(check (list string))
    "parent order kept, child replaces and appends"
    [ "link:canonical"; "meta:robots"; "meta:extra" ]
    (List.map entryKey merged.entries);
  match merged.entries with
  | [ _; Meta { content; _ }; _ ] -> Alcotest.(check string) "child wins" "noindex" content
  | _ -> Alcotest.fail "unexpected entries"

let metadata_default_keys () =
  let open RouterRuntime.Metadata in
  Alcotest.(check string) "meta" "meta:description" (entryKey (meta ~name:"description" "x"));
  Alcotest.(check string) "property" "property:og:title" (entryKey (property ~property:"og:title" "x"));
  Alcotest.(check string) "link" "link:canonical" (entryKey (link ~rel:"canonical" "/x"));
  Alcotest.(check string) "explicit" "k" (entryKey (link ~key:"k" ~rel:"alternate" "/x"));
  let merged = merge (make ~entries:[ meta ~name:"icon" "a" ] ()) (make ~entries:[ link ~rel:"icon" "/i.png" ] ()) in
  Alcotest.(check int) "no accidental collision" 2 (List.length merged.entries);
  let merged = merge (make ~entries:[ meta ~name:"x" "a" ] ()) (make ~entries:[ property ~property:"x" "b" ] ()) in
  Alcotest.(check int) "name and property differ" 2 (List.length merged.entries)

let metadata_repeated_tags_with_explicit_keys () =
  let open RouterRuntime.Metadata in
  let alternate lang = link ~key:("alt:" ^ lang) ~rel:"alternate" ~attrs:[ ("hreflang", lang) ] ("/" ^ lang) in
  let merged = merge (make ~entries:[ alternate "en" ] ()) (make ~entries:[ alternate "es" ] ()) in
  Alcotest.(check int) "both kept" 2 (List.length merged.entries);
  let merged = merge merged (make ~entries:[ link ~key:"alt:en" ~rel:"alternate" "/en2" ] ()) in
  Alcotest.(check int) "same key replaced" 2 (List.length merged.entries)

let metadata_rendering () =
  let open RouterRuntime.Metadata in
  let html =
    make ~title:"T" ~description:"D"
      ~entries:
        [
          meta ~name:"robots" "noindex";
          property ~property:"og:title" "Og";
          link ~rel:"canonical" "/c";
          link ~key:"alt:es" ~rel:"alternate"
            ~attrs:
              [
                ("hreflang", "es");
                ("rel", "evil");
                ("HREF", "/evil");
                ("x onload=alert(1) y", "1");
                ("", "2");
                ("a\"b", "3");
              ]
            "/es";
        ]
      ()
    |> RouterServer.Adapter.metadata_element |> ReactDOM.renderToStaticMarkup
  in
  Alcotest.(check string)
    "markup"
    "<title>T</title><meta name=\"description\" content=\"D\" /><meta name=\"robots\" content=\"noindex\" /><meta \
     property=\"og:title\" content=\"Og\" /><link rel=\"canonical\" href=\"/c\" /><link rel=\"alternate\" href=\"/es\" \
     hreflang=\"es\" />"
    html

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
        metadata = "metadata";
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

let navigation_response_rsc_round_trip () =
  let original : string RouterRuntime.NavigationResponse.full =
    {
      protocolVersion = 1;
      registryFingerprint = "registry";
      canonicalUrl = "/notes?page=2";
      status = 200;
      matches = [ { RouterRuntime.Navigation.routeId = "notes"; parameters = [ ("id", "2") ] } ];
      layouts = [ { RouterRuntime.Navigation.id = "root"; instanceKey = "root" } ];
      targetRevision = "r2";
      metadata = "metadata";
      payload = "payload";
    }
  in
  let encoded = RouterRuntime.NavigationResponse.full_to_rsc RSC.Primitives.string_to_rsc original in
  let decoded = RouterRuntime.NavigationResponse.full_of_rsc RSC.Primitives.string_of_rsc encoded in
  Alcotest.(check bool) "round trip" true (decoded = original)

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
        metadata = "metadata";
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

let builtin_bool_codec () =
  let open RouterRuntime.Search in
  Alcotest.(check bool) "true" true (parseBool "true" = Ok true);
  Alcotest.(check bool) "false" true (parseBool "false" = Ok false);
  List.iter
    (fun value -> match parseBool value with Ok _ -> Alcotest.failf "accepted %s" value | Error _ -> ())
    [ "True"; "FALSE"; "1"; "0"; ""; "yes" ]

let builtin_int_codec () =
  let open RouterRuntime.Search in
  List.iter
    (fun (value, expected) -> Alcotest.(check bool) value true (parseInt value = Ok expected))
    [ ("0", 0); ("42", 42); ("-5", -5); ("007", 7); ("2147483647", 2147483647); ("-2147483648", -2147483648) ];
  List.iter
    (fun value -> match parseInt value with Ok _ -> Alcotest.failf "accepted %S" value | Error _ -> ())
    [
      "";
      "-";
      "+5";
      "0x10";
      "0b11";
      "0o7";
      "1_000";
      " 1";
      "1 ";
      "1.5";
      "--1";
      "2147483648";
      "-2147483649";
      "99999999999999999999";
    ]

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
  Alcotest.(check bool)
    "hash" true
    (classifyPopByContentIdentity committed ~target:hashTarget ~currentIdentity:"r1" ~targetIdentity:(Some "r1")
    = HashOnly);
  Alcotest.(check bool)
    "search" true
    (classifyPopByContentIdentity committed ~target:searchTarget ~currentIdentity:"r1" ~targetIdentity:(Some "r1")
    = Shallow);
  Alcotest.(check bool)
    "stale" true
    (classifyPopByContentIdentity committed ~target:searchTarget ~currentIdentity:"r1" ~targetIdentity:(Some "old")
    = Content)

let typed_endpoint_decoding () =
  let endpoint =
    RouterServer.Endpoint.make ~id:"note" ~path:"/notes/:id<NoteId.t>" ~activeRoutes:[] ~fingerprint:"note"
      ~decode:(fun input ->
        match
          ( RouterServer.Decode.path ~input ~name:"id" ~parse:(fun value ->
                match int_of_string_opt value with Some value -> Ok value | None -> Error "expected integer"),
            RouterServer.Decode.searchDefault ~input ~name:"page" ~parse:RouterRuntime.Search.parseInt ~fallback:1 )
        with
        | Ok id, Ok page ->
            Ok
              (RouterServer.Endpoint.prepared ~branch:[] ~execution:(fun () -> RouterServer.Execution.done_ (id + page)))
        | Error error, _ | _, Error error -> Error error)
  in
  let registry = RouterServer.EndpointRegistry.makeExn [ endpoint ] in
  let search =
    match RouterServer.Search.parse "?page=2" with Ok search -> search | Error _ -> Alcotest.fail "expected search"
  in
  match RouterServer.EndpointRegistry.find registry ~pathname:"/notes/40" with
  | Ok (Some matched) -> (
      match RouterServer.EndpointRegistry.decode matched ~search with
      | Ok prepared -> (
          match Lwt_main.run (RouterServer.Execution.run (RouterServer.Endpoint.execution prepared)) with
          | RouterRuntime.Loader.Data value -> Alcotest.(check int) "decoded" 42 value
          | _ -> Alcotest.fail "expected data")
      | Error _ -> Alcotest.fail "expected prepared endpoint")
  | _ -> Alcotest.fail "expected endpoint match"

let typed_endpoint_decode_error () =
  let endpoint =
    RouterServer.Endpoint.make ~id:"note" ~path:"/notes/:id<NoteId.t>" ~activeRoutes:[] ~fingerprint:"note"
      ~decode:(fun input ->
        match RouterServer.Decode.path ~input ~name:"id" ~parse:(fun _ -> Error "invalid") with
        | Ok (_ : int) ->
            Ok (RouterServer.Endpoint.prepared ~branch:[] ~execution:(fun () -> RouterServer.Execution.done_ ()))
        | Error error -> Error error)
  in
  let registry = RouterServer.EndpointRegistry.makeExn [ endpoint ] in
  let search =
    match RouterServer.Search.parse "" with Ok search -> search | Error _ -> Alcotest.fail "expected search"
  in
  match RouterServer.EndpointRegistry.find registry ~pathname:"/notes/nope" with
  | Ok (Some matched) -> (
      match RouterServer.EndpointRegistry.decode matched ~search with
      | Error (RouterRuntime.Error.InvalidPathParameter { name = "id" }) -> ()
      | _ -> Alcotest.fail "expected invalid path parameter")
  | _ -> Alcotest.fail "expected endpoint match"

let run_trailing_slash_engine ~trailingSlash ~basePath ~pathname ?(search = "") () =
  let endpoint : ((string, string) RouterServer.Plan.t, string, unit) RouterServer.Endpoint.t =
    RouterServer.Endpoint.make ~id:"notes" ~path:"/notes" ~activeRoutes:[] ~fingerprint:"notes" ~decode:(fun _ ->
        Ok
          (RouterServer.Endpoint.prepared ~branch:[] ~execution:(fun () ->
               RouterServer.Execution.done_ (RouterServer.Plan.success ~scopes:[] ~page:"notes"))))
  in
  let registry = RouterServer.EndpointRegistry.makeExn [ endpoint ] in
  Lwt_main.run
    (RouterServer.ServerEngine.run ~registry ~basePath ~trailingSlash
       ~fallback:(fun ~search:_ ~error -> RouterServer.Plan.failure ~scopes:[] ~error ())
       ~applicationStatus:(fun _ -> RouterRuntime.Status.InternalServerError)
       ~diagnosticId:(fun _ -> "diagnostic")
       ~protocolVersion:1
       { pathname; search; hash = ""; kind = Document; navigation = None })

let run_redirect_engine ~kind execution =
  let endpoint : ((string, string) RouterServer.Plan.t, string, unit) RouterServer.Endpoint.t =
    RouterServer.Endpoint.make ~id:"old" ~path:"/old" ~activeRoutes:[] ~fingerprint:"old" ~decode:(fun _ ->
        Ok (RouterServer.Endpoint.prepared ~branch:[] ~execution))
  in
  let registry = RouterServer.EndpointRegistry.makeExn [ endpoint ] in
  Lwt_main.run
    (RouterServer.ServerEngine.run ~registry ~basePath:"/" ~trailingSlash:RouterServer.TrailingSlash.Redirect
       ~fallback:(fun ~search:_ ~error -> RouterServer.Plan.failure ~scopes:[] ~error ())
       ~applicationStatus:(fun _ -> RouterRuntime.Status.InternalServerError)
       ~diagnosticId:(fun _ -> "diagnostic")
       ~protocolVersion:1
       { pathname = "/old"; search = ""; hash = ""; kind; navigation = None })

let loader_permanent_redirect_reaches_engine () =
  let destination = RouterRuntime.destination ~path:"/new" in
  let execution () =
    RouterServer.Execution.load
      (fun () -> Lwt.return (RouterRuntime.Loader.PermanentRedirect destination))
      (fun (_ : unit) -> RouterServer.Execution.done_ (RouterServer.Plan.success ~scopes:[] ~page:"old"))
  in
  List.iter
    (fun kind ->
      match run_redirect_engine ~kind execution with
      | RouterServer.ServerEngine.PermanentRedirect found ->
          Alcotest.(check string) "destination" "/new" (RouterRuntime.href found)
      | _ -> Alcotest.fail "expected permanent redirect")
    [ RouterServer.ServerEngine.Document; RouterServer.ServerEngine.Rsc ]

let execution_permanent_redirect_skips_loaders () =
  let destination = RouterRuntime.destination ~path:"/new" in
  let execution () = RouterServer.Execution.permanentRedirect destination in
  match run_redirect_engine ~kind:Document execution with
  | RouterServer.ServerEngine.PermanentRedirect found ->
      Alcotest.(check string) "destination" "/new" (RouterRuntime.href found)
  | _ -> Alcotest.fail "expected permanent redirect"

let loader_redirect_stays_temporary () =
  let destination = RouterRuntime.destination ~path:"/new" in
  match run_redirect_engine ~kind:Document (fun () -> RouterServer.Execution.redirect destination) with
  | RouterServer.ServerEngine.Redirect _ -> ()
  | _ -> Alcotest.fail "expected temporary redirect"

let trailing_slash_redirects_to_canonical () =
  match
    run_trailing_slash_engine ~trailingSlash:RouterServer.TrailingSlash.Redirect ~basePath:"/app"
      ~pathname:"/app/notes/" ~search:"?page=2" ()
  with
  | RouterServer.ServerEngine.PermanentRedirect destination ->
      Alcotest.(check string) "destination" "/app/notes?page=2" (RouterRuntime.href destination)
  | _ -> Alcotest.fail "expected permanent redirect"

let trailing_slash_redirect_collapses_repeated_slashes () =
  match
    run_trailing_slash_engine ~trailingSlash:RouterServer.TrailingSlash.Redirect ~basePath:"/" ~pathname:"/notes///" ()
  with
  | RouterServer.ServerEngine.PermanentRedirect destination ->
      Alcotest.(check string) "destination" "/notes" (RouterRuntime.href destination)
  | _ -> Alcotest.fail "expected permanent redirect"

let trailing_slash_redirects_base_path_root () =
  match
    run_trailing_slash_engine ~trailingSlash:RouterServer.TrailingSlash.Redirect ~basePath:"/app" ~pathname:"/app/" ()
  with
  | RouterServer.ServerEngine.PermanentRedirect destination ->
      Alcotest.(check string) "destination" "/app" (RouterRuntime.href destination)
  | _ -> Alcotest.fail "expected permanent redirect"

let trailing_slash_reject_is_not_found () =
  match
    run_trailing_slash_engine ~trailingSlash:RouterServer.TrailingSlash.Reject ~basePath:"/" ~pathname:"/notes/" ()
  with
  | RouterServer.ServerEngine.Full full ->
      Alcotest.(check int) "status" 404 (RouterRuntime.Status.toInt full.resolved.status)
  | _ -> Alcotest.fail "expected not-found response"

let trailing_slash_redirect_never_leaves_the_origin () =
  List.iter
    (fun pathname ->
      match run_trailing_slash_engine ~trailingSlash:RouterServer.TrailingSlash.Redirect ~basePath:"/" ~pathname () with
      | RouterServer.ServerEngine.PermanentRedirect destination ->
          Alcotest.failf "%s redirected to %s" pathname (RouterRuntime.href destination)
      | RouterServer.ServerEngine.Full full ->
          Alcotest.(check int) pathname 404 (RouterRuntime.Status.toInt full.resolved.status)
      | _ -> Alcotest.fail "expected not-found response")
    [ "//evil.example/"; "///evil.example//"; "//evil.example/notes/"; "/\\evil.example/"; "/\\\\evil.example/" ]

let root_pathname_is_canonical () =
  match run_trailing_slash_engine ~trailingSlash:RouterServer.TrailingSlash.Redirect ~basePath:"/" ~pathname:"/" () with
  | RouterServer.ServerEngine.PermanentRedirect _ -> Alcotest.fail "expected no redirect for the root pathname"
  | RouterServer.ServerEngine.Full full ->
      Alcotest.(check int) "status" 404 (RouterRuntime.Status.toInt full.resolved.status)
  | _ -> Alcotest.fail "expected full response"

let engine_matches_lower_case_base_path_escapes () =
  match
    run_trailing_slash_engine ~trailingSlash:RouterServer.TrailingSlash.Redirect ~basePath:"/m%C3%BCnchen"
      ~pathname:"/m%c3%bcnchen/notes" ()
  with
  | RouterServer.ServerEngine.Full full ->
      Alcotest.(check int) "status" 200 (RouterRuntime.Status.toInt full.resolved.status)
  | _ -> Alcotest.fail "expected full response"

let default_boundary_renders_text () =
  let render error =
    let resolved =
      Lwt_main.run
        (RouterServer.Plan.resolve (RouterServer.Plan.failure ~scopes:[] ~error ()) ~applicationStatus:(fun _ ->
             RouterRuntime.Status.InternalServerError))
    in
    Alcotest.(check bool) "no app boundary" true (Option.is_none resolved.element);
    ReactDOM.renderToString (RouterServer.Plan.resolvedElement resolved)
  in
  Alcotest.(check string)
    "not found" "<p>Not found</p>"
    (render (RouterRuntime.Error.NotFound { reason = RouterRuntime.Error.NoMatchingRoute }));
  Alcotest.(check string)
    "application error hides details" "<p>Something went wrong</p>"
    (render (RouterRuntime.Error.Application "secret detail"))

let server_base_path_validation () =
  let endpoint : ((unit, unit) RouterServer.Plan.t, unit, unit) RouterServer.Endpoint.t =
    RouterServer.Endpoint.make ~id:"root" ~path:"/" ~activeRoutes:[] ~fingerprint:"root" ~decode:(fun _ ->
        Ok
          (RouterServer.Endpoint.prepared ~branch:[] ~execution:(fun () ->
               RouterServer.Execution.done_ (RouterServer.Plan.success ~scopes:[] ~page:()))))
  in
  let registry = RouterServer.EndpointRegistry.makeExn [ endpoint ] in
  let make basePath =
    RouterServer.Server.make ~basePath ~registry
      ~fallback:(fun ~search:_ ~error:_ -> RouterServer.Plan.success ~scopes:[] ~page:())
      ~applicationStatus:(fun () -> RouterRuntime.Status.InternalServerError)
      ()
  in
  ignore (make "/");
  ignore (make "/m%C3%BCnchen");
  List.iter
    (fun basePath ->
      let rejected =
        try
          ignore (make basePath);
          false
        with Invalid_argument _ -> true
      in
      Alcotest.(check bool) basePath true rejected)
    [ ""; "app"; "/app/"; "/app?preview"; "/münchen"; "/%61pp" ]

let adapter_server ?interceptLinks ?viewTransitions ?pageCacheMaxAge () =
  let page =
    RouterServer.Plan.success
      ~scopes:
        [
          RouterServer.Plan.Scope.make
            ~metadata:(fun () -> Lwt.return (RouterRuntime.Metadata.make ~title:"Item" ~description:"D" ()))
            ();
        ]
      ~page:(React.createElement "main" [] [ React.string "item" ])
  in
  let endpoint path id decode_result =
    RouterServer.Endpoint.make ~id ~path
      ~activeRoutes:[ (id, []) ]
      ~fingerprint:id
      ~decode:(fun _ -> Ok (RouterServer.Endpoint.prepared ~branch:[] ~execution:decode_result))
  in
  let registry =
    RouterServer.EndpointRegistry.makeExn
      [
        endpoint "/item" "item" (fun () -> RouterServer.Execution.done_ page);
        endpoint "/go" "go" (fun () ->
            RouterServer.Execution.load
              (fun () -> Lwt.return (RouterRuntime.Loader.Redirect (RouterRuntime.destination ~path:"/item")))
              (fun () -> RouterServer.Execution.done_ page));
      ]
  in
  RouterServer.Server.make ~basePath:"/app" ~registry
    ~fallback:(fun ~search:_ ~error -> RouterServer.Plan.failure ~scopes:[] ~error ())
    ~applicationStatus:(fun _ -> RouterRuntime.Status.InternalServerError)
    ?interceptLinks ?viewTransitions ?pageCacheMaxAge ()

let adapter_reply ?(registry = None) ?(search = "") ~kind pathname =
  let server = adapter_server () in
  let navigation =
    match kind with
    | RouterServer.ServerEngine.Document -> None
    | Rsc ->
        Some
          {
            RouterServer.ServerEngine.from = Some "/app";
            registry = Some (Option.value registry ~default:("1." ^ RouterServer.Server.fingerprint server));
            base_revision = Some "base";
          }
  in
  let outcome =
    Lwt_main.run
      (RouterServer.run server ~diagnosticId:(fun _ -> "diagnostic") { pathname; search; hash = ""; kind; navigation })
  in
  RouterServer.Adapter.reply server ~target:pathname ~pageCacheCapacity:0
    ~document:(fun ~head children ->
      React.createElement "html" []
        [ React.createElement "head" [] [ head ]; React.createElement "body" [] [ children ] ])
    ~kind outcome

let revision_defaults_to_empty () =
  let server = adapter_server () in
  let revision ?revision () =
    match
      Lwt_main.run
        (RouterServer.run server
           ~diagnosticId:(fun _ -> "diagnostic")
           ?revision
           { pathname = "/app/item"; search = ""; hash = ""; kind = Document; navigation = None })
    with
    | RouterServer.ServerEngine.Full full -> full.revision
    | _ -> Alcotest.fail "expected full response"
  in
  Alcotest.(check string) "default" "" (revision ());
  Alcotest.(check string) "given" "r2" (revision ~revision:(fun () -> "r2") ())

let header name (reply : RouterServer.Adapter.reply) = List.assoc_opt name reply.headers
let check_header reply name expected = Alcotest.(check (option string)) name expected (header name reply)

let count_occurrences ~needle haystack =
  let n = String.length needle in
  let rec go from acc =
    if from + n > String.length haystack then acc
    else if String.sub haystack from n = needle then go (from + n) (acc + 1)
    else go (from + 1) acc
  in
  go 0 0

let html_document ~head children =
  React.createElement "html" [] [ React.createElement "head" [] [ head ]; React.createElement "body" [] [ children ] ]

let parse_request_reads_router_headers () =
  let parse headers = RouterServer.Adapter.parseRequest ~target:"/app/item?q=1" ~headers in
  let rsc =
    parse
      [
        ("accept", "application/react.component");
        ("ROUTER-NAVIGATION-FROM", "/app");
        ("router-registry", "2.abc");
        ("Router-Base-Revision", "r1");
        ("router-prefetch", "viewport");
      ]
  in
  Alcotest.(check string) "pathname" "/app/item" rsc.engine.pathname;
  Alcotest.(check string) "search" "?q=1" rsc.engine.search;
  Alcotest.(check bool) "rsc" true (rsc.engine.kind = Rsc);
  Alcotest.(check bool)
    "navigation" true
    (rsc.engine.navigation = Some { from = Some "/app"; registry = Some "2.abc"; base_revision = Some "r1" });
  Alcotest.(check bool) "prefetch" true (rsc.prefetch = Some RouterRuntime.PrefetchLevel.Viewport);
  let unknown_level = parse [ ("Accept", "application/react.component"); ("Router-Prefetch", "Viewport") ] in
  Alcotest.(check bool) "unknown level" true (unknown_level.prefetch = None);
  Alcotest.(check bool)
    "missing facts" true
    (unknown_level.engine.navigation = Some { from = None; registry = None; base_revision = None });
  List.iter
    (fun (name, headers) ->
      let document = parse headers in
      Alcotest.(check bool) (name ^ " kind") true (document.engine.kind = Document);
      Alcotest.(check bool) (name ^ " navigation") true (document.engine.navigation = None);
      Alcotest.(check bool) (name ^ " prefetch") true (document.prefetch = None))
    [
      ("html", [ ("Accept", "text/html"); ("Router-Prefetch", "intent"); ("Router-Navigation-From", "/app") ]);
      ("no accept", []);
    ]

let parse_request_empty_query_and_fragment () =
  let location target =
    let { RouterServer.Adapter.engine; _ } = RouterServer.Adapter.parseRequest ~target ~headers:[] in
    (engine.pathname, engine.search)
  in
  let check target expected = Alcotest.(check (pair string string)) target expected (location target) in
  check "/app/item?" ("/app/item", "");
  check "/app/item#top" ("/app/item", "");
  check "/app/item?#top" ("/app/item", "");
  check "/app/item?q=1#top" ("/app/item", "?q=1");
  check "/app/item?q=1&" ("/app/item", "?q=1&")

let handle ?(allow = None) ?(headers = []) method_ target =
  Lwt_main.run
    (RouterServer.Adapter.handle (adapter_server ())
       ~diagnosticId:(fun _ -> "diagnostic")
       ~document:html_document ?allow ~method_ ~target ~headers ())

let adapter_handle () =
  let document = handle "GET" "/app/item" in
  Alcotest.(check int) "document status" 200 document.status;
  check_header document "Vary" (Some "Accept");
  Alcotest.(check bool) "document body" true (match document.body with Html _ -> true | Empty | Model _ -> false);
  let head = handle "HEAD" "/app/item" in
  Alcotest.(check int) "head status" 200 head.status;
  Alcotest.(check bool) "head headers" true (head.headers = document.headers);
  Alcotest.(check bool) "head body" true (head.body = RouterServer.Adapter.Empty);
  let rsc =
    handle
      ~headers:
        [
          ("accept", "application/react.component");
          ("router-navigation-from", "/app");
          ("router-registry", "1." ^ RouterServer.Server.fingerprint (adapter_server ()));
          ("router-base-revision", "");
        ]
      "GET" "/app/item"
  in
  Alcotest.(check int) "rsc status" 200 rsc.status;
  check_header rsc "Router-Response" (Some "full");
  Alcotest.(check bool) "rsc body" true (match rsc.body with Model _ -> true | Empty | Html _ -> false);
  let refused =
    handle ~headers:[ ("Accept", "application/react.component"); ("Router-Prefetch", "idle") ] "GET" "/app/item"
  in
  Alcotest.(check int) "refused prefetch" 204 refused.status;
  check_header refused "Router-Prefetch-Refused" (Some "intent");
  let options = handle "OPTIONS" "/app/item" in
  Alcotest.(check int) "options" 204 options.status;
  check_header options "Allow" (Some "GET, HEAD, OPTIONS");
  Alcotest.(check int) "post by default" 405 (handle "POST" "/app/item").status;
  let with_post = handle ~allow:(Some [ "GET"; "HEAD"; "OPTIONS"; "POST" ]) "DELETE" "/app/item" in
  Alcotest.(check int) "delete" 405 with_post.status;
  check_header with_post "Allow" (Some "GET, HEAD, OPTIONS, POST")

let adapter_handle_builds_context_only_to_run () =
  let built = ref 0 in
  let handle method_ =
    Lwt_main.run
      (RouterServer.Adapter.handleWithContext (adapter_server ())
         ~diagnosticId:(fun _ -> "diagnostic")
         ~document:html_document
         ~context:(fun () -> incr built)
         ~method_ ~target:"/app/item" ~headers:[] ())
  in
  Alcotest.(check int) "options" 204 (handle "OPTIONS").status;
  Alcotest.(check int) "no context for options" 0 !built;
  Alcotest.(check int) "get" 200 (handle "GET").status;
  Alcotest.(check int) "one context for get" 1 !built

let request_memo_reaches_streamed_components () =
  let key : string RouterServer.Request.key = RouterServer.Request.key () in
  let runs = ref 0 in
  let viewer () =
    RouterServer.Request.memo key "viewer" (fun () ->
        incr runs;
        Lwt.return ("viewer-" ^ string_of_int !runs))
  in
  let page =
    React.Async_component
      ("Viewer", fun () -> Lwt.map (fun viewer -> React.createElement "main" [] [ React.string viewer ]) (viewer ()))
  in
  let endpoint =
    RouterServer.Endpoint.make ~id:"item" ~path:"/item"
      ~activeRoutes:[ ("item", []) ]
      ~fingerprint:"item"
      ~decode:(fun _ ->
        Ok
          (RouterServer.Endpoint.prepared ~branch:[] ~execution:(fun () ->
               RouterServer.Execution.load
                 (fun () -> Lwt.map (fun viewer -> RouterRuntime.Loader.Data viewer) (viewer ()))
                 (fun (_ : string) ->
                   let metadata () = Lwt.map (fun title -> RouterRuntime.Metadata.make ~title ()) (viewer ()) in
                   RouterServer.Execution.done_
                     (RouterServer.Plan.success ~scopes:[ RouterServer.Plan.Scope.make ~metadata () ] ~page)))))
  in
  let server =
    RouterServer.Server.make ~basePath:"/app"
      ~registry:(RouterServer.EndpointRegistry.makeExn [ endpoint ])
      ~fallback:(fun ~search:_ ~error -> RouterServer.Plan.failure ~scopes:[] ~error ())
      ~applicationStatus:(fun _ -> RouterRuntime.Status.InternalServerError)
      ()
  in
  let request () =
    Lwt.bind
      (RouterServer.Adapter.serve server
         ~diagnosticId:(fun _ -> "diagnostic")
         ~document:html_document ~method_:"GET" ~target:"/app/item" ~headers:[] ())
      (fun (response : RouterServer.Adapter.response) ->
        match response.body with
        | None -> Alcotest.fail "expected a body"
        | Some body ->
            let chunks = Buffer.create 256 in
            Lwt.map
              (fun () -> Buffer.contents chunks)
              (body (fun chunk ->
                   Buffer.add_string chunks chunk;
                   Lwt.return_unit)))
  in
  let first = Lwt_main.run (request ()) in
  Alcotest.(check bool) "component reads the loader's value" true (contains ~needle:"<main>viewer-1</main>" first);
  Alcotest.(check int) "one run for loader and component" 1 !runs;
  let second = Lwt_main.run (request ()) in
  Alcotest.(check bool) "next request runs again" true (contains ~needle:"<main>viewer-2</main>" second);
  Alcotest.(check int) "one run per request" 2 !runs;
  ignore
    (Lwt_main.run
       (RouterServer.Adapter.handle server
          ~diagnosticId:(fun _ -> "diagnostic")
          ~document:html_document ~method_:"GET" ~target:"/app/item" ~headers:[] ()));
  Alcotest.(check int) "handle shares between loader and metadata" 3 !runs;
  let outer () =
    RouterServer.Request.scope (fun () ->
        let handled () =
          RouterServer.Adapter.handle server
            ~diagnosticId:(fun _ -> "diagnostic")
            ~document:html_document ~method_:"GET" ~target:"/app/item" ~headers:[] ()
        in
        Lwt.bind (handled ()) (fun _ ->
            Lwt.bind (handled ()) (fun _ -> Lwt.bind (request ()) (fun _ -> Lwt.map ignore (request ())))))
  in
  runs := 0;
  Lwt_main.run (outer ());
  Alcotest.(check int) "requests under an outer scope do not share entries" 4 !runs

let collect (response : RouterServer.Adapter.response) =
  match response.body with
  | None -> None
  | Some body ->
      let chunks = Buffer.create 256 in
      Lwt_main.run
        (body (fun chunk ->
             Buffer.add_string chunks chunk;
             Lwt.return_unit));
      Some (Buffer.contents chunks)

let count_header name (response : RouterServer.Adapter.response) =
  List.length (List.filter (fun (key, _) -> String.equal (String.lowercase_ascii key) name) response.headers)

let adapter_response () =
  let document =
    RouterServer.Adapter.response ~bootstrapModules:[ "/app.js" ] (adapter_reply ~kind:Document "/app/item")
  in
  Alcotest.(check int) "document status" 200 document.status;
  Alcotest.(check (option string))
    "document type" (Some "text/html; charset=utf-8")
    (List.assoc_opt "Content-Type" document.headers);
  Alcotest.(check int) "one content type" 1 (count_header "content-type" document);
  (match collect document with
  | Some html ->
      Alcotest.(check bool) "routed markup" true (contains ~needle:"<main>item</main>" html);
      Alcotest.(check bool) "bootstrap module" true (contains ~needle:"/app.js" html)
  | None -> Alcotest.fail "expected a document body");
  let model = RouterServer.Adapter.response (adapter_reply ~kind:Rsc "/app/item") in
  Alcotest.(check (option string)) "location" (Some "/app/item") (List.assoc_opt "X-Location" model.headers);
  Alcotest.(check (option string)) "nosniff" (Some "nosniff") (List.assoc_opt "X-Content-Type-Options" model.headers);
  Alcotest.(check int) "one model content type" 1 (count_header "content-type" model);
  Alcotest.(check (option string))
    "registry kept"
    (List.assoc_opt "Router-Registry" (adapter_reply ~kind:Rsc "/app/item").headers)
    (List.assoc_opt "Router-Registry" model.headers);
  (match collect model with
  | Some flight ->
      Alcotest.(check bool)
        "flight payload" true
        (contains ~needle:"<main>" flight || contains ~needle:"\"main\"" flight)
  | None -> Alcotest.fail "expected a model body");
  let empty = RouterServer.Adapter.response (adapter_reply ~registry:(Some "0.stale") ~kind:Rsc "/app/item") in
  Alcotest.(check int) "reload status" 409 empty.status;
  Alcotest.(check bool) "no body" true (Option.is_none empty.body)

let client_root_settings () =
  let initial : RouterRuntime.Navigation.committed =
    { location = { pathname = "/app"; search = ""; hash = ""; key = "k" }; matches = []; layouts = []; revision = "r" }
  in
  let seen server ?pageCacheCapacity () =
    let seen = ref None in
    ignore
      (RouterServer.Server.clientRootWith ?pageCacheCapacity server
         ~make:(fun
             ~initial:_
             ~protocolVersion:_
             ~registryFingerprint:_
             ~basePath:_
             ~routes:_
             ~interceptLinks
             ~viewTransitions
             ~pageCacheCapacity
             ~pageCacheMaxAge
             ~metadata:_
             ~children
           ->
           seen := Some (interceptLinks, viewTransitions, pageCacheCapacity, pageCacheMaxAge);
           children)
         ~initial ~metadata:React.null ~children:React.null);
    Option.get !seen
  in
  Alcotest.(check bool) "defaults" true (seen (adapter_server ()) () = (true, false, None, None));
  Alcotest.(check bool)
    "given" true
    (seen (adapter_server ~interceptLinks:false ~viewTransitions:true ~pageCacheMaxAge:30.0 ()) ~pageCacheCapacity:5 ()
    = (false, true, Some 5, Some 30.0));
  let html server =
    let reply =
      Lwt_main.run
        (RouterServer.Adapter.handle server
           ~diagnosticId:(fun _ -> "diagnostic")
           ~pageCacheCapacity:5 ~document:html_document ~method_:"GET" ~target:"/app/item" ~headers:[] ())
    in
    Option.get (collect (RouterServer.Adapter.response reply))
  in
  let with_max_age = html (adapter_server ~pageCacheMaxAge:30.0 ()) in
  Alcotest.(check bool) "max age prop" true (contains ~needle:{|"pageCacheMaxAge":30,|} with_max_age);
  Alcotest.(check bool) "capacity prop" true (contains ~needle:{|"pageCacheCapacity":5|} with_max_age);
  Alcotest.(check bool)
    "client default max age" true
    (contains ~needle:{|"pageCacheMaxAge":0,|} (html (adapter_server ())))

let adapter_document_reply () =
  let reply = adapter_reply ~kind:Document "/app/item" in
  Alcotest.(check int) "status" 200 reply.status;
  check_header reply "Vary" (Some "Accept");
  check_header reply "Content-Type" (Some "text/html; charset=utf-8");
  match reply.body with
  | Html element ->
      let html, _subscribe = Lwt_main.run (ReactServerDOM.render_html ~skipRoot:false element) in
      Alcotest.(check bool) "head before root" true (contains ~needle:"<head><title>Item</title>" html);
      Alcotest.(check bool) "routed markup" true (contains ~needle:"<main>item</main>" html);
      Alcotest.(check int) "one title" 1 (count_occurrences ~needle:"<title>" html);
      Alcotest.(check int) "one meta" 1 (count_occurrences ~needle:"<meta name=\"description\"" html)
  | Empty | Model _ -> Alcotest.fail "expected html"

let adapter_document_malformed_search_reply () =
  List.iter
    (fun search ->
      let reply = adapter_reply ~search ~kind:Document "/app/item" in
      Alcotest.(check int) search 200 reply.status)
    [ "?q=%zz"; "?q=%FF"; "?a=1&q=%&b=2" ]

let adapter_document_invalid_search_reply () =
  List.iter
    (fun search ->
      let reply = adapter_reply ~search ~kind:Document "/app/item" in
      Alcotest.(check int) "status" 400 reply.status;
      match reply.body with
      | Html element ->
          let html, _subscribe = Lwt_main.run (ReactServerDOM.render_html ~skipRoot:false element) in
          Alcotest.(check bool) "document" true (contains ~needle:"<body>" html)
      | Empty | Model _ -> Alcotest.fail "expected html")
    [ "?q=" ^ String.make 8190 'a' ]

let adapter_rsc_reply () =
  let reply = adapter_reply ~kind:Rsc "/app/item" in
  Alcotest.(check int) "status" 200 reply.status;
  check_header reply "Vary" (Some "Accept, Router-Prefetch");
  check_header reply "Router-Response" (Some "full");
  check_header reply "Router-Registry" (Some ("1." ^ RouterServer.Server.fingerprint (adapter_server ())));
  check_header reply "Cache-Control" (Some "private, no-store");
  match reply.body with
  | Model { location; _ } -> Alcotest.(check string) "x-location" "/app/item" location
  | Empty | Html _ -> Alcotest.fail "expected model"

let adapter_reload_required_reply () =
  let reply = adapter_reply ~registry:(Some "1.wrong") ~kind:Rsc "/app/item" in
  Alcotest.(check int) "status" 409 reply.status;
  check_header reply "Vary" (Some "Accept, Router-Prefetch");
  check_header reply "Router-Response" (Some "reload-required");
  check_header reply "Cache-Control" (Some "private, no-store");
  Alcotest.(check bool) "empty body" true (reply.body = Empty)

let adapter_document_redirect_reply () =
  let temporary = adapter_reply ~kind:Document "/app/go" in
  Alcotest.(check int) "temporary status" 303 temporary.status;
  check_header temporary "Location" (Some "/item");
  check_header temporary "Vary" (Some "Accept");
  let permanent = adapter_reply ~kind:Document "/app/item/" in
  Alcotest.(check int) "permanent status" 308 permanent.status;
  check_header permanent "Location" (Some "/app/item");
  check_header permanent "Vary" (Some "Accept")

let adapter_rsc_redirect_reply () =
  let reply = adapter_reply ~kind:Rsc "/app/go" in
  Alcotest.(check int) "status" 200 reply.status;
  check_header reply "Vary" (Some "Accept, Router-Prefetch");
  check_header reply "Router-Response" (Some "redirect");
  check_header reply "Router-Registry" (Some ("1." ^ RouterServer.Server.fingerprint (adapter_server ())));
  check_header reply "Cache-Control" (Some "private, no-store");
  check_header reply "Content-Type" (Some "application/react.component");
  match reply.body with
  | Model { location; _ } -> Alcotest.(check string) "x-location" "/app/go" location
  | Empty | Html _ -> Alcotest.fail "expected model"

let full_plan_composition () =
  let open RouterRuntime in
  let headers values = match Headers.make values with Ok headers -> headers | Error _ -> Alcotest.fail "headers" in
  let root =
    RouterServer.Plan.Scope.make
      ~layout:(fun child -> "root(" ^ child ^ ")")
      ~metadata:(fun () -> Lwt.return (Metadata.make ~title:"Root" ()))
      ~headers:(fun () -> Lwt.return (headers [ ("Vary", "Accept"); ("Set-Cookie", "root=1") ]))
      ()
  in
  let child =
    RouterServer.Plan.Scope.make
      ~layout:(fun child -> "child(" ^ child ^ ")")
      ~metadata:(fun () -> Lwt.return (Metadata.make ~description:"Child" ()))
      ~headers:(fun () -> Lwt.return (headers [ ("Cache-Control", "private"); ("Set-Cookie", "child=1") ]))
      ()
  in
  let plan = RouterServer.Plan.success ~scopes:[ root; child ] ~page:"page" in
  let resolved = Lwt_main.run (RouterServer.Plan.resolve plan ~applicationStatus:(fun _ -> Status.Forbidden)) in
  Alcotest.(check (option string)) "element" (Some "root(child(page))") resolved.element;
  Alcotest.(check (option string)) "title" (Some "Root") resolved.metadata.title;
  Alcotest.(check (option string)) "description" (Some "Child") resolved.metadata.description;
  Alcotest.(check (list (pair string string)))
    "headers"
    [ ("Set-Cookie", "root=1"); ("Cache-Control", "private"); ("Set-Cookie", "child=1"); ("Vary", "Accept") ]
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
  let scope = RouterServer.Branch.Scope.make ~search:[] in
  let root = scope ~id:"root" ~parameters:[] ~reusable:true in
  let note = scope ~id:"group:note" ~parameters:[ ("id", "1") ] ~reusable:true in
  let same = scope ~id:"group:note" ~parameters:[ ("id", "1") ] ~reusable:true in
  let other = scope ~id:"group:note" ~parameters:[ ("id", "2") ] ~reusable:true in
  let outletless = scope ~id:"group:note" ~parameters:[ ("id", "1") ] ~reusable:false in
  Alcotest.(check int) "same" 2 (RouterServer.Branch.sharedPrefix [ root; note ] [ root; same ]);
  Alcotest.(check int) "different params" 1 (RouterServer.Branch.sharedPrefix [ root; note ] [ root; other ]);
  Alcotest.(check int)
    "scope without an outlet" 1
    (RouterServer.Branch.sharedPrefix [ root; note ] [ root; outletless ])

let shared_layout_prefix_compares_search_in_reach () =
  let scope search = RouterServer.Branch.Scope.make ~search ~reusable:true in
  let root text = scope [ ("text", text) ] ~id:"root" ~parameters:[] in
  let note text = scope [ ("text", text) ] ~id:"group:note" ~parameters:[ ("id", "1") ] in
  Alcotest.(check int)
    "same search" 2
    (RouterServer.Branch.sharedPrefix [ root [ "a" ]; note [ "a" ] ] [ root [ "a" ]; note [ "a" ] ]);
  Alcotest.(check int)
    "changed search in reach" 0
    (RouterServer.Branch.sharedPrefix [ root [ "a" ]; note [ "a" ] ] [ root [ "b" ]; note [ "b" ] ]);
  Alcotest.(check int)
    "values are framed" 0
    (RouterServer.Branch.sharedPrefix [ root [ "ab"; "c" ] ] [ root [ "a"; "bc" ] ]);
  Alcotest.(check string)
    "search does not enter the instance key"
    (RouterServer.Branch.Scope.instanceKey (root [ "a" ]))
    (RouterServer.Branch.Scope.instanceKey (root [ "b" ]))

let plan_scope_count_bounds_the_graft () =
  let scope = RouterServer.Plan.Scope.make ~layout:(fun child -> child) () in
  Alcotest.(check int)
    "success" 2
    (RouterServer.Plan.scopeCount (RouterServer.Plan.success ~scopes:[ scope; scope ] ~page:"page"));
  Alcotest.(check int)
    "failure drops the failing scope" 1
    (RouterServer.Plan.scopeCount
       (RouterServer.Plan.failure ~scopes:[ scope ]
          ~error:(RouterRuntime.Error.NotFound { reason = RouterRuntime.Error.LoaderNotFound })
          ()))

let suffix_plan_omits_shared_layouts () =
  let open RouterRuntime in
  let root = RouterServer.Plan.Scope.make ~layout:(fun child -> "root(" ^ child ^ ")") () in
  let child = RouterServer.Plan.Scope.make ~layout:(fun child -> "child(" ^ child ^ ")") () in
  let plan = RouterServer.Plan.success ~scopes:[ root; child ] ~page:"page" in
  let resolved =
    Lwt_main.run
      (RouterServer.Plan.resolve plan
         ~render:(RouterServer.Plan.Suffix { omitted_scopes = 1 })
         ~applicationStatus:(fun _ -> Status.InternalServerError))
  in
  Alcotest.(check (option string)) "suffix" (Some "child(page)") resolved.element

let scope_values_resolve_concurrently () =
  let open RouterRuntime in
  let headers values = match Headers.make values with Ok headers -> headers | Error _ -> assert false in
  let started = ref [] in
  let scope name ~title ?description () =
    let ready, wake = Lwt.wait () in
    let start value =
      started := name :: !started;
      Lwt.map (fun () -> value) ready
    in
    ( RouterServer.Plan.Scope.make
        ~metadata:(fun () -> start (Metadata.make ~title ?description ()))
        ~headers:(fun () -> start (headers [ ("Set-Cookie", name ^ "=1") ]))
        (),
      wake )
  in
  let root, wake_root = scope "root" ~title:"Root" ~description:"Root" () in
  let child, wake_child = scope "child" ~title:"Child" () in
  let plan = RouterServer.Plan.success ~scopes:[ root; child ] ~page:"page" in
  let resolved = RouterServer.Plan.resolve plan ~applicationStatus:(fun _ -> Status.InternalServerError) in
  Alcotest.(check (list string))
    "all scopes start before any resolves" [ "child"; "child"; "root"; "root" ] (List.sort compare !started);
  Lwt.wakeup wake_child ();
  Lwt.wakeup wake_root ();
  match Lwt.state resolved with
  | Lwt.Return resolved ->
      Alcotest.(check (option string)) "child title wins" (Some "Child") resolved.metadata.title;
      Alcotest.(check (option string)) "root description kept" (Some "Root") resolved.metadata.description;
      Alcotest.(check (list (pair string string)))
        "headers in tree order"
        [ ("Set-Cookie", "root=1"); ("Set-Cookie", "child=1") ]
        (Headers.toList resolved.headers)
  | _ -> Alcotest.fail "expected resolved plan"

let adapter_method_replies () =
  let allow = [ "GET"; "HEAD"; "OPTIONS"; "POST" ] in
  let reply method_ = RouterServer.Adapter.methodReply ~allow method_ in
  List.iter
    (fun method_ -> Alcotest.(check bool) (method_ ^ " runs the router") true (Option.is_none (reply method_)))
    [ "GET"; "HEAD"; "POST" ];
  let check method_ status =
    match reply method_ with
    | Some reply ->
        Alcotest.(check int) (method_ ^ " status") status reply.status;
        check_header reply "Allow" (Some "GET, HEAD, OPTIONS, POST");
        Alcotest.(check bool) (method_ ^ " empty body") true (reply.body = RouterServer.Adapter.Empty)
    | None -> Alcotest.failf "expected a reply for %s" method_
  in
  check "OPTIONS" 204;
  check "PUT" 405;
  check "DELETE" 405;
  check "get" 405

let prefetch_registry ran =
  let endpoint ~id ?prefetch () : ((string, string) RouterServer.Plan.t, string, unit) RouterServer.Endpoint.t =
    let endpoint =
      RouterServer.Endpoint.make ~id ~path:("/" ^ id) ~activeRoutes:[] ~fingerprint:id ~decode:(fun _ ->
          Ok
            (RouterServer.Endpoint.prepared ~branch:[] ~execution:(fun () ->
                 RouterServer.Execution.load
                   (fun () ->
                     incr ran;
                     Lwt.return (RouterRuntime.Loader.Data ()))
                   (fun () -> RouterServer.Execution.done_ (RouterServer.Plan.success ~scopes:[] ~page:id)))))
    in
    match prefetch with Some level -> RouterServer.Endpoint.withPrefetch endpoint level | None -> endpoint
  in
  RouterServer.EndpointRegistry.makeExn
    [ endpoint ~id:"viewport" ~prefetch:RouterRuntime.PrefetchLevel.Viewport (); endpoint ~id:"default" () ]

let prefetch_request pathname : RouterServer.ServerEngine.request =
  { pathname; search = ""; hash = ""; kind = Rsc; navigation = None }

let run_prefetch ~ran ?prefetch pathname =
  Lwt_main.run
    (RouterServer.ServerEngine.run ~registry:(prefetch_registry ran) ~basePath:"/"
       ~trailingSlash:RouterServer.TrailingSlash.Redirect
       ~fallback:(fun ~search:_ ~error -> RouterServer.Plan.failure ~scopes:[] ~error ())
       ~applicationStatus:(fun _ -> RouterRuntime.Status.InternalServerError)
       ~diagnosticId:(fun _ -> "diagnostic")
       ~protocolVersion:1 ?prefetch (prefetch_request pathname))

let vary outcome =
  match outcome with
  | RouterServer.ServerEngine.Full full -> List.assoc_opt "Vary" (RouterRuntime.Headers.toList full.resolved.headers)
  | _ -> Alcotest.fail "expected full response"

let refused_prefetch_runs_no_loader () =
  let open RouterRuntime.PrefetchLevel in
  let ran = ref 0 in
  let refused ~prefetch pathname expected =
    match run_prefetch ~ran ~prefetch pathname with
    | RouterServer.ServerEngine.PrefetchRefused level ->
        Alcotest.(check string) pathname (toString expected) (toString level)
    | _ -> Alcotest.failf "expected %s to refuse a %s prefetch" pathname (toString prefetch)
  in
  refused ~prefetch:Idle "/viewport" Viewport;
  refused ~prefetch:Viewport "/default" Intent;
  refused ~prefetch:Idle "/default" Intent;
  Alcotest.(check bool)
    "unmatched path runs as a navigation" true
    (match run_prefetch ~ran ~prefetch:Idle "/missing" with
    | RouterServer.ServerEngine.Full full -> RouterRuntime.Status.toInt full.resolved.status = 404
    | _ -> false);
  Alcotest.(check int) "no loader ran" 0 !ran

let accepted_prefetch_answers_like_navigation () =
  let open RouterRuntime.PrefetchLevel in
  let ran = ref 0 in
  Alcotest.(check (option string)) "navigation" (Some "Accept, Router-Prefetch") (vary (run_prefetch ~ran "/viewport"));
  List.iter
    (fun (prefetch, pathname) ->
      Alcotest.(check (option string))
        (toString prefetch ^ " " ^ pathname)
        (Some "Accept, Router-Prefetch")
        (vary (run_prefetch ~ran ~prefetch pathname)))
    [ (Viewport, "/viewport"); (Intent, "/viewport"); (Off, "/viewport"); (Intent, "/default") ];
  Alcotest.(check int) "loaders ran" 5 !ran

let prefetch_level_names () =
  let open RouterRuntime.PrefetchLevel in
  List.iter
    (fun level -> Alcotest.(check bool) (toString level) true (fromString (toString level) = Some level))
    [ Off; Intent; Viewport; Idle ];
  Alcotest.(check bool) "unknown" true (fromString "Intent" = None);
  Alcotest.(check bool) "order" true (compare Off Intent < 0 && compare Intent Viewport < 0 && compare Viewport Idle < 0);
  Alcotest.(check string)
    "untyped destination" "intent"
    (toString (RouterRuntime.prefetchLevel (RouterRuntime.destination ~path:"/x")));
  let destination = RouterRuntime.withPrefetch (RouterRuntime.destination ~path:"/x") Off in
  Alcotest.(check string)
    "withHash keeps the level" "off"
    (toString (RouterRuntime.prefetchLevel (RouterRuntime.withHash destination ~hash:"top")))

let adapter_refused_prefetch_reply () =
  let server = adapter_server () in
  let reply prefetch =
    let outcome =
      Lwt_main.run
        (RouterServer.run server
           ~diagnosticId:(fun _ -> "diagnostic")
           ~prefetch
           { pathname = "/app/item"; search = ""; hash = ""; kind = Rsc; navigation = None })
    in
    RouterServer.Adapter.reply server ~target:"/app/item" ~pageCacheCapacity:0
      ~document:(fun ~head:_ children -> children)
      ~kind:Rsc outcome
  in
  let allowed = reply RouterRuntime.PrefetchLevel.Intent in
  Alcotest.(check int) "intent status" 200 allowed.status;
  check_header allowed "Vary" (Some "Accept, Router-Prefetch");
  let refused = reply RouterRuntime.PrefetchLevel.Viewport in
  Alcotest.(check int) "status" 204 refused.status;
  check_header refused "Router-Prefetch-Refused" (Some "intent");
  check_header refused "Vary" (Some "Accept, Router-Prefetch");
  check_header refused "Cache-Control" (Some "private, no-store");
  Alcotest.(check bool) "empty body" true (refused.body = RouterServer.Adapter.Empty)

let client_routes_exclude_base_path () =
  let endpoint path : ((React.element, string) RouterServer.Plan.t, string, unit) RouterServer.Endpoint.t =
    RouterServer.Endpoint.make ~id:path ~path ~activeRoutes:[] ~fingerprint:path ~decode:(fun _ ->
        Ok
          (RouterServer.Endpoint.prepared ~branch:[] ~execution:(fun () ->
               RouterServer.Execution.done_ (RouterServer.Plan.success ~scopes:[] ~page:React.null))))
  in
  let registry =
    RouterServer.EndpointRegistry.makeExn
      [ endpoint "/"; endpoint "/notes/:id<int>"; endpoint "/assets/:parts<string...>"; endpoint "/docs" ]
  in
  let server basePath =
    RouterServer.Server.make ~basePath ~registry
      ~fallback:(fun ~search:_ ~error -> RouterServer.Plan.failure ~scopes:[] ~error ())
      ~applicationStatus:(fun _ -> RouterRuntime.Status.InternalServerError)
      ()
  in
  let expected = [| "/"; "/notes/:id<int>"; "/assets/:parts<string...>"; "/docs" |] in
  List.iter
    (fun basePath -> Alcotest.(check (array string)) basePath expected (RouterServer.Server.routes (server basePath)))
    [ "/"; "/app"; "/m%C3%BCnchen" ];
  let passed = ref [||] in
  ignore
    (RouterServer.Server.clientRootWith (server "/app")
       ~make:(fun
           ~initial:_
           ~protocolVersion:_
           ~registryFingerprint:_
           ~basePath:_
           ~routes
           ~interceptLinks:_
           ~viewTransitions:_
           ~pageCacheCapacity:_
           ~pageCacheMaxAge:_
           ~metadata:_
           ~children
         ->
         passed := routes;
         children)
       ~initial:
         RouterRuntime.Navigation.
           {
             location = { pathname = "/app"; search = ""; hash = ""; key = "k" };
             matches = [];
             layouts = [];
             revision = "r";
           }
       ~metadata:React.null ~children:React.null);
  Alcotest.(check (array string)) "clientRootWith" expected !passed

let action_error_renders_after_loaders () =
  let run ?(redirect = false) ?(withFailure = true) () =
    let page = RouterServer.Plan.success ~scopes:[] ~page:"page" in
    let page =
      if withFailure then
        RouterServer.Plan.withFailure page (fun error ->
            RouterServer.Plan.failure ~scopes:[] ~error ~errorBoundary:(fun _ -> "boundary") ())
      else page
    in
    let endpoint : ((string, string) RouterServer.Plan.t, string, unit) RouterServer.Endpoint.t =
      RouterServer.Endpoint.make ~id:"page" ~path:"/page" ~activeRoutes:[] ~fingerprint:"page" ~decode:(fun _ ->
          Ok
            (RouterServer.Endpoint.prepared ~branch:[] ~execution:(fun () ->
                 RouterServer.Execution.load
                   (fun () ->
                     Lwt.return
                       (if redirect then RouterRuntime.Loader.Redirect (RouterRuntime.destination ~path:"/login")
                        else RouterRuntime.Loader.Data ()))
                   (fun () -> RouterServer.Execution.done_ page))))
    in
    Lwt_main.run
      (RouterServer.ServerEngine.run
         ~registry:(RouterServer.EndpointRegistry.makeExn [ endpoint ])
         ~basePath:"/" ~trailingSlash:RouterServer.TrailingSlash.Redirect
         ~fallback:(fun ~search:_ ~error -> RouterServer.Plan.failure ~scopes:[] ~error ())
         ~applicationStatus:(fun _ -> RouterRuntime.Status.Forbidden)
         ~diagnosticId:(fun _ -> "diagnostic")
         ~protocolVersion:1
         ~actionError:(RouterRuntime.Error.Internal { diagnosticId = "d" })
         { pathname = "/page"; search = ""; hash = ""; kind = Document; navigation = None })
  in
  (match run () with
  | RouterServer.ServerEngine.Full full ->
      Alcotest.(check int) "status" 500 (RouterRuntime.Status.toInt full.resolved.status);
      Alcotest.(check (option string)) "boundary" (Some "boundary") full.resolved.element
  | _ -> Alcotest.fail "expected full response");
  (match run ~withFailure:false () with
  | RouterServer.ServerEngine.Full full ->
      Alcotest.(check int) "plain status" 500 (RouterRuntime.Status.toInt full.resolved.status);
      Alcotest.(check (option string)) "no boundary" None full.resolved.element
  | _ -> Alcotest.fail "expected full response");
  match run ~redirect:true () with
  | RouterServer.ServerEngine.Redirect _ -> ()
  | _ -> Alcotest.fail "expected the loader redirect to win"

let unsafe_redirects_are_internal_errors () =
  let run target =
    let endpoint : ((string, string) RouterServer.Plan.t, string, unit) RouterServer.Endpoint.t =
      RouterServer.Endpoint.make ~id:"go" ~path:"/go" ~activeRoutes:[] ~fingerprint:"go" ~decode:(fun _ ->
          Ok
            (RouterServer.Endpoint.prepared ~branch:[] ~execution:(fun () ->
                 RouterServer.Execution.redirect (RouterRuntime.destination ~path:target))))
    in
    Lwt_main.run
      (RouterServer.ServerEngine.run
         ~registry:(RouterServer.EndpointRegistry.makeExn [ endpoint ])
         ~basePath:"/" ~trailingSlash:RouterServer.TrailingSlash.Redirect
         ~fallback:(fun ~search:_ ~error -> RouterServer.Plan.failure ~scopes:[] ~error ())
         ~applicationStatus:(fun _ -> RouterRuntime.Status.InternalServerError)
         ~diagnosticId:(fun _ -> "diagnostic")
         ~protocolVersion:1
         { pathname = "/go"; search = ""; hash = ""; kind = Document; navigation = None })
  in
  List.iter
    (fun target ->
      match run target with
      | RouterServer.ServerEngine.Full full ->
          Alcotest.(check int) target 500 (RouterRuntime.Status.toInt full.resolved.status)
      | _ -> Alcotest.failf "expected %S to be refused" target)
    [
      "javascript:alert(1)";
      "JavaScript:alert(1)";
      "data:text/html,x";
      "//evil.example/";
      "/\\evil.example/";
      "notes";
      "";
      "/a\nSet-Cookie: x=1";
      "ftp://example.com/";
    ];
  List.iter
    (fun target ->
      match run target with
      | RouterServer.ServerEngine.Redirect destination ->
          Alcotest.(check string) target target (RouterRuntime.href destination)
      | _ -> Alcotest.failf "expected %S to redirect" target)
    [ "/"; "/notes?a=1#top"; "https://example.com/x"; "http://example.com"; "HTTPS://example.com/" ];
  Alcotest.(check (option string))
    "location of a safe destination" (Some "/notes")
    (RouterServer.Adapter.redirectLocation (RouterRuntime.destination ~path:"/notes"));
  Alcotest.(check (option string))
    "location of an unsafe destination" None
    (RouterServer.Adapter.redirectLocation (RouterRuntime.destination ~path:"javascript:alert(1)"))

let signal_server () =
  let text value = React.createElement "p" [] [ React.string value ] in
  let page name body = React.Upper_case_component (name, body) in
  let plan page =
    RouterServer.Plan.withFailure (RouterServer.Plan.success ~scopes:[] ~page) (fun error ->
        RouterServer.Plan.failure ~scopes:[] ~error
          ~notFound:(fun _ -> text "missing note")
          ~errorBoundary:(fun _ -> text "broken")
          ())
  in
  let pages =
    [
      ("/missing", page "Missing" (fun () -> RouterServer.Render.notFound ()));
      ("/broken", page "Broken" (fun () -> failwith "page failed"));
      ( "/failing-fallback",
        RouterReact.errorBoundary
          ~fallback:(page "FailingFallback" (fun () -> failwith "fallback failed"))
          ~children:(text "content") () );
      ("/moved", page "Moved" (fun () -> RouterServer.Render.redirect (RouterRuntime.destination ~path:"/app/plain")));
      ( "/suspended-missing",
        React.Suspense
          {
            key = None;
            fallback = Some (text "loading");
            children = page "SyncInside" (fun () -> RouterServer.Render.notFound ());
          } );
      ( "/late-missing",
        React.Suspense
          {
            key = None;
            fallback = Some (text "loading");
            children =
              React.Async_component
                ( "Late",
                  fun () ->
                    Lwt.bind (Lwt.pause ()) (fun () ->
                        Lwt.bind (Lwt.pause ()) (fun () -> Lwt.return (RouterServer.Render.notFound ()))) );
          } );
      ( "/plain",
        React.list
          [
            text "plain";
            React.Suspense
              {
                key = None;
                fallback = Some (text "loading");
                children =
                  React.Async_component
                    ("Later", fun () -> Lwt.bind (Lwt.pause ()) (fun () -> Lwt.return (text "later")));
              };
          ] );
    ]
  in
  let registry =
    RouterServer.EndpointRegistry.makeExn
      (List.map
         (fun (path, element) ->
           RouterServer.Endpoint.make ~id:path ~path ~activeRoutes:[] ~fingerprint:path ~decode:(fun _ ->
               Ok
                 (RouterServer.Endpoint.prepared ~branch:[] ~execution:(fun () ->
                      RouterServer.Execution.done_ (plan element)))))
         pages)
  in
  RouterServer.Server.make ~basePath:"/app" ~registry
    ~fallback:(fun ~search:_ ~error -> RouterServer.Plan.failure ~scopes:[] ~error ())
    ~applicationStatus:(fun _ -> RouterRuntime.Status.InternalServerError)
    ()

let serve ?(rsc = false) target =
  let headers = if rsc then [ ("Accept", "application/react.component"); ("Router-Navigation-From", "/app") ] else [] in
  let response =
    Lwt_main.run
      (RouterServer.Adapter.serve (signal_server ())
         ~diagnosticId:(fun _ -> "d")
         ~document:(fun ~head children ->
           React.createElement "html" []
             [ React.createElement "head" [] [ head ]; React.createElement "body" [] [ children ] ])
         ~method_:"GET" ~target ~headers ())
  in
  let chunks = ref [] in
  (match response.body with
  | None -> ()
  | Some body ->
      Lwt_main.run
        (body (fun chunk ->
             chunks := chunk :: !chunks;
             Lwt.return ())));
  (response, String.concat "" (List.rev !chunks))

let render_signals_change_the_response () =
  let header (response : RouterServer.Adapter.response) name = List.assoc_opt name response.headers in
  let response, body = serve "/app/missing" in
  Alcotest.(check int) "document not found status" 404 response.status;
  Alcotest.(check bool) "not-found boundary" true (contains ~needle:"missing note" body);
  let response, body = serve ~rsc:true "/app/missing" in
  Alcotest.(check int) "navigation not found status" 404 response.status;
  Alcotest.(check bool) "navigation not-found boundary" true (contains ~needle:"missing note" body);
  let response, _ = serve "/app/moved" in
  Alcotest.(check int) "document redirect" 303 response.status;
  Alcotest.(check (option string)) "location" (Some "/app/plain") (header response "Location");
  let response, body = serve ~rsc:true "/app/moved" in
  Alcotest.(check int) "navigation redirect envelope" 200 response.status;
  Alcotest.(check (option string)) "redirect kind" (Some "redirect") (header response "Router-Response");
  Alcotest.(check bool) "redirect location" true (contains ~needle:"/app/plain" body);
  let response, body = serve "/app/broken" in
  Alcotest.(check int) "document render exception" 500 response.status;
  Alcotest.(check bool) "error boundary" true (contains ~needle:"broken" body);
  let response, body = serve "/app/suspended-missing" in
  Alcotest.(check int) "synchronous signal inside suspense" 404 response.status;
  Alcotest.(check bool) "suspense not-found boundary" true (contains ~needle:"missing note" body)

let failing_fallback_does_not_fail_the_page () =
  let response, body = serve "/app/failing-fallback" in
  Alcotest.(check int) "document status" 200 response.status;
  Alcotest.(check bool) "document content" true (contains ~needle:"<p>content</p>" body);
  let response, body = serve ~rsc:true "/app/failing-fallback" in
  Alcotest.(check int) "navigation status" 200 response.status;
  Alcotest.(check bool) "navigation content" true (contains ~needle:"content" body)

let render_signals_after_the_shell_keep_the_status () =
  let response, body = serve "/app/late-missing" in
  Alcotest.(check int) "late document signal" 200 response.status;
  Alcotest.(check bool) "fallback streamed" true (contains ~needle:"loading" body);
  let response, _ = serve ~rsc:true "/app/late-missing" in
  Alcotest.(check int) "late navigation signal" 200 response.status;
  let response, body = serve "/app/plain" in
  Alcotest.(check int) "plain document" 200 response.status;
  Alcotest.(check bool) "streamed document content" true (contains ~needle:"later" body);
  let response, body = serve ~rsc:true "/app/plain" in
  Alcotest.(check int) "plain navigation" 200 response.status;
  Alcotest.(check bool) "first navigation chunk" true (contains ~needle:"plain" body);
  Alcotest.(check bool) "streamed navigation content" true (contains ~needle:"later" body)

let render_signal_in_a_search_patch_answers_the_boundary () =
  let text value = React.createElement "p" [] [ React.string value ] in
  let endpoint =
    RouterServer.Endpoint.make ~id:"list" ~path:"/list" ~activeRoutes:[] ~fingerprint:"list" ~decode:(fun input ->
        let search = RouterServer.Decode.searchValues ~input [ "q" ] in
        let page =
          match search with
          | [ ("q", [ "missing" ]) ] -> React.Upper_case_component ("Missing", fun () -> RouterServer.Render.notFound ())
          | _ -> text "listed"
        in
        let plan =
          RouterServer.Plan.withFailure
            (RouterServer.Plan.success
               ~scopes:
                 [ RouterServer.Plan.Scope.make ~layout:(fun child -> React.list [ text "kept shell"; child ]) () ]
               ~page)
            (fun error ->
              RouterServer.Plan.failure ~scopes:[] ~error
                ~notFound:(fun _ -> text "missing note")
                ~errorBoundary:(fun _ -> text "broken")
                ())
        in
        Ok
          (RouterServer.Endpoint.prepared
             ~branch:
               [
                 RouterServer.Branch.Scope.make ~id:"root" ~parameters:[] ~search:[] ~reusable:true;
                 RouterServer.Branch.Scope.make ~id:"route:list" ~parameters:[] ~search ~reusable:false;
               ]
             ~execution:(fun () -> RouterServer.Execution.done_ plan)))
  in
  let server =
    RouterServer.Server.make ~basePath:"/app"
      ~registry:(RouterServer.EndpointRegistry.makeExn [ endpoint ])
      ~fallback:(fun ~search:_ ~error -> RouterServer.Plan.failure ~scopes:[] ~error ())
      ~applicationStatus:(fun _ -> RouterRuntime.Status.InternalServerError)
      ()
  in
  let navigate target =
    let response =
      Lwt_main.run
        (RouterServer.Adapter.serve server
           ~diagnosticId:(fun _ -> "d")
           ~document:(fun ~head:_ children -> children)
           ~method_:"GET" ~target
           ~headers:
             [
               ("Accept", "application/react.component");
               ("Router-Navigation-From", "/app/list?q=a");
               ("Router-Base-Revision", "1");
             ]
           ())
    in
    let chunks = ref [] in
    Option.iter
      (fun body ->
        Lwt_main.run
          (body (fun chunk ->
               chunks := chunk :: !chunks;
               Lwt.return ())))
      response.body;
    (response, String.concat "" (List.rev !chunks))
  in
  let kind (response : RouterServer.Adapter.response) = List.assoc_opt "Router-Response" response.headers in
  let response, body = navigate "/app/list?q=b" in
  Alcotest.(check (option string)) "search change answers a patch" (Some "patch") (kind response);
  Alcotest.(check bool) "patch omits the kept layout" false (contains ~needle:"kept shell" body);
  let response, body = navigate "/app/list?q=missing" in
  Alcotest.(check int) "not found status" 404 response.status;
  Alcotest.(check bool) "not-found boundary" true (contains ~needle:"missing note" body);
  Alcotest.(check bool) "no page content" false (contains ~needle:"listed" body)

let () =
  Alcotest.run "router server"
    [
      ( "registry and matching",
        [
          test "static precedes dynamic" static_precedes_dynamic;
          test "total specificity precedes earlier static" total_specificity_precedes_earlier_static;
          test "failed static branch backtracks to parameter" failed_static_branch_backtracks_to_parameter;
          test "encoded static segment" encoded_static_segment;
          test "decoded parameters" decoded_parameters;
          test "catch-all precedence and capture" catch_all_precedence_and_capture;
          test "a less specific route below a more specific subtree loses"
            less_specific_route_below_a_more_specific_subtree;
          test "ambiguous catch-all patterns" ambiguous_catch_all_patterns;
          test "crossing catch-all patterns are order independent" crossing_catch_all_patterns_are_order_independent;
          test "catch-all endpoint decoding" catch_all_endpoint_decoding;
          test "catch-all toString validation" catch_all_to_string_validation;
          test "destination catch-all encoding" destination_catch_all_encoding;
          test "duplicate paths" duplicate_paths;
          test "duplicate ids" duplicate_ids;
          test "ambiguous patterns" ambiguous_patterns;
          test "overlapping patterns" overlapping_patterns;
          test "malformed escape" malformed_escape;
          test "malformed escape reports leftmost segment" malformed_escape_reports_leftmost_segment;
          test "encoded slash" encoded_slash;
          test "dot segments" dot_segments;
          test "invalid UTF-8 path" invalid_utf8_path;
          test "destination segment encoding" destination_segment_encoding;
          test "scalar destinations round trip" scalar_destinations_round_trip;
          test "invalid scalar destinations" invalid_scalar_destinations;
          test "repeated search" repeated_search;
          test "large search index" large_search_index;
          test "decoded search" decoded_search;
          test "malformed search" malformed_search;
          test "oversized search" oversized_search;
          test "search skips empty pairs" search_skips_empty_pairs;
          test "invalid UTF-8 search" invalid_utf8_search;
          test "search decoders by kind" search_decoders_by_kind;
          test "base path matches segments" base_path_matches_segments;
          test "engine matches lower-case base path escapes" engine_matches_lower_case_base_path_escapes;
          test "loader sequence" loader_sequence;
          test "loader short circuit" loader_short_circuit;
          test "rejected loader uses nearest boundary" rejected_loader_uses_nearest_boundary;
          test "fatal loader exceptions propagate" fatal_loader_exceptions_propagate;
          test "started loader exceptions use boundary" started_loader_exceptions_use_boundary;
          test "request memo runs once per request" request_memo_runs_once_per_request;
          test "request memo reaches streamed components" request_memo_reaches_streamed_components;
          test "error status" error_status;
          test "metadata composition" metadata_composition;
          test "metadata default keys" metadata_default_keys;
          test "metadata repeated tags with explicit keys" metadata_repeated_tags_with_explicit_keys;
          test "metadata rendering" metadata_rendering;
          test "header composition" header_composition;
          test "latest navigation wins" latest_navigation_wins;
          test "stale revision rejected" stale_revision_rejected;
          test "shallow location commit" shallow_location_commit;
          test "valid full navigation response" valid_full_navigation_response;
          test "navigation response RSC round trip" navigation_response_rsc_round_trip;
          test "superseded navigation response is canceled" superseded_navigation_response_is_canceled;
          test "stale navigation response is rejected" stale_navigation_response_is_rejected;
          test "stale patch base is rejected" stale_patch_base_is_rejected;
          test "redirect and reload response kinds" redirect_and_reload_response_kinds;
          test "redirect and reload navigation responses" redirect_and_reload_navigation_responses;
          test "history action selects mutation" history_action_selects_mutation;
          test "hash-only location commit" hash_only_location_commit;
          test "builtin bool codec" builtin_bool_codec;
          test "builtin int codec" builtin_int_codec;
          test "typed search decoding" typed_search_decoding;
          test "shallow search preserves unowned values" shallow_search_preserves_unowned_values;
          test "pop navigation kind" pop_navigation_kind;
          test "typed endpoint decoding" typed_endpoint_decoding;
          test "typed endpoint decode error" typed_endpoint_decode_error;
          test "loader permanent redirect reaches engine" loader_permanent_redirect_reaches_engine;
          test "execution permanent redirect" execution_permanent_redirect_skips_loaders;
          test "loader redirect stays temporary" loader_redirect_stays_temporary;
          test "trailing slash redirects to canonical" trailing_slash_redirects_to_canonical;
          test "trailing slash redirect collapses repeated slashes" trailing_slash_redirect_collapses_repeated_slashes;
          test "trailing slash redirects base path root" trailing_slash_redirects_base_path_root;
          test "trailing slash reject is not found" trailing_slash_reject_is_not_found;
          test "trailing slash redirect never leaves the origin" trailing_slash_redirect_never_leaves_the_origin;
          test "root pathname is canonical" root_pathname_is_canonical;
          test "default boundary renders text" default_boundary_renders_text;
          test "server base path validation" server_base_path_validation;
          test "revision defaults to empty" revision_defaults_to_empty;
          test "adapter document reply" adapter_document_reply;
          test "adapter document malformed search reply" adapter_document_malformed_search_reply;
          test "adapter document invalid search reply" adapter_document_invalid_search_reply;
          test "adapter rsc reply" adapter_rsc_reply;
          test "adapter reload required reply" adapter_reload_required_reply;
          test "adapter document redirect reply" adapter_document_redirect_reply;
          test "adapter rsc redirect reply" adapter_rsc_redirect_reply;
          test "parse request reads router headers" parse_request_reads_router_headers;
          test "parse request empty query and fragment" parse_request_empty_query_and_fragment;
          test "adapter handle" adapter_handle;
          test "adapter handle builds context only to run" adapter_handle_builds_context_only_to_run;
          test "adapter response" adapter_response;
          test "client root settings" client_root_settings;
          test "full plan composition" full_plan_composition;
          test "failure plan selects not-found boundary" failure_plan_selects_not_found_boundary;
          test "shared layout prefix uses canonical identity" shared_layout_prefix_uses_canonical_identity;
          test "shared layout prefix compares search in reach" shared_layout_prefix_compares_search_in_reach;
          test "plan scope count bounds the graft" plan_scope_count_bounds_the_graft;
          test "suffix plan omits shared layouts" suffix_plan_omits_shared_layouts;
          test "scope values resolve concurrently" scope_values_resolve_concurrently;
          test "adapter method replies" adapter_method_replies;
          test "refused prefetch runs no loader" refused_prefetch_runs_no_loader;
          test "accepted prefetch answers like navigation" accepted_prefetch_answers_like_navigation;
          test "prefetch level names" prefetch_level_names;
          test "adapter refused prefetch reply" adapter_refused_prefetch_reply;
          test "client routes exclude base path" client_routes_exclude_base_path;
          test "action error renders after loaders" action_error_renders_after_loaders;
          test "unsafe redirects are internal errors" unsafe_redirects_are_internal_errors;
          test "render signals change the response" render_signals_change_the_response;
          test "a failing fallback does not fail the page" failing_fallback_does_not_fail_the_page;
          test "render signals after the shell keep the status" render_signals_after_the_shell_keep_the_status;
          test "a render signal in a search patch answers the boundary"
            render_signal_in_a_search_patch_answers_the_boundary;
        ] );
    ]

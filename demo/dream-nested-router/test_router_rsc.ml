let test title fn = Alcotest.test_case title `Quick fn
let assert_bool left right = Alcotest.check Alcotest.bool "should be equal" right left
let assert_option_string left right = Alcotest.check Alcotest.(option string) "should be equal" right left
let assert_string_list left right = Alcotest.check Alcotest.(list string) "should be equal" right left

let run_request ~route ~target f =
  let handler_called = ref false in
  let handler request =
    handler_called := true;
    f request;
    Dream.empty `OK
  in
  let handler_with_router = Dream.router [ Dream.get route handler ] in
  let _response = Dream.test handler_with_router (Dream.request ~target "") in
  assert_bool !handler_called true

let get_route_dynamic_params () =
  let seen_id = ref None in
  let seen_query = ref None in
  let module Page = struct
    let makeProps ~params ~query () : < params : PathParams.t ; query : URL.SearchParams.t > Js.t =
      object
        method params = params
        method query = query
      end

    let make ?key:_ props =
      seen_id := PathParams.find "id" props#params;
      seen_query := URL.SearchParams.get props#query "q";
      React.null
  end in
  let routes =
    [ RouterRSC.route ~path:"/students" [ RouterRSC.route ~path:"/:id" ~page:(module Page : RouterRSC.PAGE) [] () ] () ]
  in
  run_request ~route:"/students/:id" ~target:"/students/123?q=cat" (fun request ->
      let result = RouterRSC.getRoute ~definition:"/students/:id" ~request routes in
      assert_bool (Option.is_some result) true);
  assert_option_string !seen_id (Some "123");
  assert_option_string !seen_query (Some "cat")

let get_sub_route_dynamic_params () =
  let seen_id = ref None in
  let seen_grade_id = ref None in
  let module Page = struct
    let makeProps ~params ~query () : < params : PathParams.t ; query : URL.SearchParams.t > Js.t =
      object
        method params = params
        method query = query
      end

    let make ?key:_ props =
      seen_id := PathParams.find "id" props#params;
      seen_grade_id := PathParams.find "grade_id" props#params;
      React.null
  end in
  let routes =
    [
      RouterRSC.route ~path:"/students"
        [
          RouterRSC.route ~path:"/:id"
            [
              RouterRSC.route ~path:"/grades"
                [ RouterRSC.route ~path:"/:grade_id" ~page:(module Page : RouterRSC.PAGE) [] () ]
                ();
            ]
            ();
        ]
        ();
    ]
  in
  run_request ~route:"/students/:id/grades/:grade_id" ~target:"/students/123/grades/456" (fun request ->
      let result =
        RouterRSC.getSubRoute ~request ~parentDefinition:"/students/:id" ~subRouteDefinition:"/grades/:grade_id" routes
      in
      assert_bool (Option.is_some result) true);
  assert_option_string !seen_id (Some "123");
  assert_option_string !seen_grade_id (Some "456")

let generated_routes_paths () =
  let routes =
    [
      RouterRSC.route ~path:"/students" [ RouterRSC.route ~path:"/:id" [] () ] ();
      RouterRSC.route ~path:"/teachers" [] ();
    ]
  in
  let actual = RouterRSC.generated_routes_paths ~routes in
  let expected = [ "/students"; "/students/:id"; "/teachers" ] in
  assert_string_list actual expected

let match_definition () =
  let definitions = [ "/"; "/new"; "/:id"; "/:id/edit" ] in
  let match_from = RouterRSC.matchDefinition ~definitions in
  assert_option_string (match_from "") (Some "/");
  assert_option_string (match_from "/new") (Some "/new");
  assert_option_string (match_from "/42") (Some "/:id");
  assert_option_string (match_from "/42/edit") (Some "/:id/edit");
  assert_option_string (match_from "/42/nope") None;
  assert_option_string (match_from "/a/b/c") None

let assert_split left right = Alcotest.check Alcotest.(option (pair string string)) "should be equal" right left

let shared_prefix_split () =
  let split = RouterRSC.sharedPrefixSplit in
  (* Descend into a child: parent layout is shared. *)
  assert_split
    (split ~fromDefinition:"/:id" ~fromPath:"/1" ~targetDefinition:"/:id/edit" ~targetPath:"/1/edit")
    (Some ("/:id", "/edit"));
  (* Same definition, different params: nothing below the root is shared. *)
  assert_split
    (split ~fromDefinition:"/:id" ~fromPath:"/1" ~targetDefinition:"/:id" ~targetPath:"/2")
    (Some ("", "/:id"));
  assert_split
    (split ~fromDefinition:"/:id/edit" ~fromPath:"/1/edit" ~targetDefinition:"/:id/edit" ~targetPath:"/2/edit")
    (Some ("", "/:id/edit"));
  (* Navigate up to an ancestor: rerender the deepest shared level. *)
  assert_split
    (split ~fromDefinition:"/:id/edit" ~fromPath:"/1/edit" ~targetDefinition:"/:id" ~targetPath:"/1")
    (Some ("", "/:id"));
  (* Same location: rerender the deepest level under its parent. *)
  assert_split
    (split ~fromDefinition:"/:id/edit" ~fromPath:"/1/edit" ~targetDefinition:"/:id/edit" ~targetPath:"/1/edit")
    (Some ("/:id", "/edit"));
  (* Sibling branches share only the root. *)
  assert_split
    (split ~fromDefinition:"/new" ~fromPath:"/new" ~targetDefinition:"/:id" ~targetPath:"/1")
    (Some ("", "/:id"));
  (* From the root, everything below it is the patch. *)
  assert_split
    (split ~fromDefinition:"/" ~fromPath:"" ~targetDefinition:"/:id/edit" ~targetPath:"/1/edit")
    (Some ("", "/:id/edit"));
  (* Target root: nothing to patch, answer full. *)
  assert_split (split ~fromDefinition:"/:id" ~fromPath:"/1" ~targetDefinition:"" ~targetPath:"") None

let registry_fingerprint () =
  let routes = [ RouterRSC.route ~path:"/students" [] () ] in
  let fingerprint = RouterRSC.registryFingerprint ~basePath:"/demo" ~routes in
  let same = RouterRSC.registryFingerprint ~basePath:"/demo" ~routes in
  let other_routes = [ RouterRSC.route ~path:"/teachers" [] () ] in
  let other = RouterRSC.registryFingerprint ~basePath:"/demo" ~routes:other_routes in
  assert_bool (String.equal fingerprint same) true;
  assert_bool (String.equal fingerprint other) false;
  assert_bool (String.length fingerprint > 2) true

let () =
  Alcotest.run "RouterRSC"
    [
      ( "RouterRSC",
        [
          test "getRoute" get_route_dynamic_params;
          test "getSubRoute" get_sub_route_dynamic_params;
          test "generated_routes_paths" generated_routes_paths;
          test "matchDefinition" match_definition;
          test "sharedPrefixSplit" shared_prefix_split;
          test "registryFingerprint" registry_fingerprint;
        ] );
    ]

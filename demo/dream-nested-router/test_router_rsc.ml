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
    let make ?key:_ ~params ~query () =
      seen_id := DynamicParams.find "id" params;
      seen_query := URL.SearchParams.get query "q";
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
    let make ?key:_ ~params ~query:_ () =
      seen_id := DynamicParams.find "id" params;
      seen_grade_id := DynamicParams.find "grade_id" params;
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

let () =
  Alcotest.run "RouterRSC"
    [
      ( "RouterRSC",
        [
          test "getRoute" get_route_dynamic_params;
          test "getSubRoute" get_sub_route_dynamic_params;
          test "generated_routes_paths" generated_routes_paths;
        ] );
    ]

let test title fn = Alcotest.test_case title `Quick fn
let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left
let assert_int left right = Alcotest.check Alcotest.int "should be equal" right left

let use_state_doesnt_fire () =
  let app =
    React.Upper_case_component
      ( "app",
        fun () ->
          let state, setState = React.useState (fun () -> "foo") in
          (* You wouldn't have this code in prod, but just for testing purposes *)
          setState (fun _prev -> "bar");
          React.createElement "div" [] [ React.string state ] )
  in
  assert_string (ReactDOM.renderToStaticMarkup app) "<div>foo</div>"

let use_sync_external_store_with_server () =
  let app =
    React.Upper_case_component
      ( "app",
        fun () ->
          let value =
            React.useSyncExternalStoreWithServer
              ~getServerSnapshot:(fun () -> "foo")
              ~subscribe:(fun _ () -> ())
              ~getSnapshot:(fun _ -> "bar")
          in
          React.createElement "div" [] [ React.string value ] )
  in
  assert_string (ReactDOM.renderToStaticMarkup app) "<div>foo</div>"

let use_effect_doesnt_fire () =
  let app =
    React.Upper_case_component
      ( "app",
        fun () ->
          let ref = React.useRef "foo" in
          React.useEffect0 (fun () ->
              ref.current <- "bar";
              None);
          React.createElement "div" [] [ React.string ref.current ] )
  in
  assert_string (ReactDOM.renderToStaticMarkup app) "<div>foo</div>"

module Gap = struct
  let make ~children =
    React.Children.map children (fun element ->
        if element = React.null then React.null
        else React.createElement "div" [ React.JSX.String ("class", "className", "divider") ] [ element ])
end

let children_map_one_element () =
  let app = React.Upper_case_component ("app", fun () -> Gap.make ~children:(React.string "foo")) in
  assert_string (ReactDOM.renderToStaticMarkup app) "<div class=\"divider\">foo</div>"

let children_map_list_element () =
  let app =
    React.Upper_case_component
      ("app", fun () -> Gap.make ~children:(React.list [ React.string "foo"; React.string "lola" ]))
  in
  assert_string (ReactDOM.renderToStaticMarkup app) "<div class=\"divider\">foo</div><div class=\"divider\">lola</div>"

let use_ref_works () =
  let app =
    React.Upper_case_component
      ( "app",
        fun () ->
          let isLive = React.useRef true in
          React.useEffect0 (fun () ->
              isLive.current <- false;
              None);
          React.createElement "span" [] [ React.string (string_of_bool isLive.current) ] )
  in
  assert_string (ReactDOM.renderToStaticMarkup app) "<span>true</span>"

let invalid_children () =
  let raises () =
    let _ = React.createElement "input" [ React.JSX.String ("type", "type", "text") ] [ React.string "Hellow" ] in
    ()
  in
  Alcotest.check_raises "Expected invalid argument"
    (React.Invalid_children {|"input" is a self-closing tag and must not have "children".\n|})
    raises

let invalid_dangerouslySetInnerHtml () =
  let raises () =
    let _ =
      React.createElement "meta"
        [ React.JSX.String ("char-set", "charSet", "utf-8"); React.JSX.DangerouslyInnerHtml "Hellow" ]
        []
    in
    ()
  in
  Alcotest.check_raises "Expected invalid argument"
    (React.Invalid_children {|"meta" is a self-closing tag and must not have "dangerouslySetInnerHTML".\n|})
    raises

let raw_element () =
  let original = React.createElement "div" [] [ React.string "Hello" ] in
  let app = React.Upper_case_component ("app", fun () -> React.Static { prerendered = "<div>Hello</div>"; original }) in
  assert_string (ReactDOM.renderToStaticMarkup app) "<div>Hello</div>"

let cache_hits_within_request () =
  let calls = ref 0 in
  let cached =
    React.cache (fun value ->
        calls := !calls + 1;
        value ^ "-ok")
  in
  React.Cache.with_request_cache (fun () ->
      assert_string (cached "a") "a-ok";
      assert_string (cached "a") "a-ok");
  assert_int !calls 1

let cache_error_is_cached () =
  let calls = ref 0 in
  let cached =
    React.cache (fun value ->
        calls := !calls + 1;
        if value = "boom" then raise (Failure "boom");
        "ok")
  in
  let raises () =
    let _ = cached "boom" in
    ()
  in
  React.Cache.with_request_cache (fun () ->
      Alcotest.check_raises "cache error" (Failure "boom") raises;
      Alcotest.check_raises "cache error" (Failure "boom") raises);
  assert_int !calls 1

let cache_separate_per_call () =
  let calls = ref 0 in
  let make_cached () =
    React.cache (fun value ->
        calls := !calls + 1;
        value + 1)
  in
  let cached1 = make_cached () in
  let cached2 = make_cached () in
  React.Cache.with_request_cache (fun () ->
      ignore (cached1 1);
      ignore (cached1 1);
      ignore (cached2 1));
  assert_int !calls 2

let cache_resets_between_requests () =
  let calls = ref 0 in
  let cached =
    React.cache (fun value ->
        calls := !calls + 1;
        value)
  in
  React.Cache.with_request_cache (fun () ->
      ignore (cached "a");
      ignore (cached "a"));
  React.Cache.with_request_cache (fun () -> ignore (cached "a"));
  assert_int !calls 2

let cache_error_different_args () =
  let calls = ref 0 in
  let cached =
    React.cache (fun value ->
        calls := !calls + 1;
        if value = "boom1" then raise (Failure "boom1");
        if value = "boom2" then raise (Failure "boom2");
        "ok")
  in
  let raises1 () = ignore (cached "boom1") in
  let raises2 () = ignore (cached "boom2") in
  React.Cache.with_request_cache (fun () ->
      Alcotest.check_raises "first error" (Failure "boom1") raises1;
      Alcotest.check_raises "second error" (Failure "boom2") raises2;
      Alcotest.check_raises "first error cached" (Failure "boom1") raises1;
      Alcotest.check_raises "second error cached" (Failure "boom2") raises2);
  assert_int !calls 2

let cache_error_mixed_with_success () =
  let calls = ref 0 in
  let cached =
    React.cache (fun value ->
        calls := !calls + 1;
        if value = "boom" then raise (Failure "boom");
        value ^ "-ok")
  in
  let raises () = ignore (cached "boom") in
  React.Cache.with_request_cache (fun () ->
      assert_string (cached "good") "good-ok";
      Alcotest.check_raises "error" (Failure "boom") raises;
      assert_string (cached "good") "good-ok";
      Alcotest.check_raises "error cached" (Failure "boom") raises);
  assert_int !calls 2

let cache_error_resets_between_requests () =
  let calls = ref 0 in
  let cached =
    React.cache (fun value ->
        calls := !calls + 1;
        if value = "boom" then raise (Failure "boom");
        "ok")
  in
  let raises () = ignore (cached "boom") in
  React.Cache.with_request_cache (fun () ->
      Alcotest.check_raises "first request error" (Failure "boom") raises;
      Alcotest.check_raises "first request error cached" (Failure "boom") raises);
  React.Cache.with_request_cache (fun () -> Alcotest.check_raises "second request error" (Failure "boom") raises);
  assert_int !calls 2

let cache_error_same_instance () =
  let original_exn = Failure "unique" in
  let cached_exn = ref None in
  let cached = React.cache (fun () -> raise original_exn) in
  let capture_exn () = try ignore (cached ()) with exn -> cached_exn := Some exn in
  React.Cache.with_request_cache (fun () ->
      capture_exn ();
      let first = !cached_exn in
      cached_exn := None;
      capture_exn ();
      let second = !cached_exn in
      match (first, second) with
      | Some e1, Some e2 ->
          Alcotest.(check bool) "same exception instance" true (e1 == e2);
          Alcotest.(check bool) "is original exception" true (e1 == original_exn)
      | _ -> Alcotest.fail "expected exceptions to be captured")

let tests =
  ( "React",
    [
      test "useState" use_state_doesnt_fire;
      test "useSyncExternalStoreWithServer" use_sync_external_store_with_server;
      test "useEffect" use_effect_doesnt_fire;
      test "Children.map" children_map_one_element;
      test "Children.map" children_map_list_element;
      test "useRef" use_ref_works;
      test "invalid_children" invalid_children;
      test "invalid_dangerouslySetInnerHtml" invalid_dangerouslySetInnerHtml;
      test "raw_element" raw_element;
      test "cache hits within request" cache_hits_within_request;
      test "cache errors are cached" cache_error_is_cached;
      test "cache is separate per call" cache_separate_per_call;
      test "cache resets between requests" cache_resets_between_requests;
      test "cache errors different args" cache_error_different_args;
      test "cache errors mixed with success" cache_error_mixed_with_success;
      test "cache errors reset between requests" cache_error_resets_between_requests;
      test "cache errors same instance" cache_error_same_instance;
    ] )

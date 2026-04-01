let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left

(* Helper components *)
let div_with_id () =
  React.Upper_case_component
    ( "DivWithId",
      fun () ->
        let id = React.useId () in
        React.createElement "div" [ React.JSX.String ("id", "id", id) ] [] )

let div_with_two_ids () =
  React.Upper_case_component
    ( "DivWithTwoIds",
      fun () ->
        let id1 = React.useId () in
        let id2 = React.useId () in
        React.createElement "div"
          [ React.JSX.String ("data-id1", "data-id1", id1); React.JSX.String ("data-id2", "data-id2", id2) ]
          [] )

let div_with_three_ids () =
  React.Upper_case_component
    ( "DivWithThreeIds",
      fun () ->
        let id1 = React.useId () in
        let id2 = React.useId () in
        let id3 = React.useId () in
        React.createElement "div"
          [
            React.JSX.String ("data-id1", "data-id1", id1);
            React.JSX.String ("data-id2", "data-id2", id2);
            React.JSX.String ("data-id3", "data-id3", id3);
          ]
          [] )

let wrapper children =
  React.Upper_case_component
    ("Wrapper", fun () -> React.createElement "div" [ React.JSX.String ("class", "className", "wrapper") ] [ children ])

let parent_with_id children =
  React.Upper_case_component
    ( "ParentWithId",
      fun () ->
        let id = React.useId () in
        React.createElement "div" [ React.JSX.String ("id", "id", id) ] [ children ] )

(* Unicode delimiters used by React 19: \u00ab = « and \u00bb = » *)
let prefix = "\xc2\xab"
let suffix = "\xc2\xbb"
let id s = prefix ^ s ^ suffix

(* Test 1: Single component with useId *)
let single_component_with_use_id () =
  let html = ReactDOM.renderToString (div_with_id ()) in
  assert_string html ("<div id=\"" ^ id "R0" ^ "\"></div>")

(* Test 2: Two sibling components with useId *)
let two_sibling_components () =
  let el = React.createElement "div" [] [ div_with_id (); div_with_id () ] in
  let html = ReactDOM.renderToString el in
  assert_string html ("<div><div id=\"" ^ id "R1" ^ "\"></div><div id=\"" ^ id "R2" ^ "\"></div></div>")

(* Test 3: Nested components with useId *)
let nested_components () =
  let el = parent_with_id (div_with_id ()) in
  let html = ReactDOM.renderToString el in
  assert_string html ("<div id=\"" ^ id "R0" ^ "\"><div id=\"" ^ id "R1" ^ "\"></div></div>")

(* Test 4: Multiple useId calls in one component *)
let multiple_use_id_calls () =
  let html = ReactDOM.renderToString (div_with_two_ids ()) in
  assert_string html ("<div data-id1=\"" ^ id "R0" ^ "\" data-id2=\"" ^ id "R0H1" ^ "\"></div>")

(* Test 5: Three useId calls in one component *)
let three_use_id_calls () =
  let html = ReactDOM.renderToString (div_with_three_ids ()) in
  assert_string html
    ("<div data-id1=\"" ^ id "R0" ^ "\" data-id2=\"" ^ id "R0H1" ^ "\" data-id3=\"" ^ id "R0H2" ^ "\"></div>")

(* Test 6: Siblings with nested children *)
let siblings_with_nested_children () =
  let el = React.createElement "div" [] [ parent_with_id (div_with_id ()); div_with_id () ] in
  let html = ReactDOM.renderToString el in
  assert_string html
    ("<div><div id=\"" ^ id "R1" ^ "\"><div id=\"" ^ id "R5" ^ "\"></div></div><div id=\"" ^ id "R2" ^ "\"></div></div>")

(* Test 7: Deep nesting (3 levels) *)
let deep_nesting () =
  let el = parent_with_id (parent_with_id (div_with_id ())) in
  let html = ReactDOM.renderToString el in
  assert_string html
    ("<div id=\"" ^ id "R0" ^ "\"><div id=\"" ^ id "R1" ^ "\"><div id=\"" ^ id "R3" ^ "\"></div></div></div>")

(* Test 8: Wrapper without useId is transparent *)
let wrapper_without_use_id () =
  let el = wrapper (div_with_id ()) in
  let html = ReactDOM.renderToString el in
  assert_string html ("<div class=\"wrapper\"><div id=\"" ^ id "R0" ^ "\"></div></div>")

(* Test 9: Three siblings *)
let three_siblings () =
  let el = React.createElement "div" [] [ div_with_id (); div_with_id (); div_with_id () ] in
  let html = ReactDOM.renderToString el in
  assert_string html
    ("<div><div id=\"" ^ id "R1" ^ "\"></div><div id=\"" ^ id "R2" ^ "\"></div><div id=\"" ^ id "R3" ^ "\"></div></div>")

(* Test 10: Complex siblings with nested *)
let complex_siblings_with_nested () =
  let el =
    React.createElement "div" []
      [
        parent_with_id (React.Fragment (React.List [ div_with_id (); div_with_id () ])); parent_with_id (div_with_id ());
      ]
  in
  let html = ReactDOM.renderToString el in
  assert_string html
    ("<div><div id=\"" ^ id "R1" ^ "\"><div id=\"" ^ id "Rd" ^ "\"></div><div id=\"" ^ id "Rl"
   ^ "\"></div></div><div id=\"" ^ id "R2" ^ "\"><div id=\"" ^ id "R6" ^ "\"></div></div></div>")

(* Test 12: Separate renders produce same IDs *)
let separate_renders_same_ids () =
  let html1 = ReactDOM.renderToString (div_with_id ()) in
  let html2 = ReactDOM.renderToString (div_with_id ()) in
  assert_string html1 html2

(* Test: renderToStaticMarkup also works *)
let static_markup_use_id () =
  let html = ReactDOM.renderToStaticMarkup (div_with_id ()) in
  assert_string html ("<div id=\"" ^ id "R0" ^ "\"></div>")

(* Test: identifier_prefix *)
let identifier_prefix () =
  let html = ReactDOM.renderToString ~identifier_prefix:"myapp" (div_with_id ()) in
  assert_string html ("<div id=\"" ^ id "myappR0" ^ "\"></div>")

let test title fn =
  (Printf.sprintf "ReactDOM.renderToString / useId / %s" title, [ Alcotest_lwt.test_case_sync "" `Quick fn ])

let tests =
  [
    test "single component with useId" single_component_with_use_id;
    test "two sibling components" two_sibling_components;
    test "nested components" nested_components;
    test "multiple useId calls in one component" multiple_use_id_calls;
    test "three useId calls in one component" three_use_id_calls;
    test "siblings with nested children" siblings_with_nested_children;
    test "deep nesting (3 levels)" deep_nesting;
    test "wrapper without useId is transparent" wrapper_without_use_id;
    test "three siblings" three_siblings;
    test "complex siblings with nested" complex_siblings_with_nested;
    test "separate renders produce same IDs" separate_renders_same_ids;
    test "renderToStaticMarkup also works" static_markup_use_id;
    test "identifier_prefix" identifier_prefix;
  ]

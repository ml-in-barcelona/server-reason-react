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

let mk_provider ctx ~value ~children () = React.Context.provider ctx (React.Context.makeProps ~value ~children ())

(* All expected values verified against React 19.1.0 (bun arch/server/test-useid.js)
   React 19 ID format: \xc2\xab (U+00AB «) + prefix + R + treeId + \xc2\xbb (U+00BB ») *)

let single_component_with_use_id () =
  let html = ReactDOM.renderToString (div_with_id ()) in
  assert_string html "<div id=\"\xc2\xabR0\xc2\xbb\"></div>"

let two_sibling_components () =
  let el = React.createElement "div" [] [ div_with_id (); div_with_id () ] in
  let html = ReactDOM.renderToString el in
  assert_string html "<div><div id=\"\xc2\xabR1\xc2\xbb\"></div><div id=\"\xc2\xabR2\xc2\xbb\"></div></div>"

let nested_components () =
  let el = parent_with_id (div_with_id ()) in
  let html = ReactDOM.renderToString el in
  assert_string html "<div id=\"\xc2\xabR0\xc2\xbb\"><div id=\"\xc2\xabR1\xc2\xbb\"></div></div>"

let multiple_use_id_calls () =
  let html = ReactDOM.renderToString (div_with_two_ids ()) in
  assert_string html "<div data-id1=\"\xc2\xabR0\xc2\xbb\" data-id2=\"\xc2\xabR0H1\xc2\xbb\"></div>"

let three_use_id_calls () =
  let html = ReactDOM.renderToString (div_with_three_ids ()) in
  assert_string html
    "<div data-id1=\"\xc2\xabR0\xc2\xbb\" data-id2=\"\xc2\xabR0H1\xc2\xbb\" data-id3=\"\xc2\xabR0H2\xc2\xbb\"></div>"

let siblings_with_nested_children () =
  let el = React.createElement "div" [] [ parent_with_id (div_with_id ()); div_with_id () ] in
  let html = ReactDOM.renderToString el in
  assert_string html
    "<div><div id=\"\xc2\xabR1\xc2\xbb\"><div id=\"\xc2\xabR5\xc2\xbb\"></div></div><div \
     id=\"\xc2\xabR2\xc2\xbb\"></div></div>"

let deep_nesting () =
  let el = parent_with_id (parent_with_id (div_with_id ())) in
  let html = ReactDOM.renderToString el in
  assert_string html
    "<div id=\"\xc2\xabR0\xc2\xbb\"><div id=\"\xc2\xabR1\xc2\xbb\"><div id=\"\xc2\xabR3\xc2\xbb\"></div></div></div>"

let wrapper_without_use_id () =
  let el = wrapper (div_with_id ()) in
  let html = ReactDOM.renderToString el in
  assert_string html "<div class=\"wrapper\"><div id=\"\xc2\xabR0\xc2\xbb\"></div></div>"

let three_siblings () =
  let el = React.createElement "div" [] [ div_with_id (); div_with_id (); div_with_id () ] in
  let html = ReactDOM.renderToString el in
  assert_string html
    "<div><div id=\"\xc2\xabR1\xc2\xbb\"></div><div id=\"\xc2\xabR2\xc2\xbb\"></div><div \
     id=\"\xc2\xabR3\xc2\xbb\"></div></div>"

let complex_siblings_with_nested () =
  let el =
    React.createElement "div" []
      [
        parent_with_id (React.Fragment (React.List [ div_with_id (); div_with_id () ])); parent_with_id (div_with_id ());
      ]
  in
  let html = ReactDOM.renderToString el in
  assert_string html
    "<div><div id=\"\xc2\xabR1\xc2\xbb\"><div id=\"\xc2\xabRd\xc2\xbb\"></div><div \
     id=\"\xc2\xabRl\xc2\xbb\"></div></div><div id=\"\xc2\xabR2\xc2\xbb\"><div \
     id=\"\xc2\xabR6\xc2\xbb\"></div></div></div>"

let separate_renders_same_ids () =
  let html1 = ReactDOM.renderToString (div_with_id ()) in
  let html2 = ReactDOM.renderToString (div_with_id ()) in
  assert_string html1 html2

let static_markup_use_id () =
  let html = ReactDOM.renderToStaticMarkup (div_with_id ()) in
  assert_string html "<div id=\"\xc2\xabR0\xc2\xbb\"></div>"

let identifier_prefix () =
  let html = ReactDOM.renderToString ~identifier_prefix:"myapp" (div_with_id ()) in
  assert_string html "<div id=\"\xc2\xabmyappR0\xc2\xbb\"></div>"

(* ── Edge case tests (verified against React 19.1.0 output) ────────────────── *)

let use_id_inside_suspense () =
  let el =
    React.Suspense
      { key = None; children = div_with_id (); fallback = React.createElement "div" [] [ React.string "loading" ] }
  in
  let html = ReactDOM.renderToString el in
  assert_string html "<!--$--><div id=\"\xc2\xabR0\xc2\xbb\"></div><!--/$-->"

let use_id_suspense_and_sibling () =
  let el =
    React.createElement "div" []
      [
        React.Suspense
          { key = None; children = div_with_id (); fallback = React.createElement "div" [] [ React.string "loading" ] };
        div_with_id ();
      ]
  in
  let html = ReactDOM.renderToString el in
  assert_string html
    "<div><!--$--><div id=\"\xc2\xabR1\xc2\xbb\"></div><!--/$--><div id=\"\xc2\xabR2\xc2\xbb\"></div></div>"

let fragment_single_child () =
  let el = React.createElement "div" [] [ React.Fragment (div_with_id ()) ] in
  let html = ReactDOM.renderToString el in
  assert_string html "<div><div id=\"\xc2\xabR0\xc2\xbb\"></div></div>"

let fragment_multiple_children () =
  let el = React.createElement "div" [] [ React.Fragment (React.List [ div_with_id (); div_with_id () ]) ] in
  let html = ReactDOM.renderToString el in
  assert_string html "<div><div id=\"\xc2\xabR1\xc2\xbb\"></div><div id=\"\xc2\xabR2\xc2\xbb\"></div></div>"

let nested_fragments () =
  let el = React.createElement "div" [] [ React.Fragment (React.Fragment (div_with_id ())) ] in
  let html = ReactDOM.renderToString el in
  assert_string html "<div><div id=\"\xc2\xabR0\xc2\xbb\"></div></div>"

let null_between_siblings () =
  let el = React.createElement "div" [] [ div_with_id (); React.Empty; div_with_id () ] in
  let html = ReactDOM.renderToString el in
  assert_string html "<div><div id=\"\xc2\xabR1\xc2\xbb\"></div><div id=\"\xc2\xabR3\xc2\xbb\"></div></div>"

let many_siblings () =
  let children = List.init 10 (fun _ -> div_with_id ()) in
  let el = React.createElement "div" [] children in
  let html = ReactDOM.renderToString el in
  assert_string html
    "<div><div id=\"\xc2\xabR1\xc2\xbb\"></div><div id=\"\xc2\xabR2\xc2\xbb\"></div><div \
     id=\"\xc2\xabR3\xc2\xbb\"></div><div id=\"\xc2\xabR4\xc2\xbb\"></div><div id=\"\xc2\xabR5\xc2\xbb\"></div><div \
     id=\"\xc2\xabR6\xc2\xbb\"></div><div id=\"\xc2\xabR7\xc2\xbb\"></div><div id=\"\xc2\xabR8\xc2\xbb\"></div><div \
     id=\"\xc2\xabR9\xc2\xbb\"></div><div id=\"\xc2\xabRa\xc2\xbb\"></div></div>"

let provider_transparent () =
  let ctx = React.createContext "default" in
  let el = mk_provider ctx ~value:"provided" ~children:(div_with_id ()) () in
  let html = ReactDOM.renderToString el in
  assert_string html "<div id=\"\xc2\xabR0\xc2\xbb\"></div>"

let kitchen_sink () =
  let ctx = React.createContext "default" in
  let el =
    React.createElement "div" []
      [
        mk_provider ctx ~value:"a"
          ~children:
            (React.Fragment
               (React.List
                  [
                    div_with_id ();
                    React.Suspense
                      {
                        key = None;
                        children = div_with_id ();
                        fallback = React.createElement "span" [] [ React.string "..." ];
                      };
                  ]))
          ();
        div_with_id ();
      ]
  in
  let html = ReactDOM.renderToString el in
  assert_string html
    "<div><div id=\"\xc2\xabR5\xc2\xbb\"></div><!--$--><div id=\"\xc2\xabR9\xc2\xbb\"></div><!--/$--><div \
     id=\"\xc2\xabR2\xc2\xbb\"></div></div>"

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
    test "useId inside Suspense (sync)" use_id_inside_suspense;
    test "Suspense with useId + sibling" use_id_suspense_and_sibling;
    test "Fragment single child is transparent" fragment_single_child;
    test "Fragment multiple children forks" fragment_multiple_children;
    test "Nested fragments transparent" nested_fragments;
    test "Null/Empty between siblings preserves slots" null_between_siblings;
    test "Many siblings (10, base-32 at Ra)" many_siblings;
    test "Provider is transparent" provider_transparent;
    test "Kitchen sink (Provider + Fragment + Suspense)" kitchen_sink;
  ]

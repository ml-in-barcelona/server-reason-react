let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left

let react_root_one_element () =
  let div = React.createElement "div" [] [] in
  assert_string (ReactDOM.renderToString div) "<div></div>"

let react_root_two_elements () =
  let div = React.createElement "div" [] [ React.createElement "span" [] [] ] in
  assert_string (ReactDOM.renderToString div) "<div><span></span></div>"

let text_single_node () =
  let div = React.createElement "div" [] [ React.createElement "span" [] [ React.string "Hello" ] ] in
  assert_string (ReactDOM.renderToString div) "<div><span>Hello</span></div>"

let consecutives_text_nodes () =
  let div =
    React.createElement "div" [] [ React.createElement "span" [] [ React.string "Hello"; React.string "Hello" ] ]
  in
  assert_string (ReactDOM.renderToString div) "<div><span>Hello<!-- -->Hello</span></div>"

let separated_text_nodes_by_other_parents () =
  let app () =
    React.Upper_case_component
      ( "app",
        fun () ->
          React.list
            [
              React.createElement "main" [] [ React.string "Hi"; React.createElement "span" [] [ React.string "chat" ] ];
            ] )
  in
  assert_string (ReactDOM.renderToString (app ())) "<main>Hi<span>chat</span></main>"

let text_after_element_with_text_child () =
  let div =
    React.createElement "div" []
      [ React.string "before "; React.createElement "span" [] [ React.string "inner" ]; React.string " after" ]
  in
  assert_string (ReactDOM.renderToString div) "<div>before <span>inner</span> after</div>"

let suspense_children_render_once () =
  let render_count = ref 0 in
  let child () =
    React.Upper_case_component
      ( "Child",
        fun () ->
          render_count := !render_count + 1;
          React.createElement "div" [] [ React.string "hello" ] )
  in
  let el =
    React.Suspense
      { key = None; children = child (); fallback = React.createElement "div" [] [ React.string "loading" ] }
  in
  let html = ReactDOM.renderToString el in
  assert_string html "<!--$--><div>hello</div><!--/$-->";
  Alcotest.(check int) "children should render exactly once" 1 !render_count

let suspense_fallback_on_error () =
  let el =
    React.Suspense
      {
        key = None;
        children = React.Upper_case_component ("Throws", fun () -> raise (Failure "boom"));
        fallback = React.createElement "div" [] [ React.string "fallback" ];
      }
  in
  let html = ReactDOM.renderToString el in
  assert_string html "<!--$!--><div>fallback</div><!--/$-->"

let test title fn = (Printf.sprintf "ReactDOM.renderToString / %s" title, [ Alcotest_lwt.test_case_sync "" `Quick fn ])

let tests =
  [
    test "react_root_one_element" react_root_one_element;
    test "react_root_two_elements" react_root_two_elements;
    test "text_single_node should not add <!-- -->" text_single_node;
    test "consecutives_text_nodes should add <!-- -->" consecutives_text_nodes;
    test "separated_text_nodes_by_other_parents" separated_text_nodes_by_other_parents;
    test "text_after_element_with_text_child" text_after_element_with_text_child;
    test "suspense children render exactly once" suspense_children_render_once;
    test "suspense renders fallback on error" suspense_fallback_on_error;
  ]

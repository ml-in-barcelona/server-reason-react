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

let test title fn = (Printf.sprintf "ReactDOM.renderToString / %s" title, [ Alcotest_lwt.test_case_sync "" `Quick fn ])

let tests =
  [
    test "react root" react_root_one_element;
    test "react root in two" react_root_two_elements;
    test "one text node should not add <!-- -->" text_single_node;
    test "consecutive text nodes should add <!-- -->" consecutives_text_nodes;
  ]

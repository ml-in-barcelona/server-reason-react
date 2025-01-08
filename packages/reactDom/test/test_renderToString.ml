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
      (fun () ->
        React.List
          [|
            React.createElement "main" [] [ React.string "Hi"; React.createElement "span" [] [ React.string "chat" ] ];
          |])
  in
  assert_string (ReactDOM.renderToString (app ())) "<main>Hi<span>chat</span></main>"

let test title fn = (Printf.sprintf "ReactDOM.renderToString / %s" title, [ Alcotest_lwt.test_case_sync "" `Quick fn ])

let tests =
  [
    test "react_root_one_element" react_root_one_element;
    test "react_root_two_elements" react_root_two_elements;
    test "text_single_node should not add <!-- -->" text_single_node;
    test "consecutives_text_nodes should add <!-- -->" consecutives_text_nodes;
    test "separated_text_nodes_by_other_parents" separated_text_nodes_by_other_parents;
  ]

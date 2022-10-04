open Alcotest

let assert_string left right = (check string) "should be equal" right left

let test_react_root_one_element () =
  let div = React.createElement "div" [||] [] in
  assert_string (ReactDOM.renderToString div) "<div data-reactroot=\"\"></div>"

let test_react_root_two_elements () =
  let div =
    React.createElement "div" [||] [ React.createElement "span" [||] [] ]
  in
  assert_string
    (ReactDOM.renderToString div)
    "<div data-reactroot=\"\"><span></span></div>"

let test_text_single_node () =
  let div =
    React.createElement "div" [||]
      [ React.createElement "span" [||] [ React.string "Hello" ] ]
  in
  assert_string
    (ReactDOM.renderToString div)
    "<div data-reactroot=\"\"><span>Hello</span></div>"

let test_consecutives_text_nodes () =
  let div =
    React.createElement "div" [||]
      [ React.createElement "span" [||]
          [ React.string "Hello"; React.string "Hello" ]
      ]
  in
  assert_string
    (ReactDOM.renderToString div)
    "<div data-reactroot=\"\"><span>Hello<!-- -->Hello</span></div>"

let tests =
  ( "renderToString"
  , [ test_case "react root" `Quick test_react_root_one_element
    ; test_case "react root in two" `Quick test_react_root_two_elements
    ; test_case "one text node should not add <!-- -->" `Quick
        test_text_single_node
    ; test_case "consecutive text nodes should add <!-- -->" `Quick
        test_consecutives_text_nodes
    ] )

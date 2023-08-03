let assert_string left right =
  Alcotest.check Alcotest.string "should be equal" right left

let react_root_one_element () =
  let div = React.createElement "div" [||] [] in
  assert_string (ReactDOM.renderToString div) "<div data-reactroot=\"\"></div>"

let react_root_two_elements () =
  let div =
    React.createElement "div" [||] [ React.createElement "span" [||] [] ]
  in
  assert_string
    (ReactDOM.renderToString div)
    "<div data-reactroot=\"\"><span></span></div>"

let text_single_node () =
  let div =
    React.createElement "div" [||]
      [ React.createElement "span" [||] [ React.string "Hello" ] ]
  in
  assert_string
    (ReactDOM.renderToString div)
    "<div data-reactroot=\"\"><span>Hello</span></div>"

let consecutives_text_nodes () =
  let div =
    React.createElement "div" [||]
      [
        React.createElement "span" [||]
          [ React.string "Hello"; React.string "Hello" ];
      ]
  in
  assert_string
    (ReactDOM.renderToString div)
    "<div data-reactroot=\"\"><span>Hello<!-- -->Hello</span></div>"

let case title fn = Alcotest_lwt.test_case_sync title `Quick fn

let whatever =
  React.createElement "div"
    ([||] |> Array.to_list |> List.filter_map (fun a -> a) |> Array.of_list)
    [
      React.fragment
        ~children:
          (React.list
             [
               React.createElement "iframe"
                 ([||] |> Array.to_list
                 |> List.filter_map (fun a -> a)
                 |> Array.of_list)
                 [];
             ])
        ();
    ]

let tests =
  ( "renderToString",
    [
      case "react root" react_root_one_element;
      case "react root in two" react_root_two_elements;
      case "one text node should not add <!-- -->" text_single_node;
      case "consecutive text nodes should add <!-- -->" consecutives_text_nodes;
    ] )

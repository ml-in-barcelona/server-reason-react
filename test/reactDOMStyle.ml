open Alcotest

let assert_string left right = (check string) "should be equal" right left

let test_two_styles () =
  let styles = ReactDOM.Style.make ~background:"#333" ~fontSize:"24px" () in
  assert_string styles "background: #333; font-size: 24px"

let test_one_styles () =
  let styles = ReactDOM.Style.make ~background:"#333" () in
  assert_string styles "background: #333"

let tests =
  ( "ReactDOM.Style.make"
  , [ test_case "generate one style" `Quick test_one_styles
    ; test_case "generate more than one style" `Quick test_two_styles
    ] )

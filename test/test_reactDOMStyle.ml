let assert_string left right =
  (Alcotest.check Alcotest.string) "should be equal" right left

let two_styles () =
  let styles = ReactDOM.Style.make ~background:"#333" ~fontSize:"24px" () in
  assert_string styles "background: #333; font-size: 24px"

let one_styles () =
  let styles = ReactDOM.Style.make ~background:"#333" () in
  assert_string styles "background: #333"

let case title fn = Alcotest.test_case title `Quick fn

let tests =
  ( "ReactDOM.Style.make",
    [
      case "generate one style" one_styles;
      case "generate more than one style" two_styles;
    ] )

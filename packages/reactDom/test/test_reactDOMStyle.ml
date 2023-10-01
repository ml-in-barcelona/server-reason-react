let assert_styles styles str =
  Alcotest.check Alcotest.string "should be equal" str
    (ReactDOM.Style.to_string styles)

let two_styles () =
  let styles = ReactDOM.Style.make ~background:"#333" ~fontSize:"24px" () in
  assert_styles styles "background:#333;font-size:24px"

let one_styles () =
  let styles = ReactDOM.Style.make ~background:"#333" () in
  assert_styles styles "background:#333"

let zero_styles () =
  let styles = ReactDOM.Style.make () in
  assert_styles styles ""

let unsafe_add_prop () =
  let styles =
    ReactDOM.Style.unsafeAddProp
      (ReactDOM.Style.make ~background:"#333" ())
      "colorScheme" "dark"
  in
  assert_styles styles "background:#333;color-scheme:dark"

let style_order_matters () =
  let styles =
    ReactDOM.Style.make ~lineBreak:"100px" ~overflowWrap:"break-word" ()
  in
  assert_styles styles "line-break:100px;overflow-wrap:break-word"

let case title fn = Alcotest_lwt.test_case_sync title `Quick fn

let tests =
  ( "ReactDOM.Style.make",
    [
      case "generate empty style" zero_styles;
      case "generate one style" one_styles;
      case "generate more than one style" two_styles;
      case "unsafeAddProp should be kebab-case" unsafe_add_prop;
      case "unsafeAddProp should be kebab-case" style_order_matters;
    ] )

let assert_styles styles str = Alcotest.check Alcotest.string "should be equal" str (ReactDOM.Style.to_string styles)

let one_styles () =
  let styles = ReactDOM.Style.make ~background:"#333" () in
  assert_styles styles "background:#333"

let two_styles () =
  let styles = ReactDOM.Style.make ~background:"#333" ~fontSize:"24px" () in
  assert_styles styles "font-size:24px;background:#333"

let zero_styles () =
  let styles = ReactDOM.Style.make () in
  assert_styles styles ""

let emtpy_value () =
  let styles = ReactDOM.Style.make ~background:"" () in
  assert_styles styles ""

let emtpy_value_with_more () =
  let styles = ReactDOM.Style.make ~background:"" ~color:"transparent" () in
  assert_styles styles "color:transparent"

let unsafe_add_prop () =
  let styles = ReactDOM.Style.unsafeAddProp (ReactDOM.Style.make ~background:"#333" ()) "colorScheme" "dark" in
  assert_styles styles "color-scheme:dark;background:#333"

let style_order_matters () =
  let styles = ReactDOM.Style.make ~lineBreak:"100px" ~overflowWrap:"break-word" () in
  assert_styles styles "overflow-wrap:break-word;line-break:100px"

let style_order_matters_2 () =
  let styles = ReactDOM.Style.make ~opacity:"1.0" ~stress:"0" ~width:"20" ~backgroundColor:"red" ~columnGap:"2px" () in
  assert_styles styles "column-gap:2px;opacity:1.0;width:20;stress:0;background-color:red"

let test title fn = (Printf.sprintf "ReactDOM.Style.make / %s" title, [ Alcotest_lwt.test_case_sync "" `Quick fn ])

let tests =
  [
    test "generate empty style" zero_styles;
    test "generate one style" one_styles;
    test "generate more than one style" two_styles;
    test "unsafeAddProp should be kebab-case" unsafe_add_prop;
    (* TODO: Add more test for unsafeAddProp *)
    test "order matters" style_order_matters;
    test "order matters II" style_order_matters_2;
  ]

let assert_styles styles str = Alcotest.check Alcotest.string "should be equal" str (ReactDOM.Style.to_string styles)

let one_styles () =
  let styles = ReactDOM.Style.make ~background:"#333" () in
  assert_styles styles "background:#333"

let two_styles () =
  let styles = ReactDOM.Style.make ~background:"#333" ~fontSize:"24px" () in
  assert_styles styles "background:#333;font-size:24px"

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
  assert_styles styles "background:#333;color-scheme:dark"

let unsafe_add_prop_css_custom_property () =
  let styles = ReactDOM.Style.unsafeAddProp (ReactDOM.Style.make ()) "--var-136njlt_1" "8px" in
  assert_styles styles "--var-136njlt_1:8px"

let unsafe_add_prop_css_custom_property_with_var_value () =
  let styles = ReactDOM.Style.unsafeAddProp (ReactDOM.Style.make ()) "--var-qog-9iu" "var(--alt-background--box)" in
  assert_styles styles "--var-qog-9iu:var(--alt-background--box)"

let unsafe_add_prop_css_custom_property_simple () =
  let styles = ReactDOM.Style.unsafeAddProp (ReactDOM.Style.make ()) "--var-5uugbw" "16px" in
  assert_styles styles "--var-5uugbw:16px"

let unsafe_add_prop_camel_with_digits () =
  (* Digits and underscores in non-custom-property keys must not insert dashes. *)
  let styles = ReactDOM.Style.unsafeAddProp (ReactDOM.Style.make ()) "grid_area1" "main" in
  assert_styles styles "grid_area1:main"

let combine_same_key_last_value_wins () =
  let styles = ReactDOM.Style.combine (ReactDOM.Style.make ~color:"red" ()) (ReactDOM.Style.make ~color:"blue" ()) in
  assert_styles styles "color:blue"

let combine_key_keeps_first_position () =
  let styles =
    ReactDOM.Style.combine
      (ReactDOM.Style.combine
         (ReactDOM.Style.make ~background:"red" ())
         (ReactDOM.Style.make ~backgroundColor:"blue" ()))
      (ReactDOM.Style.make ~background:"green" ())
  in
  assert_styles styles "background:green;background-color:blue"

let combine_same_custom_property () =
  let a = ReactDOM.Style.unsafeAddProp (ReactDOM.Style.make ()) "--tone" "#0000FF" in
  assert_styles (ReactDOM.Style.combine a a) "--tone:#0000FF";
  assert_styles (ReactDOM.Style.combine a (ReactDOM.Style.combine a a)) "--tone:#0000FF"

let combine_distinct_keys_keep_order () =
  let one = ReactDOM.Style.unsafeAddProp (ReactDOM.Style.make ()) "--one" "1" in
  let two = ReactDOM.Style.unsafeAddProp (ReactDOM.Style.make ()) "--two" "2" in
  let three = ReactDOM.Style.unsafeAddProp (ReactDOM.Style.make ()) "--three" "3" in
  assert_styles (ReactDOM.Style.combine (ReactDOM.Style.combine one two) three) "--one:1;--two:2;--three:3"

let combine_empty_value_replaces_and_keeps_position () =
  let base = ReactDOM.Style.make ~color:"red" ~display:"block" () in
  let cleared = ReactDOM.Style.combine base (ReactDOM.Style.make ~color:"" ()) in
  assert_styles cleared "display:block";
  assert_styles (ReactDOM.Style.combine cleared (ReactDOM.Style.make ~color:"blue" ())) "color:blue;display:block"

let unsafe_add_prop_same_key_last_value_wins () =
  let styles = ReactDOM.Style.unsafeAddProp (ReactDOM.Style.make ()) "--g" "8px" in
  let styles = ReactDOM.Style.unsafeAddProp styles "--g" "12px" in
  assert_styles styles "--g:12px"

let unsafe_add_prop_existing_key_keeps_position () =
  let styles = ReactDOM.Style.make ~color:"red" ~display:"block" () in
  assert_styles (ReactDOM.Style.unsafeAddProp styles "color" "blue") "color:blue;display:block"

let style_order_matters () =
  let styles = ReactDOM.Style.make ~lineBreak:"100px" ~overflowWrap:"break-word" () in
  assert_styles styles "line-break:100px;overflow-wrap:break-word"

let style_order_matters_2 () =
  let styles = ReactDOM.Style.make ~opacity:"1.0" ~stress:"0" ~width:"20" ~backgroundColor:"red" ~columnGap:"2px" () in
  assert_styles styles "background-color:red;stress:0;width:20;opacity:1.0;column-gap:2px"

let cursor_renders_once () =
  let styles = ReactDOM.Style.make ?cursor:(Some "pointer") () in
  assert_styles styles "cursor:pointer"

let test title fn = (Printf.sprintf "ReactDOM.Style.make / %s" title, [ Alcotest_lwt.test_case_sync "" `Quick fn ])

let tests =
  [
    test "generate empty style" zero_styles;
    test "generate one style" one_styles;
    test "generate more than one style" two_styles;
    test "unsafeAddProp should be kebab-case" unsafe_add_prop;
    test "unsafeAddProp preserves CSS custom property keys verbatim" unsafe_add_prop_css_custom_property;
    test "unsafeAddProp preserves CSS custom property with var() value"
      unsafe_add_prop_css_custom_property_with_var_value;
    test "unsafeAddProp preserves simple CSS custom property" unsafe_add_prop_css_custom_property_simple;
    test "unsafeAddProp does not insert dashes around digits/underscores" unsafe_add_prop_camel_with_digits;
    test "unsafeAddProp same key keeps one entry with the last value" unsafe_add_prop_same_key_last_value_wins;
    test "unsafeAddProp existing key keeps its position" unsafe_add_prop_existing_key_keeps_position;
    test "combine same key keeps the last value" combine_same_key_last_value_wins;
    test "combine key keeps its first position" combine_key_keeps_first_position;
    test "combine same custom property gives one entry" combine_same_custom_property;
    test "combine distinct keys keep order" combine_distinct_keys_keep_order;
    test "combine empty value replaces and keeps position" combine_empty_value_replaces_and_keeps_position;
    test "order matters" style_order_matters;
    test "order matters II" style_order_matters_2;
    test "cursor renders one declaration" cursor_renders_once;
  ]

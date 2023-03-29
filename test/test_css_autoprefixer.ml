let assert_string left right =
  (Alcotest.check Alcotest.string) "should be equal" right left

let prefix_one_declaration declaration output =
  let _rule = Css.style [ declaration ] in
  let css = Css.render_style_tag () in
  Css.flush ();
  assert_string css output

let text_size_adjust () =
  prefix_one_declaration
    (Css.unsafe "text-size-adjust" "none")
    " .css-4bcd2j { -webkit-text-size-adjust: none; -moz-text-size-adjust: \
     none; -ms-text-size-adjust: none; text-size-adjust: none; }"

let text_decoration () =
  prefix_one_declaration
    (Css.textDecoration `lineThrough)
    " .css-lemim { -webkit-text-decoration: line-through; text-decoration: \
     line-through; }"

let display_grid () =
  prefix_one_declaration (Css.display `grid) " .css-u5mu6e { display: grid; }"

let animation_duration () =
  prefix_one_declaration
    (Css.animationIterationCount `infinite)
    " .css-5vecbj { -webkit-animation-iteration-count: infinite; \
     animation-iteration-count: infinite; }"

let case title fn = Alcotest.test_case title `Quick fn

let tests =
  ( "Autoprefixer"
  , [ case "text-size-adjust" text_size_adjust
    ; case "text-decoration" text_decoration
    ; case "display: grid" display_grid
    ; case "animation-duration" animation_duration
    ] )

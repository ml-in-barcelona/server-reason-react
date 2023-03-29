let assert_string left right =
  (Alcotest.check Alcotest.string) "should be equal" right left

let one_property () =
  let _className = Css.style [ Css.display `block ] in
  let css = Css.render_style_tag () in
  Css.flush ();
  assert_string css " .css-etlvsf { display: block; }"

let multiple_properties () =
  let _className = Css.style [ Css.display `block; Css.fontSize (`px 10) ] in
  let css = Css.render_style_tag () in
  Css.flush ();
  assert_string css " .css-66lw0t { display: block; font-size: 10px; }"

let float_values () =
  let _className = Css.style [ Css.padding (`rem 10.) ] in
  let css = Css.render_style_tag () in
  Css.flush ();
  assert_string css " .css-g4terb { padding: 10rem; }"

let selector_one_nesting () =
  let _className =
    Css.style
      [ Css.color Css.aliceblue
      ; Css.selector "a" [ Css.color Css.rebeccapurple ]
      ]
  in
  let css = Css.render_style_tag () in
  Css.flush ();
  assert_string css
    " .css-kx51ye { color: #F0F8FF; } .css-kx51ye a { color: #663399; }"

let selector_more_than_one_nesting () =
  let _className =
    Css.style
      [ Css.color Css.aliceblue
      ; Css.selector "a"
          [ Css.display `block; Css.selector "div" [ Css.display `none ] ]
      ]
  in
  let css = Css.render_style_tag () in
  Css.flush ();
  assert_string css
    " .css-5hr6i6 { color: #F0F8FF; } .css-5hr6i6 a { display: block; } \
     .css-5hr6i6 a div { display: none; }"

let selector_with_a_lot_of_nesting () =
  let _className =
    Css.style
      [ Css.display `flex
      ; Css.selector "a"
          [ Css.display `block
          ; Css.selector "div"
              [ Css.display `none
              ; Css.selector "span"
                  [ Css.display `none
                  ; Css.selector "hr"
                      [ Css.display `none
                      ; Css.selector "code" [ Css.display `none ]
                      ]
                  ]
              ]
          ]
      ]
  in
  let css = Css.render_style_tag () in
  Css.flush ();
  assert_string css
    " .css-or3ar2 { display: flex; } .css-or3ar2 a { display: block; } \
     .css-or3ar2 a div { display: none; } .css-or3ar2 a div span { display: \
     none; } .css-or3ar2 a div span hr { display: none; } .css-or3ar2 a div \
     span hr code { display: none; }"

let selector_ampersand () =
  let _className =
    Css.style
      [ Css.fontSize (`px 42); Css.selector "& .div" [ Css.fontSize (`px 24) ] ]
  in
  let css = Css.render_style_tag () in
  Css.flush ();
  assert_string css
    " .css-rz74tm { font-size: 42px; } .css-rz74tm  .div { font-size: 24px; }"

let selector_ampersand_at_the_middle () =
  let _className =
    Css.style
      [ Css.fontSize (`px 42)
      ; Css.selector "& div &" [ Css.fontSize (`px 24) ]
      ]
  in
  let css = Css.render_style_tag () in
  Css.flush ();
  assert_string css
    " .css-oitwqf { font-size: 42px; } .css-oitwqf  div .css-oitwqf { \
     font-size: 24px; }"

let media_queries () =
  let _className =
    Css.style
      [ Css.maxWidth (`px 800)
      ; Css.media "(max-width: 768px)" [ Css.width (`px 300) ]
      ]
  in
  let css = Css.render_style_tag () in
  Css.flush ();
  assert_string css
    " .css-czgfdn { max-width: 800px; } @media (max-width: 768px) { \
     .css-czgfdn { width: 300px; } }"

(* let media_queries_nested () =
   let _className =
     style
       [ Css.maxWidth (`px 800)
       ; Css.media "(max-width: 768px)"
           [ Css.width (`px 300)
           ; Css.media "(min-width: 400px)"
               [ Css.width (`px 300) ]
           ]
       ]
   in
   let css = Css.render_style_tag () in
   assert_string css
     ".s2073633259 { max-width: 800px; } @media (max-width: 768px) { \
      .s2073633259 { width: 300px; } }"
*)
let selector_params () =
  let _className =
    Css.style [ Css.maxWidth (`px 800); Css.firstChild [ Css.width (`px 300) ] ]
  in
  let css = Css.render_style_tag () in
  Css.flush ();
  assert_string css
    " .css-39mqrq { max-width: 800px; } .css-39mqrq:first-child { width: \
     300px; }"

let keyframe () =
  let loading = "random" in
  (* let loading =
       Css.keyframes
         [ (0, [ Css.transform (`rotate (`deg 0.)) ])
         ; (100, [ Css.transform (`rotate (`deg (-360.))) ])
         ]
     in *)
  let _className = Css.style [ Css.animationName loading ] in
  let css = Css.render_style_tag () in
  Css.flush ();
  assert_string css
    " .css-7t1ji0 { -webkit-animation-name: random; animation-name: random; }"

let with_react () =
  let className = Css.style [ Css.display `block ] in
  let css = Css.render_style_tag () in
  Css.flush ();
  let head =
    React.createElement "head" [||]
      [ React.createElement "style" [||] [ React.string css ] ]
  in
  let body =
    React.createElement "body" [||]
      [ React.createElement "div"
          [| React.Attribute.String ("className", className) |]
          []
      ]
  in
  let app = React.createElement "html" [||] [ head; body ] in
  assert_string
    (ReactDOM.renderToStaticMarkup app)
    "<html><head><style> .css-etlvsf { display: block; \
     }</style></head><body><div class=\"css-etlvsf\"></div></body></html>"

let empty () =
  let className = Css.style [] in
  Css.flush ();
  assert_string className "css-"

let case title fn = Alcotest.test_case title `Quick fn

let tests =
  ( "Emotion"
  , [ case "one_property" one_property
    ; case "multiple_properties" multiple_properties
    ; case "float_values" float_values
    ; case "selector_one_nesting" selector_one_nesting
    ; case "selector_more_than_one_nesting" selector_more_than_one_nesting
    ; case "selector_with_a_lot_of_nesting" selector_with_a_lot_of_nesting
    ; case "media_queries" media_queries
      (* ; case "media_queries_nested" media_queries_nested *)
    ; case "selector_ampersand" selector_ampersand
    ; case "selector_ampersand_at_the_middle" selector_ampersand_at_the_middle
    ; case "selector_params" selector_params
    ; case "keyframe" keyframe
    ; case "with_react_component" with_react
    ; case "emtpy" empty
    ] )

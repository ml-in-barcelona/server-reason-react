open Alcotest

let assert_string left right = (check string) "should be equal" right left

let test_one_property () =
  let _className = Css.style [ Css.display `block ] in
  let css = Css.render_style_tag () in
  Css.flush ();
  assert_string css " .css-42f7af95 { display: block; }"

let test_multiple_properties () =
  let _className = Css.style [ Css.display `block; Css.fontSize (`px 10) ] in
  let css = Css.render_style_tag () in
  Css.flush ();
  assert_string css " .css-164ffa0 { display: block; font-size: 10px; }"

let test_selector_one_nesting () =
  let _className =
    Css.style
      [ Css.color Css.aliceblue
      ; Css.selector "a" [ Css.color Css.rebeccapurple ]
      ]
  in
  let css = Css.render_style_tag () in
  Css.flush ();
  assert_string css
    " .css-136b0184 { color: #F0F8FF; } .css-136b0184 a { color: #663399;  }"

let test_selector_more_than_one_nesting () =
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
    " .css-3c3ab5a { color: #F0F8FF; } .css-3c3ab5a a { display: block;  } \
     .css-3c3ab5a a div { display: none;  }"

let test_selector_with_a_lot_of_nesting () =
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
    " .css-57dfd065 { display: flex; } .css-57dfd065 a { display: block;  } \
     .css-57dfd065 a div { display: none;  } .css-57dfd065 a div span { \
     display: none;  } .css-57dfd065 a div span hr { display: none;  } \
     .css-57dfd065 a div span hr code { display: none;  }"

let test_selector_ampersand () =
  let _className =
    Css.style
      [ Css.fontSize (`px 42); Css.selector "& .div" [ Css.fontSize (`px 24) ] ]
  in
  let css = Css.render_style_tag () in
  Css.flush ();
  assert_string css
    " .css-2bc2e528 { font-size: 42px; } .css-2bc2e528  .div { font-size: \
     24px;  }"

let test_selector_ampersand_at_the_middle () =
  let _className =
    Css.style
      [ Css.fontSize (`px 42)
      ; Css.selector "& div &" [ Css.fontSize (`px 24) ]
      ]
  in
  let css = Css.render_style_tag () in
  Css.flush ();
  assert_string css
    " .css-42eeb071 { font-size: 42px; } .css-42eeb071 div .css-42eeb071 { \
     font-size: 24px;  }"

let test_media_queries () =
  let _className =
    Css.style
      [ Css.maxWidth (`px 800)
      ; Css.media "(max-width: 768px)" [ Css.width (`px 300) ]
      ]
  in
  let css = Css.render_style_tag () in
  Css.flush ();
  assert_string css
    " .css-42eeb071 { max-width: 800px; } @media (max-width: 768px) { \
     .css-42eeb071 { width: 300px;  } }"

(* let test_media_queries_nested () =
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
let test_selector_params () =
  let _className =
    Css.style [ Css.maxWidth (`px 800); Css.firstChild [ Css.width (`px 300) ] ]
  in
  let css = Css.render_style_tag () in
  Css.flush ();
  assert_string css
    " .css-13b21f82 { max-width: 800px; } .css-13b21f82:first-child { width: \
     300px;  }"

let test_keyframe () =
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
  assert_string css " .css-6f95f730 { animation-name: random; }"

let test_with_react () =
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
    "<html><head><style> .css-42f7af95 { display: block; \
     }</style></head><body><div class=\"css-42f7af95\"></div></body></html>"

let tests =
  ( "Emotion"
  , [ test_case "test_one_property" `Quick test_one_property
    ; test_case "test_multiple_properties" `Quick test_multiple_properties
    ; test_case "test_selector_one_nesting" `Quick test_selector_one_nesting
    ; test_case "test_selector_more_than_one_nesting" `Quick
        test_selector_more_than_one_nesting
    ; test_case "test_selector_with_a_lot_of_nesting" `Quick
        test_selector_with_a_lot_of_nesting
    ; test_case "test_media_queries" `Quick test_media_queries
      (* ; test_case "test_media_queries_nested" `Quick test_media_queries_nested *)
    ; test_case "test_selector_ampersand" `Quick test_selector_ampersand
    ; test_case "test_selector_params" `Quick test_selector_params
    ; test_case "test_keyframe" `Quick test_keyframe
    ; test_case "test_with_react_component" `Quick test_with_react
    ] )

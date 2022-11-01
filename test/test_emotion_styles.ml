open Alcotest

let assert_string left right = (check string) "should be equal" right left

let test_one_property () =
  let style = Emotion.create () in
  let _className = style [ Css.Properties.display `block ] in
  let css = Emotion.render_style_tag () in
  assert_string css ".s8509574055721759670 { display: block; }"

let test_multiple_properties () =
  let style = Emotion.create () in
  let _className =
    style [ Css.Properties.display `block; Css.Properties.fontSize (`px 10) ]
  in
  let css = Emotion.render_style_tag () in
  assert_string css ".s9188976592960551744 { display: block; font-size: 10px; }"

let test_selector_one_nesting () =
  let style = Emotion.create () in
  let _className =
    style
      [ Css.Properties.color Css.Colors.aliceblue
      ; Css.Properties.selector "a"
          [ Css.Properties.color Css.Colors.rebeccapurple ]
      ]
  in
  let css = Emotion.render_style_tag () in
  assert_string css
    ".s2630910063741011612 { color: #F0F8FF; } .s2630910063741011612 a { \
     color: #663399; }"

let test_selector_more_than_one_nesting () =
  let style = Emotion.create () in
  let _className =
    style
      [ Css.Properties.color Css.Colors.aliceblue
      ; Css.Properties.selector "a"
          [ Css.Properties.display `block
          ; Css.Properties.selector "div" [ Css.Properties.display `none ]
          ]
      ]
  in
  let css = Emotion.render_style_tag () in
  assert_string css
    ".s4013267212197328780 { color: #F0F8FF; } .s4013267212197328780 a { \
     display: block; } .s4013267212197328780 a div { display: none; }"

let test_selector_with_a_lot_of_nesting () =
  let style = Emotion.create () in
  let _className =
    style
      [ Css.Properties.display `flex
      ; Css.Properties.selector "a"
          [ Css.Properties.display `block
          ; Css.Properties.selector "div"
              [ Css.Properties.display `none
              ; Css.Properties.selector "span"
                  [ Css.Properties.display `none
                  ; Css.Properties.selector "hr"
                      [ Css.Properties.display `none
                      ; Css.Properties.selector "code"
                          [ Css.Properties.display `none ]
                      ]
                  ]
              ]
          ]
      ]
  in
  let css = Emotion.render_style_tag () in
  assert_string css
    ".s8087706279073073590 { display: flex; } .s8087706279073073590 a { \
     display: block; } .s8087706279073073590 a div { display: none; } \
     .s8087706279073073590 a div span { display: none; } .s8087706279073073590 \
     a div span hr { display: none; } .s8087706279073073590 a div span hr code \
     { display: none; }"

let test_with_react () =
  let style = Emotion.create () in
  let className = style [ Css.Properties.display `block ] in
  let css = Emotion.render_style_tag () in
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
    "<html><head><style>.s8509574055721759670 { display: block; \
     }</style></head><body><div \
     class=\"s8509574055721759670\"></div></body></html>"

let test_selector_ampersand () =
  let style = Emotion.create () in
  let _className =
    style
      [ Css.Properties.fontSize (`px 42)
      ; Css.Properties.selector "& .div" [ Css.Properties.fontSize (`px 24) ]
      ]
  in
  let css = Emotion.render_style_tag () in
  assert_string css
    ".s7041836792339950151 { font-size: 42px; } .s7041836792339950151 .div { \
     font-size: 24px; }"

let test_selector_ampersand_at_the_middle () =
  let style = Emotion.create () in
  let _className =
    style
      [ Css.Properties.fontSize (`px 42)
      ; Css.Properties.selector "& div &" [ Css.Properties.fontSize (`px 24) ]
      ]
  in
  let css = Emotion.render_style_tag () in
  assert_string css
    ".s8112958294750809463 { font-size: 42px; } .s8112958294750809463 div \
     .s8112958294750809463 { font-size: 24px; }"

let test_media_queries () =
  let style = Emotion.create () in
  let _className =
    style
      [ Css.Properties.maxWidth (`px 800)
      ; Css.Properties.media "(max-width: 768px)"
          [ Css.Properties.width (`px 300) ]
      ]
  in
  let css = Emotion.render_style_tag () in
  assert_string css
    ".s8112958294750809463 { max-width: 800px; } @media (max-width: 768px) { \
     .s8112958294750809463 { width: 300px; } }"

(* let test_media_queries_nested () =
   let style = Emotion.create () in
   let _className =
     style
       [ Css.Properties.maxWidth (`px 800)
       ; Css.Properties.media "(max-width: 768px)"
           [ Css.Properties.width (`px 300)
           ; Css.Properties.media "(min-width: 400px)"
               [ Css.Properties.width (`px 300) ]
           ]
       ]
   in
   let css = Emotion.render_style_tag () in
   assert_string css
     ".s2073633259 { max-width: 800px; } @media (max-width: 768px) { \
      .s2073633259 { width: 300px; } }"
*)
let test_selector_params () =
  let style = Emotion.create () in
  let _className =
    style
      [ Css.Properties.maxWidth (`px 800)
      ; Css.Properties.firstChild [ Css.Properties.width (`px 300) ]
      ]
  in
  let css = Emotion.render_style_tag () in
  assert_string css
    ".s2654165039198648687 { max-width: 800px; } \
     .s2654165039198648687:first-child { width: 300px; }"

let test_keyframe () =
  let style = Emotion.create () in
  let loading = "random" in
  (* let loading =
       Emotion.keyframes
         [ (0, [ Css.Properties.transform (`rotate (`deg 0.)) ])
         ; (100, [ Css.Properties.transform (`rotate (`deg (-360.))) ])
         ]
     in *)
  let _className = style [ Css.Properties.animationName loading ] in
  let css = Emotion.render_style_tag () in
  assert_string css ".s4414540036276571615 { animation-name: random; }"

let tests =
  ( "Emotion"
  , [ test_case "test_with_react_component" `Quick test_with_react
    ; test_case "test_one_property" `Quick test_one_property
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
    ] )

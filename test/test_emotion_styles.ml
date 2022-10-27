open Alcotest

let assert_string left right = (check string) "should be equal" right left

let test_one_property () =
  let style = Emotion.create () in
  let _className = style [| Css.Properties.display `block |] in
  let css = Emotion.render_style_tag () in
  assert_string css ".362999430 { display: block; }"

let test_multiple_properties () =
  let style = Emotion.create () in
  let _className =
    style [| Css.Properties.display `block; Css.Properties.fontSize (`px 10) |]
  in
  let css = Emotion.render_style_tag () in
  assert_string css ".1016840165 { display: block; font-size: 10px; }"

(* let test_different_emotion_instances () =
   let style1 = Emotion.create () in
   let style2 = Emotion.create () in
   let _className1 = style1 [| Css.Properties.color Css.Colors.red |] in
   let _className2 =
     style2 [| Css.Properties.color Css.Colors.rebeccapurple |]
   in
   let css = Emotion.render_style_tag () in
   assert_string css ".362999430 { display: block; }";
   assert_string css ".362999430 { display: block; }" *)

(* let test_with_react () =
   let style = Emotion.create () in
   let className = style [| Css.Properties.display `block |] in
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
     "<html><head><style>.362999430 { display: block; \
      }</style></head><body><div class=\"362999430\"></div></body></html>" *)

let tests =
  ( "Emotion"
  , [ (* test_case "test_with_react_component" `Quick test_with_react *)
      test_case "test_one_property" `Quick test_one_property
    ; test_case "test_multiple_properties" `Quick test_multiple_properties
    ] )

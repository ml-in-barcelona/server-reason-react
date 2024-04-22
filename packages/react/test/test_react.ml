let test title fn = Alcotest.test_case title `Quick fn

let assert_string left right =
  Alcotest.check Alcotest.string "should be equal" right left

let use_state_doesnt_fire () =
  let app =
    React.Upper_case_component
      (fun () ->
        let state, set_state = React.useState (fun () -> "foo") in
        (* You wouldn't have this code in prod, but just for testing purposes *)
        set_state (fun _prev -> "bar");
        React.createElement "div" [] [ React.string state ])
  in
  assert_string (ReactDOM.renderToStaticMarkup app) "<div>foo</div>"

let use_effect_doesnt_fire () =
  let app =
    React.Upper_case_component
      (fun () ->
        let ref = React.useRef "foo" in
        React.useEffect0 (fun () ->
            ref.current <- "bar";
            None);
        React.createElement "div" [] [ React.string ref.current ])
  in
  assert_string (ReactDOM.renderToStaticMarkup app) "<div>foo</div>"

module Gap = struct
  let make ~children =
    React.Children.map children (fun element ->
        if element = React.null then React.null
        else
          React.createElement "div"
            [ React.JSX.String ("class", "divider") ]
            [ element ])
end

let children_map_one_element () =
  let app =
    React.Upper_case_component
      (fun () -> Gap.make ~children:(React.string "foo"))
  in
  assert_string
    (ReactDOM.renderToStaticMarkup app)
    "<div class=\"divider\">foo</div>"

let children_map_list_element () =
  let app =
    React.Upper_case_component
      (fun () ->
        Gap.make
          ~children:(React.list [ React.string "foo"; React.string "lola" ]))
  in
  assert_string
    (ReactDOM.renderToStaticMarkup app)
    "<div class=\"divider\">foo</div><div class=\"divider\">lola</div>"

let tests =
  ( "React",
    [
      test "useState" use_state_doesnt_fire;
      test "useEffect" use_effect_doesnt_fire;
      test "Children.map" children_map_one_element;
      test "Children.map" children_map_list_element;
    ] )

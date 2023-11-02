let assert_string left right =
  Alcotest.check Alcotest.string "should be equal" right left

let use_state_doesnt_fire () =
  let app =
    React.Upper_case_component
      (fun () ->
        let state, set_state = React.useState (fun () -> "foo") in
        (* You wouldn't have this code in prod, but just for testing purposes *)
        set_state (fun _prev -> "bar");
        React.createElement "div" [||] [ React.string state ])
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
        React.createElement "div" [||] [ React.string ref.current ])
  in
  assert_string (ReactDOM.renderToStaticMarkup app) "<div>foo</div>"

let case title fn = Alcotest.test_case title `Quick fn

let tests =
  ( "React",
    [
      case "useState" use_state_doesnt_fire;
      case "useEffect" use_effect_doesnt_fire;
    ] )

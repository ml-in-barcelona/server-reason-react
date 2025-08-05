let test title fn = Alcotest.test_case title `Quick fn
let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left

let use_state_doesnt_fire () =
  let app =
    React.Upper_case_component
      ( "app",
        fun () ->
          let state, setState = React.useState (fun () -> "foo") in
          (* You wouldn't have this code in prod, but just for testing purposes *)
          setState (fun _prev -> "bar");
          React.createElement "div" [] [ React.string state ] )
  in
  assert_string (ReactDOM.renderToStaticMarkup app) "<div>foo</div>"

let use_sync_external_store_with_server () =
  let app =
    React.Upper_case_component
      ( "app",
        fun () ->
          let value =
            React.useSyncExternalStoreWithServer
              ~getServerSnapshot:(fun () -> "foo")
              ~subscribe:(fun _ () -> ())
              ~getSnapshot:(fun _ -> "bar")
          in
          React.createElement "div" [] [ React.string value ] )
  in
  assert_string (ReactDOM.renderToStaticMarkup app) "<div>foo</div>"

let use_effect_doesnt_fire () =
  let app =
    React.Upper_case_component
      ( "app",
        fun () ->
          let ref = React.useRef "foo" in
          React.useEffect0 (fun () ->
              ref.current <- "bar";
              None);
          React.createElement "div" [] [ React.string ref.current ] )
  in
  assert_string (ReactDOM.renderToStaticMarkup app) "<div>foo</div>"

module Gap = struct
  let make ~children =
    React.Children.map children (fun element ->
        if element = React.null then React.null
        else React.createElement "div" [ React.JSX.String ("class", "className", "divider") ] [ element ])
end

let children_map_one_element () =
  let app = React.Upper_case_component ("app", fun () -> Gap.make ~children:(React.string "foo")) in
  assert_string (ReactDOM.renderToStaticMarkup app) "<div class=\"divider\">foo</div>"

let children_map_list_element () =
  let app =
    React.Upper_case_component
      ("app", fun () -> Gap.make ~children:(React.list [ React.string "foo"; React.string "lola" ]))
  in
  assert_string (ReactDOM.renderToStaticMarkup app) "<div class=\"divider\">foo</div><div class=\"divider\">lola</div>"

let use_ref_works () =
  let app =
    React.Upper_case_component
      ( "app",
        fun () ->
          let isLive = React.useRef true in
          React.useEffect0 (fun () ->
              isLive.current <- false;
              None);
          React.createElement "span" [] [ React.string (string_of_bool isLive.current) ] )
  in
  assert_string (ReactDOM.renderToStaticMarkup app) "<span>true</span>"

let invalid_children () =
  let raises () =
    let _ = React.createElement "input" [ React.JSX.String ("type", "type", "text") ] [ React.string "Hellow" ] in
    ()
  in
  Alcotest.check_raises "Expected invalid argument"
    (React.Invalid_children {|"input" is a self-closing tag and must not have "children".\n|})
    raises

let invalid_dangerouslySetInnerHtml () =
  let raises () =
    let _ =
      React.createElement "meta"
        [ React.JSX.String ("char-set", "charSet", "utf-8"); React.JSX.DangerouslyInnerHtml "Hellow" ]
        []
    in
    ()
  in
  Alcotest.check_raises "Expected invalid argument"
    (React.Invalid_children {|"meta" is a self-closing tag and must not have "dangerouslySetInnerHTML".\n|})
    raises

let raw_element () =
  let app = React.Upper_case_component ("app", fun () -> React.DangerouslyInnerHtml "<div>Hello</div>") in
  assert_string (ReactDOM.renderToStaticMarkup app) "<div>Hello</div>"

let tests =
  ( "React",
    [
      test "useState" use_state_doesnt_fire;
      test "useSyncExternalStoreWithServer" use_sync_external_store_with_server;
      test "useEffect" use_effect_doesnt_fire;
      test "Children.map" children_map_one_element;
      test "Children.map" children_map_list_element;
      test "useRef" use_ref_works;
      test "invalid_children" invalid_children;
      test "invalid_dangerouslySetInnerHtml" invalid_dangerouslySetInnerHtml;
      test "raw_element" raw_element;
    ] )

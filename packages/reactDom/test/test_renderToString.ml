let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left

let react_root_one_element () =
  let div = React.createElement "div" [] [] in
  assert_string (ReactDOM.renderToString div) "<div></div>"

let react_root_two_elements () =
  let div = React.createElement "div" [] [ React.createElement "span" [] [] ] in
  assert_string (ReactDOM.renderToString div) "<div><span></span></div>"

let text_single_node () =
  let div = React.createElement "div" [] [ React.createElement "span" [] [ React.string "Hello" ] ] in
  assert_string (ReactDOM.renderToString div) "<div><span>Hello</span></div>"

let consecutives_text_nodes () =
  let div =
    React.createElement "div" [] [ React.createElement "span" [] [ React.string "Hello"; React.string "Hello" ] ]
  in
  assert_string (ReactDOM.renderToString div) "<div><span>Hello<!-- -->Hello</span></div>"

let separated_text_nodes_by_other_parents () =
  let app () =
    React.Upper_case_component
      ( "app",
        fun () ->
          React.list
            [
              React.createElement "main" [] [ React.string "Hi"; React.createElement "span" [] [ React.string "chat" ] ];
            ] )
  in
  assert_string (ReactDOM.renderToString (app ())) "<main>Hi<span>chat</span></main>"

let text_after_element_with_text_child () =
  let div =
    React.createElement "div" []
      [ React.string "before "; React.createElement "span" [] [ React.string "inner" ]; React.string " after" ]
  in
  assert_string (ReactDOM.renderToString div) "<div>before <span>inner</span> after</div>"

let suspense_children_render_once () =
  let render_count = ref 0 in
  let child () =
    React.Upper_case_component
      ( "Child",
        fun () ->
          render_count := !render_count + 1;
          React.createElement "div" [] [ React.string "hello" ] )
  in
  let el =
    React.Suspense
      { key = None; children = child (); fallback = Some (React.createElement "div" [] [ React.string "loading" ]) }
  in
  let html = ReactDOM.renderToString el in
  assert_string html "<!--$--><div>hello</div><!--/$-->";
  Alcotest.(check int) "children should render exactly once" 1 !render_count

let suspense_fallback_on_error () =
  let el =
    React.Suspense
      {
        key = None;
        children = React.Upper_case_component ("Throws", fun () -> raise (Failure "boom"));
        fallback = Some (React.createElement "div" [] [ React.string "fallback" ]);
      }
  in
  let html = ReactDOM.renderToString el in
  assert_string html "<!--$!--><div>fallback</div><!--/$-->"

let context_default_survives_provider_child_throw () =
  let context = React.createContext "default" in
  let first =
    React.Suspense
      {
        key = None;
        children =
          React.Context.provider context
            (React.Context.makeProps ~value:"provided"
               ~children:(React.Upper_case_component ("Throws", fun () -> raise (Failure "boom")))
               ());
        fallback = Some (React.string "fallback");
      }
  in
  assert_string (ReactDOM.renderToString first) "<!--$!-->fallback<!--/$-->";
  let second = React.Upper_case_component ("Reader", fun () -> React.string (React.useContext context)) in
  assert_string (ReactDOM.renderToString second) "default"

let inline_style_escaping () =
  (* A quoted CSS value must be escaped so it doesn't terminate the style="..."
     attribute early and drop the following custom properties. *)
  let style = ReactDOMStyle.unsafeAddProp (ReactDOMStyle.make ~padding:"8px" ()) "--font" {|"Ahrefs", sans-serif|} in
  let div = React.createElement "div" [ React.JSX.style style ] [] in
  assert_string (ReactDOM.renderToString div) {|<div style="padding:8px;--font:&quot;Ahrefs&quot;, sans-serif"></div>|}

let inline_style_empty_value_skipped () =
  (* [""] here lives in this compilation unit, so a [v == ""] check inside
     ReactDOMStyle wouldn't skip it (string constants are only shared per
     unit). Regression test for the structural check. *)
  let style = ReactDOMStyle.make ~color:"" ~padding:"8px" () in
  let div = React.createElement "div" [ React.JSX.style style ] [] in
  assert_string (ReactDOM.renderToString div) {|<div style="padding:8px"></div>|}

let default_checked_and_value_render_as_checked_and_value () =
  (* React maps defaultChecked/defaultValue to the checked/value DOM attributes on server output *)
  let props = ReactDOM.domProps ~defaultChecked:true ~defaultValue:"hello" () in
  let input = React.createElement "input" props [] in
  assert_string (ReactDOM.renderToString input) {|<input value="hello" checked />|}

let xlink_and_xmlns_props_render_with_colon_names () =
  (* xlinkActuate/xlinkArcrole/xmlnsXlink render as xlink:actuate/xlink:arcrole/xmlns:xlink, matching React *)
  let props =
    ReactDOM.domProps ~xlinkActuate:"onLoad" ~xlinkArcrole:"arc" ~xmlnsXlink:"http://www.w3.org/1999/xlink" ()
  in
  let use = React.createElement "use" props [] in
  assert_string (ReactDOM.renderToString use)
    {|<use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:arcrole="arc" xlink:actuate="onLoad"></use>|}

let test title fn = (Printf.sprintf "ReactDOM.renderToString / %s" title, [ Alcotest_lwt.test_case_sync "" `Quick fn ])

let tests =
  [
    test "react_root_one_element" react_root_one_element;
    test "react_root_two_elements" react_root_two_elements;
    test "text_single_node should not add <!-- -->" text_single_node;
    test "consecutives_text_nodes should add <!-- -->" consecutives_text_nodes;
    test "separated_text_nodes_by_other_parents" separated_text_nodes_by_other_parents;
    test "text_after_element_with_text_child" text_after_element_with_text_child;
    test "suspense children render exactly once" suspense_children_render_once;
    test "suspense renders fallback on error" suspense_fallback_on_error;
    test "context default survives provider child throw" context_default_survives_provider_child_throw;
    test "inline style escaping" inline_style_escaping;
    test "inline style empty value skipped" inline_style_empty_value_skipped;
    test "defaultChecked/defaultValue render as checked/value" default_checked_and_value_render_as_checked_and_value;
    test "xlink/xmlns props render with colon names" xlink_and_xmlns_props_render_with_colon_names;
  ]

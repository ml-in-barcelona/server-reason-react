let equal_attrs (a1 : React.JSX.prop) (a2 : React.JSX.prop) =
  match (a1, a2) with
  | Bool (k1, x1, v1), Bool (k2, x2, v2) -> k1 == k2 && x1 == x2 && v1 = v2
  | String (k1, x1, v1), String (k2, x2, v2) -> k1 == k2 && x1 == x2 && v1 == v2
  | Style s1, Style s2 -> s1 == s2
  | DangerouslyInnerHtml s1, DangerouslyInnerHtml s2 -> s1 == s2
  | Event (k1, _v1), Event (k2, _v2) -> k1 == k2
  | _ -> false

let equal_elements (c1 : React.element) (c2 : React.element) =
  let rec equal_rec (c1 : React.element) (c2 : React.element) =
    match (c1, c2) with
    | Lower_case_element lc1, Lower_case_element lc2 ->
        lc1.tag == lc2.tag
        && List.for_all2 equal_rec lc1.children lc2.children
        && List.for_all2 equal_attrs lc1.attributes lc2.attributes
    | Upper_case_component (name1, cf1), Upper_case_component (name2, cf2) ->
        name1 == name2 && equal_rec (cf1 ()) (cf2 ())
    | List cl1, List cl2 -> List.for_all2 equal_rec cl1 cl2
    | Array cl1, Array cl2 -> Array.for_all2 equal_rec cl1 cl2
    | Text t1, Text t2 -> t1 == t2
    | Fragment fl1, Fragment fl2 -> equal_rec fl1 fl2
    | Empty, Empty -> true
    | Static { original = original1; prerendered = _ }, Static { original = original2; prerendered = _ } ->
        equal_rec original1 original2
    | Writer { original = original1; emit = _ }, Writer { original = original2; emit = _ } ->
        equal_rec (original1 ()) (original2 ())
    | _, _ -> false
  in
  equal_rec c1 c2

let assert_element left right = Alcotest.(check bool) "should be equal" true (equal_elements left right)

let clone_empty () =
  let element = React.createElement "div" [ React.JSX.Bool ("hidden", "hidden", true) ] [] in
  assert_element element (React.cloneElement element [])

let clone_attributes () =
  let element = React.createElement "div" [ React.JSX.String ("val", "val", "33") ] [] in
  let expected =
    React.createElement "div" [ React.JSX.String ("val", "val", "31"); React.JSX.Bool ("lola", "lola", true) ] []
  in
  let cloned =
    React.cloneElement element [ React.JSX.Bool ("lola", "lola", true); React.JSX.String ("val", "val", "31") ]
  in
  assert_element cloned expected

let clone_order_attributes () =
  let element = React.createElement "div" [] [] in
  (* spread semantics: new attributes are appended in their original order *)
  let expected =
    React.createElement "div" [ React.JSX.Bool ("lola", "lola", true); React.JSX.String ("val", "val", "31") ] []
  in
  let cloned =
    React.cloneElement element [ React.JSX.Bool ("lola", "lola", true); React.JSX.String ("val", "val", "31") ]
  in
  assert_element cloned expected

let clone_uppercase_component_raises () =
  let element = React.Upper_case_component ("MyComponent", fun () -> React.null) in
  Alcotest.check_raises "cloneElement with uppercase component raises Invalid_argument"
    (Invalid_argument
       "React.cloneElement: cannot clone 'MyComponent'. In server-reason-react, component props are compile-time \
        labelled arguments (and extending them with new props at runtime is not supported). React.cloneElement only \
        works with lowercase DOM elements.") (fun () -> ignore (React.cloneElement element []))

let clone_async_component_raises () =
  let element = React.Async_component ("AsyncComponent", fun () -> Lwt.return React.null) in
  Alcotest.check_raises "cloneElement with async component raises Invalid_argument"
    (Invalid_argument
       "React.cloneElement: cannot clone 'AsyncComponent'. In server-reason-react, component props are compile-time \
        labelled arguments (and extending them with new props at runtime is not supported). React.cloneElement only \
        works with lowercase DOM elements.") (fun () -> ignore (React.cloneElement element []))

let clone_client_component_raises () =
  let element =
    React.Client_component
      {
        key = None;
        props = [];
        client = React.null;
        import_module = "./MyClient.js";
        import_name = "MyClientComponent";
      }
  in
  Alcotest.check_raises "cloneElement with client component raises Invalid_argument"
    (Invalid_argument
       "React.cloneElement: cannot clone 'MyClientComponent'. In server-reason-react, component props are compile-time \
        labelled arguments (and extending them with new props at runtime is not supported). React.cloneElement only \
        works with lowercase DOM elements.") (fun () -> ignore (React.cloneElement element []))

let clone_static_unwraps () =
  let original = React.createElement "div" [ React.JSX.Bool ("hidden", "hidden", true) ] [] in
  let static_element = React.Static { prerendered = {|<div hidden=""></div>|}; original } in
  let cloned = React.cloneElement static_element [] in
  assert_element cloned original

let clone_static_with_new_attributes () =
  let original = React.createElement "div" [ React.JSX.String ("id", "id", "root") ] [] in
  let static_element = React.Static { prerendered = {|<div id="root"></div>|}; original } in
  let cloned = React.cloneElement static_element [ React.JSX.String ("class", "className", "container") ] in
  (* spread semantics: base attributes first, new attributes appended *)
  let expected =
    React.createElement "div"
      [ React.JSX.String ("id", "id", "root"); React.JSX.String ("class", "className", "container") ]
      []
  in
  assert_element cloned expected

let clone_static_overrides_attributes () =
  let original = React.createElement "span" [ React.JSX.String ("id", "id", "old") ] [] in
  let static_element = React.Static { prerendered = {|<span id="old"></span>|}; original } in
  let cloned = React.cloneElement static_element [ React.JSX.String ("id", "id", "new") ] in
  let expected = React.createElement "span" [ React.JSX.String ("id", "id", "new") ] [] in
  assert_element cloned expected

let clone_static_result_is_not_static () =
  let original = React.createElement "div" [] [] in
  let static_element = React.Static { prerendered = "<div></div>"; original } in
  let cloned = React.cloneElement static_element [] in
  match cloned with
  | React.Lower_case_element _ -> ()
  | React.Static _ -> Alcotest.fail "cloneElement on Static should return a Lower_case_element, not Static"
  | _ -> Alcotest.fail "cloneElement on Static should return a Lower_case_element"

let clone_static_preserves_children () =
  let children = [ React.createElement "span" [] []; React.string "hello" ] in
  let original = React.createElement "div" [ React.JSX.String ("id", "id", "parent") ] children in
  let static_element = React.Static { prerendered = {|<div id="parent"><span></span>hello</div>|}; original } in
  let cloned = React.cloneElement static_element [ React.JSX.String ("class", "className", "wrapper") ] in
  (* spread semantics: base attributes first, new attributes appended *)
  let expected =
    React.createElement "div"
      [ React.JSX.String ("id", "id", "parent"); React.JSX.String ("class", "className", "wrapper") ]
      children
  in
  assert_element cloned expected

let clone_nested_static () =
  let inner_original = React.createElement "p" [ React.JSX.String ("id", "id", "inner") ] [] in
  let inner_static = React.Static { prerendered = {|<p id="inner"></p>|}; original = inner_original } in
  let outer_original = React.createElement "div" [] [ inner_static ] in
  let outer_static = React.Static { prerendered = {|<div><p id="inner"></p></div>|}; original = outer_original } in
  let cloned = React.cloneElement outer_static [ React.JSX.Bool ("hidden", "hidden", true) ] in
  let expected = React.createElement "div" [ React.JSX.Bool ("hidden", "hidden", true) ] [ inner_static ] in
  assert_element cloned expected

let clone_preserves_style_and_event () =
  let styles = [ ("color", "color", "red") ] in
  let on_click = React.JSX.Event ("onClick", React.JSX.Mouse (fun _ -> ())) in
  let element =
    React.createElement "button" [ React.JSX.Style styles; on_click; React.JSX.String ("name", "name", "submit") ] []
  in
  let cloned = React.cloneElement element [ React.JSX.String ("id", "id", "cta") ] in
  let expected =
    React.createElement "button"
      [
        React.JSX.Style styles;
        on_click;
        React.JSX.String ("name", "name", "submit");
        React.JSX.String ("id", "id", "cta");
      ]
      []
  in
  assert_element cloned expected

let clone_override_keeps_base_position () =
  let element =
    React.createElement "div"
      [ React.JSX.String ("class", "className", "a"); React.JSX.Bool ("hidden", "hidden", true) ]
      []
  in
  let cloned = React.cloneElement element [ React.JSX.String ("class", "className", "b") ] in
  let expected =
    React.createElement "div"
      [ React.JSX.String ("class", "className", "b"); React.JSX.Bool ("hidden", "hidden", true) ]
      []
  in
  assert_element cloned expected;
  Alcotest.(check string) "renders overridden class" {|<div class="b" hidden></div>|} (ReactDOM.renderToString cloned)

let clone_preserves_attribute_order () =
  let element =
    React.createElement "div"
      [ React.JSX.String ("a", "a", "1"); React.JSX.String ("b", "b", "2"); React.JSX.String ("c", "c", "3") ]
      []
  in
  let cloned = React.cloneElement element [ React.JSX.String ("d", "d", "4") ] in
  let expected =
    React.createElement "div"
      [
        React.JSX.String ("a", "a", "1");
        React.JSX.String ("b", "b", "2");
        React.JSX.String ("c", "c", "3");
        React.JSX.String ("d", "d", "4");
      ]
      []
  in
  assert_element cloned expected

let clone_preserves_dangerously_inner_html () =
  let html = "<strong>hi</strong>" in
  let element = React.createElement "div" [ React.JSX.DangerouslyInnerHtml html ] [] in
  let cloned = React.cloneElement element [ React.JSX.String ("id", "id", "raw") ] in
  let expected =
    React.createElement "div" [ React.JSX.DangerouslyInnerHtml html; React.JSX.String ("id", "id", "raw") ] []
  in
  assert_element cloned expected

let case title fn = Alcotest.test_case title `Quick fn

let tests =
  ( "cloneElement",
    [
      case "empty component" clone_empty;
      case "attributes component" clone_attributes;
      case "ordered attributes component" clone_order_attributes;
      case "uppercase component raises" clone_uppercase_component_raises;
      case "async component raises" clone_async_component_raises;
      case "client component raises" clone_client_component_raises;
      case "static unwraps to original" clone_static_unwraps;
      case "static adds new attributes" clone_static_with_new_attributes;
      case "static overrides existing attributes" clone_static_overrides_attributes;
      case "static result is Lower_case_element not Static" clone_static_result_is_not_static;
      case "static preserves children" clone_static_preserves_children;
      case "static nested static unwraps outer only" clone_nested_static;
      case "style and event props survive a clone" clone_preserves_style_and_event;
      case "override replaces value in base position" clone_override_keeps_base_position;
      case "base order preserved, new attributes appended" clone_preserves_attribute_order;
      case "dangerouslySetInnerHTML survives a clone" clone_preserves_dangerously_inner_html;
    ] )

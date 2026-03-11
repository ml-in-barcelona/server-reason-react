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
  let expected =
    React.createElement "div" [ React.JSX.String ("val", "val", "31"); React.JSX.Bool ("lola", "lola", true) ] []
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
      { props = []; client = React.null; import_module = "./MyClient.js"; import_name = "MyClientComponent" }
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
  let expected =
    React.createElement "div"
      [ React.JSX.String ("class", "className", "container"); React.JSX.String ("id", "id", "root") ]
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
  let expected =
    React.createElement "div"
      [ React.JSX.String ("class", "className", "wrapper"); React.JSX.String ("id", "id", "parent") ]
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
    ] )

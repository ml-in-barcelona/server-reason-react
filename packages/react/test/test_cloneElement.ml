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
    | _ -> false
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
    ] )

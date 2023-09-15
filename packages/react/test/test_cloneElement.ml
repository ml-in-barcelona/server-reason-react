let equal_attrs (a1 : React.JSX.prop) (a2 : React.JSX.prop) =
  match (a1, a2) with
  | Bool (k1, v1), Bool (k2, v2) -> k1 == k2 && v1 = v2
  | String (k1, v1), String (k2, v2) -> k1 == k2 && v1 == v2
  | Style s1, Style s2 -> s1 == s2
  | DangerouslyInnerHtml s1, DangerouslyInnerHtml s2 -> s1 == s2
  (* Can't compare functions ^^ *)
  | Event (k1, _v1), Event (k2, _v2) -> k1 == k2
  | _ -> false

let equal_components (c1 : React.element) (c2 : React.element) =
  let rec equal_rec (c1 : React.element) (c2 : React.element) =
    match (c1, c2) with
    | Lower_case_element lc1, Lower_case_element lc2 ->
        lc1.tag == lc2.tag
        && List.for_all2 equal_rec lc1.children lc2.children
        && Array.for_all2 equal_attrs lc1.attributes lc2.attributes
    | Upper_case_component cf1, Upper_case_component cf2 ->
        equal_rec (cf1 ()) (cf2 ())
    | List cl1, List cl2 -> Array.for_all2 equal_rec cl1 cl2
    | Text t1, Text t2 -> t1 == t2
    | Fragment fl1, Fragment fl2 -> equal_rec fl1 fl2
    | Empty, Empty -> true
    | _ -> false
  in
  equal_rec c1 c2

let component =
  Alcotest.testable
    (fun ppf v ->
      Fmt.string ppf (Printf.sprintf "%s" (ReactDOM.renderToStaticMarkup v)))
    equal_components

let assert_component left right =
  (Alcotest.check component) "should be equal" right left

let clone_empty () =
  let component =
    React.createElement "div" [| React.JSX.Bool ("hidden", true) |] []
  in
  assert_component component (React.cloneElement component [||] [])

let clone_attributes () =
  let component =
    React.createElement "div" [| React.JSX.String ("val", "33") |] []
  in
  let expected =
    React.createElement "div"
      [| React.JSX.String ("val", "31"); React.JSX.Bool ("lola", true) |]
      []
  in
  let cloned =
    React.cloneElement component
      [| React.JSX.Bool ("lola", true); React.JSX.String ("val", "31") |]
      []
  in
  assert_component cloned expected

let clone_order_attributes () =
  let component = React.createElement "div" [||] [] in
  let expected =
    React.createElement "div"
      [| React.JSX.String ("val", "31"); React.JSX.Bool ("lola", true) |]
      []
  in
  let cloned =
    React.cloneElement component
      [| React.JSX.Bool ("lola", true); React.JSX.String ("val", "31") |]
      []
  in
  assert_component cloned expected

let case title fn = Alcotest.test_case title `Quick fn

let tests =
  ( (* FIXME: those test shouldn't rely on renderToStaticMarkup,
       make an alcotest TESTABLE component *)
    "cloneElement",
    [
      case "empty component" clone_empty;
      case "attributes component" clone_attributes;
      case "ordered attributes component" clone_order_attributes;
    ] )

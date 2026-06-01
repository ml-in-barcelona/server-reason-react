open Ppxlib

let loc = Location.none
let jsx_attr = { attr_name = { txt = "JSX"; loc }; attr_payload = PStr []; attr_loc = loc }
let with_jsx expr = { expr with pexp_attributes = [ jsx_attr ] }
let lowercase_jsx_apply = with_jsx [%expr div ()]
let uppercase_jsx_apply = with_jsx [%expr Uppercase.make ()]

let pp_arg_label fmt = function
  | Nolabel -> Format.pp_print_string fmt "Nolabel"
  | Labelled label -> Format.fprintf fmt "Labelled %S" label
  | Optional label -> Format.fprintf fmt "Optional %S" label

let arg_label_to_string label = Format.asprintf "%a" pp_arg_label label

let attribute_to_string (label, expr) =
  Printf.sprintf "%s: %s" (arg_label_to_string label) (Pprintast.string_of_expression expr)

let assert_list expected actual =
  Alcotest.(check (list string))
    "expanded attributes" (List.map attribute_to_string expected) (List.map attribute_to_string actual)

let expand_attributes apply_expr attributes =
  let apply_expr =
    match apply_expr.pexp_desc with
    | Pexp_apply (fn, _) -> { apply_expr with pexp_desc = Pexp_apply (fn, attributes) }
    | _ -> apply_expr
  in
  match (Styles_attribute.expand apply_expr).pexp_desc with
  | Pexp_apply (_, attributes) -> attributes
  | _ -> Alcotest.fail "Expected an apply expression"

let test_expand_styles () =
  let expr = [%expr lola] in
  let attributes = [ (Labelled "styles", expr) ] in
  let expanded_attributes = expand_attributes lowercase_jsx_apply attributes in

  assert_list [ (Labelled "className", [%expr fst lola]); (Labelled "style", [%expr snd lola]) ] expanded_attributes

let test_expand_styles_with_previous_className () =
  let expr = [%expr generated_styles] in
  let attributes = [ (Labelled "className", [%expr "previous-class-name"]); (Labelled "styles", expr) ] in
  let expanded_attributes = expand_attributes lowercase_jsx_apply attributes in
  assert_list
    [
      (Labelled "className", [%expr fst generated_styles ^ " " ^ "previous-class-name"]);
      (Labelled "style", [%expr snd generated_styles]);
    ]
    expanded_attributes

let test_expand_styles_with_previous_style () =
  let expr = [%expr generated_styles] in
  let attributes = [ (Labelled "style", [%expr "previous-style"]); (Labelled "styles", expr) ] in
  let expanded_attributes = expand_attributes lowercase_jsx_apply attributes in
  assert_list
    [
      (Labelled "className", [%expr fst generated_styles]);
      (Labelled "style", [%expr ReactDOM.Style.combine "previous-style" (snd generated_styles)]);
    ]
    expanded_attributes

let test_expand_styles_optional () =
  let expr = [%expr Some generated_styles] in
  let attributes = [ (Optional "styles", expr) ] in
  let expanded_attributes = expand_attributes lowercase_jsx_apply attributes in
  assert_list
    [
      (Optional "className", [%expr match Some generated_styles with None -> None | Some x -> Some (fst x)]);
      (Optional "style", [%expr match Some generated_styles with None -> None | Some x -> Some (snd x)]);
    ]
    expanded_attributes

let test_does_not_expand_without_jsx () =
  let expr = [%expr generated_styles] in
  let attributes = [ (Labelled "styles", expr) ] in
  let expanded_attributes = expand_attributes [%expr div ()] attributes in
  assert_list [ (Labelled "styles", expr) ] expanded_attributes

let test_does_not_expand_uppercase_jsx () =
  let expr = [%expr generated_styles] in
  let attributes = [ (Labelled "styles", expr) ] in
  let expanded_attributes = expand_attributes uppercase_jsx_apply attributes in
  assert_list [ (Labelled "styles", expr) ] expanded_attributes

let test title fn = (title, [ Alcotest.test_case "" `Quick fn ])

let () =
  Alcotest.run "expand_styles_attribute"
    [
      test "expand_styles_prop_on_attributes" test_expand_styles;
      test "expand_styles_with_previous_className" test_expand_styles_with_previous_className;
      test "expand_styles_with_previous_style" test_expand_styles_with_previous_style;
      test "expand_styles_optional" test_expand_styles_optional;
      test "does_not_expand_without_jsx" test_does_not_expand_without_jsx;
      test "does_not_expand_uppercase_jsx" test_does_not_expand_uppercase_jsx;
    ]

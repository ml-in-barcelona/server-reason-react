let loc = Ppxlib.Location.none
let jsx_attr = { Ppxlib.attr_name = { txt = "JSX"; loc }; attr_payload = Ppxlib.PStr []; attr_loc = loc }
let with_jsx expr = { expr with Ppxlib.pexp_attributes = [ jsx_attr ] }
let lowercase_jsx_apply = with_jsx [%expr div ()]
let uppercase_jsx_apply = with_jsx [%expr Uppercase.make ()]

let test_expand_styles () =
  let expr = [%expr "some-class-name", ReactDOM.Style.make ~backgroundColor:"gainsboro" ()] in
  let attributes = [ (Ppxlib.Labelled "styles", expr) ] in
  let expanded_attributes = Expand_styles_attribute.make ~loc ~apply_expr:lowercase_jsx_apply attributes in

  List.iter
    (fun attribute ->
      match attribute with
      | ( Ppxlib.Labelled "className",
          [%expr fst ("some-class-name", ReactDOM.Style.make ~backgroundColor:"gainsboro" ())] ) ->
          Alcotest.(check pass) "className uses fst" () ()
      | Ppxlib.Labelled "style", [%expr snd ("some-class-name", ReactDOM.Style.make ~backgroundColor:"gainsboro" ())] ->
          Alcotest.(check pass) "style uses snd" () ()
      | _ -> Alcotest.fail "Expanded attributes should be className and style")
    expanded_attributes

let test_expand_styles_with_previous_className () =
  let expr = [%expr "some-class-name", ReactDOM.Style.make ~backgroundColor:"gainsboro" ()] in
  let attributes = [ (Ppxlib.Labelled "className", [%expr "previous-class-name"]); (Ppxlib.Labelled "styles", expr) ] in
  let expanded_attributes = Expand_styles_attribute.make ~loc ~apply_expr:lowercase_jsx_apply attributes in
  List.iter
    (fun attribute ->
      match attribute with
      | ( Ppxlib.Labelled "className",
          [%expr
            fst ("some-class-name", ReactDOM.Style.make ~backgroundColor:"gainsboro" ()) ^ " " ^ "previous-class-name"]
        ) ->
          Alcotest.(check pass) "className uses previous class name" () ()
      | Ppxlib.Labelled "style", [%expr snd ("some-class-name", ReactDOM.Style.make ~backgroundColor:"gainsboro" ())] ->
          Alcotest.(check pass) "style uses combine" () ()
      | _ -> Alcotest.fail "Expanded attributes should be className and style")
    expanded_attributes

let test_expand_styles_with_previous_style () =
  let expr = [%expr "some-class-name", ReactDOM.Style.make ~backgroundColor:"gainsboro" ()] in
  let attributes = [ (Ppxlib.Labelled "style", [%expr "previous-style"]); (Ppxlib.Labelled "styles", expr) ] in
  let expanded_attributes = Expand_styles_attribute.make ~loc ~apply_expr:lowercase_jsx_apply attributes in
  List.iter
    (fun attribute ->
      match attribute with
      | ( Ppxlib.Labelled "className",
          [%expr fst ("some-class-name", ReactDOM.Style.make ~backgroundColor:"gainsboro" ())] ) ->
          Alcotest.(check pass) "className uses fst" () ()
      | ( Ppxlib.Labelled "style",
          [%expr
            ReactDOM.Style.combine "previous-style"
              (snd ("some-class-name", ReactDOM.Style.make ~backgroundColor:"gainsboro" ()))] ) ->
          Alcotest.(check pass) "style uses combine" () ()
      | _ -> Alcotest.fail "Expanded attributes should be className and style")
    expanded_attributes

let test_expand_styles_optional () =
  let expr = [%expr Some ("some-class-name", ReactDOM.Style.make ~backgroundColor:"gainsboro" ())] in
  let attributes = [ (Ppxlib.Optional "styles", expr) ] in
  let expanded_attributes = Expand_styles_attribute.make ~loc ~apply_expr:lowercase_jsx_apply attributes in
  List.iter
    (fun attribute ->
      match attribute with
      | ( Ppxlib.Optional "className",
          [%expr
            match Some ("some-class-name", ReactDOM.Style.make ~backgroundColor:"gainsboro" ()) with
            | None -> None
            | Some x -> Some (fst x)] ) ->
          Alcotest.(check pass) "className uses fst" () ()
      | ( Ppxlib.Optional "style",
          [%expr
            match Some ("some-class-name", ReactDOM.Style.make ~backgroundColor:"gainsboro" ()) with
            | None -> None
            | Some x -> Some (snd x)] ) ->
          Alcotest.(check pass) "style uses snd" () ()
      | _ -> Alcotest.fail "Expanded attributes should be className and style")
    expanded_attributes

let test_does_not_expand_without_jsx () =
  let expr = [%expr "some-class-name", ReactDOM.Style.make ~backgroundColor:"gainsboro" ()] in
  let attributes = [ (Ppxlib.Labelled "styles", expr) ] in
  let expanded_attributes = Expand_styles_attribute.make ~loc ~apply_expr:[%expr div ()] attributes in
  Alcotest.(check int) "keeps the original styles prop" 1 (List.length expanded_attributes);
  match expanded_attributes with
  | [ (Ppxlib.Labelled "styles", _) ] -> Alcotest.(check pass) "styles remains untouched" () ()
  | _ -> Alcotest.fail "styles should not expand without a JSX attribute"

let test_does_not_expand_uppercase_jsx () =
  let expr = [%expr "some-class-name", ReactDOM.Style.make ~backgroundColor:"gainsboro" ()] in
  let attributes = [ (Ppxlib.Labelled "styles", expr) ] in
  let expanded_attributes = Expand_styles_attribute.make ~loc ~apply_expr:uppercase_jsx_apply attributes in
  Alcotest.(check int) "keeps the original styles prop" 1 (List.length expanded_attributes);
  match expanded_attributes with
  | [ (Ppxlib.Labelled "styles", _) ] -> Alcotest.(check pass) "styles remains untouched" () ()
  | _ -> Alcotest.fail "styles should not expand on uppercase JSX calls"

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

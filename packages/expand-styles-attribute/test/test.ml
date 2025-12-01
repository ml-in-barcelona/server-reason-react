let test_expand_styles () =
  let loc = Ppxlib.Location.none in
  let expr = [%expr "some-class-name", ReactDOM.Style.make ~backgroundColor:"gainsboro" ()] in
  let attributes = [ (Ppxlib.Labelled "styles", expr) ] in
  let expanded_attributes = Expand_styles_attribute.make ~loc:Ppxlib.Location.none attributes in

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
  let loc = Ppxlib.Location.none in
  let expr = [%expr "some-class-name", ReactDOM.Style.make ~backgroundColor:"gainsboro" ()] in
  let attributes = [ (Ppxlib.Labelled "className", [%expr "previous-class-name"]); (Ppxlib.Labelled "styles", expr) ] in
  let expanded_attributes = Expand_styles_attribute.make ~loc:Ppxlib.Location.none attributes in
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
  let loc = Ppxlib.Location.none in
  let expr = [%expr "some-class-name", ReactDOM.Style.make ~backgroundColor:"gainsboro" ()] in
  let attributes = [ (Ppxlib.Labelled "style", [%expr "previous-style"]); (Ppxlib.Labelled "styles", expr) ] in
  let expanded_attributes = Expand_styles_attribute.make ~loc:Ppxlib.Location.none attributes in
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
  let loc = Ppxlib.Location.none in
  let expr = [%expr Some ("some-class-name", ReactDOM.Style.make ~backgroundColor:"gainsboro" ())] in
  let attributes = [ (Ppxlib.Optional "styles", expr) ] in
  let expanded_attributes = Expand_styles_attribute.make ~loc:Ppxlib.Location.none attributes in
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

let test title fn = (title, [ Alcotest.test_case "" `Quick fn ])

let () =
  Alcotest.run "expand_styles_attribute"
    [
      test "expand_styles_prop_on_attributes" test_expand_styles;
      test "expand_styles_with_previous_className" test_expand_styles_with_previous_className;
      test "expand_styles_with_previous_style" test_expand_styles_with_previous_style;
      test "expand_styles_optional" test_expand_styles_optional;
    ]

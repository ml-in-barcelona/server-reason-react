open Html

let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left

let assert_option_some_tag left right =
  match left with
  | Some node -> Alcotest.check Alcotest.string "tag should match" right node.tag
  | None -> Alcotest.fail "Expected Some but got None"

let assert_option_none left = match left with None -> () | Some _ -> Alcotest.fail "Expected None but got Some"

let test_find_node_by_tag_multiple_elements () =
  let div = node "div" [] [ node "span" [] [ string "Target" ] ] in
  let div2 = node "div" [] [ node "span" [] [ string "Target" ] ] in
  let main = node "main" [] [ div; div2 ] in

  let div = Html.Node.find_by_tag ~tag:"div" main in
  match div with
  | Some
      {
        tag = "div";
        children = [ Html.Node { tag = "span"; children = [ Html.String "Target" ]; attributes = [] } ];
        attributes = [];
      } ->
      ()
  | Some div -> Alcotest.fail (Printf.sprintf "Expected a div with a span with 'Target' but got %s" div.tag)
  | None -> Alcotest.fail "Expected node with tag 'div' but got none"

let test_prepend_to_node () =
  let div = { tag = "div"; children = [ Html.String "Target" ]; attributes = [] } in
  Html.Node.prepend div (node "span" [] [ string "Target" ]);
  assert_string (to_string (Node div)) "<div><span>Target</span><!-- -->Target</div>"

let test_append_to_node () =
  let div = { tag = "div"; children = [ Html.String "Target" ]; attributes = [] } in
  Html.Node.append div (node "span" [] [ string "Target" ]);
  assert_string (to_string (Node div)) "<div>Target<span>Target</span></div>"

let test title fn = (Printf.sprintf "Node Manipulation / %s" title, [ Alcotest.test_case "" `Quick fn ])

let tests =
  [
    test "test_find_node_by_tag_multiple_elements" test_find_node_by_tag_multiple_elements;
    test "test_prepend_to_node" test_prepend_to_node;
    test "test_append_to_node" test_append_to_node;
  ]

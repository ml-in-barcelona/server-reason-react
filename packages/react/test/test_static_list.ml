let check_same label expected actual = Alcotest.(check bool) label true (expected == actual)
let span () = React.createElement "span" [] []

let group_operations () =
  let a = span () and b = span () in
  let group = React.Static_list [ a; b ] in
  Alcotest.(check int) "count" 2 (React.Children.count group);
  check_same "only returns the first member" a (React.Children.only group);
  Alcotest.(check bool) "group is not an element" false (React.isValidElement group);
  let visited = ref [] in
  React.Children.forEach group (fun child -> visited := child :: !visited);
  Alcotest.(check int) "forEach visits members" 2 (List.length !visited);
  Alcotest.check_raises "clone rejects a group" (Invalid_argument "React.cloneElement: cannot clone a Static_list")
    (fun () -> ignore (React.cloneElement group []));
  Alcotest.(check string) "renders members in order" "<span></span><span></span>" (ReactDOM.renderToStaticMarkup group)

let map_keeps_group () =
  let a = span () and b = span () in
  let keyed key = React.createElementWithKey ~key "span" [] [] in
  (match React.Children.map (React.Static_list [ a; b ]) Fun.id with
  | React.Static_list [ x; y ] ->
      Alcotest.(check bool) "first member, keyed .0" true (x = keyed ".0");
      Alcotest.(check bool) "second member, keyed .1" true (y = keyed ".1")
  | _ -> Alcotest.fail "map over a group yields a group");
  match React.Children.mapWithIndex (React.Static_list [ a; b ]) (fun child _ -> child) with
  | React.Static_list [ _; _ ] -> ()
  | _ -> Alcotest.fail "mapWithIndex over a group yields a group"

let tests =
  ( "Static_list",
    List.map
      (fun (name, fn) -> Alcotest.test_case name `Quick fn)
      [ ("group operations", group_operations); ("Children.map keeps the group", map_keeps_group) ] )

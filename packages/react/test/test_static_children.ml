let check_same label expected actual = Alcotest.(check bool) label true (expected == actual)
let span ?key () = React.createElementWithKey ?key "span" [] []

let key_of = function
  | React.Lower_case_element { key; _ } | React.Client_component { key; _ } | React.Suspense { key; _ } -> key
  | _ -> None

let keys = function
  | React.List members -> List.map key_of members
  | React.Array members -> Array.to_list (Array.map key_of members)
  | _ -> Alcotest.fail "expected a collection"

let check_keys label expected mapped = Alcotest.(check (list (option string))) label expected (keys mapped)

let group_operations () =
  let a = span () and b = span () in
  let group = React.Static_children [ a; b ] in
  Alcotest.(check int) "count" 2 (React.Children.count group);
  check_same "only returns the first member" a (React.Children.only group);
  Alcotest.(check bool) "group is not an element" false (React.isValidElement group);
  let visited = ref [] in
  React.Children.forEach group (fun child -> visited := child :: !visited);
  Alcotest.(check int) "forEach visits members" 2 (List.length !visited);
  Alcotest.check_raises "clone rejects a group"
    (Invalid_argument "React.cloneElement: cannot clone a Static_children group") (fun () ->
      ignore (React.cloneElement group []));
  Alcotest.(check string) "renders members in order" "<span></span><span></span>" (ReactDOM.renderToStaticMarkup group);
  match React.Children.map group Fun.id with React.List _ -> () | _ -> Alcotest.fail "map yields a runtime list"

let map_keys () =
  check_keys "unkeyed members get index keys" [ Some ".0"; Some ".1" ]
    (React.Children.map (React.list [ span (); span () ]) Fun.id);
  check_keys "group members get index keys" [ Some ".0"; Some ".1" ]
    (React.Children.map (React.Static_children [ span (); span () ]) Fun.id);
  check_keys "array keeps its shape" [ Some ".0" ] (React.Children.map (React.array [| span () |]) Fun.id);
  check_keys "keyed member" [ Some ".$a" ] (React.Children.map (React.list [ span ~key:"a" () ]) Fun.id);
  check_keys "escaped key" [ Some ".$a=0b=2c" ] (React.Children.map (React.list [ span ~key:"a=b:c" () ]) Fun.id);
  let eleven = React.Children.map (React.list (List.init 11 (fun _ -> span ()))) Fun.id in
  Alcotest.(check (option string)) "index in base 36" (Some ".a") (List.nth (keys eleven) 10);
  check_keys "callback key is prefixed" [ Some "x/.0" ]
    (React.Children.map (React.list [ span () ]) (fun _ -> span ~key:"x" ()));
  check_keys "slashes in a callback key are doubled" [ Some "x//y/.0" ]
    (React.Children.map (React.list [ span () ]) (fun _ -> span ~key:"x/y" ()));
  check_keys "same key is not prefixed" [ Some ".$k" ]
    (React.Children.map (React.list [ span ~key:"k" () ]) (fun child -> child));
  check_keys "text results are untouched" [ None ]
    (React.Children.map (React.list [ span () ]) (fun _ -> React.string "t"));
  check_keys "mapWithIndex keys too" [ Some ".0"; Some ".1" ]
    (React.Children.mapWithIndex (React.list [ span (); span () ]) (fun child _ -> child));
  let single = span () in
  check_same "single element maps without a key" single (React.Children.map single Fun.id)

let tests =
  ( "Static_children",
    List.map
      (fun (name, fn) -> Alcotest.test_case name `Quick fn)
      [ ("group operations", group_operations); ("Children.map keys", map_keys) ] )

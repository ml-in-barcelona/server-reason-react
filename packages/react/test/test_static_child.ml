let check_same label expected actual = Alcotest.(check bool) label true (expected == actual)
let host_children = function React.Lower_case_element { children; _ } -> children | _ -> Alcotest.fail "expected host"

let construction_and_reuse () =
  let bare = React.createElement "span" [] [] in
  let dynamic = React.list [ bare ] in
  let marked =
    match host_children (React.createElement "div" [] [ bare; dynamic; React.int 1 ]) with
    | [ (React.Static_child child as marked); collection; React.Int 1 ] ->
        check_same "same underlying child" bare child;
        check_same "collection unchanged" dynamic collection;
        marked
    | _ -> Alcotest.fail "expected shallow static positions"
  in
  List.iter
    (fun () ->
      let children = host_children (React.createElement "div" [] [ marked; bare ]) in
      check_same "existing mark reused" marked (List.hd children);
      check_same "bare occurrence unchanged" bare (React.Children.only dynamic);
      check_same "extracted mark survives collection reuse" marked (React.Children.only (React.list [ marked ])))
    [ (); () ]

let children_operations () =
  let bare = React.createElement "span" [] [] in
  let marked = React.Static_child bare in
  List.iter
    (fun collection ->
      let wrapped = React.Static_child (React.Static_child collection) in
      Alcotest.(check int) "count" 2 (React.Children.count wrapped);
      check_same "only keeps member mark" marked (React.Children.only wrapped);
      let seen = ref [] in
      let mapped =
        React.Children.map wrapped (fun child ->
            seen := child :: !seen;
            child)
      in
      Alcotest.(check bool)
        "map keeps collection shape" true
        (match (collection, mapped) with
        | React.List _, React.List _ | React.Array _, React.Array _ -> true
        | _ -> false);
      (match List.rev !seen with
      | [ first; second ] ->
          check_same "marked callback input" marked first;
          check_same "bare callback input" bare second
      | _ -> Alcotest.fail "expected two callback inputs");
      let indices = ref [] in
      ignore
        (React.Children.mapWithIndex wrapped (fun child index ->
             indices := index :: !indices;
             child));
      Alcotest.(check (list int)) "map indices" [ 1; 0 ] !indices;
      let visited = ref [] in
      React.Children.forEach wrapped (fun child -> visited := child :: !visited);
      (match !visited with
      | [ second; first ] ->
          check_same "iteration first" marked first;
          check_same "iteration second" bare second
      | _ -> Alcotest.fail "expected two visits");
      indices := [];
      React.Children.forEachWithIndex wrapped (fun _ index -> indices := index :: !indices);
      Alcotest.(check (list int)) "iteration indices" [ 1; 0 ] !indices)
    [ React.list [ marked; bare ]; React.array [| marked; bare |] ];
  check_same "scalar map preserves occurrence" marked (React.Children.map marked Fun.id);
  check_same "replacement does not inherit mark" bare (React.Children.map marked (fun _ -> bare));
  check_same "only keeps scalar occurrence" marked (React.Children.only marked);
  check_same "toArray keeps its existing shape" marked (React.Children.toArray marked).(0);
  let collection = React.Static_child (React.list [ marked; bare ]) in
  check_same "toArray does not flatten collections" collection (React.Children.toArray collection).(0);
  Alcotest.(check int) "wrapped empty count" 0 (React.Children.count (React.Static_child React.null));
  Alcotest.(check bool)
    "wrapped scalar transparent" true
    (React.Children.only (React.Static_child (React.int 7)) = React.int 7);
  List.iter
    (fun empty ->
      Alcotest.check_raises "empty collection selection" (Invalid_argument "Expected at least one child") (fun () ->
          ignore (React.Children.only (React.Static_child empty))))
    [ React.list []; React.array [||] ];
  check_same "collection mark does not reach selected member" bare
    (React.Children.only (React.Static_child (React.list [ bare ])))

let validity_and_clone () =
  let bare = React.createElement "span" [] [ React.string "child" ] in
  let marked = React.Static_child (React.Static_child bare) in
  Alcotest.(check bool) "valid marked host" true (React.isValidElement marked);
  List.iter
    (fun child -> Alcotest.(check bool) "invalid marked value" false (React.isValidElement (React.Static_child child)))
    [ React.list [ bare ]; React.array [| bare |]; React.string "text"; React.int 1; React.float 1.; React.null ];
  let cloned = React.cloneElement marked [ React.JSX.String ("id", "id", "cloned") ] in
  (match cloned with
  | React.Static_child (React.Lower_case_element { children; _ }) ->
      check_same "cloned children unchanged" (List.hd (host_children bare)) (List.hd children)
  | _ -> Alcotest.fail "expected one retained mark after clone");
  Alcotest.(check string)
    "clone updates attributes" "<span id=\"cloned\">child</span>" (ReactDOM.renderToStaticMarkup cloned);
  Alcotest.check_raises "marked collection clone still fails"
    (Invalid_argument "React.cloneElement: cannot clone a List") (fun () ->
      ignore (React.cloneElement (React.Static_child (React.list [ bare ])) []))

let scalar_slots_and_fast_paths () =
  let original_calls = ref 0 in
  let writer =
    React.Writer
      {
        emit = (fun buf ~separators:_ -> Buffer.add_string buf "<span>fast</span>");
        original =
          (fun () ->
            incr original_calls;
            React.createElement "span" [] [ React.string "fast" ]);
      }
  in
  let context = React.createContext () in
  let slots =
    [
      React.fragment writer;
      context.provider ~value:() ~children:writer ();
      context.consumer ~children:writer;
      React.Suspense.make (React.Suspense.makeProps ~children:writer ~fallback:writer ());
    ]
  in
  List.iter
    (fun slot ->
      match slot with
      | React.Fragment (React.Static_child child)
      | React.Provider { children = React.Static_child child; _ }
      | React.Consumer (React.Static_child child) ->
          check_same "marked scalar slot" writer child
      | React.Suspense { children = React.Static_child child; fallback = Some (React.Static_child fallback); _ } ->
          check_same "marked suspense child" writer child;
          check_same "marked fallback" writer fallback
      | _ -> Alcotest.fail "expected marked scalar slot")
    slots;
  Alcotest.(check int) "construction is lazy" 0 !original_calls;
  let marked = React.Static_child (React.Static_child writer) in
  List.iter
    (fun render -> Alcotest.(check string) "writer fast path" "<span>fast</span>" (render marked))
    [ ReactDOM.renderToString; ReactDOM.renderToStaticMarkup ];
  let stream, _ = Lwt_main.run (ReactDOM.renderToStream marked) in
  let html = Lwt_main.run (Lwt_stream.to_list stream) |> String.concat "" in
  Alcotest.(check string) "stream writer fast path" "<span>fast</span>" html;
  Alcotest.(check int) "rendering did not force original" 0 !original_calls;
  let cloned = React.cloneElement marked [ React.JSX.String ("id", "id", "clone") ] in
  (match cloned with
  | React.Static_child (React.Lower_case_element _) -> ()
  | _ -> Alcotest.fail "cloning writer must keep the occurrence mark");
  Alcotest.(check int) "clone forces original once" 1 !original_calls;
  Alcotest.(check string)
    "cloned writer uses updated attributes" "<span id=\"clone\">fast</span>" (ReactDOM.renderToStaticMarkup cloned);
  let original = React.Upper_case_component ("unused", fun () -> Alcotest.fail "static fast path forced original") in
  let static = React.Static_child (React.Static { prerendered = "<b>static</b>"; original }) in
  Alcotest.(check string) "static fast path" "<b>static</b>" (ReactDOM.renderToString static);
  let stream, _ = Lwt_main.run (ReactDOM.renderToStream static) in
  Alcotest.(check string)
    "stream static fast path" "<b>static</b>"
    (Lwt_main.run (Lwt_stream.to_list stream) |> String.concat "")

let use_id_positions () =
  let calls = ref 0 in
  let component =
    React.Upper_case_component
      ( "id",
        fun () ->
          incr calls;
          React.createElement "span" [ React.JSX.String ("id", "id", React.useId ()) ] [] )
  in
  let bare = React.list [ component; component ] in
  let marked = React.Static_child (React.list [ React.Static_child component; React.Static_child component ]) in
  Alcotest.(check string)
    "markers do not change tree positions" (ReactDOM.renderToString bare) (ReactDOM.renderToString marked);
  Alcotest.(check int) "one call per occurrence" 4 !calls

let tests =
  ( "Static_child",
    List.map
      (fun (name, fn) -> Alcotest.test_case name `Quick fn)
      [
        ("construction and reuse", construction_and_reuse);
        ("Children operations", children_operations);
        ("validity and cloning", validity_and_clone);
        ("scalar slots and fast paths", scalar_slots_and_fast_paths);
        ("useId positions", use_id_positions);
      ] )

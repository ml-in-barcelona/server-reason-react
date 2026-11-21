open Helpers

let assert_int_entries left right = Alcotest.(check (array (pair string int))) "should be equal" right left
let assert_string_array left right = Alcotest.(check (array string)) "should be equal" right left
let assert_int_array left right = Alcotest.(check (array int)) "should be equal" right left
let assert_string_pair_array left right = Alcotest.(check (array (pair string string))) "should be equal" right left

let map_tests =
  [
    test "make is empty" (fun () ->
        let m : (string, int) Js.Map.t = Js.Map.make () in
        assert_int (Js.Map.size m) 0;
        assert_int_entries (Js.Map.toArray m) [||]);
    test "set / get / has / size" (fun () ->
        let m = Js.Map.fromArray [| ("x", 1) |] in
        assert_option Alcotest.int "should be equal" (Js.Map.get ~key:"x" m) (Some 1);
        assert_option Alcotest.int "should be equal" (Js.Map.get ~key:"nope" m) None;
        assert_bool (Js.Map.has ~key:"x" m) true;
        assert_bool (Js.Map.has ~key:"nope" m) false;
        assert_int (Js.Map.size m) 1);
    test "set returns the map for chaining" (fun () ->
        let m = Js.Map.make () in
        let returned =
          m |> Js.Map.set ~key:"a" ~value:1 |> Js.Map.set ~key:"b" ~value:2 |> Js.Map.set ~key:"c" ~value:3
        in
        assert_bool (returned == m) true;
        assert_int_entries (Js.Map.toArray m) [| ("a", 1); ("b", 2); ("c", 3) |]);
    test "re-set keeps position, updates value" (fun () ->
        let m = Js.Map.fromArray [| ("a", 1); ("b", 2); ("c", 3) |] in
        let (_ : (string, int) Js.Map.t) = Js.Map.set ~key:"a" ~value:10 m in
        assert_int (Js.Map.size m) 3;
        assert_int_entries (Js.Iterator.toArray (Js.Map.entries m)) [| ("a", 10); ("b", 2); ("c", 3) |];
        assert_string_array (Js.Iterator.toArray (Js.Map.keys m)) [| "a"; "b"; "c" |];
        assert_int_array (Js.Iterator.toArray (Js.Map.values m)) [| 10; 2; 3 |]);
    test "delete then re-add moves key to the end" (fun () ->
        let m = Js.Map.fromArray [| ("a", 10); ("b", 2); ("c", 3) |] in
        assert_bool (Js.Map.delete ~key:"b" m) true;
        let (_ : (string, int) Js.Map.t) = Js.Map.set ~key:"b" ~value:20 m in
        assert_string_array (Js.Iterator.toArray (Js.Map.keys m)) [| "a"; "c"; "b" |];
        assert_int_array (Js.Iterator.toArray (Js.Map.values m)) [| 10; 3; 20 |]);
    test "delete returns whether the key was present" (fun () ->
        let m = Js.Map.fromArray [| ("x", 1) |] in
        assert_bool (Js.Map.delete ~key:"x" m) true;
        assert_bool (Js.Map.delete ~key:"nope" m) false;
        assert_int (Js.Map.size m) 0;
        assert_option Alcotest.int "should be equal" (Js.Map.get ~key:"x" m) None);
    test "fromArray dedup: last value wins, first position kept" (fun () ->
        let m = Js.Map.fromArray [| ("b", 1); ("a", 2); ("b", 3) |] in
        assert_int (Js.Map.size m) 2;
        assert_int_entries (Js.Map.toArray m) [| ("b", 3); ("a", 2) |]);
    test "toArray follows insertion order" (fun () ->
        let m = Js.Map.fromArray [| ("a", 1); ("b", 2); ("a", 3) |] in
        let (_ : (string, int) Js.Map.t) = Js.Map.set ~key:"c" ~value:4 m in
        let (_ : (string, int) Js.Map.t) = Js.Map.set ~key:"a" ~value:9 m in
        assert_int_entries (Js.Map.toArray m) [| ("a", 9); ("b", 2); ("c", 4) |]);
    test "forEach passes value then key, in insertion order" (fun () ->
        let m = Js.Map.fromArray [| ("a", 1); ("b", 2); ("a", 3) |] in
        let (_ : (string, int) Js.Map.t) = Js.Map.set ~key:"c" ~value:4 m in
        let (_ : bool) = Js.Map.delete ~key:"a" m in
        let (_ : (string, int) Js.Map.t) = Js.Map.set ~key:"a" ~value:5 m in
        let acc = ref [] in
        Js.Map.forEach ~f:(fun value key (_ : (string, int) Js.Map.t) -> acc := (key, value) :: !acc) m;
        assert_int_entries (Stdlib.Array.of_list (Stdlib.List.rev !acc)) [| ("b", 2); ("c", 4); ("a", 5) |]);
    test "forEach receives the map itself" (fun () ->
        let m = Js.Map.fromArray [| ("x", 1) |] in
        Js.Map.forEach ~f:(fun _value _key map -> assert_bool (map == m) true) m);
    test "clear empties the map" (fun () ->
        let m = Js.Map.fromArray [| ("x", 1); ("y", 2) |] in
        Js.Map.clear m;
        assert_int (Js.Map.size m) 0;
        assert_int_entries (Js.Map.toArray m) [||];
        assert_option Alcotest.int "should be equal" (Js.Map.get ~key:"x" m) None);
    test "set works after clear" (fun () ->
        let m = Js.Map.fromArray [| ("x", 1) |] in
        Js.Map.clear m;
        let (_ : (string, int) Js.Map.t) = Js.Map.set ~key:"y" ~value:2 m in
        assert_int_entries (Js.Map.toArray m) [| ("y", 2) |]);
    test "keys/values/entries iterators support next" (fun () ->
        let m = Js.Map.fromArray [| ("a", 1) |] in
        let it = Js.Map.keys m in
        let step = Js.Iterator.next it in
        assert_option Alcotest.string "should be equal" step.value (Some "a");
        assert_option Alcotest.bool "should be equal" step.done_ (Some false);
        let step = Js.Iterator.next it in
        assert_option Alcotest.string "should be equal" step.value None;
        assert_option Alcotest.bool "should be equal" step.done_ (Some true));
  ]

let set_tests =
  [
    test "make is empty" (fun () ->
        let s : string Js.Set.t = Js.Set.make () in
        assert_int (Js.Set.size s) 0;
        assert_string_array (Js.Set.toArray s) [||]);
    test "add / has / size" (fun () ->
        let s = Js.Set.make () in
        let (_ : string Js.Set.t) = Js.Set.add ~value:"a" s in
        assert_bool (Js.Set.has ~value:"a" s) true;
        assert_bool (Js.Set.has ~value:"b" s) false;
        assert_int (Js.Set.size s) 1);
    test "add returns the set for chaining" (fun () ->
        let s = Js.Set.make () in
        let returned = s |> Js.Set.add ~value:1 |> Js.Set.add ~value:2 |> Js.Set.add ~value:3 in
        assert_bool (returned == s) true;
        assert_int_array (Js.Set.toArray s) [| 1; 2; 3 |]);
    test "add dedup keeps original position" (fun () ->
        let s = Js.Set.fromArray [| 1; 2; 3 |] in
        let (_ : int Js.Set.t) = Js.Set.add ~value:1 s in
        assert_int (Js.Set.size s) 3;
        assert_int_array (Js.Set.toArray s) [| 1; 2; 3 |]);
    test "fromArray dedup keeps first position" (fun () ->
        let s = Js.Set.fromArray [| "b"; "a"; "b"; "c"; "a" |] in
        assert_int (Js.Set.size s) 3;
        assert_string_array (Js.Set.toArray s) [| "b"; "a"; "c" |]);
    test "delete returns whether the value was present" (fun () ->
        let s = Js.Set.fromArray [| 1; 3 |] in
        assert_bool (Js.Set.delete ~value:3 s) true;
        assert_bool (Js.Set.delete ~value:99 s) false;
        assert_int (Js.Set.size s) 1);
    test "delete then re-add moves value to the end" (fun () ->
        let s = Js.Set.fromArray [| 1; 2; 3 |] in
        assert_bool (Js.Set.delete ~value:2 s) true;
        let (_ : int Js.Set.t) = Js.Set.add ~value:2 s in
        assert_int_array (Js.Set.toArray s) [| 1; 3; 2 |]);
    test "forEach follows insertion order" (fun () ->
        let s = Js.Set.fromArray [| 1; 2; 3 |] in
        let (_ : bool) = Js.Set.delete ~value:2 s in
        let (_ : int Js.Set.t) = Js.Set.add ~value:2 s in
        let acc = ref [] in
        Js.Set.forEach ~f:(fun v -> acc := v :: !acc) s;
        assert_int_array (Stdlib.Array.of_list (Stdlib.List.rev !acc)) [| 1; 3; 2 |]);
    test "values iterator follows insertion order" (fun () ->
        let s = Js.Set.fromArray [| "b"; "a"; "c" |] in
        assert_string_array (Js.Iterator.toArray (Js.Set.values s)) [| "b"; "a"; "c" |]);
    test "entries yields (value, value) pairs" (fun () ->
        let s = Js.Set.fromArray [| "x"; "y" |] in
        assert_string_pair_array (Js.Iterator.toArray (Js.Set.entries s)) [| ("x", "x"); ("y", "y") |]);
    test "clear empties the set" (fun () ->
        let s = Js.Set.fromArray [| 1; 2 |] in
        Js.Set.clear s;
        assert_int (Js.Set.size s) 0;
        assert_int_array (Js.Set.toArray s) [||];
        assert_bool (Js.Set.has ~value:1 s) false);
    test "add works after clear" (fun () ->
        let s = Js.Set.fromArray [| 1 |] in
        Js.Set.clear s;
        let (_ : int Js.Set.t) = Js.Set.add ~value:2 s in
        assert_int_array (Js.Set.toArray s) [| 2 |]);
  ]

let tests = map_tests @ set_tests

open Helpers

let assert_int_array left right = Alcotest.check (Alcotest.array Alcotest.int) "should be equal" right left
let assert_string_array left right = Alcotest.check (Alcotest.array Alcotest.string) "should be equal" right left

let assert_entries_array left right =
  Alcotest.check (Alcotest.array (Alcotest.pair Alcotest.int Alcotest.string)) "should be equal" right left

let assert_int_option left right = Alcotest.check (Alcotest.option Alcotest.int) "should be equal" right left

let tests =
  [
    test "at: positive index" (fun () -> assert_int_option (Js.Array.at ~index:2 [| 1; 2; 3; 4; 5 |]) (Some 3));
    test "at: index 0" (fun () -> assert_int_option (Js.Array.at ~index:0 [| 1; 2; 3; 4; 5 |]) (Some 1));
    test "at: negative index counts from the end" (fun () ->
        assert_int_option (Js.Array.at ~index:(-1) [| 1; 2; 3; 4; 5 |]) (Some 5));
    test "at: most negative in-range index" (fun () ->
        assert_int_option (Js.Array.at ~index:(-5) [| 1; 2; 3; 4; 5 |]) (Some 1));
    test "at: out-of-range positive index" (fun () -> assert_int_option (Js.Array.at ~index:5 [| 1; 2; 3; 4; 5 |]) None);
    test "at: out-of-range negative index" (fun () ->
        assert_int_option (Js.Array.at ~index:(-6) [| 1; 2; 3; 4; 5 |]) None);
    test "at: empty array" (fun () -> assert_int_option (Js.Array.at ~index:0 [||]) None);
    test "findLast: found" (fun () ->
        assert_int_option (Js.Array.findLast ~f:(fun x -> x mod 2 = 0) [| 1; 2; 3; 4; 5 |]) (Some 4));
    test "findLast: not found" (fun () ->
        assert_int_option (Js.Array.findLast ~f:(fun x -> x > 9) [| 1; 2; 3; 4; 5 |]) None);
    test "findLasti: found using index" (fun () ->
        assert_int_option (Js.Array.findLasti ~f:(fun _ i -> i < 3) [| 10; 20; 30; 40 |]) (Some 30));
    test "findLasti: not found" (fun () ->
        assert_int_option (Js.Array.findLasti ~f:(fun _ i -> i > 9) [| 10; 20; 30; 40 |]) None);
    test "findLastIndex: found" (fun () ->
        assert_int (Js.Array.findLastIndex ~f:(fun x -> x mod 2 = 0) [| 1; 2; 3; 4; 5 |]) 3);
    test "findLastIndex: not found" (fun () ->
        assert_int (Js.Array.findLastIndex ~f:(fun x -> x > 9) [| 1; 2; 3; 4; 5 |]) (-1));
    test "findLastIndexi: found using index" (fun () ->
        assert_int (Js.Array.findLastIndexi ~f:(fun _ i -> i < 2) [| 10; 20; 30; 40 |]) 1);
    test "findLastIndexi: not found" (fun () ->
        assert_int (Js.Array.findLastIndexi ~f:(fun _ i -> i > 9) [| 10; 20; 30; 40 |]) (-1));
    test "flat: flattens one level" (fun () ->
        assert_int_array (Js.Array.flat [| [| 1; 2 |]; [||]; [| 3 |]; [| 4; 5 |] |]) [| 1; 2; 3; 4; 5 |]);
    test "flat: empty array" (fun () -> assert_int_array (Js.Array.flat [||]) [||]);
    test "toReversed: returns reversed copy" (fun () ->
        assert_int_array (Js.Array.toReversed [| 1; 2; 3 |]) [| 3; 2; 1 |]);
    test "toReversed: does not mutate the original" (fun () ->
        let orig = [| 1; 2; 3 |] in
        let (_ : int array) = Js.Array.toReversed orig in
        assert_int_array orig [| 1; 2; 3 |]);
    test "toSortedWith: ascending" (fun () ->
        assert_int_array (Js.Array.toSortedWith ~f:(fun a b -> a - b) [| 3; 1; 2 |]) [| 1; 2; 3 |]);
    test "toSortedWith: descending" (fun () ->
        assert_int_array (Js.Array.toSortedWith ~f:(fun a b -> b - a) [| 3; 1; 2 |]) [| 3; 2; 1 |]);
    test "toSortedWith: does not mutate the original" (fun () ->
        let orig = [| 3; 1; 2 |] in
        let (_ : int array) = Js.Array.toSortedWith ~f:(fun a b -> a - b) orig in
        assert_int_array orig [| 3; 1; 2 |]);
    test "toSpliced: remove and add" (fun () ->
        assert_int_array
          (Js.Array.toSpliced ~start:1 ~remove:2 ~add:[| 9; 10 |] [| 1; 2; 3; 4; 5 |])
          [| 1; 9; 10; 4; 5 |]);
    test "toSpliced: negative start" (fun () ->
        assert_int_array (Js.Array.toSpliced ~start:(-2) ~remove:1 ~add:[||] [| 1; 2; 3; 4; 5 |]) [| 1; 2; 3; 5 |]);
    test "toSpliced: remove count clamped to length" (fun () ->
        assert_int_array (Js.Array.toSpliced ~start:1 ~remove:100 ~add:[||] [| 1; 2; 3 |]) [| 1 |]);
    test "toSpliced: start beyond length appends" (fun () ->
        assert_int_array (Js.Array.toSpliced ~start:10 ~remove:1 ~add:[| 7 |] [| 1; 2; 3 |]) [| 1; 2; 3; 7 |]);
    test "toSpliced: negative remove count treated as 0" (fun () ->
        assert_int_array (Js.Array.toSpliced ~start:1 ~remove:(-5) ~add:[| 9 |] [| 1; 2; 3 |]) [| 1; 9; 2; 3 |]);
    test "toSpliced: does not mutate the original" (fun () ->
        let orig = [| 1; 2; 3 |] in
        let (_ : int array) = Js.Array.toSpliced ~start:0 ~remove:1 ~add:[||] orig in
        assert_int_array orig [| 1; 2; 3 |]);
    test "removeFrom" (fun () -> assert_int_array (Js.Array.removeFrom ~start:2 [| 1; 2; 3; 4 |]) [| 1; 2 |]);
    test "removeCount" (fun () ->
        assert_int_array (Js.Array.removeCount ~start:1 ~count:2 [| 1; 2; 3; 4; 5 |]) [| 1; 4; 5 |]);
    test "entries" (fun () ->
        assert_entries_array (Js.Iterator.toArray (Js.Array.entries [| "a"; "b" |])) [| (0, "a"); (1, "b") |]);
    test "entries: empty array" (fun () ->
        assert_entries_array (Js.Iterator.toArray (Js.Array.entries ([||] : string array))) [||]);
    test "keys" (fun () -> assert_int_array (Js.Iterator.toArray (Js.Array.keys [| "a"; "b"; "c" |])) [| 0; 1; 2 |]);
    test "values" (fun () -> assert_int_array (Js.Iterator.toArray (Js.Array.values [| 7; 8 |])) [| 7; 8 |]);
    test "iterator: next and exhaustion behavior" (fun () ->
        let it = Js.Array.values [| 1 |] in
        let first = Js.Iterator.next it in
        assert_int_option first.value (Some 1);
        assert_bool (first.done_ = Some false) true;
        let second = Js.Iterator.next it in
        assert_int_option second.value None;
        assert_bool (second.done_ = Some true) true;
        let third = Js.Iterator.next it in
        assert_int_option third.value None;
        assert_bool (third.done_ = Some true) true);
    test "iterator: empty iterator is exhausted immediately" (fun () ->
        let it = Js.Array.values ([||] : int array) in
        let result = Js.Iterator.next it in
        assert_int_option result.value None;
        assert_bool (result.done_ = Some true) true);
    test "iterator: toArray drains the remaining elements" (fun () ->
        let it = Js.Array.values [| 1; 2; 3 |] in
        let (_ : int Js.Iterator.value) = Js.Iterator.next it in
        assert_int_array (Js.Iterator.toArray it) [| 2; 3 |];
        let after = Js.Iterator.next it in
        assert_bool (after.done_ = Some true) true);
    test "iterator: toArrayWithMapper" (fun () ->
        assert_int_array
          (Js.Iterator.toArrayWithMapper (Js.Array.values [| 1; 2; 3 |]) ~f:(fun x -> x * 2))
          [| 2; 4; 6 |]);
    test "iterator: toArrayWithMapper over entries" (fun () ->
        assert_string_array
          (Js.Iterator.toArrayWithMapper
             (Js.Array.entries [| "a"; "b" |])
             ~f:(fun (i, v) -> Stdlib.string_of_int i ^ v))
          [| "0a"; "1b" |]);
  ]

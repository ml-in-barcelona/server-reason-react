(** Ported from Melange's test suite: jscomp/test/js_array_test.ml (melange 6.0.1-54).

    Mutating functions (copyWithin, fill, pop, push, ...) raise by design natively, so those tests are skipped. ES2019+
    additions (flat, at, findLast, toReversed, ...) are not implemented in our Js.Array and are skipped as well. *)

open Helpers

let assert_int_array actual expected = Alcotest.check Alcotest.(array int) "should be equal" expected actual
let assert_int_option actual expected = Alcotest.check Alcotest.(option int) "should be equal" expected actual

let tests =
  [
    (* skipped (raises by design natively): from *)
    (* skipped (raises by design natively): fromMap *)
    test "isArray_array" (fun () -> assert_bool (Js.Array.isArray [||]) true);
    (* skipped (melange-only): isArray_int — native isArray only accepts arrays, cannot pass an int *)
    test "length" (fun () -> assert_int (Js.Array.length [| 1; 2; 3 |]) 3);
    (* skipped (raises by design natively): copyWithin *)
    (* skipped (raises by design natively): copyWithinFrom *)
    (* skipped (raises by design natively): copyWithinFromRange *)
    (* skipped (raises by design natively): fillInPlace *)
    (* skipped (raises by design natively): fillFromInPlace *)
    (* skipped (raises by design natively): fillRangeInPlace *)
    (* skipped (raises by design natively): pop *)
    (* skipped (raises by design natively): pop - empty array *)
    (* skipped (raises by design natively): push *)
    (* skipped (raises by design natively): pushMany *)
    (* skipped (raises by design natively): reverseInPlace *)
    (* skipped (raises by design natively): shift *)
    (* skipped (raises by design natively): shift - empty array *)
    (* skipped (raises by design natively): sortInPlace *)
    (* skipped (raises by design natively): sortInPlaceWith *)
    (* skipped (raises by design natively): spliceInPlace *)
    (* skipped (raises by design natively): removeFromInPlace *)
    (* skipped (raises by design natively): removeCountInPlace *)
    (* skipped (raises by design natively): unshift *)
    (* skipped (raises by design natively): unshiftMany *)
    test "append" (fun () -> assert_int_array (Js.Array.concat ~other:[| 4 |] [| 1; 2; 3 |]) [| 1; 2; 3; 4 |]);
    test "concat" (fun () -> assert_int_array (Js.Array.concat ~other:[| 4; 5 |] [| 1; 2; 3 |]) [| 1; 2; 3; 4; 5 |]);
    test "concatMany" (fun () ->
        assert_int_array
          (Js.Array.concatMany ~arrays:[| [| 4; 5 |]; [| 6; 7 |] |] [| 1; 2; 3 |])
          [| 1; 2; 3; 4; 5; 6; 7 |]);
    test "includes" (fun () -> assert_bool (Js.Array.includes ~value:3 [| 1; 2; 3 |]) true);
    test "indexOf" (fun () -> assert_int (Js.Array.indexOf ~value:2 [| 1; 2; 3 |]) 1);
    test "indexOfFrom" (fun () -> assert_int (Js.Array.indexOf ~value:2 ~start:2 [| 1; 2; 3; 2 |]) 3);
    (* Our join only accepts string arrays, so the int arrays from Melange's test are adapted to strings. *)
    test "join" (fun () -> assert_string (Js.Array.join ~sep:"," [| "1"; "2"; "3" |]) "1,2,3");
    test "joinWith" (fun () -> assert_string (Js.Array.join ~sep:";" [| "1"; "2"; "3" |]) "1;2;3");
    test "lastIndexOf" (fun () -> assert_int (Js.Array.lastIndexOf ~value:2 [| 1; 2; 3 |]) 1);
    test "lastIndexOfFrom" (fun () -> assert_int (Js.Array.lastIndexOfFrom ~value:2 ~start:2 [| 1; 2; 3; 2 |]) 1);
    test "slice" (fun () -> assert_int_array (Js.Array.slice ~start:1 ~end_:3 [| 1; 2; 3; 4; 5 |]) [| 2; 3 |]);
    test "copy" (fun () -> assert_int_array (Js.Array.copy [| 1; 2; 3; 4; 5 |]) [| 1; 2; 3; 4; 5 |]);
    test "sliceFrom" (fun () -> assert_int_array (Js.Array.slice ~start:2 [| 1; 2; 3; 4; 5 |]) [| 3; 4; 5 |]);
    (* skipped (raises by design natively): toString *)
    (* skipped (raises by design natively): toLocaleString *)
    (* skipped (not implemented natively): entries *)
    test "every" (fun () -> assert_bool (Js.Array.every ~f:(fun n -> n > 0) [| 1; 2; 3 |]) true);
    test "everyi" (fun () -> assert_bool (Js.Array.everyi ~f:(fun _ i -> i > 0) [| 1; 2; 3 |]) false);
    test "filter" (fun () -> assert_int_array (Js.Array.filter ~f:(fun n -> n mod 2 = 0) [| 1; 2; 3; 4 |]) [| 2; 4 |]);
    test "filteri" (fun () ->
        assert_int_array (Js.Array.filteri ~f:(fun _ i -> i mod 2 = 0) [| 1; 2; 3; 4 |]) [| 1; 3 |]);
    test "find" (fun () -> assert_int_option (Js.Array.find ~f:(fun n -> n mod 2 = 0) [| 1; 2; 3; 4 |]) (Some 2));
    test "find - no match" (fun () -> assert_int_option (Js.Array.find ~f:(fun n -> n mod 2 = 5) [| 1; 2; 3; 4 |]) None);
    test "findi" (fun () -> assert_int_option (Js.Array.findi ~f:(fun _ i -> i mod 2 = 0) [| 1; 2; 3; 4 |]) (Some 1));
    test "findi - no match" (fun () ->
        assert_int_option (Js.Array.findi ~f:(fun _ i -> i mod 2 = 5) [| 1; 2; 3; 4 |]) None);
    test "findIndex" (fun () -> assert_int (Js.Array.findIndex ~f:(fun n -> n mod 2 = 0) [| 1; 2; 3; 4 |]) 1);
    test "findIndexi" (fun () -> assert_int (Js.Array.findIndexi ~f:(fun _ i -> i mod 2 = 0) [| 1; 2; 3; 4 |]) 0);
    test "forEach" (fun () ->
        let sum = ref 0 in
        Js.Array.forEach ~f:(fun n -> sum := !sum + n) [| 1; 2; 3 |];
        assert_int !sum 6);
    test "forEachi" (fun () ->
        let sum = ref 0 in
        Js.Array.forEachi ~f:(fun _ i -> sum := !sum + i) [| 1; 2; 3 |];
        assert_int !sum 3);
    (* skipped (not implemented natively): keys *)
    test "map" (fun () -> assert_int_array (Js.Array.map ~f:(fun n -> n * 2) [| 1; 2; 3; 4 |]) [| 2; 4; 6; 8 |]);
    test "mapi" (fun () -> assert_int_array (Js.Array.mapi ~f:(fun _ i -> i * 2) [| 1; 2; 3; 4 |]) [| 0; 2; 4; 6 |]);
    test "reduce" (fun () -> assert_int (Js.Array.reduce ~f:(fun acc n -> acc - n) ~init:0 [| 1; 2; 3; 4 |]) (-10));
    test "reducei" (fun () -> assert_int (Js.Array.reducei ~f:(fun acc _ i -> acc - i) ~init:0 [| 1; 2; 3; 4 |]) (-6));
    test "reduceRight" (fun () ->
        assert_int (Js.Array.reduceRight ~f:(fun acc n -> acc - n) ~init:0 [| 1; 2; 3; 4 |]) (-10));
    test "reduceRighti" (fun () ->
        assert_int (Js.Array.reduceRighti ~f:(fun acc _ i -> acc - i) ~init:0 [| 1; 2; 3; 4 |]) (-6));
    test "some" (fun () -> assert_bool (Js.Array.some ~f:(fun n -> n <= 0) [| 1; 2; 3; 4 |]) false);
    test "somei" (fun () -> assert_bool (Js.Array.somei ~f:(fun _ i -> i <= 0) [| 1; 2; 3; 4 |]) true);
    (* skipped (not implemented natively): values *)
    (* skipped (not implemented natively): flat *)
    (* skipped (not implemented natively): at *)
    (* skipped (not implemented natively): at - negative index *)
    (* skipped (not implemented natively): at - missing *)
    (* skipped (not implemented natively): findLast *)
    (* skipped (not implemented natively): findLast - no match *)
    (* skipped (not implemented natively): findLasti *)
    (* skipped (not implemented natively): findLasti - no match *)
    (* skipped (not implemented natively): findLastIndex *)
    (* skipped (not implemented natively): findLastIndexi *)
    (* skipped (not implemented natively): toReversed *)
    (* skipped (not implemented natively): toSorted *)
    (* skipped (not implemented natively): toSortedWith *)
    (* skipped (not implemented natively): toSpliced *)
    (* skipped (not implemented natively): removeFrom *)
    (* skipped (not implemented natively): removeCount *)
  ]

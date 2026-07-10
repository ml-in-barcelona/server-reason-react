(* Ported from melange jscomp/test/bs_sort_test.ml *)

module S = Belt.SortArray
module SI = Belt.SortArray.Int
module R = Belt.Range
module A = Belt.Array

let cmp x y = x - y
let range = inclusive_range
let random_range = shuffled_range

(* Native [makeUninitializedUnsafe] takes a filler value and
   [truncateToLengthUnsafe] returns a fresh array instead of mutating. *)
let unions xs ys =
  let len_x, len_y = (A.length xs, A.length ys) in
  let o = A.makeUninitializedUnsafe (len_x + len_y) 0 in
  let v = S.union xs 0 len_x ys 0 len_y o 0 cmp in
  A.truncateToLengthUnsafe o v

let inters xs ys =
  let len_x, len_y = (A.length xs, A.length ys) in
  let o = A.makeUninitializedUnsafe len_x 0 in
  let v = S.intersect xs 0 len_x ys 0 len_y o 0 cmp in
  A.truncateToLengthUnsafe o v

let diffs xs ys =
  let len_x, len_y = (A.length xs, A.length ys) in
  let o = A.makeUninitializedUnsafe len_x 0 in
  let v = S.diff xs 0 len_x ys 0 len_y o 0 cmp in
  A.truncateToLengthUnsafe o v

let int_string = Alcotest.pair Alcotest.int Alcotest.string
let lt (x : int) y = x < y

let suites =
  [
    ( "Melange.Belt.SortArray",
      [
        test "union" (fun () ->
            assert_array Alcotest.int (range 1 13) (unions (range 1 10) (range 3 13));
            assert_array Alcotest.int (range 1 13) (unions (range 1 10) (range 9 13));
            assert_array Alcotest.int (range 8 13) (unions (range 8 10) (range 9 13));
            assert_array Alcotest.int [| 0; 1; 2; 4; 5; 6; 7 |] (unions (range 0 2) (range 4 7)));
        test "intersect" (fun () ->
            assert_array Alcotest.int (range 3 10) (inters (range 1 10) (range 3 13));
            assert_array Alcotest.int (range 9 10) (inters (range 1 10) (range 9 13));
            assert_array Alcotest.int (range 9 10) (inters (range 8 10) (range 9 13));
            assert_array Alcotest.int [||] (inters (range 0 2) (range 4 7)));
        test "diff" (fun () ->
            assert_array Alcotest.int (range 1 2) (diffs (range 1 10) (range 3 13));
            assert_array Alcotest.int (range 1 8) (diffs (range 1 10) (range 9 13));
            assert_array Alcotest.int (range 8 8) (diffs (range 8 10) (range 9 13));
            assert_array Alcotest.int [| 0; 1; 2 |] (diffs (range 0 2) (range 4 7)));
        test "stableSortInPlaceBy and isSorted" (fun () ->
            assert_bool true
              (R.every 0 200 (fun i ->
                   let v = random_range 0 i in
                   S.stableSortInPlaceBy v cmp;
                   S.isSorted v cmp));
            assert_bool true
              (R.every 0 200 (fun i ->
                   let v = random_range 0 i in
                   S.stableSortInPlaceBy v cmp;
                   S.isSorted v cmp));
            assert_bool true (S.isSorted [||] cmp);
            assert_bool true (S.isSorted [| 0 |] cmp);
            assert_bool true (S.isSorted [| 0; 1 |] cmp);
            assert_bool true (not @@ S.isSorted [| 1; 0 |] cmp));
        (* skipped (melange-only): the [%time] instrumentation around the large
           sorts; the sorting assertions themselves are kept below *)
        test "large stable sorts stay sorted" (fun () ->
            let u = random_range 0 1_000_000 in
            let u1 = A.copy u in
            let u2 = A.copy u in
            S.stableSortInPlaceBy u cmp;
            assert_bool true (S.isSorted u cmp);
            SI.stableSortInPlace u2;
            assert_bool true (S.isSorted u2 cmp);
            S.stableSortInPlaceBy u1 cmp;
            assert_bool true (S.isSorted u1 cmp));
        test "stableSortBy is stable" (fun () ->
            let u = [| (1, "a"); (1, "b"); (2, "a") |] in
            assert_array int_string [| (1, "a"); (1, "b"); (2, "a") |] (S.stableSortBy u (fun (a, _) (b, _) -> a - b));
            let u = [| (1, "b"); (1, "a"); (1, "b"); (2, "a") |] in
            assert_array int_string
              [| (1, "b"); (1, "a"); (1, "b"); (2, "a") |]
              (S.stableSortBy u (fun (a, _) (b, _) -> a - b));
            let u = [| (1, "c"); (1, "b"); (1, "a"); (1, "b"); (1, "c"); (2, "a") |] in
            assert_array int_string
              [| (1, "c"); (1, "b"); (1, "a"); (1, "b"); (1, "c"); (2, "a") |]
              (S.stableSortBy u (fun (a, _) (b, _) -> a - b)));
        test "binarySearchBy" (fun () ->
            assert_int 2 (lnot (S.binarySearchBy [| 1; 3; 5; 7 |] 4 compare));
            assert_int 4 (S.binarySearchBy [| 1; 2; 3; 4; 33; 35; 36 |] 33 cmp);
            assert_int 0 (S.binarySearchBy [| 1; 2; 3; 4; 33; 35; 36 |] 1 cmp);
            assert_int 1 (S.binarySearchBy [| 1; 2; 3; 4; 33; 35; 36 |] 2 cmp);
            assert_int 2 (S.binarySearchBy [| 1; 2; 3; 4; 33; 35; 36 |] 3 cmp);
            assert_int 3 (S.binarySearchBy [| 1; 2; 3; 4; 33; 35; 36 |] 4 cmp);
            let aa = range 0 1000 in
            assert_bool true (R.every 0 1000 (fun i -> S.binarySearchBy aa i cmp = i));
            (* 0, 2, 4, ... 4000 *)
            let cc = A.map (range 0 2000) (fun x -> x * 2) in
            assert_int 2001 (lnot (S.binarySearchBy cc 5000 cmp));
            assert_int 0 (lnot (S.binarySearchBy cc (-1) cmp));
            assert_int 0 (S.binarySearchBy cc 0 cmp);
            assert_int 1 (lnot (S.binarySearchBy cc 1 cmp));
            assert_bool true
              (R.every 0 1999 (fun i -> lnot (S.binarySearchBy cc ((2 * i) + 1) cmp) = i + 1 (* 1, 3, 5, ... , 3999 *))));
        test "strictlySortedLength" (fun () ->
            assert_int 0 (S.strictlySortedLength [||] lt);
            assert_int 1 (S.strictlySortedLength [| 1 |] lt);
            assert_int 1 (S.strictlySortedLength [| 1; 1 |] lt);
            assert_int 1 (S.strictlySortedLength [| 1; 1; 2 |] lt);
            assert_int 2 (S.strictlySortedLength [| 1; 2 |] lt);
            assert_int 4 (S.strictlySortedLength [| 1; 2; 3; 4; 3 |] lt);
            assert_int 1 (S.strictlySortedLength [| 4; 4; 3; 2; 1 |] lt);
            assert_int (-4) (S.strictlySortedLength [| 4; 3; 2; 1 |] lt);
            assert_int (-5) (S.strictlySortedLength [| 4; 3; 2; 1; 0 |] lt));
      ] );
  ]

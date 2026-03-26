let int_cmp = compare

let union xs ys =
  let output = Belt.Array.makeUninitializedUnsafe (Array.length xs + Array.length ys) 0 in
  let written = Belt.SortArray.union xs 0 (Array.length xs) ys 0 (Array.length ys) output 0 int_cmp in
  Belt.Array.truncateToLengthUnsafe output written

let intersect xs ys =
  let output = Belt.Array.makeUninitializedUnsafe (Array.length xs) 0 in
  let written = Belt.SortArray.intersect xs 0 (Array.length xs) ys 0 (Array.length ys) output 0 int_cmp in
  Belt.Array.truncateToLengthUnsafe output written

let diff xs ys =
  let output = Belt.Array.makeUninitializedUnsafe (Array.length xs) 0 in
  let written = Belt.SortArray.diff xs 0 (Array.length xs) ys 0 (Array.length ys) output 0 int_cmp in
  Belt.Array.truncateToLengthUnsafe output written

let suites =
  [
    ( "SortArray",
      [
        test "union" (fun () ->
            assert_array Alcotest.int (inclusive_range 1 13) (union (inclusive_range 1 10) (inclusive_range 3 13));
            assert_array Alcotest.int (inclusive_range 1 13) (union (inclusive_range 1 10) (inclusive_range 9 13));
            assert_array Alcotest.int (inclusive_range 8 13) (union (inclusive_range 8 10) (inclusive_range 9 13));
            assert_array Alcotest.int [| 0; 1; 2; 4; 5; 6; 7 |] (union (inclusive_range 0 2) (inclusive_range 4 7)));
        test "intersect" (fun () ->
            assert_array Alcotest.int (inclusive_range 3 10) (intersect (inclusive_range 1 10) (inclusive_range 3 13));
            assert_array Alcotest.int (inclusive_range 9 10) (intersect (inclusive_range 1 10) (inclusive_range 9 13));
            assert_array Alcotest.int (inclusive_range 9 10) (intersect (inclusive_range 8 10) (inclusive_range 9 13));
            assert_array Alcotest.int [||] (intersect (inclusive_range 0 2) (inclusive_range 4 7)));
        test "diff" (fun () ->
            assert_array Alcotest.int [| 1; 2 |] (diff (inclusive_range 1 10) (inclusive_range 3 13));
            assert_array Alcotest.int (inclusive_range 1 8) (diff (inclusive_range 1 10) (inclusive_range 9 13));
            assert_array Alcotest.int [| 8 |] (diff (inclusive_range 8 10) (inclusive_range 9 13));
            assert_array Alcotest.int [| 0; 1; 2 |] (diff (inclusive_range 0 2) (inclusive_range 4 7)));
        test "isSorted and stableSortInPlace" (fun () ->
            for upper = 0 to 200 do
              let values = shuffled_range 0 upper in
              Belt.SortArray.stableSortInPlaceBy values int_cmp;
              assert_bool true (Belt.SortArray.isSorted values int_cmp)
            done;
            assert_bool true (Belt.SortArray.isSorted [||] int_cmp);
            assert_bool true (Belt.SortArray.isSorted [| 0 |] int_cmp);
            assert_bool true (Belt.SortArray.isSorted [| 0; 1 |] int_cmp);
            assert_bool false (Belt.SortArray.isSorted [| 1; 0 |] int_cmp));
        slow_test "specialized stable sorts" (fun () ->
            let values = shuffled_range 0 100_000 in
            let copy1 = Array.copy values in
            let copy2 = Array.copy values in
            Belt.SortArray.stableSortInPlaceBy values int_cmp;
            assert_bool true (Belt.SortArray.isSorted values int_cmp);
            Belt.SortArray.Int.stableSortInPlace copy1;
            assert_bool true (Belt.SortArray.isSorted copy1 int_cmp);
            Belt.SortArray.stableSortInPlaceBy copy2 int_cmp;
            assert_bool true (Belt.SortArray.isSorted copy2 int_cmp));
        test "stableSortBy" (fun () ->
            assert_array
              (Alcotest.pair Alcotest.int Alcotest.string)
              [| (1, "a"); (1, "b"); (2, "a") |]
              (Belt.SortArray.stableSortBy
                 [| (1, "a"); (1, "b"); (2, "a") |]
                 (fun (left, _) (right, _) -> left - right));
            assert_array
              (Alcotest.pair Alcotest.int Alcotest.string)
              [| (1, "b"); (1, "a"); (1, "b"); (2, "a") |]
              (Belt.SortArray.stableSortBy
                 [| (1, "b"); (1, "a"); (1, "b"); (2, "a") |]
                 (fun (left, _) (right, _) -> left - right));
            assert_array
              (Alcotest.pair Alcotest.int Alcotest.string)
              [| (1, "c"); (1, "b"); (1, "a"); (1, "b"); (1, "c"); (2, "a") |]
              (Belt.SortArray.stableSortBy
                 [| (1, "c"); (1, "b"); (1, "a"); (1, "b"); (1, "c"); (2, "a") |]
                 (fun (left, _) (right, _) -> left - right)));
        test "binarySearch" (fun () ->
            assert_int 2 (lnot (Belt.SortArray.binarySearchBy [| 1; 3; 5; 7 |] 4 compare));
            assert_int 4 (Belt.SortArray.binarySearchBy [| 1; 2; 3; 4; 33; 35; 36 |] 33 int_cmp);
            assert_int 0 (Belt.SortArray.binarySearchBy [| 1; 2; 3; 4; 33; 35; 36 |] 1 int_cmp);
            assert_int 1 (Belt.SortArray.binarySearchBy [| 1; 2; 3; 4; 33; 35; 36 |] 2 int_cmp);
            assert_int 2 (Belt.SortArray.binarySearchBy [| 1; 2; 3; 4; 33; 35; 36 |] 3 int_cmp);
            assert_int 3 (Belt.SortArray.binarySearchBy [| 1; 2; 3; 4; 33; 35; 36 |] 4 int_cmp);
            let values = inclusive_range 0 1000 in
            for index = 0 to 1000 do
              assert_int index (Belt.SortArray.binarySearchBy values index int_cmp)
            done;
            let evens = Array.map (fun value -> value * 2) (inclusive_range 0 2000) in
            assert_int 2001 (lnot (Belt.SortArray.binarySearchBy evens 5000 int_cmp));
            assert_int 0 (lnot (Belt.SortArray.binarySearchBy evens (-1) int_cmp));
            assert_int 0 (Belt.SortArray.binarySearchBy evens 0 int_cmp);
            assert_int 1 (lnot (Belt.SortArray.binarySearchBy evens 1 int_cmp));
            for index = 0 to 1999 do
              assert_int (index + 1) (lnot (Belt.SortArray.binarySearchBy evens ((2 * index) + 1) int_cmp))
            done);
        test "strictlySortedLength" (fun () ->
            let less left right = left < right in
            assert_int 0 (Belt.SortArray.strictlySortedLength [||] less);
            assert_int 1 (Belt.SortArray.strictlySortedLength [| 1 |] less);
            assert_int 1 (Belt.SortArray.strictlySortedLength [| 1; 1 |] less);
            assert_int 1 (Belt.SortArray.strictlySortedLength [| 1; 1; 2 |] less);
            assert_int 2 (Belt.SortArray.strictlySortedLength [| 1; 2 |] less);
            assert_int 4 (Belt.SortArray.strictlySortedLength [| 1; 2; 3; 4; 3 |] less);
            assert_int 1 (Belt.SortArray.strictlySortedLength [| 4; 4; 3; 2; 1 |] less);
            assert_int (-4) (Belt.SortArray.strictlySortedLength [| 4; 3; 2; 1 |] less);
            assert_int (-5) (Belt.SortArray.strictlySortedLength [| 4; 3; 2; 1; 0 |] less));
      ] );
  ]

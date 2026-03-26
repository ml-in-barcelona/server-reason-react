let suites =
  [
    ( "HashSet.Int",
      [
        test "dedupe reduce and forEach" (fun () ->
            let values = Belt.HashSet.Int.fromArray (Array.append (shuffled_range 30 100) (shuffled_range 40 120)) in
            assert_int 91 (Belt.HashSet.Int.size values);
            let sorted = Belt.Set.Int.toArray (Belt.Set.Int.fromArray (Belt.HashSet.Int.toArray values)) in
            assert_array Alcotest.int (inclusive_range 30 120) sorted;
            let expected_sum = arithmetic_sum 30 120 in
            assert_int expected_sum (Belt.HashSet.Int.reduce values 0 (fun acc value -> acc + value));
            let total = ref 0 in
            Belt.HashSet.Int.forEach values (fun value -> total := !total + value);
            assert_int expected_sum !total);
        slow_test "size stress" (fun () ->
            let values = Belt.HashSet.Int.make ~hintSize:40 in
            Belt.HashSet.Int.mergeMany values (Array.append (shuffled_range 0 100_000) (shuffled_range 0 100));
            assert_int 100_001 (Belt.HashSet.Int.size values);
            for key = 0 to 1000 do
              Belt.HashSet.Int.remove values key
            done;
            assert_int 99_000 (Belt.HashSet.Int.size values);
            for key = 0 to 2000 do
              Belt.HashSet.Int.remove values key
            done;
            assert_int 98_000 (Belt.HashSet.Int.size values));
        slow_test "copy independence" (fun () ->
            let original = Belt.HashSet.Int.fromArray (shuffled_range 0 100_000) in
            let copy = Belt.HashSet.Int.copy original in
            assert_array_unordered Alcotest.int (Belt.HashSet.Int.toArray original) (Belt.HashSet.Int.toArray copy);
            for key = 0 to 2000 do
              Belt.HashSet.Int.remove copy key
            done;
            for key = 0 to 1000 do
              Belt.HashSet.Int.remove original key
            done;
            let left = Array.append (inclusive_range 0 1000) (Belt.HashSet.Int.toArray original) in
            let right = Array.append (inclusive_range 0 2000) (Belt.HashSet.Int.toArray copy) in
            Belt.SortArray.Int.stableSortInPlace left;
            Belt.SortArray.Int.stableSortInPlace right;
            assert_array Alcotest.int left right);
        slow_test "bucket histogram sanity" (fun () ->
            let values = Belt.HashSet.Int.fromArray (shuffled_range 0 200_000) in
            assert_bool true (Array.length (Belt.HashSet.Int.getBucketHistogram values) <= 10));
      ] );
  ]

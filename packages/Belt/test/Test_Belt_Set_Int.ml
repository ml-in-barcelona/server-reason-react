let of_array = Belt.Set.Int.fromArray

let suites =
  [
    ( "Set.Int",
      [
        test "eq and partition" (fun () ->
            assert_bool true (Belt.Set.Int.eq (of_array [| 1; 2; 3 |]) (of_array [| 3; 2; 1 |]));
            let values = of_array (Array.append (inclusive_range 100 1000) (reverse_inclusive_range 400 1500)) in
            assert_array Alcotest.int (inclusive_range 100 1500) (Belt.Set.Int.toArray values);
            let left, right = Belt.Set.Int.partition values (fun value -> value mod 3 = 0) in
            let expected_left = ref Belt.Set.Int.empty in
            let expected_right = ref Belt.Set.Int.empty in
            for value = 100 to 1500 do
              if value mod 3 = 0 then expected_left := Belt.Set.Int.add !expected_left value
              else expected_right := Belt.Set.Int.add !expected_right value
            done;
            assert_bool true (Belt.Set.Int.eq left !expected_left);
            assert_bool true (Belt.Set.Int.eq right !expected_right));
        test "set algebra" (fun () ->
            assert_array Alcotest.int (inclusive_range 50 100)
              (Belt.Set.Int.toArray
                 (Belt.Set.Int.intersect (of_array (inclusive_range 1 100)) (of_array (inclusive_range 50 200))));
            assert_array Alcotest.int (inclusive_range 1 200)
              (Belt.Set.Int.toArray
                 (Belt.Set.Int.union (of_array (inclusive_range 1 100)) (of_array (inclusive_range 50 200))));
            assert_array Alcotest.int (inclusive_range 1 49)
              (Belt.Set.Int.toArray
                 (Belt.Set.Int.diff (of_array (inclusive_range 1 100)) (of_array (inclusive_range 50 200))));
            assert_array Alcotest.int (inclusive_range 50 100)
              (Belt.Set.Int.toArray
                 (Belt.Set.Int.intersect
                    (of_array (reverse_inclusive_range 1 100))
                    (of_array (reverse_inclusive_range 50 200))));
            assert_array Alcotest.int (inclusive_range 1 200)
              (Belt.Set.Int.toArray
                 (Belt.Set.Int.union
                    (of_array (reverse_inclusive_range 1 100))
                    (of_array (reverse_inclusive_range 50 200))));
            assert_array Alcotest.int (inclusive_range 1 49)
              (Belt.Set.Int.toArray
                 (Belt.Set.Int.diff
                    (of_array (reverse_inclusive_range 1 100))
                    (of_array (reverse_inclusive_range 50 200)))));
        test "min max reduce and emptiness" (fun () ->
            let source = [| 1; 222; 3; 4; 2; 0; 33; -1 |] in
            let values = of_array source in
            assert_int (Array.fold_left ( + ) 0 source) (Belt.Set.Int.reduce values 0 (fun acc value -> acc + value));
            assert_undefined Alcotest.int (Some (-1)) (Belt.Set.Int.minUndefined values);
            assert_undefined Alcotest.int (Some 222) (Belt.Set.Int.maxUndefined values);
            let values = Belt.Set.Int.remove values 3 in
            assert_option Alcotest.int (Some (-1)) (Belt.Set.Int.minimum values);
            assert_option Alcotest.int (Some 222) (Belt.Set.Int.maximum values);
            let values = Belt.Set.Int.remove values 222 in
            assert_option Alcotest.int (Some (-1)) (Belt.Set.Int.minimum values);
            assert_option Alcotest.int (Some 33) (Belt.Set.Int.maximum values);
            let values = Belt.Set.Int.remove values (-1) in
            assert_option Alcotest.int (Some 0) (Belt.Set.Int.minimum values);
            assert_option Alcotest.int (Some 33) (Belt.Set.Int.maximum values);
            let values = Belt.Set.Int.remove values 0 in
            let values = Belt.Set.Int.remove values 33 in
            let values = Belt.Set.Int.remove values 2 in
            let values = Belt.Set.Int.remove values 3 in
            let values = Belt.Set.Int.remove values 4 in
            let values = Belt.Set.Int.remove values 1 in
            assert_bool true (Belt.Set.Int.isEmpty values));
        slow_test "invariant under large removals" (fun () ->
            let shuffled = shuffled_range 0 200_000 in
            let values = Belt.Set.Int.fromArray shuffled in
            Belt.Set.Int.checkInvariantInternal values;
            let removed = Array.sub shuffled 0 2000 in
            let remaining = Array.fold_left (fun set value -> Belt.Set.Int.remove set value) values removed in
            Belt.Set.Int.checkInvariantInternal values;
            assert_bool true (Belt.Set.Int.eq (Belt.Set.Int.union (Belt.Set.Int.fromArray removed) remaining) values));
        test "subset eq cmp get and add identity" (fun () ->
            let base = Belt.Set.Int.fromArray (shuffled_range 0 100) in
            let superset = Belt.Set.Int.fromArray (shuffled_range 0 200) in
            let membership_set = Belt.Set.Int.fromArray (shuffled_range 0 2000) in
            let right_only = Belt.Set.Int.fromArray (shuffled_range 120 200) in
            let unioned = Belt.Set.Int.union base right_only in
            let checks = Array.map (fun value -> Belt.Set.Int.has membership_set value) (shuffled_range 1000 3000) in
            let present_count = Array.fold_left (fun acc present -> if present then acc + 1 else acc) 0 checks in
            assert_int 1001 present_count;
            assert_bool true (Belt.Set.Int.subset base superset);
            assert_bool true (Belt.Set.Int.subset unioned superset);
            assert_same_physical unioned (Belt.Set.Int.add unioned 200);
            assert_same_physical unioned (Belt.Set.Int.add unioned 0);
            assert_bool false (Belt.Set.Int.subset (Belt.Set.Int.add unioned 201) superset);
            let equal_left = Belt.Set.Int.fromArray (shuffled_range 0 100) in
            let equal_right = Belt.Set.Int.fromArray (shuffled_range 0 100) in
            let with_extra = Belt.Set.Int.add equal_right 101 in
            let removed = Belt.Set.Int.remove equal_right 99 in
            let changed = Belt.Set.Int.add removed 101 in
            assert_bool true (Belt.Set.Int.eq equal_left equal_right);
            assert_bool false (Belt.Set.Int.eq equal_left with_extra);
            assert_bool false (Belt.Set.Int.eq removed with_extra);
            assert_bool false (Belt.Set.Int.eq equal_right changed);
            assert_bool true (Belt.Set.Int.cmp equal_left equal_right = 0);
            assert_bool true (Belt.Set.Int.cmp equal_left with_extra < 0);
            assert_bool true
              (Belt.Set.Int.cmp
                 (Belt.Set.Int.fromArray (shuffled_range 0 2000))
                 (Belt.Set.Int.fromArray (shuffled_range 3 2_002))
              > 0);
            assert_option Alcotest.int (Some 30) (Belt.Set.Int.get (Belt.Set.Int.fromArray (shuffled_range 0 2000)) 30);
            assert_option Alcotest.int None (Belt.Set.Int.get (Belt.Set.Int.fromArray (shuffled_range 0 2000)) 3000));
        test "mergeMany removeMany and split" (fun () ->
            let merged = Belt.Set.Int.mergeMany Belt.Set.Int.empty (shuffled_range 0 100) in
            let trimmed = Belt.Set.Int.removeMany merged (shuffled_range 40 100) in
            let expected_trimmed = Belt.Set.Int.fromArray (inclusive_range 0 39) in
            let (left, right), present = Belt.Set.Int.split merged 40 in
            assert_bool true (Belt.Set.Int.eq merged (Belt.Set.Int.fromArray (inclusive_range 0 100)));
            assert_bool true (Belt.Set.Int.eq trimmed expected_trimmed);
            assert_bool true present;
            assert_bool true (Belt.Set.Int.eq expected_trimmed left);
            let right_without_40 = Belt.Set.Int.remove (Belt.Set.Int.removeMany merged (inclusive_range 0 39)) 40 in
            assert_bool true (Belt.Set.Int.eq right right_without_40);
            let removed_40 = Belt.Set.Int.remove merged 40 in
            let (left_missing, right_missing), present_missing = Belt.Set.Int.split removed_40 40 in
            assert_bool false present_missing;
            assert_bool true (Belt.Set.Int.eq left left_missing);
            assert_bool true (Belt.Set.Int.eq right right_missing);
            let single = Belt.Set.Int.removeMany right (inclusive_range 42 2000) in
            assert_int 1 (Belt.Set.Int.size single);
            assert_bool true (Belt.Set.Int.isEmpty (Belt.Set.Int.removeMany right (inclusive_range 0 2000))));
        test "empty split" (fun () ->
            let (left, right), present = Belt.Set.Int.split Belt.Set.Int.empty 0 in
            assert_bool true (Belt.Set.Int.isEmpty left);
            assert_bool true (Belt.Set.Int.isEmpty right);
            assert_bool false present);
      ] );
  ]

let of_array values = Belt.Set.fromArray values ~id:(module IntCmp)

let suites =
  [
    ( "Set",
      [
        test "remove add and minmax behavior" (fun () ->
            let original = of_array (inclusive_range 0 30) in
            let removed_zero = Belt.Set.remove original 0 in
            let removed_zero_again = Belt.Set.remove removed_zero 0 in
            let removed_tail = Belt.Set.remove removed_zero 30 in
            let removed_mid = Belt.Set.remove removed_tail 20 in
            let shuffled = shuffled_range 0 30 in
            let added_back = Belt.Set.add removed_mid 3 in
            let emptied = Belt.Set.removeMany added_back shuffled in
            let rebuilt = Belt.Set.mergeMany emptied [| 0; 1; 2; 0 |] in
            let emptied_again = Belt.Set.removeMany rebuilt [| 0; 1; 2; 3 |] in
            let merged = Belt.Set.mergeMany emptied_again (shuffled_range 0 2_000) in
            let merged_again = Belt.Set.mergeMany merged (shuffled_range 0 200) in
            let removed_small = Belt.Set.removeMany merged_again (shuffled_range 0 200) in
            let removed_medium = Belt.Set.removeMany removed_small (shuffled_range 0 1000) in
            let removed_medium_again = Belt.Set.removeMany removed_medium (shuffled_range 0 1000) in
            let removed_large = Belt.Set.removeMany removed_medium_again (shuffled_range 1000 1_500) in
            let only_last = Belt.Set.removeMany removed_large (shuffled_range 1_500 1_999) in
            let empty_final = Belt.Set.removeMany only_last (shuffled_range 2_000 2_100) in
            assert_not_same_physical original removed_zero;
            assert_same_physical removed_zero removed_zero_again;
            assert_int 28 (Belt.Set.size removed_mid);
            assert_undefined Alcotest.int (Some 29) (Belt.Set.maxUndefined removed_mid);
            assert_undefined Alcotest.int (Some 1) (Belt.Set.minUndefined removed_mid);
            assert_same_physical removed_mid added_back;
            assert_bool true (Belt.Set.isEmpty emptied);
            assert_int 3 (Belt.Set.size rebuilt);
            assert_bool false (Belt.Set.isEmpty rebuilt);
            assert_bool true (Belt.Set.isEmpty emptied_again);
            assert_bool true (Belt.Set.has merged_again 20);
            assert_bool true (Belt.Set.has merged_again 21);
            assert_int 2_001 (Belt.Set.size merged_again);
            assert_int 1_800 (Belt.Set.size removed_small);
            assert_int 1_000 (Belt.Set.size removed_medium);
            assert_int (Belt.Set.size removed_medium) (Belt.Set.size removed_medium_again);
            assert_int 500 (Belt.Set.size removed_large);
            assert_int 1 (Belt.Set.size only_last);
            assert_bool true (Belt.Set.has only_last 2_000);
            assert_bool false (Belt.Set.has only_last 500);
            assert_bool true (Belt.Set.isEmpty empty_final));
        test "union intersect diff subset and undefined access" (fun () ->
            let left = of_array (shuffled_range 0 100) in
            let right = of_array (shuffled_range 59 200) in
            let unioned = Belt.Set.union left right in
            let expected_union = of_array (inclusive_range 0 200) in
            let intersected = Belt.Set.intersect left right in
            let diff_left = Belt.Set.diff left right in
            let diff_right = Belt.Set.diff right left in
            let with_59 = Belt.Set.add diff_left 59 in
            let singleton = Belt.Set.add (Belt.Set.make ~id:(module IntCmp)) 3 in
            let even_values = of_array (Array.map (fun value -> value * 2) (shuffled_range 0 100)) in
            let union_singleton = Belt.Set.union even_values singleton in
            let expected_union_singleton =
              Array.append (Array.map (fun value -> value * 2) (inclusive_range 0 100)) [| 3 |]
            in
            Array.sort compare expected_union_singleton;
            assert_bool true (Belt.Set.eq unioned expected_union);
            assert_array Alcotest.int expected_union_singleton (Belt.Set.toArray union_singleton);
            assert_array Alcotest.int (inclusive_range 59 100) (Belt.Set.toArray intersected);
            assert_array Alcotest.int (inclusive_range 0 58) (Belt.Set.toArray diff_left);
            assert_bool true (Belt.Set.eq (Belt.Set.union right left) unioned);
            assert_array Alcotest.int (inclusive_range 101 200) (Belt.Set.toArray diff_right);
            assert_bool true (Belt.Set.subset diff_right right);
            assert_bool false (Belt.Set.subset right diff_right);
            assert_bool true (Belt.Set.subset diff_left left);
            assert_bool true (Belt.Set.subset intersected left && Belt.Set.subset intersected right);
            assert_undefined Alcotest.int (Some 47) (Belt.Set.getUndefined diff_left 47);
            assert_option Alcotest.int (Some 47) (Belt.Set.get diff_left 47);
            assert_undefined Alcotest.int None (Belt.Set.getUndefined diff_left 59);
            assert_option Alcotest.int None (Belt.Set.get diff_left 59);
            assert_int 60 (Belt.Set.size with_59);
            assert_option Alcotest.int None (Belt.Set.minimum (Belt.Set.make ~id:(module IntCmp)));
            assert_option Alcotest.int None (Belt.Set.maximum (Belt.Set.make ~id:(module IntCmp)));
            assert_undefined Alcotest.int None (Belt.Set.minUndefined (Belt.Set.make ~id:(module IntCmp)));
            assert_undefined Alcotest.int None (Belt.Set.maxUndefined (Belt.Set.make ~id:(module IntCmp))));
        test "iteration every some cmp" (fun () ->
            let values = of_array (shuffled_range 0 20) in
            let removed = Belt.Set.remove values 17 in
            let with_extra = Belt.Set.add removed 33 in
            let collected = ref [] in
            Belt.Set.forEach values (fun value -> collected := value :: !collected);
            assert_list Alcotest.int (Array.to_list (inclusive_range 0 20)) (List.rev !collected);
            assert_list Alcotest.int (Belt.Set.toList values) (Array.to_list (inclusive_range 0 20));
            assert_bool true (Belt.Set.some values (fun value -> value = 17));
            assert_bool false (Belt.Set.some removed (fun value -> value = 17));
            assert_bool true (Belt.Set.every values (fun value -> value < 24));
            assert_bool false (Belt.Set.every with_extra (fun value -> value < 24));
            assert_bool false (Belt.Set.every (of_array [| 1; 2; 3 |]) (fun value -> value = 2));
            assert_bool true (Belt.Set.cmp removed values < 0);
            assert_bool true (Belt.Set.cmp values removed > 0));
        test "keep partition getExn and split" (fun () ->
            let values = of_array (shuffled_range 0 1000) in
            let evens = Belt.Set.keep values (fun value -> value mod 2 = 0) in
            let odds = Belt.Set.keep values (fun value -> value mod 2 <> 0) in
            let evens_part, odds_part = Belt.Set.partition values (fun value -> value mod 2 = 0) in
            assert_bool true (Belt.Set.eq evens evens_part);
            assert_bool true (Belt.Set.eq odds odds_part);
            assert_int 3 (Belt.Set.getExn values 3);
            assert_int 4 (Belt.Set.getExn values 4);
            assert_raises_any (fun () -> ignore (Belt.Set.getExn values 1002));
            assert_raises_any (fun () -> ignore (Belt.Set.getExn values (-1)));
            assert_int 1001 (Belt.Set.size values);
            assert_bool false (Belt.Set.isEmpty values);
            let (left, right), present = Belt.Set.split values 200 in
            assert_bool true present;
            assert_array Alcotest.int (inclusive_range 0 199) (Belt.Set.toArray left);
            assert_list Alcotest.int (Array.to_list (inclusive_range 201 1000)) (Belt.Set.toList right);
            let removed_200 = Belt.Set.remove values 200 in
            let (left_missing, right_missing), present_missing = Belt.Set.split removed_200 200 in
            assert_bool false present_missing;
            assert_array Alcotest.int (inclusive_range 0 199) (Belt.Set.toArray left_missing);
            assert_list Alcotest.int (Array.to_list (inclusive_range 201 1000)) (Belt.Set.toList right_missing);
            assert_option Alcotest.int (Some 0) (Belt.Set.minimum left);
            assert_option Alcotest.int (Some 201) (Belt.Set.minimum right));
        test "empty keep and empty split" (fun () ->
            let empty = Belt.Set.fromArray [||] ~id:(module IntCmp) in
            assert_bool true (Belt.Set.isEmpty (Belt.Set.keep empty (fun value -> value mod 2 = 0)));
            let (left, right), present = Belt.Set.split (Belt.Set.make ~id:(module IntCmp)) 0 in
            assert_bool true (Belt.Set.isEmpty left);
            assert_bool true (Belt.Set.isEmpty right);
            assert_bool false present);
      ] );
  ]

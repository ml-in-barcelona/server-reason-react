let of_array = Belt.MutableSet.Int.fromArray

let suites =
  [
    ( "MutableSet.Int",
      [
        test "removeCheck addCheck mergeMany and removeMany" (fun () ->
            let values = of_array (inclusive_range 0 30) in
            assert_bool true (Belt.MutableSet.Int.removeCheck values 0);
            assert_bool false (Belt.MutableSet.Int.removeCheck values 0);
            assert_bool true (Belt.MutableSet.Int.removeCheck values 30);
            assert_bool true (Belt.MutableSet.Int.removeCheck values 20);
            assert_int 28 (Belt.MutableSet.Int.size values);
            assert_undefined Alcotest.int (Some 29) (Belt.MutableSet.Int.maxUndefined values);
            assert_undefined Alcotest.int (Some 1) (Belt.MutableSet.Int.minUndefined values);
            Belt.MutableSet.Int.add values 3;
            Array.iter (Belt.MutableSet.Int.remove values) (shuffled_range 0 30);
            assert_bool true (Belt.MutableSet.Int.isEmpty values);
            Belt.MutableSet.Int.add values 0;
            Belt.MutableSet.Int.add values 1;
            Belt.MutableSet.Int.add values 2;
            Belt.MutableSet.Int.add values 0;
            assert_int 3 (Belt.MutableSet.Int.size values);
            assert_bool false (Belt.MutableSet.Int.isEmpty values);
            for key = 0 to 3 do
              Belt.MutableSet.Int.remove values key
            done;
            assert_bool true (Belt.MutableSet.Int.isEmpty values);
            Belt.MutableSet.Int.mergeMany values (shuffled_range 0 20_000);
            Belt.MutableSet.Int.mergeMany values (shuffled_range 0 200);
            assert_int 20_001 (Belt.MutableSet.Int.size values);
            Belt.MutableSet.Int.removeMany values (shuffled_range 0 200);
            assert_int 19_800 (Belt.MutableSet.Int.size values);
            Belt.MutableSet.Int.removeMany values (shuffled_range 0 1000);
            assert_int 19_000 (Belt.MutableSet.Int.size values);
            Belt.MutableSet.Int.removeMany values (shuffled_range 0 1000);
            assert_int 19_000 (Belt.MutableSet.Int.size values);
            Belt.MutableSet.Int.removeMany values (shuffled_range 1000 10_000);
            assert_int 10_000 (Belt.MutableSet.Int.size values);
            Belt.MutableSet.Int.removeMany values (shuffled_range 10_000 19_999);
            assert_int 1 (Belt.MutableSet.Int.size values);
            assert_bool true (Belt.MutableSet.Int.has values 20_000);
            Belt.MutableSet.Int.removeMany values (shuffled_range 10_000 30_000);
            assert_bool true (Belt.MutableSet.Int.isEmpty values));
        test "stats split and subset" (fun () ->
            let values = of_array (shuffled_range 1000 2000) in
            let removals =
              Array.map (fun key -> Belt.MutableSet.Int.removeCheck values key) (shuffled_range 500 1499)
            in
            let removed_count = Array.fold_left (fun acc removed -> if removed then acc + 1 else acc) 0 removals in
            assert_int 500 removed_count;
            assert_int 501 (Belt.MutableSet.Int.size values);
            let additions = Array.map (fun key -> Belt.MutableSet.Int.addCheck values key) (shuffled_range 500 2000) in
            let added_count = Array.fold_left (fun acc added -> if added then acc + 1 else acc) 0 additions in
            assert_int 1000 added_count;
            assert_int 1501 (Belt.MutableSet.Int.size values);
            assert_bool true (Belt.MutableSet.Int.isEmpty (Belt.MutableSet.Int.make ()));
            assert_option Alcotest.int (Some 500) (Belt.MutableSet.Int.minimum values);
            assert_option Alcotest.int (Some 2000) (Belt.MutableSet.Int.maximum values);
            assert_undefined Alcotest.int (Some 500) (Belt.MutableSet.Int.minUndefined values);
            assert_undefined Alcotest.int (Some 2000) (Belt.MutableSet.Int.maxUndefined values);
            assert_int ((500 + 2000) / 2 * 1501) (Belt.MutableSet.Int.reduce values 0 (fun acc value -> acc + value));
            assert_list Alcotest.int (Array.to_list (inclusive_range 500 2000)) (Belt.MutableSet.Int.toList values);
            assert_array Alcotest.int (inclusive_range 500 2000) (Belt.MutableSet.Int.toArray values);
            Belt.MutableSet.Int.checkInvariantInternal values;
            assert_option Alcotest.int None (Belt.MutableSet.Int.get values 3);
            assert_option Alcotest.int (Some 1200) (Belt.MutableSet.Int.get values 1200);
            let (left, right), present = Belt.MutableSet.Int.split values 1000 in
            assert_bool true present;
            assert_array Alcotest.int (inclusive_range 500 999) (Belt.MutableSet.Int.toArray left);
            assert_array Alcotest.int (inclusive_range 1001 2000) (Belt.MutableSet.Int.toArray right);
            assert_bool true (Belt.MutableSet.Int.subset left values);
            assert_bool true (Belt.MutableSet.Int.subset right values);
            assert_bool true (Belt.MutableSet.Int.isEmpty (Belt.MutableSet.Int.intersect left right));
            assert_bool true (Belt.MutableSet.Int.removeCheck values 1000);
            let (left_missing, right_missing), present_missing = Belt.MutableSet.Int.split values 1000 in
            assert_bool false present_missing;
            assert_array Alcotest.int (inclusive_range 500 999) (Belt.MutableSet.Int.toArray left_missing);
            assert_array Alcotest.int (inclusive_range 1001 2000) (Belt.MutableSet.Int.toArray right_missing));
        test "set algebra and partitions" (fun () ->
            let left = of_array (shuffled_range 0 100) in
            let right = of_array (shuffled_range 40 120) in
            assert_bool true
              (Belt.MutableSet.Int.eq (Belt.MutableSet.Int.union left right) (of_array (inclusive_range 0 120)));
            assert_bool true
              (Belt.MutableSet.Int.eq
                 (Belt.MutableSet.Int.union (of_array (shuffled_range 0 20)) (of_array (shuffled_range 21 40)))
                 (of_array (inclusive_range 0 40)));
            assert_bool true
              (Belt.MutableSet.Int.eq (Belt.MutableSet.Int.intersect left right) (of_array (inclusive_range 40 100)));
            assert_bool true
              (Belt.MutableSet.Int.eq
                 (Belt.MutableSet.Int.intersect (of_array (shuffled_range 0 20)) (of_array (shuffled_range 21 40)))
                 (Belt.MutableSet.Int.make ()));
            assert_bool true
              (Belt.MutableSet.Int.eq
                 (Belt.MutableSet.Int.intersect (of_array [| 1; 3; 4; 5; 7; 9 |]) (of_array [| 2; 4; 5; 6; 8; 10 |]))
                 (of_array [| 4; 5 |]));
            assert_bool true
              (Belt.MutableSet.Int.eq (Belt.MutableSet.Int.diff left right) (of_array (inclusive_range 0 39)));
            assert_bool true
              (Belt.MutableSet.Int.eq (Belt.MutableSet.Int.diff right left) (of_array (inclusive_range 101 120)));
            let values = of_array (shuffled_range 0 1000) in
            let evens = Belt.MutableSet.Int.keep values (fun value -> value mod 2 = 0) in
            let odds = Belt.MutableSet.Int.keep values (fun value -> value mod 2 <> 0) in
            let evens_part, odds_part = Belt.MutableSet.Int.partition values (fun value -> value mod 2 = 0) in
            assert_bool true (Belt.MutableSet.Int.eq evens evens_part);
            assert_bool true (Belt.MutableSet.Int.eq odds odds_part);
            List.iter Belt.MutableSet.Int.checkInvariantInternal [ values; evens; odds; evens_part; odds_part ]);
        slow_test "large add stress" (fun () ->
            let values = Belt.MutableSet.Int.make () in
            for key = 0 to 100_000 do
              Belt.MutableSet.Int.add values key
            done;
            Belt.MutableSet.Int.checkInvariantInternal values;
            for key = 0 to 100_000 do
              assert_bool true (Belt.MutableSet.Int.has values key)
            done;
            assert_int 100_001 (Belt.MutableSet.Int.size values));
        test "fromArray and removal stress" (fun () ->
            let values = Belt.MutableSet.Int.make () in
            Belt.MutableSet.Int.mergeMany values (Array.append (shuffled_range 30 100) (shuffled_range 40 120));
            assert_int 91 (Belt.MutableSet.Int.size values);
            assert_array Alcotest.int (inclusive_range 30 120) (Belt.MutableSet.Int.toArray values);
            let values =
              Belt.MutableSet.Int.fromArray (Array.append (shuffled_range 0 100_000) (shuffled_range 0 100))
            in
            assert_int 100_001 (Belt.MutableSet.Int.size values);
            Array.iter (fun key -> Belt.MutableSet.Int.remove values key) (shuffled_range 50_000 80_000);
            assert_int 70_000 (Belt.MutableSet.Int.size values);
            Array.iter (fun key -> Belt.MutableSet.Int.remove values key) (shuffled_range 0 100_000);
            assert_int 0 (Belt.MutableSet.Int.size values);
            assert_bool true (Belt.MutableSet.Int.isEmpty values));
        test "fromSortedArrayUnsafe and derived copies" (fun () ->
            List.iter
              (fun values ->
                let set = Belt.MutableSet.Int.fromSortedArrayUnsafe values in
                Belt.MutableSet.Int.checkInvariantInternal set;
                assert_array Alcotest.int values (Belt.MutableSet.Int.toArray set))
              [
                [||];
                [| 0 |];
                [| 0; 1 |];
                [| 0; 1; 2 |];
                [| 0; 1; 2; 3 |];
                [| 0; 1; 2; 3; 4 |];
                [| 0; 1; 2; 3; 4; 5 |];
                [| 0; 1; 2; 3; 4; 6 |];
                [| 0; 1; 2; 3; 4; 6; 7 |];
                [| 0; 1; 2; 3; 4; 6; 7; 8 |];
                [| 0; 1; 2; 3; 4; 6; 7; 8; 9 |];
                inclusive_range 0 1000;
              ];
            let values = Belt.MutableSet.Int.fromArray (shuffled_range 0 1000) in
            let copy = Belt.MutableSet.Int.keep values (fun value -> value mod 8 = 0) in
            let keep_even, keep_odd = Belt.MutableSet.Int.partition values (fun value -> value mod 8 = 0) in
            let rest = Belt.MutableSet.Int.keep values (fun value -> value mod 8 <> 0) in
            for key = 0 to 200 do
              Belt.MutableSet.Int.remove values key
            done;
            assert_int 126 (Belt.MutableSet.Int.size copy);
            assert_array Alcotest.int (Array.init 126 (fun index -> index * 8)) (Belt.MutableSet.Int.toArray copy);
            assert_int 800 (Belt.MutableSet.Int.size values);
            assert_bool true (Belt.MutableSet.Int.eq copy keep_even);
            assert_bool true (Belt.MutableSet.Int.eq rest keep_odd);
            let values = Belt.MutableSet.Int.fromArray (shuffled_range 0 1000) in
            let (left, right), _ = Belt.MutableSet.Int.split values 400 in
            assert_bool true (Belt.MutableSet.Int.eq left (Belt.MutableSet.Int.fromArray (inclusive_range 0 399)));
            assert_bool true (Belt.MutableSet.Int.eq right (Belt.MutableSet.Int.fromArray (inclusive_range 401 1000))));
      ] );
  ]

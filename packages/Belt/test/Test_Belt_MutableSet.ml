let of_array values = Belt.MutableSet.fromArray values ~id:(module IntCmp)

let suites =
  [
    ( "MutableSet",
      [
        test "remove add and split" (fun () ->
            let values = of_array (inclusive_range 0 30) in
            assert_bool true (Belt.MutableSet.removeCheck values 0);
            assert_bool false (Belt.MutableSet.removeCheck values 0);
            assert_bool true (Belt.MutableSet.removeCheck values 30);
            assert_bool true (Belt.MutableSet.removeCheck values 20);
            assert_int 28 (Belt.MutableSet.size values);
            assert_undefined Alcotest.int (Some 29) (Belt.MutableSet.maxUndefined values);
            assert_undefined Alcotest.int (Some 1) (Belt.MutableSet.minUndefined values);
            Belt.MutableSet.add values 3;
            Array.iter (Belt.MutableSet.remove values) (shuffled_range 0 30);
            assert_bool true (Belt.MutableSet.isEmpty values);
            Belt.MutableSet.add values 0;
            Belt.MutableSet.add values 1;
            Belt.MutableSet.add values 2;
            Belt.MutableSet.add values 0;
            assert_int 3 (Belt.MutableSet.size values);
            Belt.MutableSet.mergeMany values (shuffled_range 0 20_000);
            Belt.MutableSet.mergeMany values (shuffled_range 0 200);
            assert_int 20_001 (Belt.MutableSet.size values);
            Belt.MutableSet.removeMany values (shuffled_range 0 200);
            assert_int 19_800 (Belt.MutableSet.size values);
            Belt.MutableSet.removeMany values (shuffled_range 0 1000);
            assert_int 19_000 (Belt.MutableSet.size values);
            let values = of_array (shuffled_range 1000 2000) in
            let (left, right), present = Belt.MutableSet.split values 1000 in
            assert_bool true present;
            assert_array Alcotest.int (inclusive_range 1000 2000) (Belt.MutableSet.toArray values);
            assert_array Alcotest.int (inclusive_range 1001 2000) (Belt.MutableSet.toArray right);
            assert_bool true (Belt.MutableSet.subset left values));
        test "set algebra and partitions" (fun () ->
            let left = of_array (shuffled_range 0 100) in
            let right = of_array (shuffled_range 40 120) in
            assert_bool true (Belt.MutableSet.eq (Belt.MutableSet.union left right) (of_array (inclusive_range 0 120)));
            assert_bool true
              (Belt.MutableSet.eq (Belt.MutableSet.intersect left right) (of_array (inclusive_range 40 100)));
            assert_bool true (Belt.MutableSet.eq (Belt.MutableSet.diff left right) (of_array (inclusive_range 0 39)));
            let values = of_array (shuffled_range 0 1000) in
            let evens = Belt.MutableSet.keep values (fun value -> value mod 2 = 0) in
            let odds = Belt.MutableSet.keep values (fun value -> value mod 2 <> 0) in
            let evens_part, odds_part = Belt.MutableSet.partition values (fun value -> value mod 2 = 0) in
            assert_bool true (Belt.MutableSet.eq evens evens_part);
            assert_bool true (Belt.MutableSet.eq odds odds_part);
            List.iter Belt.MutableSet.checkInvariantInternal [ values; evens; odds; evens_part; odds_part ]);
      ] );
  ]

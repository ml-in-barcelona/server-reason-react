let random_pairs start finish = Array.map (fun value -> (value, value)) (shuffled_range start finish)
let make_map () = Belt.MutableMap.make ~id:(module IntCmp)

let suites =
  [
    ( "MutableMap",
      [
        test "remove preserves successor values" (fun () ->
            let values = make_map () in
            Belt.MutableMap.set values 2 "two";
            Belt.MutableMap.set values 1 "one";
            Belt.MutableMap.set values 3 "three";
            Belt.MutableMap.remove values 2;
            assert_option Alcotest.string None (Belt.MutableMap.get values 2);
            assert_option Alcotest.string (Some "one") (Belt.MutableMap.get values 1);
            assert_option Alcotest.string (Some "three") (Belt.MutableMap.get values 3));
        test "remove deep successor preserves values" (fun () ->
            let values = make_map () in
            List.iter
              (fun (key, value) -> Belt.MutableMap.set values key value)
              [ (5, "five"); (2, "two"); (8, "eight"); (6, "six"); (9, "nine"); (7, "seven") ];
            Belt.MutableMap.remove values 5;
            Belt.MutableMap.checkInvariantInternal values;
            assert_option Alcotest.string None (Belt.MutableMap.get values 5);
            assert_option Alcotest.string (Some "six") (Belt.MutableMap.get values 6);
            assert_array
              (Alcotest.pair Alcotest.int Alcotest.string)
              [| (2, "two"); (6, "six"); (7, "seven"); (8, "eight"); (9, "nine") |]
              (Belt.MutableMap.toArray values));
        test "update remove preserves values" (fun () ->
            let values = make_map () in
            List.iter
              (fun (key, value) -> Belt.MutableMap.set values key value)
              [ (5, "five"); (2, "two"); (8, "eight"); (6, "six"); (9, "nine") ];
            Belt.MutableMap.update values 5 (fun _ -> None);
            Belt.MutableMap.checkInvariantInternal values;
            assert_option Alcotest.string None (Belt.MutableMap.get values 5);
            assert_option Alcotest.string (Some "six") (Belt.MutableMap.get values 6);
            assert_array
              (Alcotest.pair Alcotest.int Alcotest.string)
              [| (2, "two"); (6, "six"); (8, "eight"); (9, "nine") |]
              (Belt.MutableMap.toArray values));
        test "removeMany exact keys" (fun () ->
            let values = Belt.MutableMap.fromArray (random_pairs 0 10) ~id:(module IntCmp) in
            Belt.MutableMap.set values 3 33;
            assert_int 33 (Belt.MutableMap.getExn values 3);
            Belt.MutableMap.removeMany values [| 7; 8; 0; 1; 3; 2; 4; 922; 4; 5; 6 |];
            assert_array Alcotest.int [| 9; 10 |] (Belt.MutableMap.keysToArray values);
            Belt.MutableMap.removeMany values (inclusive_range 0 100);
            assert_bool true (Belt.MutableMap.isEmpty values));
        test "trim to three entries" (fun () ->
            let values = Belt.MutableMap.fromArray (random_pairs 0 10_000) ~id:(module IntCmp) in
            Belt.MutableMap.set values 2000 33;
            Belt.MutableMap.removeMany values (inclusive_range 0 1998);
            Belt.MutableMap.removeMany values (inclusive_range 2002 11_000);
            assert_array
              (Alcotest.pair Alcotest.int Alcotest.int)
              [| (1999, 1999); (2000, 33); (2001, 2001) |]
              (Belt.MutableMap.toArray values));
      ] );
  ]

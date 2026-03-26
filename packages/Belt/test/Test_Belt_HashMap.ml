let collision_hashmap () =
  let values = Belt.HashMap.make ~hintSize:16 ~id:(module CollidingIntHash) in
  Belt.HashMap.set values 0 "zero";
  Belt.HashMap.set values 11 "eleven";
  Belt.HashMap.set values 23 "twenty-three";
  values

let assert_hashmap_state expected values =
  assert_int (Array.length expected) (Belt.HashMap.size values);
  let count = ref 0 in
  Belt.HashMap.forEach values (fun _ _ -> incr count);
  assert_int (Array.length expected) !count;
  assert_array_unordered (Alcotest.pair Alcotest.int Alcotest.string) expected (Belt.HashMap.toArray values);
  assert_array_unordered Alcotest.int (Array.map fst expected) (Belt.HashMap.keysToArray values);
  assert_array_unordered Alcotest.string (Array.map snd expected) (Belt.HashMap.valuesToArray values)

let suites =
  [
    ( "HashMap",
      [
        test "mergeMany overwrites duplicates" (fun () ->
            let values = Belt.HashMap.make ~id:(module IntHash) ~hintSize:30 in
            Belt.HashMap.mergeMany values [| (1, 1); (2, 3); (3, 3); (2, 2) |];
            assert_option Alcotest.int (Some 2) (Belt.HashMap.get values 2);
            assert_int 3 (Belt.HashMap.size values));
        test "fromArray dedupes overlapping keys" (fun () ->
            let input =
              Array.map (fun value -> (value, value)) (Array.append (shuffled_range 30 100) (shuffled_range 40 120))
            in
            let values = Belt.HashMap.fromArray input ~id:(module IntHash) in
            assert_int 91 (Belt.HashMap.size values);
            let keys = Belt.HashMap.keysToArray values in
            Belt.SortArray.Int.stableSortInPlace keys;
            assert_array Alcotest.int (inclusive_range 30 120) keys);
        slow_test "remove stress" (fun () ->
            let input =
              Array.map (fun value -> (value, value)) (Array.append (shuffled_range 0 100_000) (shuffled_range 0 100))
            in
            let values = Belt.HashMap.make ~id:(module IntHash) ~hintSize:40 in
            Belt.HashMap.mergeMany values input;
            assert_int 100_001 (Belt.HashMap.size values);
            for key = 0 to 1000 do
              Belt.HashMap.remove values key
            done;
            assert_int 99_000 (Belt.HashMap.size values);
            for key = 0 to 2000 do
              Belt.HashMap.remove values key
            done;
            assert_int 98_000 (Belt.HashMap.size values);
            for key = 2001 to 100_000 do
              assert_bool true (Belt.HashMap.has values key)
            done);
        test "keepMapInPlace middle remove" (fun () ->
            let values = collision_hashmap () in
            Belt.HashMap.keepMapInPlace values (fun key value -> if key <> 11 then Some (value ^ "!") else None);
            assert_option Alcotest.string (Some "zero!") (Belt.HashMap.get values 0);
            assert_option Alcotest.string None (Belt.HashMap.get values 11);
            assert_option Alcotest.string (Some "twenty-three!") (Belt.HashMap.get values 23);
            assert_hashmap_state [| (0, "zero!"); (23, "twenty-three!") |] values);
        test "keepMapInPlace head remove" (fun () ->
            let values = collision_hashmap () in
            Belt.HashMap.keepMapInPlace values (fun key value -> if key <> 23 then Some value else None);
            assert_option Alcotest.string None (Belt.HashMap.get values 23);
            assert_hashmap_state [| (0, "zero"); (11, "eleven") |] values);
        test "keepMapInPlace tail remove" (fun () ->
            let values = collision_hashmap () in
            Belt.HashMap.keepMapInPlace values (fun key value -> if key <> 0 then Some value else None);
            assert_option Alcotest.string None (Belt.HashMap.get values 0);
            assert_hashmap_state [| (11, "eleven"); (23, "twenty-three") |] values);
        test "keepMapInPlace consecutive remove" (fun () ->
            let values = collision_hashmap () in
            Belt.HashMap.keepMapInPlace values (fun key value -> if key = 0 then Some (value ^ "!") else None);
            assert_hashmap_state [| (0, "zero!") |] values);
        test "keepMapInPlace remove all" (fun () ->
            let values = collision_hashmap () in
            Belt.HashMap.keepMapInPlace values (fun _ _ -> None);
            assert_hashmap_state [||] values);
      ] );
  ]

let int_pairs start finish = Array.map (fun value -> (value, value)) (inclusive_range start finish)
let map_of_array values = Belt.Map.fromArray values ~id:(module IntCmp)
let set_of_keys values = Belt.Set.fromArray values ~id:(module IntCmp)

let merge_inter left right =
  set_of_keys
    (Belt.Map.keysToArray
       (Belt.Map.merge left right (fun _ left_value right_value ->
            match (left_value, right_value) with Some _, Some _ -> Some () | _ -> None)))

let merge_union left right =
  set_of_keys
    (Belt.Map.keysToArray
       (Belt.Map.merge left right (fun _ left_value right_value ->
            match (left_value, right_value) with None, None -> None | _ -> Some ())))

let merge_diff left right =
  set_of_keys
    (Belt.Map.keysToArray
       (Belt.Map.merge left right (fun _ left_value right_value ->
            match (left_value, right_value) with Some _, None -> Some () | _ -> None)))

let suites =
  [
    ( "Map",
      [
        test "fromArray set get toArray and toList" (fun () ->
            let values = map_of_array (Array.map (fun key -> (key, key)) (shuffled_range 0 39)) in
            let updated = Belt.Map.set values 39 120 in
            assert_array
              (Alcotest.pair Alcotest.int Alcotest.int)
              (Array.map (fun key -> (key, key)) (inclusive_range 0 39))
              (Belt.Map.toArray values);
            assert_list
              (Alcotest.pair Alcotest.int Alcotest.int)
              (Array.to_list (Array.map (fun key -> (key, key)) (inclusive_range 0 39)))
              (Belt.Map.toList values);
            assert_option Alcotest.int (Some 39) (Belt.Map.get values 39);
            assert_option Alcotest.int (Some 120) (Belt.Map.get updated 39));
        test "large fromArray sorts output" (fun () ->
            let values = map_of_array (Array.map (fun key -> (key, key)) (shuffled_range 0 10_000)) in
            assert_array
              (Alcotest.pair Alcotest.int Alcotest.int)
              (Array.map (fun key -> (key, key)) (inclusive_range 0 10_000))
              (Belt.Map.toArray values));
        test "merge variants" (fun () ->
            let left = map_of_array (int_pairs 0 100) in
            let right = map_of_array (int_pairs 30 120) in
            assert_bool true (Belt.Set.eq (merge_inter left right) (set_of_keys (inclusive_range 30 100)));
            assert_bool true (Belt.Set.eq (merge_union left right) (set_of_keys (inclusive_range 0 120)));
            assert_bool true (Belt.Set.eq (merge_diff left right) (set_of_keys (inclusive_range 0 29)));
            assert_bool true (Belt.Set.eq (merge_diff right left) (set_of_keys (inclusive_range 101 120))));
        test "update removeMany and undefined access" (fun () ->
            let base = map_of_array (int_pairs 0 10) in
            let overwritten = Belt.Map.set base 3 33 in
            let removed = Belt.Map.remove overwritten 3 in
            let inserted = Belt.Map.update removed 3 (function Some value -> Some (value + 1) | None -> Some 11) in
            let absent = Belt.Map.update removed 3 (function Some value -> Some (value + 1) | None -> None) in
            let removed_once = Belt.Map.remove base 3 in
            let removed_twice = Belt.Map.remove removed_once 3 in
            assert_same_physical removed_once removed_twice;
            assert_bool true (Belt.Map.has base 3);
            assert_bool false (Belt.Map.has removed_once 3);
            assert_undefined Alcotest.int (Some 3) (Belt.Map.getUndefined base 3);
            assert_undefined Alcotest.int (Some 33) (Belt.Map.getUndefined overwritten 3);
            assert_undefined Alcotest.int None (Belt.Map.getUndefined removed 3);
            assert_undefined Alcotest.int (Some 11) (Belt.Map.getUndefined inserted 3);
            assert_undefined Alcotest.int None (Belt.Map.getUndefined absent 3);
            let leftovers = Belt.Map.removeMany base [| 7; 8; 0; 1; 3; 2; 4; 922; 4; 5; 6 |] in
            assert_array Alcotest.int [| 9; 10 |] (Belt.Map.keysToArray leftovers);
            let empty = Belt.Map.removeMany leftovers (inclusive_range 0 100) in
            assert_bool true (Belt.Map.isEmpty empty));
        test "set returns new map" (fun () ->
            let values = map_of_array (int_pairs 0 100) in
            let updated = Belt.Map.set values 3 32 in
            assert_option Alcotest.int (Some 32) (Belt.Map.get updated 3);
            assert_option Alcotest.int (Some 3) (Belt.Map.get values 3));
        test "repeated update accumulation" (fun () ->
            let values = Belt.Map.make ~id:(module IntCmp) in
            let combined = Belt.Array.concat (shuffled_range 0 20) (shuffled_range 10 30) in
            let accumulated =
              Array.fold_left
                (fun map key -> Belt.Map.update map key (function None -> Some 1 | Some count -> Some (count + 1)))
                values combined
            in
            let expected = map_of_array (Array.init 31 (fun key -> (key, if key >= 10 && key <= 20 then 2 else 1))) in
            assert_bool true (Belt.Map.eq accumulated expected ( = )));
        test "mergeMany split and empty removals" (fun () ->
            let merged = Belt.Map.mergeMany (Belt.Map.make ~id:(module IntCmp)) (int_pairs 0 10_000) in
            let from_array = map_of_array (int_pairs 0 10_000) in
            assert_bool true (Belt.Map.eq merged from_array ( = ));
            let increment = function None -> Some 0 | Some value -> Some (value + 1) in
            let updated = Belt.Map.update merged 10 increment in
            let with_negative = Belt.Map.update updated (-10) increment in
            let (left, right), present = Belt.Map.split updated 5000 in
            assert_option Alcotest.int (Some 11) (Belt.Map.get updated 10);
            assert_option Alcotest.int None (Belt.Map.get updated (-10));
            assert_option Alcotest.int (Some 0) (Belt.Map.get with_negative (-10));
            assert_bool true (Belt.Map.isEmpty (Belt.Map.remove (Belt.Map.make ~id:(module IntCmp)) 0));
            assert_bool true (Belt.Map.isEmpty (Belt.Map.removeMany (Belt.Map.make ~id:(module IntCmp)) [| 0 |]));
            assert_option Alcotest.int (Some 5000) present;
            assert_array Alcotest.int (inclusive_range 0 4999) (Belt.Map.keysToArray left);
            assert_array Alcotest.int (inclusive_range 5001 10_000) (Belt.Map.keysToArray right);
            let removed = Belt.Map.remove updated 5000 in
            let (left_missing, right_missing), present_missing = Belt.Map.split removed 5000 in
            assert_option Alcotest.int None present_missing;
            assert_array Alcotest.int (inclusive_range 0 4999) (Belt.Map.keysToArray left_missing);
            assert_array Alcotest.int (inclusive_range 5001 10_000) (Belt.Map.keysToArray right_missing));
      ] );
  ]

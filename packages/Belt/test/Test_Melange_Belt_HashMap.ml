(* Ported from melange jscomp/test/bs_hashmap_test.ml *)

module N = Belt.HashMap
module A = Belt.Array
module So = Belt.SortArray

let eq (x : int) y = x = y
let hash (x : int) = Hashtbl.hash x
let cmp (x : int) y = compare x y

module Y = (val Belt.Id.hashable ~eq ~hash)

let range = inclusive_range
let random_range = shuffled_range
let ( ++ ) = Belt.Array.concat

let suites =
  [
    ( "Melange.Belt.HashMap",
      [
        test "mergeMany, get and size" (fun () ->
            let empty : (int, int, _) N.t = N.make ~id:(module Y) ~hintSize:30 in
            N.mergeMany empty [| (1, 1); (2, 3); (3, 3); (2, 2) |];
            assert_option Alcotest.int (Some 2) (N.get empty 2);
            assert_int 3 (N.size empty));
        test "fromArray dedupes overlapping keys" (fun () ->
            let u = random_range 30 100 ++ random_range 40 120 in
            let v = A.zip u u in
            let xx = N.fromArray ~id:(module Y) v in
            assert_int 91 (N.size xx);
            assert_array Alcotest.int (range 30 120) (So.stableSortBy (N.keysToArray xx) cmp));
        test "remove stress" (fun () ->
            let u = random_range 0 100_000 ++ random_range 0 100 in
            let v = N.make ~id:(module Y) ~hintSize:40 in
            N.mergeMany v (A.zip u u);
            assert_int 100_001 (N.size v);
            for i = 0 to 1_000 do
              N.remove v i
            done;
            assert_int 99_000 (N.size v);
            for i = 0 to 2_000 do
              N.remove v i
            done;
            assert_int 98_000 (N.size v);
            assert_bool true (A.every (range 2_001 100_000) (fun x -> N.has v x)));
      ] );
  ]

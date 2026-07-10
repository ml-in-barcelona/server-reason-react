(* Ported from melange jscomp/test/bs_hashset_int_test.ml *)

module N = Belt.HashSet.Int
module S = Belt.Set.Int
module A = Belt.Array
module SI = Belt.SortArray.Int

let range = inclusive_range
let random_range = shuffled_range
let ( ++ ) = Belt.Array.concat
let add x y = x + y

let sum2 h =
  let v = ref 0 in
  N.forEach h (fun x -> v := !v + x);
  !v

let suites =
  [
    ( "Melange.Belt.HashSet.Int",
      [
        test "fromArray, toArray, reduce and forEach" (fun () ->
            let u = random_range 30 100 ++ random_range 40 120 in
            let v = N.fromArray u in
            assert_int 91 (N.size v);
            let xs = S.toArray (S.fromArray (N.toArray v)) in
            assert_array Alcotest.int (range 30 120) xs;
            let x = (30 + 120) / 2 * 91 in
            assert_int x (N.reduce v 0 add);
            assert_int x (sum2 v));
        test "mergeMany and remove" (fun () ->
            let u = random_range 0 100_000 ++ random_range 0 100 in
            let v = N.make ~hintSize:40 in
            N.mergeMany v u;
            assert_int 100_001 (N.size v);
            for i = 0 to 1_000 do
              N.remove v i
            done;
            assert_int 99_000 (N.size v);
            for i = 0 to 2_000 do
              N.remove v i
            done;
            assert_int 98_000 (N.size v));
        test "copy" (fun () ->
            let u0 = N.fromArray (random_range 0 100_000) in
            let u1 = N.copy u0 in
            assert_array Alcotest.int (N.toArray u0) (N.toArray u1);
            for i = 0 to 2000 do
              N.remove u1 i
            done;
            for i = 0 to 1000 do
              N.remove u0 i
            done;
            let v0 = A.concat (range 0 1000) (N.toArray u0) in
            let v1 = A.concat (range 0 2000) (N.toArray u1) in
            SI.stableSortInPlace v0;
            SI.stableSortInPlace v1;
            assert_array Alcotest.int v0 v1);
        test "getBucketHistogram" (fun () ->
            let h = N.fromArray (random_range 0 1_000_000) in
            let histo = N.getBucketHistogram h in
            assert_bool true (A.length histo <= 10));
      ] );
  ]

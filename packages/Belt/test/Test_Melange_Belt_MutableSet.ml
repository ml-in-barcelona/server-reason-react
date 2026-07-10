(* Ported from melange jscomp/test/bs_mutable_set_test.ml *)

module N = Belt.MutableSet.Int
module R = Belt.Range
module A = Belt.Array
module L = Belt.List

let empty = N.make
let fromArray = N.fromArray

(* The melange source contains this union/intersect/diff block twice (once inside the
   sealed struct using [empty ()], once at the toplevel using [N.make ()], both
   identical). It is ported once here and reused by both test cases. *)
let union_intersect_diff_assertions () =
  let f = fromArray in
  let ( =~ ) = N.eq in
  let aa = f (shuffled_range 0 100) in
  let bb = f (shuffled_range 40 120) in
  let cc = N.union aa bb in
  assert_bool true (cc =~ f (shuffled_range 0 120));
  assert_bool true (N.eq (N.union (f (shuffled_range 0 20)) (f (shuffled_range 21 40))) (f (shuffled_range 0 40)));
  let dd = N.intersect aa bb in
  assert_bool true (dd =~ f (shuffled_range 40 100));
  assert_bool true (N.intersect (f (shuffled_range 0 20)) (f (shuffled_range 21 40)) =~ empty ());
  assert_bool true (N.intersect (f (shuffled_range 21 40)) (f (shuffled_range 0 20)) =~ empty ());
  assert_bool true (N.intersect (f [| 1; 3; 4; 5; 7; 9 |]) (f [| 2; 4; 5; 6; 8; 10 |]) =~ f [| 4; 5 |]);
  assert_bool true (N.diff aa bb =~ f (shuffled_range 0 39));
  assert_bool true (N.diff bb aa =~ f (shuffled_range 101 120));
  assert_bool true (N.diff (f (shuffled_range 21 40)) (f (shuffled_range 0 20)) =~ f (shuffled_range 21 40));
  assert_bool true (N.diff (f (shuffled_range 0 20)) (f (shuffled_range 21 40)) =~ f (shuffled_range 0 20));
  assert_bool true (N.diff (f (shuffled_range 0 20)) (f (shuffled_range 0 40)) =~ f (shuffled_range 0 (-1)))

let suites =
  [
    ( "Melange.Belt.MutableSet",
      [
        test "removeCheck add mergeMany and removeMany" (fun () ->
            let u = fromArray (inclusive_range 0 30) in
            assert_bool true (N.removeCheck u 0);
            assert_bool false (N.removeCheck u 0);
            assert_bool true (N.removeCheck u 30);
            assert_bool true (N.removeCheck u 20);
            assert_int 28 (N.size u);
            let r = shuffled_range 0 30 in
            assert_undefined Alcotest.int (Some 29) (N.maxUndefined u);
            assert_undefined Alcotest.int (Some 1) (N.minUndefined u);
            N.add u 3;
            for i = 0 to A.length r - 1 do
              N.remove u (A.getUnsafe r i)
            done;
            assert_bool true (N.isEmpty u);
            N.add u 0;
            N.add u 1;
            N.add u 2;
            N.add u 0;
            assert_int 3 (N.size u);
            assert_bool false (N.isEmpty u);
            for i = 0 to 3 do
              N.remove u i
            done;
            assert_bool true (N.isEmpty u);
            N.mergeMany u (shuffled_range 0 20000);
            N.mergeMany u (shuffled_range 0 200);
            assert_int 20001 (N.size u);
            N.removeMany u (shuffled_range 0 200);
            assert_int 19800 (N.size u);
            N.removeMany u (shuffled_range 0 1000);
            assert_int 19000 (N.size u);
            N.removeMany u (shuffled_range 0 1000);
            assert_int 19000 (N.size u);
            N.removeMany u (shuffled_range 1000 10000);
            assert_int 10000 (N.size u);
            N.removeMany u (shuffled_range 10000 (20000 - 1));
            assert_int 1 (N.size u);
            assert_bool true (N.has u 20000);
            N.removeMany u (shuffled_range 10_000 30_000);
            assert_bool true (N.isEmpty u));
        test "removeCheck addCheck min max reduce split subset intersect" (fun () ->
            let v = fromArray (shuffled_range 1_000 2_000) in
            let bs = A.map (shuffled_range 500 1499) (fun x -> N.removeCheck v x) in
            let indeedRemoved = A.reduce bs 0 (fun acc x -> if x then acc + 1 else acc) in
            assert_int 500 indeedRemoved;
            assert_int 501 (N.size v);
            let cs = A.map (shuffled_range 500 2_000) (fun x -> N.addCheck v x) in
            let indeedAdded = A.reduce cs 0 (fun acc x -> if x then acc + 1 else acc) in
            assert_int 1000 indeedAdded;
            assert_int 1_501 (N.size v);
            assert_bool true (N.isEmpty (empty ()));
            assert_option Alcotest.int (Some 500) (N.minimum v);
            assert_option Alcotest.int (Some 2000) (N.maximum v);
            assert_undefined Alcotest.int (Some 500) (N.minUndefined v);
            assert_undefined Alcotest.int (Some 2000) (N.maxUndefined v);
            assert_int ((500 + 2000) / 2 * 1501) (N.reduce v 0 (fun x y -> x + y));
            assert_bool true (L.eq (N.toList v) (L.makeBy 1_501 (fun i -> i + 500)) (fun x y -> x = y));
            assert_array Alcotest.int (inclusive_range 500 2000) (N.toArray v);
            N.checkInvariantInternal v;
            assert_option Alcotest.int None (N.get v 3);
            assert_option Alcotest.int (Some 1_200) (N.get v 1_200);
            let (aa, bb), pres = N.split v 1000 in
            assert_bool true pres;
            assert_bool true (A.eq (N.toArray aa) (inclusive_range 500 999) (fun x y -> x = y));
            assert_bool true (A.eq (N.toArray bb) (inclusive_range 1_001 2_000) ( = ));
            assert_bool true (N.subset aa v);
            assert_bool true (N.subset bb v);
            assert_bool true (N.isEmpty (N.intersect aa bb));
            let c = N.removeCheck v 1_000 in
            assert_bool true c;
            let (aa, bb), pres = N.split v 1_000 in
            assert_bool false pres;
            assert_bool true (A.eq (N.toArray aa) (inclusive_range 500 999) ( = ));
            assert_bool true (A.eq (N.toArray bb) (inclusive_range 1_001 2_000) ( = ));
            assert_bool true (N.subset aa v);
            assert_bool true (N.subset bb v);
            assert_bool true (N.isEmpty (N.intersect aa bb)));
        test "union intersect diff" (fun () -> union_intersect_diff_assertions ());
        test "keep and partition" (fun () ->
            let a0 = fromArray (shuffled_range 0 1000) in
            let a1, a2 = (N.keep a0 (fun x -> x mod 2 = 0), N.keep a0 (fun x -> x mod 2 <> 0)) in
            let a3, a4 = N.partition a0 (fun x -> x mod 2 = 0) in
            assert_bool true (N.eq a1 a3);
            assert_bool true (N.eq a2 a4);
            L.forEach [ a0; a1; a2; a3; a4 ] (fun x -> N.checkInvariantInternal x));
        test "add many then has via Range.every" (fun () ->
            let v = N.make () in
            for i = 0 to 1_00_000 do
              N.add v i
            done;
            N.checkInvariantInternal v;
            assert_bool true (R.every 0 1_00_000 (fun i -> N.has v i));
            assert_int 1_00_001 (N.size v));
        test "mergeMany overlapping ranges" (fun () ->
            let u = A.concat (shuffled_range 30 100) (shuffled_range 40 120) in
            let v = N.make () in
            N.mergeMany v u;
            assert_int 91 (N.size v);
            assert_array Alcotest.int (inclusive_range 30 120) (N.toArray v));
        test "fromArray with duplicates and remove loops" (fun () ->
            let u = A.concat (shuffled_range 0 100_000) (shuffled_range 0 100) in
            let v = N.fromArray u in
            assert_int 100_001 (N.size v);
            let u = shuffled_range 50_000 80_000 in
            for i = 0 to A.length u - 1 do
              N.remove v i
            done;
            assert_int 70_000 (N.size v);
            let count = 100_000 in
            let vv = shuffled_range 0 count in
            for i = 0 to A.length vv - 1 do
              N.remove v vv.(i)
            done;
            assert_int 0 (N.size v);
            assert_bool true (N.isEmpty v));
        test "min max after removes" (fun () ->
            let v = N.fromArray (A.makeBy 30 (fun i -> i)) in
            N.remove v 30;
            N.remove v 29;
            assert_undefined Alcotest.int (Some 28) (N.maxUndefined v);
            N.remove v 0;
            assert_undefined Alcotest.int (Some 1) (N.minUndefined v);
            assert_int 28 (N.size v);
            let vv = shuffled_range 1 28 in
            for i = 0 to A.length vv - 1 do
              N.remove v vv.(i)
            done;
            assert_int 0 (N.size v));
        test "fromSortedArrayUnsafe" (fun () ->
            let id x =
              let u = N.fromSortedArrayUnsafe x in
              N.checkInvariantInternal u;
              assert_bool true (A.every2 (N.toArray u) x ( = ))
            in
            id [||];
            id [| 0 |];
            id [| 0; 1 |];
            id [| 0; 1; 2 |];
            id [| 0; 1; 2; 3 |];
            id [| 0; 1; 2; 3; 4 |];
            id [| 0; 1; 2; 3; 4; 5 |];
            id [| 0; 1; 2; 3; 4; 6 |];
            id [| 0; 1; 2; 3; 4; 6; 7 |];
            id [| 0; 1; 2; 3; 4; 6; 7; 8 |];
            id [| 0; 1; 2; 3; 4; 6; 7; 8; 9 |];
            id (inclusive_range 0 1000));
        test "keep and partition are unaffected by later removes" (fun () ->
            let v = N.fromArray (shuffled_range 0 1000) in
            let copyV = N.keep v (fun x -> x mod 8 = 0) in
            let aa, bb = N.partition v (fun x -> x mod 8 = 0) in
            let cc = N.keep v (fun x -> x mod 8 <> 0) in
            for i = 0 to 200 do
              N.remove v i
            done;
            assert_int 126 (N.size copyV);
            assert_array Alcotest.int (A.makeBy 126 (fun i -> i * 8)) (N.toArray copyV);
            assert_int 800 (N.size v);
            assert_bool true (N.eq copyV aa);
            assert_bool true (N.eq cc bb));
        test "split" (fun () ->
            let v = N.fromArray (shuffled_range 0 1000) in
            let (aa, bb), _ = N.split v 400 in
            assert_bool true (N.eq aa (N.fromArray (shuffled_range 0 399)));
            assert_bool true (N.eq bb (N.fromArray (shuffled_range 401 1000)));
            let d = N.fromArray (A.map (shuffled_range 0 1000) (fun x -> x * 2)) in
            let (cc, dd), _ = N.split d 1001 in
            assert_bool true (N.eq cc (N.fromArray (A.makeBy 501 (fun x -> x * 2))));
            assert_bool true (N.eq dd (N.fromArray (A.makeBy 500 (fun x -> 1002 + (x * 2))))));
        test "union intersect diff (repeated toplevel block)" (fun () -> union_intersect_diff_assertions ());
      ] );
  ]

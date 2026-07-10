(* Ported from melange jscomp/test/bs_set_int_test.ml *)

module N = Belt.Set.Int
module A = Belt.Array

let ( =~ ) s i = N.eq (N.fromArray i) s
let ( =* ) a b = N.eq (N.fromArray a) (N.fromArray b)
let ofA = N.fromArray

(* inclusive, matching the melange test's local [range]/[revRange] *)
let range = inclusive_range
let revRange = reverse_inclusive_range

let suites =
  [
    ( "Melange.Belt.Set.Int",
      [
        test "eq ignores order and intersect" (fun () ->
            assert_bool true ([| 1; 2; 3 |] =* [| 3; 2; 1 |]);
            let u = N.intersect (ofA [| 1; 2; 3 |]) (ofA [| 3; 4; 5 |]) in
            assert_bool true (u =~ [| 3 |]));
        test "partition matches manual split" (fun () ->
            let v = ofA (Array.append (range 100 1000) (revRange 400 1500)) in
            assert_bool true (v =~ range 100 1500);
            let l, r = N.partition v (fun x -> x mod 3 = 0) in
            let nl, nr =
              let l, r = (ref N.empty, ref N.empty) in
              for i = 100 to 1500 do
                if i mod 3 = 0 then l := N.add !l i else r := N.add !r i
              done;
              (!l, !r)
            in
            assert_bool true (N.eq l nl);
            assert_bool true (N.eq r nr));
        test "intersect union diff on ranges" (fun () ->
            assert_bool true (N.intersect (ofA (range 1 100)) (ofA (range 50 200)) =~ range 50 100);
            assert_bool true (N.union (ofA (range 1 100)) (ofA (range 50 200)) =~ range 1 200);
            assert_bool true (N.diff (ofA (range 1 100)) (ofA (range 50 200)) =~ range 1 49);
            assert_bool true (N.intersect (ofA (revRange 1 100)) (ofA (revRange 50 200)) =~ revRange 50 100);
            assert_bool true (N.union (ofA (revRange 1 100)) (ofA (revRange 50 200)) =~ revRange 1 200);
            assert_bool true (N.diff (ofA (revRange 1 100)) (ofA (revRange 50 200)) =~ revRange 1 49));
        test "reduce min max and remove until empty" (fun () ->
            let ss = [| 1; 222; 3; 4; 2; 0; 33; -1 |] in
            let v = ofA [| 1; 222; 3; 4; 2; 0; 33; -1 |] in
            assert_int (A.reduce ss 0 ( + )) (N.reduce v 0 (fun x y -> x + y));
            assert_undefined Alcotest.int (Some (-1)) (N.minUndefined v);
            assert_undefined Alcotest.int (Some 222) (N.maxUndefined v);
            let v = N.remove v 3 in
            assert_option Alcotest.int (Some (-1)) (N.minimum v);
            assert_option Alcotest.int (Some 222) (N.maximum v);
            let v = N.remove v 222 in
            assert_option Alcotest.int (Some (-1)) (N.minimum v);
            assert_option Alcotest.int (Some 33) (N.maximum v);
            let v = N.remove v (-1) in
            assert_option Alcotest.int (Some 0) (N.minimum v);
            assert_option Alcotest.int (Some 33) (N.maximum v);
            let v = N.remove v 0 in
            let v = N.remove v 33 in
            let v = N.remove v 2 in
            let v = N.remove v 3 in
            let v = N.remove v 4 in
            let v = N.remove v 1 in
            assert_bool true (N.isEmpty v));
        test "large fromArray remove and union" (fun () ->
            let count = 1_000_000 in
            let v = A.makeByAndShuffle count (fun i -> i) in
            let u = N.fromArray v in
            N.checkInvariantInternal u;
            let firstHalf = A.slice v ~offset:0 ~len:2_000 in
            let xx = A.reduce firstHalf u N.remove in
            N.checkInvariantInternal u;
            assert_bool true (N.eq (N.union (N.fromArray firstHalf) xx) u));
        test "subset and physical equality on redundant add" (fun () ->
            let aa = N.fromArray (shuffled_range 0 100) in
            let bb = N.fromArray (shuffled_range 0 200) in
            let cc = N.fromArray (shuffled_range 120 200) in
            let dd = N.union aa cc in
            assert_bool true (N.subset aa bb);
            assert_bool true (N.subset dd bb);
            assert_bool true (N.subset (N.add dd 200) bb);
            assert_bool true (N.add dd 200 == dd);
            assert_bool true (N.add dd 0 == dd);
            assert_bool true (not (N.subset (N.add dd 201) bb)));
        test "eq after add and remove" (fun () ->
            let aa = N.fromArray (shuffled_range 0 100) in
            let bb = N.fromArray (shuffled_range 0 100) in
            let cc = N.add bb 101 in
            let dd = N.remove bb 99 in
            let ee = N.add dd 101 in
            assert_bool true (N.eq aa bb);
            assert_bool false (N.eq aa cc);
            assert_bool false (N.eq dd cc);
            assert_bool false (N.eq bb ee));
        test "mergeMany removeMany and split" (fun () ->
            let a0 = N.empty in
            let a1 = N.mergeMany a0 (shuffled_range 0 100) in
            let a2 = N.removeMany a1 (shuffled_range 40 100) in
            let a3 = N.fromArray (shuffled_range 0 39) in
            let (a4, a5), pres = N.split a1 40 in
            assert_bool true (N.eq a1 (N.fromArray (shuffled_range 0 100)));
            assert_bool true (N.eq a2 a3);
            assert_bool true pres;
            assert_bool true (N.eq a3 a4);
            let a6 = N.remove (N.removeMany a1 (shuffled_range 0 39)) 40 in
            assert_bool true (N.eq a5 a6);
            let a7 = N.remove a1 40 in
            let (a8, a9), pres2 = N.split a7 40 in
            assert_bool false pres2;
            assert_bool true (N.eq a4 a8);
            assert_bool true (N.eq a5 a9);
            let a10 = N.removeMany a9 (shuffled_range 42 2000) in
            assert_int 1 (N.size a10);
            let a11 = N.removeMany a9 (shuffled_range 0 2000) in
            assert_bool true (N.isEmpty a11));
        test "split empty" (fun () ->
            let (aa, bb), pres = N.split N.empty 0 in
            assert_bool true (N.isEmpty aa);
            assert_bool true (N.isEmpty bb);
            assert_bool false pres);
        test "has cmp subset and get" (fun () ->
            let v = N.fromArray (shuffled_range 0 2_000) in
            let v0 = N.fromArray (shuffled_range 0 2_000) in
            let v1 = N.fromArray (shuffled_range 1 2_001) in
            let v2 = N.fromArray (shuffled_range 3 2_002) in
            let v3 = N.removeMany v2 [| 2_002; 2_001 |] in
            let us = A.map (shuffled_range 1_000 3_000) (fun x -> N.has v x) in
            let counted = A.reduce us 0 (fun acc x -> if x then acc + 1 else acc) in
            assert_int 1_001 counted;
            assert_bool true (N.eq v v0);
            assert_bool true (N.cmp v v0 = 0);
            assert_bool true (N.cmp v v1 < 0);
            assert_bool true (N.cmp v v2 > 0);
            assert_bool true (N.subset v3 v0);
            assert_bool true (not (N.subset v1 v0));
            assert_option Alcotest.int (Some 30) (N.get v 30);
            assert_option Alcotest.int None (N.get v 3_000));
      ] );
  ]

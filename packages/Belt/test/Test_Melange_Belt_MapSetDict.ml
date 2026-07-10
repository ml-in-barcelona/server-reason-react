(* Ported from melange jscomp/test/bs_map_set_dict_test.ml *)

module Icmp = (val Belt.Id.comparable ~cmp:(fun (x : int) y -> compare x y))
module Icmp2 = (val Belt.Id.comparable ~cmp:(fun (x : int) y -> compare x y))
module Ic3 = (val Belt.Id.comparable ~cmp:(compare : int -> int -> int))
module I2 = (val Belt.Id.comparable ~cmp:(fun (x : int) y -> compare y x))
module M = Belt.Map
module A = Belt.Array
module L = Belt.List
module Md0 = Belt.Map.Dict
module ISet = Belt.Set
module S0 = Belt.Set.Dict

let f x = M.fromArray x ~id:(module Icmp)

let suites =
  [
    ( "Melange.Belt.MapSetDict",
      [
        test "Map.Dict set with cmp from getId and packIdData" (fun () ->
            let m = M.make ~id:(module Icmp2) in
            let m2 : (int, string, _) M.t = M.make ~id:(module I2) in
            let count = 1_000_00 in
            let data = ref (M.getData m) in
            let m2_dict, m_dict = (M.getId m2, M.getId m) in
            let module N = (val m2_dict) in
            let module Mm = (val m_dict) in
            for i = 0 to count do
              data := Md0.set !data ~cmp:Mm.cmp i i
            done;
            let newm = M.packIdData ~data:!data ~id:m_dict in
            (* skipped (melange-only): Js.log newm *)
            assert_int (count + 1) (M.size newm));
        test "Map.Dict set on empty dict" (fun () ->
            let m = Md0.empty in
            let m11 = Md0.set ~cmp:Icmp.cmp m 1 1 in
            let _m20 = M.make ~id:(module Icmp) in
            (* skipped (melange-only): Js.log m11 *)
            assert_array (Alcotest.pair Alcotest.int Alcotest.int) [| (1, 1) |] (Md0.toArray m11));
        test "Set.Dict add with cmp from map id" (fun () ->
            let count = 100_000 in
            let v = ISet.make ~id:(module Icmp2) in
            let m = M.make ~id:(module Icmp2) in
            let m_dict = M.getId m in
            let module M = (val m_dict) in
            let cmp = M.cmp in
            let data = ref (ISet.getData v) in
            for i = 0 to count do
              data := S0.add ~cmp !data i
            done;
            (* skipped (melange-only): Js.log !data *)
            assert_int (count + 1) (S0.size !data));
        test "fromArray toArray toList get and set" (fun () ->
            let u0 = f (A.map (shuffled_range 0 39) (fun x -> (x, x))) in
            let u1 = M.set u0 39 120 in
            assert_bool true
              (A.every2 (M.toArray u0)
                 (A.map (inclusive_range 0 39) (fun x -> (x, x)))
                 (fun (x0, x1) (y0, y1) -> x0 = y0 && x1 = y1));
            assert_bool true
              (L.every2 (M.toList u0)
                 (L.fromArray (A.map (inclusive_range 0 39) (fun x -> (x, x))))
                 (fun (x0, x1) (y0, y1) -> x0 = y0 && x1 = y1));
            assert_option Alcotest.int (Some 39) (M.get u0 39);
            assert_option Alcotest.int (Some 120) (M.get u1 39));
        test "large fromArray sorts output" (fun () ->
            let u = f (A.makeByAndShuffle 10_000 (fun x -> (x, x))) in
            assert_array (Alcotest.pair Alcotest.int Alcotest.int) (A.makeBy 10_000 (fun x -> (x, x))) (M.toArray u));
      ] );
  ]

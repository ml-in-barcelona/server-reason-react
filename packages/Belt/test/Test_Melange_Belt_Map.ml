(* Ported from melange jscomp/test/bs_map_test.ml *)

module M = Belt.Map.Int
module A = Belt.Array

let suites =
  [
    ( "Melange.Belt.Map",
      [
        test "checkInvariantInternal after large fromArray and removes" (fun () ->
            let v = A.makeByAndShuffle 1_000_000 (fun i -> (i, i)) in
            let u = M.fromArray v in
            M.checkInvariantInternal u;
            assert_int 1_000_000 (M.size u);
            let firstHalf = A.slice v ~offset:0 ~len:2_000 in
            let xx = A.reduce firstHalf u (fun acc (x, _) -> M.remove acc x) in
            M.checkInvariantInternal u;
            M.checkInvariantInternal xx;
            assert_int 998_000 (M.size xx));
      ] );
  ]

let suites =
  [
    ( "Map.Dict",
      [
        test "packIdData and first class comparator" (fun () ->
            let module Comparable = (val Belt.Id.comparable ~cmp:(compare : int -> int -> int)) in
            let empty = Belt.Map.make ~id:(module Comparable) in
            let id = Belt.Map.getId empty in
            let module Cmp = (val id) in
            let data = Belt.Map.getData empty in
            let data = Belt.Map.Dict.set data 1 1 ~cmp:Cmp.cmp in
            let data = Belt.Map.Dict.set data 2 2 ~cmp:Cmp.cmp in
            let packed = Belt.Map.packIdData ~id ~data in
            assert_array (Alcotest.pair Alcotest.int Alcotest.int) [| (1, 1); (2, 2) |] (Belt.Map.toArray packed));
      ] );
  ]

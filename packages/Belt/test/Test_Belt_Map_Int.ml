let suites =
  [
    ( "Map.Int",
      [
        test "findFirstBy" (fun () ->
            let values = Belt.Map.Int.fromArray [| (4, "four"); (1, "one"); (2, "two") |] in
            assert_option
              (Alcotest.pair Alcotest.int Alcotest.string)
              (Some (2, "two"))
              (Belt.Map.Int.findFirstBy values (fun key _ -> key mod 2 = 0 && key < 4));
            assert_option
              (Alcotest.pair Alcotest.int Alcotest.string)
              None
              (Belt.Map.Int.findFirstBy values (fun key _ -> key > 10)));
        test "invariant after removals" (fun () ->
            let shuffled = Array.map (fun key -> (key, key)) (shuffled_range 0 10_000) in
            let values = Belt.Map.Int.fromArray shuffled in
            Belt.Map.Int.checkInvariantInternal values;
            let removed = Array.sub shuffled 0 2000 in
            let reduced = Array.fold_left (fun map (key, _) -> Belt.Map.Int.remove map key) values removed in
            Belt.Map.Int.checkInvariantInternal values;
            Belt.Map.Int.checkInvariantInternal reduced;
            Array.iter (fun (key, _) -> assert_option Alcotest.int None (Belt.Map.Int.get reduced key)) removed);
        test "set get remove stress" (fun () ->
            let values = ref Belt.Map.Int.empty in
            let count = 10_000 in
            for key = 0 to count do
              values := Belt.Map.Int.set !values key key
            done;
            for key = 0 to count do
              assert_bool true (Belt.Map.Int.get !values key <> None)
            done;
            for key = 0 to count do
              values := Belt.Map.Int.remove !values key
            done;
            assert_bool true (Belt.Map.Int.isEmpty !values));
      ] );
  ]

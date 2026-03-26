let suites =
  [
    ( "Map.String",
      [
        test "findFirstBy" (fun () ->
            let values = Belt.Map.String.fromArray [| ("cc", 3); ("b", 1); ("aa", 2) |] in
            assert_option
              (Alcotest.pair Alcotest.string Alcotest.int)
              (Some ("aa", 2))
              (Belt.Map.String.findFirstBy values (fun key _ -> String.length key = 2));
            assert_option
              (Alcotest.pair Alcotest.string Alcotest.int)
              None
              (Belt.Map.String.findFirstBy values (fun key _ -> key = "zzz")));
      ] );
  ]

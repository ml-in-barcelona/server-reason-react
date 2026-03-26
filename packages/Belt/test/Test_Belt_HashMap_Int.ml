let suites =
  [
    ( "HashMap.Int",
      [
        test "smoke" (fun () ->
            let values = Belt.HashMap.Int.make ~hintSize:4 in
            Belt.HashMap.Int.set values 1 "one";
            assert_int 1 (Belt.HashMap.Int.size values);
            assert_array_unordered
              (Alcotest.pair Alcotest.int Alcotest.string)
              [| (1, "one") |]
              (Belt.HashMap.Int.toArray values));
      ] );
  ]

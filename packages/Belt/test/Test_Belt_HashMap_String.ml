let suites =
  [
    ( "HashMap.String",
      [
        test "smoke" (fun () ->
            let values = Belt.HashMap.String.make ~hintSize:4 in
            Belt.HashMap.String.set values "one" 1;
            assert_int 1 (Belt.HashMap.String.size values);
            assert_array_unordered
              (Alcotest.pair Alcotest.string Alcotest.int)
              [| ("one", 1) |]
              (Belt.HashMap.String.toArray values));
      ] );
  ]

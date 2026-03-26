let suites =
  [
    ( "HashSet.String",
      [
        test "smoke" (fun () ->
            let values = Belt.HashSet.String.make ~hintSize:4 in
            Belt.HashSet.String.add values "a";
            assert_int 1 (Belt.HashSet.String.size values);
            assert_array_unordered Alcotest.string [| "a" |] (Belt.HashSet.String.toArray values));
      ] );
  ]

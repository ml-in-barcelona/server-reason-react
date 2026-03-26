let suites =
  [
    ( "MutableSet.String",
      [
        test "smoke" (fun () ->
            let values = Belt.MutableSet.String.make () in
            assert_bool true (Belt.MutableSet.String.addCheck values "a");
            assert_bool false (Belt.MutableSet.String.addCheck values "a");
            assert_array Alcotest.string [| "a" |] (Belt.MutableSet.String.toArray values));
      ] );
  ]

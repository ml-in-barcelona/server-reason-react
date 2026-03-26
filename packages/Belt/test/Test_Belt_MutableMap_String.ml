let suites =
  [
    ( "MutableMap.String",
      [
        test "smoke" (fun () ->
            let values = Belt.MutableMap.String.make () in
            Belt.MutableMap.String.set values "one" 1;
            assert_option Alcotest.int (Some 1) (Belt.MutableMap.String.get values "one"));
      ] );
  ]

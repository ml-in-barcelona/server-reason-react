let suites =
  [
    ( "MutableMap.Int",
      [
        test "smoke" (fun () ->
            let values = Belt.MutableMap.Int.make () in
            Belt.MutableMap.Int.set values 1 "one";
            assert_option Alcotest.string (Some "one") (Belt.MutableMap.Int.get values 1));
      ] );
  ]

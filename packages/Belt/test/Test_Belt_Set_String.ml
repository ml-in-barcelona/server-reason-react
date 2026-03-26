let suites =
  [
    ( "Set.String",
      [
        test "smoke" (fun () ->
            assert_array Alcotest.string [| "a"; "b"; "c" |]
              (Belt.Set.String.toArray (Belt.Set.String.fromArray [| "c"; "a"; "b"; "b" |])));
      ] );
  ]

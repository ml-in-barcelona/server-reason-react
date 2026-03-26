let suites =
  [
    ( "Option",
      [
        test "keep" (fun () ->
            assert_option Alcotest.int (Some 10) (Belt.Option.keep (Some 10) (fun x -> x > 5));
            assert_option Alcotest.int None (Belt.Option.keep (Some 4) (fun x -> x > 5));
            assert_option Alcotest.int None (Belt.Option.keep None (fun x -> x > 5)));
        test "orElse" (fun () ->
            assert_option Alcotest.int (Some 10) (Belt.Option.orElse (Some 10) (Some 20));
            assert_option Alcotest.int (Some 20) (Belt.Option.orElse None (Some 20));
            assert_option Alcotest.int None (Belt.Option.orElse None None));
      ] );
  ]

let suites =
  [
    ( "Int",
      [
        test "toFloat" (fun () ->
            assert_float 1. (Belt.Int.toFloat 1);
            assert_float (-1.) (Belt.Int.toFloat (-1)));
        test "fromFloat" (fun () ->
            assert_int 1 (Belt.Int.fromFloat 1.);
            assert_int 1 (Belt.Int.fromFloat 1.3);
            assert_int 1 (Belt.Int.fromFloat 1.7);
            assert_int (-1) (Belt.Int.fromFloat (-1.));
            assert_int (-1) (Belt.Int.fromFloat (-1.5));
            assert_int (-1) (Belt.Int.fromFloat (-1.7)));
        test "fromString" (fun () ->
            assert_option Alcotest.int (Some 1) (Belt.Int.fromString "1");
            assert_option Alcotest.int (Some (-1)) (Belt.Int.fromString "-1");
            assert_option Alcotest.int (Some 1) (Belt.Int.fromString "1.7");
            assert_option Alcotest.int (Some (-1)) (Belt.Int.fromString "-1.0");
            assert_option Alcotest.int (Some (-1)) (Belt.Int.fromString "-1.5");
            assert_option Alcotest.int (Some (-1)) (Belt.Int.fromString "-1.7");
            assert_option Alcotest.int None (Belt.Int.fromString "not an int"));
        test "fromString follows JS parseInt(_, 10) semantics" (fun () ->
            assert_option Alcotest.int (Some 10) (Belt.Int.fromString "10px");
            assert_option Alcotest.int (Some 0) (Belt.Int.fromString "0x10");
            assert_option Alcotest.int (Some 42) (Belt.Int.fromString " 42 ");
            assert_option Alcotest.int (Some 123) (Belt.Int.fromString "123abc");
            assert_option Alcotest.int None (Belt.Int.fromString "");
            assert_option Alcotest.int None (Belt.Int.fromString "   "));
        test "toString and operators" (fun () ->
            assert_string "1" (Belt.Int.toString 1);
            assert_string "-1" (Belt.Int.toString (-1));
            let open Belt.Int in
            assert_int 5 (2 + 3);
            assert_int (-1) (2 - 3);
            assert_int 6 (2 * 3);
            assert_int 0 (2 / 3));
      ] );
  ]

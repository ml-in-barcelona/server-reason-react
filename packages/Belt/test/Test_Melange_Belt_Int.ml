(* Ported from melange jscomp/test/bs_int_test.ml *)

module I = Belt.Int

let suites =
  [
    ( "Melange.Belt.Int",
      [
        test "toFloat" (fun () ->
            assert_float 1.0 (I.toFloat 1);
            assert_float (-1.0) (I.toFloat (-1)));
        test "fromFloat" (fun () ->
            assert_int 1 (I.fromFloat 1.0);
            assert_int 1 (I.fromFloat 1.3);
            assert_int 1 (I.fromFloat 1.7);
            assert_int (-1) (I.fromFloat (-1.0));
            assert_int (-1) (I.fromFloat (-1.5));
            assert_int (-1) (I.fromFloat (-1.7)));
        test "fromString" (fun () ->
            assert_option Alcotest.int (Some 1) (I.fromString "1");
            assert_option Alcotest.int (Some (-1)) (I.fromString "-1");
            assert_option Alcotest.int (Some 1) (I.fromString "1.7");
            assert_option Alcotest.int (Some (-1)) (I.fromString "-1.0");
            assert_option Alcotest.int (Some (-1)) (I.fromString "-1.5");
            assert_option Alcotest.int (Some (-1)) (I.fromString "-1.7");
            assert_option Alcotest.int None (I.fromString "not an int"));
        test "toString" (fun () ->
            assert_string "1" (I.toString 1);
            assert_string "-1" (I.toString (-1)));
        test "operators" (fun () ->
            let open! I in
            assert_int 5 (2 + 3);
            assert_int (-1) (2 - 3);
            assert_int 6 (2 * 3);
            assert_int 0 (2 / 3));
      ] );
  ]

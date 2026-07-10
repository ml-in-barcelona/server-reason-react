(* Ported from melange jscomp/test/bs_float_test.ml *)

module F = Belt.Float

let suites =
  [
    ( "Melange.Belt.Float",
      [
        test "fromInt" (fun () ->
            assert_float 1.0 (F.fromInt 1);
            assert_float (-1.0) (F.fromInt (-1)));
        test "toInt" (fun () ->
            assert_int 1 (F.toInt 1.0);
            assert_int 1 (F.toInt 1.3);
            assert_int 1 (F.toInt 1.7);
            assert_int (-1) (F.toInt (-1.0));
            assert_int (-1) (F.toInt (-1.5));
            assert_int (-1) (F.toInt (-1.7)));
        test "fromString" (fun () ->
            assert_option float (Some 1.0) (F.fromString "1");
            assert_option float (Some (-1.0)) (F.fromString "-1");
            assert_option float (Some 1.7) (F.fromString "1.7");
            assert_option float (Some (-1.0)) (F.fromString "-1.0");
            assert_option float (Some (-1.5)) (F.fromString "-1.5");
            assert_option float (Some (-1.7)) (F.fromString "-1.7");
            assert_option float None (F.fromString "not a float"));
        test "toString" (fun () ->
            assert_string "1" (F.toString 1.0);
            assert_string "-1" (F.toString (-1.0));
            assert_string "-1.5" (F.toString (-1.5)));
        test "operators" (fun () ->
            let open! F in
            assert_float 5.0 (2.0 + 3.0);
            assert_float (-1.0) (2.0 - 3.0);
            assert_float 6.0 (2.0 * 3.0);
            assert_float 1.5 (3.0 / 2.0));
      ] );
  ]

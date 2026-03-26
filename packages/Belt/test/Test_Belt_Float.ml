let suites =
  [
    ( "Float",
      [
        test "fromInt" (fun () ->
            assert_float 1. (Belt.Float.fromInt 1);
            assert_float (-1.) (Belt.Float.fromInt (-1)));
        test "toInt" (fun () ->
            assert_int 1 (Belt.Float.toInt 1.);
            assert_int 1 (Belt.Float.toInt 1.3);
            assert_int 1 (Belt.Float.toInt 1.7);
            assert_int (-1) (Belt.Float.toInt (-1.));
            assert_int (-1) (Belt.Float.toInt (-1.5));
            assert_int (-1) (Belt.Float.toInt (-1.7)));
        test "fromString" (fun () ->
            assert_option float (Some 1.) (Belt.Float.fromString "1");
            assert_option float (Some (-1.)) (Belt.Float.fromString "-1");
            assert_option float (Some 1.7) (Belt.Float.fromString "1.7");
            assert_option float (Some (-1.)) (Belt.Float.fromString "-1.0");
            assert_option float (Some (-1.5)) (Belt.Float.fromString "-1.5");
            assert_option float (Some (-1.7)) (Belt.Float.fromString "-1.7");
            assert_option float None (Belt.Float.fromString "not a float"));
        test "toString and operators" (fun () ->
            assert_string "1" (Belt.Float.toString 1.);
            assert_string "-1" (Belt.Float.toString (-1.));
            assert_string "-1.5" (Belt.Float.toString (-1.5));
            let open Belt.Float in
            assert_float 5. (2. + 3.);
            assert_float (-1.) (2. - 3.);
            assert_float 6. (2. * 3.);
            assert_float 1.5 (3. / 2.));
      ] );
  ]

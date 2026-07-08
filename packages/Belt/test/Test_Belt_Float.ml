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
        test "fromString follows JS parseFloat semantics" (fun () ->
            (* node: parseFloat("3.5px") === 3.5 *)
            assert_option float (Some 3.5) (Belt.Float.fromString "3.5px");
            (* node: parseFloat("0x10") === 0 (no hex in parseFloat) *)
            assert_option float (Some 0.) (Belt.Float.fromString "0x10");
            (* node: parseFloat(" 42 ") === 42 *)
            assert_option float (Some 42.) (Belt.Float.fromString " 42 ");
            (* node: parseFloat("Infinity") === Infinity *)
            assert_option float (Some infinity) (Belt.Float.fromString "Infinity");
            assert_option float (Some neg_infinity) (Belt.Float.fromString "-Infinity");
            (* node: parseFloat("NaN") and parseFloat("") are NaN *)
            assert_option float None (Belt.Float.fromString "NaN");
            assert_option float None (Belt.Float.fromString ""));
        test "toString follows JS Number#toString semantics" (fun () ->
            (* node: String(0.1 + 0.2) === "0.30000000000000004" *)
            assert_string "0.30000000000000004" (Belt.Float.toString (0.1 +. 0.2));
            (* node: String(80.0) === "80" (no trailing dot) *)
            assert_string "80" (Belt.Float.toString 80.0);
            (* node: String(NaN) === "NaN", String(Infinity) === "Infinity" *)
            assert_string "NaN" (Belt.Float.toString nan);
            assert_string "Infinity" (Belt.Float.toString infinity);
            assert_string "-Infinity" (Belt.Float.toString neg_infinity));
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

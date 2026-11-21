open Helpers

let a1_t1 () = assert_nan (Number.parseFloat "")

let a1_t2 () =
  assert_float (Number.parseFloat "0") 0.0;
  assert_float (Number.parseFloat "1") 1.0;
  assert_float (Number.parseFloat "123") 123.0

let a1_t3 () =
  assert_nan (Number.parseFloat "abc");
  assert_nan (Number.parseFloat "xyz123")

let a1_t4 () =
  assert_float (Number.parseFloat "3.14") 3.14;
  assert_float (Number.parseFloat "0.5") 0.5;
  assert_float (Number.parseFloat "123.456") 123.456

let a1_t5 () =
  assert_float (Number.parseFloat "123abc") 123.0;
  assert_float (Number.parseFloat "3.14xyz") 3.14;
  assert_float (Number.parseFloat "1.5.6") 1.5

let a1_t6 () =
  assert_nan (Number.parseFloat "   ");
  assert_nan (Number.parseFloat "\t\n")

let a1_t7 () =
  assert_nan (Number.parseFloat "$123");
  assert_nan (Number.parseFloat "#123");
  assert_nan (Number.parseFloat "@3.14")

let a2_t1 () =
  assert_float (Number.parseFloat "  123") 123.0;
  assert_float (Number.parseFloat "   3.14") 3.14

let a2_t2 () =
  assert_float (Number.parseFloat "\t123") 123.0;
  assert_float (Number.parseFloat "\t3.14") 3.14

let a2_t3 () =
  assert_float (Number.parseFloat "\n123") 123.0;
  assert_float (Number.parseFloat "\n3.14") 3.14

let a2_t4 () = assert_float (Number.parseFloat "\r123") 123.0
let a2_t5 () = assert_float (Number.parseFloat "\x0C123") 123.0
let a2_t6 () = assert_float (Number.parseFloat "\x0B123") 123.0
let a2_t7 () = assert_float (Number.parseFloat " \t\n\r3.14159") 3.14159
let a2_t8 () = assert_float (Number.parseFloat "\xC2\xA0123.5") 123.5

let a2_t9 () =
  assert_float (Number.parseFloat "123   ") 123.0;
  assert_float (Number.parseFloat "3.14   abc") 3.14

let a2_t10 () =
  assert_nan (Number.parseFloat "- 123");
  assert_nan (Number.parseFloat "+ 3.14")

let a3_t1 () =
  assert_float (Number.parseFloat "+123") 123.0;
  assert_float (Number.parseFloat "+3.14") 3.14

let a3_t2 () =
  assert_float (Number.parseFloat "-123") (-123.0);
  assert_float (Number.parseFloat "-3.14") (-3.14)

let a3_t3 () =
  assert_float (Number.parseFloat "  +123") 123.0;
  assert_float (Number.parseFloat "  -3.14") (-3.14)

let a4_t1 () =
  assert_float (Number.parseFloat "1e10") 1e10;
  assert_float (Number.parseFloat "1e5") 100000.0;
  assert_float (Number.parseFloat "5e0") 5.0

let a4_t2 () =
  assert_float (Number.parseFloat "1E10") 1e10;
  assert_float (Number.parseFloat "2E3") 2000.0

let a4_t3 () =
  assert_float (Number.parseFloat "1e-3") 0.001;
  assert_float (Number.parseFloat "5e-1") 0.5;
  assert_float (Number.parseFloat "1.5e-2") 0.015

let a4_t4 () =
  assert_float (Number.parseFloat "1e+10") 1e10;
  assert_float (Number.parseFloat "2e+3") 2000.0

let a4_t5 () =
  assert_float (Number.parseFloat "1.5e3") 1500.0;
  assert_float (Number.parseFloat "3.14e2") 314.0;
  assert_float (Number.parseFloat "2.5e-1") 0.25

let a4_t6 () =
  assert_float (Number.parseFloat "1e") 1.0;
  assert_float (Number.parseFloat "1e+") 1.0;
  assert_float (Number.parseFloat "1e-") 1.0

let a4_t7 () =
  assert_infinity (Number.parseFloat "1e309");
  assert_float (Number.parseFloat "1e308") 1e308

let a5_t1 () =
  assert_infinity (Number.parseFloat "Infinity");
  assert_neg_infinity (Number.parseFloat "-Infinity")

let a5_t2 () =
  assert_infinity (Number.parseFloat "+Infinity");
  assert_neg_infinity (Number.parseFloat "-Infinity")

let a5_t3 () =
  assert_infinity (Number.parseFloat "  Infinity");
  assert_neg_infinity (Number.parseFloat "  -Infinity")

let a5_t4 () =
  assert_infinity (Number.parseFloat "Infinityxyz");
  assert_infinity (Number.parseFloat "Infinity123")

let a6 () =
  assert_float (Number.parseFloat "1.2.3") 1.2;
  assert_nan (Number.parseFloat "...3");
  assert_nan (Number.parseFloat "..3")

let a7_5 () =
  assert_float (Number.parseFloat ".5") 0.5;
  assert_float (Number.parseFloat ".123") 0.123;
  assert_float (Number.parseFloat "-.5") (-0.5);
  assert_float (Number.parseFloat "+.5") 0.5

let a7_6 () =
  assert_float (Number.parseFloat "5.") 5.0;
  assert_float (Number.parseFloat "123.") 123.0

let a7_7 () =
  assert_float (Number.parseFloat ".5e2") 50.0;
  assert_float (Number.parseFloat "5.e2") 500.0;
  assert_float (Number.parseFloat ".1e-1") 0.01

let misc_t1 () =
  assert_float (Number.parseFloat "0x10") 0.0;
  assert_float (Number.parseFloat "0xFF") 0.0

let misc_t2 () =
  assert_float (Number.parseFloat "0b101") 0.0;
  assert_float (Number.parseFloat "0o777") 0.0

let misc_t3 () =
  assert_float (Number.parseFloat "00123") 123.0;
  assert_float (Number.parseFloat "007.5") 7.5;
  assert_float (Number.parseFloat "0000") 0.0

let misc_t4 () =
  assert_nan (Number.parseFloat "NaN");
  assert_nan (Number.parseFloat "nan")

let misc_t5 () =
  assert_nan (Number.parseFloat "+");
  assert_nan (Number.parseFloat "-");
  assert_nan (Number.parseFloat "++1");
  assert_nan (Number.parseFloat "--1");
  assert_nan (Number.parseFloat "+-1")

let misc_t6 () =
  assert_float (Number.parseFloat "1e-323") 1e-323;
  assert_float (Number.parseFloat "5e-324") 5e-324

let misc_t7 () =
  let result = Number.parseFloat "-0" in
  assert_float result 0.0;
  assert_negative_zero result

let misc_t8 () =
  assert_float (Number.parseFloat "9007199254740993") 9007199254740992.0;
  assert_float (Number.parseFloat "0.1") 0.1

let misc_t9 () =
  assert_nan (Number.parseFloat "e10");
  assert_nan (Number.parseFloat "E10")

let misc_t10 () = assert_float (Number.parseFloat "\t\n\x0B\x0C\r 3.14") 3.14

let misc_t11 () =
  assert_nan (Number.parseFloat "infinity");
  assert_nan (Number.parseFloat "INFINITY");
  assert_infinity (Number.parseFloat "Infinity")

let misc_t12 () =
  assert_float (Number.parseFloat "-.0") (-0.0);
  assert_float (Number.parseFloat "+.0") 0.0;
  assert_float (Number.parseFloat "-.1") (-0.1);
  assert_float (Number.parseFloat "+.1") 0.1

let misc_t13 () =
  assert_float (Number.parseFloat "1e2e3") 100.0;
  assert_float (Number.parseFloat "1E2E3") 100.0

let misc_t14 () = assert_float (Number.parseFloat "1e2.5") 100.0

let tests =
  [
    test "S15.1.2.3_A1_T1: empty string returns NaN" a1_t1;
    test "S15.1.2.3_A1_T2: simple integers" a1_t2;
    test "S15.1.2.3_A1_T3: non-numeric returns NaN" a1_t3;
    test "S15.1.2.3_A1_T4: decimal numbers" a1_t4;
    test "S15.1.2.3_A1_T5: stops at invalid char" a1_t5;
    test "S15.1.2.3_A1_T6: whitespace only returns NaN" a1_t6;
    test "S15.1.2.3_A1_T7: invalid start chars" a1_t7;
    test "S15.1.2.3_A2_T1: leading spaces" a2_t1;
    test "S15.1.2.3_A2_T2: leading tabs" a2_t2;
    test "S15.1.2.3_A2_T3: leading newlines" a2_t3;
    test "S15.1.2.3_A2_T4: leading carriage return" a2_t4;
    test "S15.1.2.3_A2_T5: leading form feed" a2_t5;
    test "S15.1.2.3_A2_T6: leading vertical tab" a2_t6;
    test "S15.1.2.3_A2_T7: mixed whitespace" a2_t7;
    test "S15.1.2.3_A2_T8: non-breaking space" a2_t8;
    test "S15.1.2.3_A2_T9: trailing characters" a2_t9;
    test "S15.1.2.3_A2_T10: whitespace between sign and number" a2_t10;
    test "S15.1.2.3_A3_T1: positive sign" a3_t1;
    test "S15.1.2.3_A3_T2: negative sign" a3_t2;
    test "S15.1.2.3_A3_T3: sign with whitespace" a3_t3;
    test "S15.1.2.3_A4_T1: basic exponent" a4_t1;
    test "S15.1.2.3_A4_T2: uppercase E" a4_t2;
    test "S15.1.2.3_A4_T3: negative exponent" a4_t3;
    test "S15.1.2.3_A4_T4: positive exponent with +" a4_t4;
    test "S15.1.2.3_A4_T5: decimal with exponent" a4_t5;
    test "S15.1.2.3_A4_T6: incomplete exponent" a4_t6;
    test "S15.1.2.3_A4_T7: very large exponents" a4_t7;
    test "S15.1.2.3_A5_T1: Infinity string" a5_t1;
    test "S15.1.2.3_A5_T2: signed Infinity" a5_t2;
    test "S15.1.2.3_A5_T3: Infinity with whitespace" a5_t3;
    test "S15.1.2.3_A5_T4: Infinity with trailing chars" a5_t4;
    test "S15.1.2.3_A6: multiple decimal points" a6;
    test "S15.1.2.3_A7.5: leading decimal point" a7_5;
    test "S15.1.2.3_A7.6: trailing decimal point" a7_6;
    test "S15.1.2.3_A7.7: decimal with exponent" a7_7;
    test "misc_t1: hex not supported" misc_t1;
    test "misc_t2: binary/octal not supported" misc_t2;
    test "misc_t3: leading zeros" misc_t3;
    test "misc_t4: NaN string" misc_t4;
    test "misc_t5: sign edge cases" misc_t5;
    test "misc_t6: very small numbers" misc_t6;
    test "misc_t7: negative zero" misc_t7;
    test "misc_t8: precision loss" misc_t8;
    test "misc_t9: exponent without mantissa" misc_t9;
    test "misc_t10: comprehensive whitespace" misc_t10;
    test "misc_t11: Infinity case sensitivity" misc_t11;
    test "misc_t12: sign with decimal only" misc_t12;
    test "misc_t13: multiple e" misc_t13;
    test "misc_t14: exponent with decimal" misc_t14;
  ]

(** TC39 Test262: parseFloat tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/parseFloat

    ECMA-262 Section: parseFloat(string)

    Test naming convention follows tc39/test262:
    - S15.1.2.3_A{section}_T{test} format for legacy tests *)

open Helpers

(* ===================================================================
   S15.1.2.3_A1: Basic parsing tests
   =================================================================== *)

let a1_t1 () =
  (* parseFloat("") should return NaN *)
  assert_nan (Number.parseFloat "")

let a1_t2 () =
  (* parseFloat with simple integers *)
  assert_float (Number.parseFloat "0") 0.0;
  assert_float (Number.parseFloat "1") 1.0;
  assert_float (Number.parseFloat "123") 123.0

let a1_t3 () =
  (* parseFloat with no numeric characters should return NaN *)
  assert_nan (Number.parseFloat "abc");
  assert_nan (Number.parseFloat "xyz123")
(* starts with non-digit *)

let a1_t4 () =
  (* parseFloat with decimal numbers *)
  assert_float (Number.parseFloat "3.14") 3.14;
  assert_float (Number.parseFloat "0.5") 0.5;
  assert_float (Number.parseFloat "123.456") 123.456

let a1_t5 () =
  (* parseFloat stops at invalid character *)
  assert_float (Number.parseFloat "123abc") 123.0;
  assert_float (Number.parseFloat "3.14xyz") 3.14;
  assert_float (Number.parseFloat "1.5.6") 1.5 (* second decimal point stops parsing *)

let a1_t6 () =
  (* parseFloat with only whitespace returns NaN *)
  assert_nan (Number.parseFloat "   ");
  assert_nan (Number.parseFloat "\t\n")

let a1_t7 () =
  (* parseFloat behavior with various invalid starts *)
  assert_nan (Number.parseFloat "$123");
  assert_nan (Number.parseFloat "#123");
  assert_nan (Number.parseFloat "@3.14")

(* ===================================================================
   S15.1.2.3_A2: Whitespace handling
   =================================================================== *)

let a2_t1 () =
  (* Leading spaces *)
  assert_float (Number.parseFloat "  123") 123.0;
  assert_float (Number.parseFloat "   3.14") 3.14

let a2_t2 () =
  (* Leading tabs *)
  assert_float (Number.parseFloat "\t123") 123.0;
  assert_float (Number.parseFloat "\t3.14") 3.14

let a2_t3 () =
  (* Leading newlines *)
  assert_float (Number.parseFloat "\n123") 123.0;
  assert_float (Number.parseFloat "\n3.14") 3.14

let a2_t4 () =
  (* Leading carriage return *)
  assert_float (Number.parseFloat "\r123") 123.0

let a2_t5 () =
  (* Leading form feed *)
  assert_float (Number.parseFloat "\x0C123") 123.0

let a2_t6 () =
  (* Leading vertical tab *)
  assert_float (Number.parseFloat "\x0B123") 123.0

let a2_t7 () =
  (* Multiple whitespace types *)
  assert_float (Number.parseFloat " \t\n\r3.14159") 3.14159

let a2_t8 () =
  (* Non-breaking space (U+00A0) - JavaScript treats NBSP as whitespace in parseFloat *)
  assert_float (Number.parseFloat "\xC2\xA0123.5") 123.5

let a2_t9 () =
  (* Trailing characters are ignored *)
  assert_float (Number.parseFloat "123   ") 123.0;
  assert_float (Number.parseFloat "3.14   abc") 3.14

let a2_t10 () =
  (* Whitespace between sign and number *)
  assert_nan (Number.parseFloat "- 123");
  assert_nan (Number.parseFloat "+ 3.14")

(* ===================================================================
   S15.1.2.3_A3: Sign handling
   =================================================================== *)

let a3_t1 () =
  (* Positive sign *)
  assert_float (Number.parseFloat "+123") 123.0;
  assert_float (Number.parseFloat "+3.14") 3.14

let a3_t2 () =
  (* Negative sign *)
  assert_float (Number.parseFloat "-123") (-123.0);
  assert_float (Number.parseFloat "-3.14") (-3.14)

let a3_t3 () =
  (* Sign with whitespace before *)
  assert_float (Number.parseFloat "  +123") 123.0;
  assert_float (Number.parseFloat "  -3.14") (-3.14)

(* ===================================================================
   S15.1.2.3_A4: Scientific notation (exponent)
   =================================================================== *)

let a4_t1 () =
  (* Basic exponent with e *)
  assert_float (Number.parseFloat "1e10") 1e10;
  assert_float (Number.parseFloat "1e5") 100000.0;
  assert_float (Number.parseFloat "5e0") 5.0

let a4_t2 () =
  (* Exponent with E (uppercase) *)
  assert_float (Number.parseFloat "1E10") 1e10;
  assert_float (Number.parseFloat "2E3") 2000.0

let a4_t3 () =
  (* Negative exponent *)
  assert_float (Number.parseFloat "1e-3") 0.001;
  assert_float (Number.parseFloat "5e-1") 0.5;
  assert_float (Number.parseFloat "1.5e-2") 0.015

let a4_t4 () =
  (* Positive exponent with explicit + *)
  assert_float (Number.parseFloat "1e+10") 1e10;
  assert_float (Number.parseFloat "2e+3") 2000.0

let a4_t5 () =
  (* Decimal with exponent *)
  assert_float (Number.parseFloat "1.5e3") 1500.0;
  assert_float (Number.parseFloat "3.14e2") 314.0;
  assert_float (Number.parseFloat "2.5e-1") 0.25

let a4_t6 () =
  (* Exponent edge cases *)
  assert_float (Number.parseFloat "1e") 1.0;
  (* incomplete exponent - returns mantissa *)
  assert_float (Number.parseFloat "1e+") 1.0;
  (* incomplete exponent *)
  assert_float (Number.parseFloat "1e-") 1.0 (* incomplete exponent *)

let a4_t7 () =
  (* Very large exponents *)
  assert_infinity (Number.parseFloat "1e309");
  (* Overflow to Infinity *)
  assert_float (Number.parseFloat "1e308") 1e308

(* ===================================================================
   S15.1.2.3_A5: Infinity
   =================================================================== *)

let a5_t1 () =
  (* Infinity string *)
  assert_infinity (Number.parseFloat "Infinity");
  assert_neg_infinity (Number.parseFloat "-Infinity")

let a5_t2 () =
  (* Infinity with sign *)
  assert_infinity (Number.parseFloat "+Infinity");
  assert_neg_infinity (Number.parseFloat "-Infinity")

let a5_t3 () =
  (* Infinity with leading whitespace *)
  assert_infinity (Number.parseFloat "  Infinity");
  assert_neg_infinity (Number.parseFloat "  -Infinity")

let a5_t4 () =
  (* Infinity followed by characters *)
  assert_infinity (Number.parseFloat "Infinityxyz");
  assert_infinity (Number.parseFloat "Infinity123")

(* ===================================================================
   S15.1.2.3_A6: Miscellaneous edge cases
   =================================================================== *)

let a6 () =
  (* Multiple decimal points *)
  assert_float (Number.parseFloat "1.2.3") 1.2;
  (* In JavaScript, both "...3" and "..3" return NaN:
     - First "." is valid but followed by another "." which stops parsing
     - No valid digits found, so result is NaN *)
  assert_nan (Number.parseFloat "...3");
  assert_nan (Number.parseFloat "..3")

let a7_5 () =
  (* Leading decimal point *)
  assert_float (Number.parseFloat ".5") 0.5;
  assert_float (Number.parseFloat ".123") 0.123;
  assert_float (Number.parseFloat "-.5") (-0.5);
  assert_float (Number.parseFloat "+.5") 0.5

let a7_6 () =
  (* Trailing decimal point *)
  assert_float (Number.parseFloat "5.") 5.0;
  assert_float (Number.parseFloat "123.") 123.0

let a7_7 () =
  (* Decimal point with exponent *)
  assert_float (Number.parseFloat ".5e2") 50.0;
  assert_float (Number.parseFloat "5.e2") 500.0;
  assert_float (Number.parseFloat ".1e-1") 0.01

(* ===================================================================
   Additional edge cases
   =================================================================== *)

let misc_t1 () =
  (* Hex notation NOT supported by parseFloat *)
  assert_float (Number.parseFloat "0x10") 0.0;
  (* stops at 'x' *)
  assert_float (Number.parseFloat "0xFF") 0.0

let misc_t2 () =
  (* Binary/Octal prefixes NOT supported *)
  assert_float (Number.parseFloat "0b101") 0.0;
  (* stops at 'b' *)
  assert_float (Number.parseFloat "0o777") 0.0 (* stops at 'o' *)

let misc_t3 () =
  (* Leading zeros *)
  assert_float (Number.parseFloat "00123") 123.0;
  assert_float (Number.parseFloat "007.5") 7.5;
  assert_float (Number.parseFloat "0000") 0.0

let misc_t4 () =
  (* NaN string does NOT parse to NaN value *)
  assert_nan (Number.parseFloat "NaN");
  (* Actually JS returns NaN for "NaN" *)
  assert_nan (Number.parseFloat "nan")
(* case sensitive *)

let misc_t5 () =
  (* Sign edge cases *)
  assert_nan (Number.parseFloat "+");
  assert_nan (Number.parseFloat "-");
  assert_nan (Number.parseFloat "++1");
  assert_nan (Number.parseFloat "--1");
  assert_nan (Number.parseFloat "+-1")

let misc_t6 () =
  (* Very small numbers *)
  assert_float (Number.parseFloat "1e-323") 1e-323;
  assert_float (Number.parseFloat "5e-324") 5e-324 (* MIN_VALUE *)

let misc_t7 () =
  (* Negative zero *)
  let result = Number.parseFloat "-0" in
  assert_float result 0.0;
  (* -0.0 = 0.0 in comparison *)
  assert_negative_zero result

let misc_t8 () =
  (* Numbers that would lose precision *)
  assert_float (Number.parseFloat "9007199254740993") 9007199254740992.0;
  (* > MAX_SAFE_INTEGER *)
  assert_float (Number.parseFloat "0.1") 0.1 (* known floating point representation issue *)

let misc_t9 () =
  (* Exponent without mantissa digits before e *)
  assert_nan (Number.parseFloat "e10");
  assert_nan (Number.parseFloat "E10")

let misc_t10 () =
  (* Comprehensive whitespace *)
  assert_float (Number.parseFloat "\t\n\x0B\x0C\r 3.14") 3.14

let misc_t11 () =
  (* Mixed case Infinity *)
  assert_nan (Number.parseFloat "infinity");
  (* case sensitive *)
  assert_nan (Number.parseFloat "INFINITY");
  assert_infinity (Number.parseFloat "Infinity")

let misc_t12 () =
  (* Plus and minus with decimals *)
  assert_float (Number.parseFloat "-.0") (-0.0);
  assert_float (Number.parseFloat "+.0") 0.0;
  assert_float (Number.parseFloat "-.1") (-0.1);
  assert_float (Number.parseFloat "+.1") 0.1

let misc_t13 () =
  (* Multiple e in number *)
  assert_float (Number.parseFloat "1e2e3") 100.0;
  (* stops at second e *)
  assert_float (Number.parseFloat "1E2E3") 100.0

let misc_t14 () =
  (* Exponent with decimal *)
  assert_float (Number.parseFloat "1e2.5") 100.0 (* stops at . in exponent *)

let tests =
  [
    (* A1: Basic parsing *)
    test "S15.1.2.3_A1_T1: empty string returns NaN" a1_t1;
    test "S15.1.2.3_A1_T2: simple integers" a1_t2;
    test "S15.1.2.3_A1_T3: non-numeric returns NaN" a1_t3;
    test "S15.1.2.3_A1_T4: decimal numbers" a1_t4;
    test "S15.1.2.3_A1_T5: stops at invalid char" a1_t5;
    test "S15.1.2.3_A1_T6: whitespace only returns NaN" a1_t6;
    test "S15.1.2.3_A1_T7: invalid start chars" a1_t7;
    (* A2: Whitespace handling *)
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
    (* A3: Sign handling *)
    test "S15.1.2.3_A3_T1: positive sign" a3_t1;
    test "S15.1.2.3_A3_T2: negative sign" a3_t2;
    test "S15.1.2.3_A3_T3: sign with whitespace" a3_t3;
    (* A4: Scientific notation *)
    test "S15.1.2.3_A4_T1: basic exponent" a4_t1;
    test "S15.1.2.3_A4_T2: uppercase E" a4_t2;
    test "S15.1.2.3_A4_T3: negative exponent" a4_t3;
    test "S15.1.2.3_A4_T4: positive exponent with +" a4_t4;
    test "S15.1.2.3_A4_T5: decimal with exponent" a4_t5;
    test "S15.1.2.3_A4_T6: incomplete exponent" a4_t6;
    test "S15.1.2.3_A4_T7: very large exponents" a4_t7;
    (* A5: Infinity *)
    test "S15.1.2.3_A5_T1: Infinity string" a5_t1;
    test "S15.1.2.3_A5_T2: signed Infinity" a5_t2;
    test "S15.1.2.3_A5_T3: Infinity with whitespace" a5_t3;
    test "S15.1.2.3_A5_T4: Infinity with trailing chars" a5_t4;
    (* A6-A7: Edge cases *)
    test "S15.1.2.3_A6: multiple decimal points" a6;
    test "S15.1.2.3_A7.5: leading decimal point" a7_5;
    test "S15.1.2.3_A7.6: trailing decimal point" a7_6;
    test "S15.1.2.3_A7.7: decimal with exponent" a7_7;
    (* Miscellaneous *)
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

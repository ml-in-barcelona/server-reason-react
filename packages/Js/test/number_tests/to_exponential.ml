(** TC39 Test262: Number.prototype.toExponential tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/Number/prototype/toExponential

    ECMA-262 Section: Number.prototype.toExponential([fractionDigits]) *)

open Helpers

(* ===================================================================
   Basic toExponential without fractionDigits
   =================================================================== *)

let basic_no_digits () =
  (* Without fractionDigits, uses the minimum digits needed *)
  assert_string (Number.toExponential 1.0) "1";
  assert_string (Number.toExponential 123.0) "123";
  assert_string (Number.toExponential 0.0) "0"

(* ===================================================================
   toExponential with fractionDigits
   =================================================================== *)

let with_digits_zero () =
  assert_string (Number.toExponential ~digits:0 1.0) "1e+0";
  assert_string (Number.toExponential ~digits:0 123.0) "1e+2";
  assert_string (Number.toExponential ~digits:0 0.5) "5e-1"

let with_digits_one () =
  assert_string (Number.toExponential ~digits:1 1.0) "1.0e+0";
  assert_string (Number.toExponential ~digits:1 123.0) "1.2e+2";
  assert_string (Number.toExponential ~digits:1 0.05) "5.0e-2"

let with_digits_multiple () =
  assert_string (Number.toExponential ~digits:2 123.0) "1.23e+2";
  assert_string (Number.toExponential ~digits:3 123.0) "1.230e+2";
  assert_string (Number.toExponential ~digits:4 12345.0) "1.2345e+4"

let with_large_digits () =
  assert_string (Number.toExponential ~digits:10 1.0) "1.0000000000e+0";
  assert_string (Number.toExponential ~digits:20 1.0) "1.00000000000000000000e+0"

(* ===================================================================
   Special values
   =================================================================== *)

let special_values () =
  assert_string (Number.toExponential nan) "NaN";
  assert_string (Number.toExponential infinity) "Infinity";
  assert_string (Number.toExponential neg_infinity) "-Infinity"

let special_values_with_digits () =
  assert_string (Number.toExponential ~digits:2 nan) "NaN";
  assert_string (Number.toExponential ~digits:2 infinity) "Infinity";
  assert_string (Number.toExponential ~digits:2 neg_infinity) "-Infinity"

(* ===================================================================
   Negative numbers
   =================================================================== *)

let negative_numbers () =
  assert_string (Number.toExponential ~digits:0 (-1.0)) "-1e+0";
  assert_string (Number.toExponential ~digits:2 (-123.0)) "-1.23e+2";
  assert_string (Number.toExponential ~digits:1 (-0.05)) "-5.0e-2"

(* ===================================================================
   Rounding
   =================================================================== *)

let rounding () =
  assert_string (Number.toExponential ~digits:1 1.25) "1.3e+0";
  assert_string (Number.toExponential ~digits:1 1.24) "1.2e+0";
  assert_string (Number.toExponential ~digits:0 1.5) "2e+0";
  (* Note: 1.005 is actually stored as slightly less than 1.005 in IEEE 754 *)
  assert_string (Number.toExponential ~digits:2 1.005) "1.00e+0"

(* ===================================================================
   Edge cases
   =================================================================== *)

let very_small_numbers () =
  assert_string (Number.toExponential ~digits:2 0.0001) "1.00e-4";
  assert_string (Number.toExponential ~digits:2 1e-10) "1.00e-10"

let very_large_numbers () =
  assert_string (Number.toExponential ~digits:2 1e10) "1.00e+10";
  assert_string (Number.toExponential ~digits:2 1e20) "1.00e+20"

let negative_zero () =
  assert_string (Number.toExponential ~digits:0 (-0.0)) "0e+0"

let tests =
  [
    (* Basic *)
    test "basic: no digits" basic_no_digits;
    (* With digits *)
    test "digits: 0" with_digits_zero;
    test "digits: 1" with_digits_one;
    test "digits: multiple" with_digits_multiple;
    test "digits: large" with_large_digits;
    (* Special values *)
    test "special values" special_values;
    test "special values with digits" special_values_with_digits;
    (* Negative numbers *)
    test "negative numbers" negative_numbers;
    (* Rounding *)
    test "rounding" rounding;
    (* Edge cases *)
    test "very small numbers" very_small_numbers;
    test "very large numbers" very_large_numbers;
    test "negative zero" negative_zero;
  ]


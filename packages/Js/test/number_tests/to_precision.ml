(** TC39 Test262: Number.prototype.toPrecision tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/Number/prototype/toPrecision

    ECMA-262 Section: Number.prototype.toPrecision([precision]) *)

open Helpers

(* ===================================================================
   Basic toPrecision without precision argument
   =================================================================== *)

let basic_no_precision () =
  (* Without precision, returns same as toString *)
  assert_string (Number.toPrecision 1.0) "1";
  assert_string (Number.toPrecision 123.0) "123";
  assert_string (Number.toPrecision 3.14159) "3.14159"

(* ===================================================================
   toPrecision with precision argument
   =================================================================== *)

let precision_1 () =
  assert_string (Number.toPrecision ~digits:1 1.0) "1";
  assert_string (Number.toPrecision ~digits:1 12.0) "1e+1";
  assert_string (Number.toPrecision ~digits:1 123.0) "1e+2";
  assert_string (Number.toPrecision ~digits:1 0.5) "0.5";
  assert_string (Number.toPrecision ~digits:1 0.05) "0.05"

let precision_2 () =
  assert_string (Number.toPrecision ~digits:2 1.0) "1.0";
  assert_string (Number.toPrecision ~digits:2 12.0) "12";
  assert_string (Number.toPrecision ~digits:2 123.0) "1.2e+2";
  assert_string (Number.toPrecision ~digits:2 0.05) "0.050"

let precision_multiple () =
  assert_string (Number.toPrecision ~digits:3 123.0) "123";
  assert_string (Number.toPrecision ~digits:4 123.0) "123.0";
  assert_string (Number.toPrecision ~digits:5 123.0) "123.00";
  assert_string (Number.toPrecision ~digits:6 123.456) "123.456"

let precision_large () =
  assert_string (Number.toPrecision ~digits:10 1.0) "1.000000000";
  assert_string (Number.toPrecision ~digits:20 1.0) "1.0000000000000000000"

(* ===================================================================
   Special values
   =================================================================== *)

let special_values () =
  assert_string (Number.toPrecision nan) "NaN";
  assert_string (Number.toPrecision infinity) "Infinity";
  assert_string (Number.toPrecision neg_infinity) "-Infinity"

let special_values_with_precision () =
  assert_string (Number.toPrecision ~digits:2 nan) "NaN";
  assert_string (Number.toPrecision ~digits:2 infinity) "Infinity";
  assert_string (Number.toPrecision ~digits:2 neg_infinity) "-Infinity"

(* ===================================================================
   Negative numbers
   =================================================================== *)

let negative_numbers () =
  assert_string (Number.toPrecision ~digits:1 (-1.0)) "-1";
  assert_string (Number.toPrecision ~digits:2 (-123.0)) "-1.2e+2";
  assert_string (Number.toPrecision ~digits:4 (-123.4)) "-123.4"

(* ===================================================================
   Rounding
   =================================================================== *)

let rounding () =
  assert_string (Number.toPrecision ~digits:2 1.25) "1.3";
  assert_string (Number.toPrecision ~digits:2 1.24) "1.2";
  (* Note: 1.005 is actually stored as slightly less than 1.005 in IEEE 754 *)
  assert_string (Number.toPrecision ~digits:3 1.005) "1.00";
  assert_string (Number.toPrecision ~digits:3 1234.0) "1.23e+3"

(* ===================================================================
   Edge cases
   =================================================================== *)

let zero_handling () =
  assert_string (Number.toPrecision ~digits:1 0.0) "0";
  assert_string (Number.toPrecision ~digits:2 0.0) "0.0";
  assert_string (Number.toPrecision ~digits:5 0.0) "0.0000"

let negative_zero () = assert_string (Number.toPrecision ~digits:1 (-0.0)) "0"

let very_small_numbers () =
  assert_string (Number.toPrecision ~digits:2 0.0001) "0.00010";
  assert_string (Number.toPrecision ~digits:2 1e-10) "1.0e-10"

let very_large_numbers () =
  assert_string (Number.toPrecision ~digits:2 1e10) "1.0e+10";
  assert_string (Number.toPrecision ~digits:5 12345.0) "12345"

let tests =
  [
    (* Basic *)
    test "basic: no precision" basic_no_precision;
    (* With precision *)
    test "precision: 1" precision_1;
    test "precision: 2" precision_2;
    test "precision: multiple" precision_multiple;
    test "precision: large" precision_large;
    (* Special values *)
    test "special values" special_values;
    test "special values with precision" special_values_with_precision;
    (* Negative numbers *)
    test "negative numbers" negative_numbers;
    (* Rounding *)
    test "rounding" rounding;
    (* Edge cases *)
    test "zero handling" zero_handling;
    test "negative zero" negative_zero;
    test "very small numbers" very_small_numbers;
    test "very large numbers" very_large_numbers;
  ]

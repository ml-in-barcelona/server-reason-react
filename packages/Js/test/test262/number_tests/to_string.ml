(** TC39 Test262: Number.prototype.toString tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/Number/prototype/toString

    ECMA-262 Section: Number.prototype.toString([radix]) *)

open Helpers

(* ===================================================================
   Basic toString (no radix)
   =================================================================== *)

let basic_integers () =
  assert_string (Number.toString 0.0) "0";
  assert_string (Number.toString 1.0) "1";
  assert_string (Number.toString 42.0) "42";
  assert_string (Number.toString 123.0) "123";
  assert_string (Number.toString (-1.0)) "-1";
  assert_string (Number.toString (-123.0)) "-123"

let basic_decimals () =
  assert_string (Number.toString 0.5) "0.5";
  assert_string (Number.toString 3.14159) "3.14159";
  assert_string (Number.toString (-0.5)) "-0.5";
  assert_string (Number.toString 1.23) "1.23"

let special_values () =
  assert_string (Number.toString nan) "NaN";
  assert_string (Number.toString infinity) "Infinity";
  assert_string (Number.toString neg_infinity) "-Infinity"

let scientific_notation () =
  (* Very large numbers use exponential notation *)
  assert_string (Number.toString 1e20) "100000000000000000000";
  assert_string (Number.toString 1e21) "1e+21";
  (* Very small numbers *)
  assert_string (Number.toString 1e-6) "0.000001";
  assert_string (Number.toString 1e-7) "1e-7"

let negative_zero () =
  (* Note: toString of -0 returns "0" *)
  assert_string (Number.toString (-0.0)) "0"

(* ===================================================================
   toString with radix
   =================================================================== *)

let radix_2_binary () =
  assert_string (Number.toString ~radix:2 0.0) "0";
  assert_string (Number.toString ~radix:2 1.0) "1";
  assert_string (Number.toString ~radix:2 2.0) "10";
  assert_string (Number.toString ~radix:2 10.0) "1010";
  assert_string (Number.toString ~radix:2 255.0) "11111111"

let radix_8_octal () =
  assert_string (Number.toString ~radix:8 0.0) "0";
  assert_string (Number.toString ~radix:8 7.0) "7";
  assert_string (Number.toString ~radix:8 8.0) "10";
  assert_string (Number.toString ~radix:8 64.0) "100";
  assert_string (Number.toString ~radix:8 255.0) "377"

let radix_16_hex () =
  assert_string (Number.toString ~radix:16 0.0) "0";
  assert_string (Number.toString ~radix:16 15.0) "f";
  assert_string (Number.toString ~radix:16 16.0) "10";
  assert_string (Number.toString ~radix:16 255.0) "ff";
  assert_string (Number.toString ~radix:16 256.0) "100"

let radix_36_max () =
  assert_string (Number.toString ~radix:36 0.0) "0";
  assert_string (Number.toString ~radix:36 35.0) "z";
  assert_string (Number.toString ~radix:36 36.0) "10";
  assert_string (Number.toString ~radix:36 1295.0) "zz"

let radix_10_explicit () =
  assert_string (Number.toString ~radix:10 0.0) "0";
  assert_string (Number.toString ~radix:10 123.0) "123";
  assert_string (Number.toString ~radix:10 (-456.0)) "-456"

let negative_with_radix () =
  assert_string (Number.toString ~radix:2 (-10.0)) "-1010";
  assert_string (Number.toString ~radix:16 (-255.0)) "-ff";
  assert_string (Number.toString ~radix:8 (-64.0)) "-100"

(* ===================================================================
   Special values with radix
   =================================================================== *)

let special_values_with_radix () =
  assert_string (Number.toString ~radix:2 nan) "NaN";
  assert_string (Number.toString ~radix:16 infinity) "Infinity";
  assert_string (Number.toString ~radix:8 neg_infinity) "-Infinity"

(* ===================================================================
   Edge cases
   =================================================================== *)

let large_numbers () =
  assert_string (Number.toString max_safe_integer) "9007199254740991";
  assert_string (Number.toString min_safe_integer) "-9007199254740991"

let tests =
  [
    (* Basic toString *)
    test "basic: integers" basic_integers;
    test "basic: decimals" basic_decimals;
    test "basic: special values" special_values;
    test "basic: scientific notation" scientific_notation;
    test "basic: negative zero" negative_zero;
    (* With radix *)
    test "radix 2: binary" radix_2_binary;
    test "radix 8: octal" radix_8_octal;
    test "radix 16: hex" radix_16_hex;
    test "radix 36: max" radix_36_max;
    test "radix 10: explicit" radix_10_explicit;
    test "negative with radix" negative_with_radix;
    test "special values with radix" special_values_with_radix;
    test "large numbers" large_numbers;
  ]


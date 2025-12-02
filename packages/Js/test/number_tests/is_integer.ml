(** TC39 Test262: Number.isInteger tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/Number/isInteger

    ECMA-262 Section: Number.isInteger(number)

    Note: Number.isInteger returns true if the number is a finite number with no fractional part. *)

open Helpers

(* ===================================================================
   Integer values should return true
   =================================================================== *)

let zero_values () =
  assert_bool (Number.isInteger 0.0) true;
  assert_bool (Number.isInteger (-0.0)) true

let positive_integers () =
  assert_bool (Number.isInteger 1.0) true;
  assert_bool (Number.isInteger 2.0) true;
  assert_bool (Number.isInteger 42.0) true;
  assert_bool (Number.isInteger 100.0) true;
  assert_bool (Number.isInteger 1000000.0) true

let negative_integers () =
  assert_bool (Number.isInteger (-1.0)) true;
  assert_bool (Number.isInteger (-2.0)) true;
  assert_bool (Number.isInteger (-42.0)) true;
  assert_bool (Number.isInteger (-100.0)) true

let large_integers () =
  assert_bool (Number.isInteger max_safe_integer) true;
  assert_bool (Number.isInteger min_safe_integer) true;
  assert_bool (Number.isInteger 9007199254740992.0) true (* MAX_SAFE_INTEGER + 1 *)

let decimal_zero_fraction () =
  (* Numbers that look like decimals but have .0 *)
  assert_bool (Number.isInteger 5.0) true;
  assert_bool (Number.isInteger 123.0) true;
  assert_bool (Number.isInteger 1e10) true (* 10000000000.0 *)

(* ===================================================================
   Non-integer values should return false
   =================================================================== *)

let decimals () =
  assert_bool (Number.isInteger 0.1) false;
  assert_bool (Number.isInteger 0.5) false;
  assert_bool (Number.isInteger 1.5) false;
  assert_bool (Number.isInteger 3.14159) false;
  assert_bool (Number.isInteger (-2.71828)) false

let small_fractions () =
  assert_bool (Number.isInteger 0.0001) false;
  assert_bool (Number.isInteger 1.0001) false;
  assert_bool (Number.isInteger 1e-10) false

(* ===================================================================
   Special values should return false
   =================================================================== *)

let nan_value () = assert_bool (Number.isInteger nan) false

let infinity_values () =
  assert_bool (Number.isInteger infinity) false;
  assert_bool (Number.isInteger neg_infinity) false

(* ===================================================================
   Edge cases
   =================================================================== *)

let max_value_is_integer () =
  (* MAX_VALUE is an integer (though very large) *)
  assert_bool (Number.isInteger max_value) true;
  assert_bool (Number.isInteger (-.max_value)) true

let min_value_is_not_integer () =
  (* MIN_VALUE is 5e-324, a very small fraction *)
  assert_bool (Number.isInteger min_value) false

let epsilon_is_not_integer () = assert_bool (Number.isInteger epsilon) false

let powers_of_two () =
  assert_bool (Number.isInteger (2.0 ** 10.0)) true;
  (* 1024 *)
  assert_bool (Number.isInteger (2.0 ** 52.0)) true;
  (* Within safe integer range *)
  assert_bool (Number.isInteger (2.0 ** 53.0)) true (* MAX_SAFE_INTEGER + 1 *)

let scientific_notation () =
  assert_bool (Number.isInteger 1e5) true;
  (* 100000 *)
  assert_bool (Number.isInteger 5e3) true;
  (* 5000 *)
  assert_bool (Number.isInteger 1e-5) false (* 0.00001 *)

(* Note: In OCaml, Number.isInteger only takes float values, so we don't need
   to test non-number types. Those would be type errors at compile time. *)

let tests =
  [
    (* Integer values - return true *)
    test "integers: zeros" zero_values;
    test "integers: positive" positive_integers;
    test "integers: negative" negative_integers;
    test "integers: large" large_integers;
    test "integers: decimal zero fraction" decimal_zero_fraction;
    (* Non-integer values - return false *)
    test "non_integers: decimals" decimals;
    test "non_integers: small fractions" small_fractions;
    (* Special values - return false *)
    test "special: NaN" nan_value;
    test "special: Infinity" infinity_values;
    (* Edge cases *)
    test "edge: MAX_VALUE is integer" max_value_is_integer;
    test "edge: MIN_VALUE is not integer" min_value_is_not_integer;
    test "edge: epsilon is not integer" epsilon_is_not_integer;
    test "edge: powers of two" powers_of_two;
    test "edge: scientific notation" scientific_notation;
  ]

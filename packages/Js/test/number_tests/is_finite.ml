(** TC39 Test262: Number.isFinite tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/Number/isFinite

    ECMA-262 Section: Number.isFinite(number)

    Note: Number.isFinite is different from global isFinite:
    - Number.isFinite only returns true for finite number values
    - It does NOT perform type coercion
    - Returns false for NaN and Infinity *)

open Helpers

(* ===================================================================
   Infinity values should return false
   =================================================================== *)

let positive_infinity () = assert_bool (Number.isFinite infinity) false
let negative_infinity () = assert_bool (Number.isFinite neg_infinity) false

(* ===================================================================
   NaN should return false
   =================================================================== *)

let nan_value () = assert_bool (Number.isFinite nan) false

let nan_from_operations () =
  assert_bool (Number.isFinite (0.0 /. 0.0)) false;
  assert_bool (Number.isFinite (infinity -. infinity)) false

(* ===================================================================
   Finite numbers should return true
   =================================================================== *)

let zero_values () =
  assert_bool (Number.isFinite 0.0) true;
  assert_bool (Number.isFinite (-0.0)) true

let positive_integers () =
  assert_bool (Number.isFinite 1.0) true;
  assert_bool (Number.isFinite 42.0) true;
  assert_bool (Number.isFinite 100.0) true

let negative_integers () =
  assert_bool (Number.isFinite (-1.0)) true;
  assert_bool (Number.isFinite (-42.0)) true;
  assert_bool (Number.isFinite (-100.0)) true

let decimals () =
  assert_bool (Number.isFinite 0.5) true;
  assert_bool (Number.isFinite 3.14159) true;
  assert_bool (Number.isFinite (-2.71828)) true

let max_min_values () =
  (* MAX_VALUE and MIN_VALUE are finite *)
  assert_bool (Number.isFinite max_value) true;
  assert_bool (Number.isFinite min_value) true;
  assert_bool (Number.isFinite (-.max_value)) true

let safe_integer_bounds () =
  (* MAX_SAFE_INTEGER and MIN_SAFE_INTEGER are finite *)
  assert_bool (Number.isFinite max_safe_integer) true;
  assert_bool (Number.isFinite min_safe_integer) true

let epsilon_value () = assert_bool (Number.isFinite epsilon) true

let very_small_numbers () =
  assert_bool (Number.isFinite 1e-300) true;
  assert_bool (Number.isFinite 5e-324) true (* MIN_VALUE *)

let very_large_numbers () =
  assert_bool (Number.isFinite 1e308) true;
  assert_bool (Number.isFinite (-1e308)) true

(* Note: In OCaml, Number.isFinite only takes float values, so we don't need
   to test non-number types. Those would be type errors at compile time. *)

let tests =
  [
    (* Infinity - returns false *)
    test "infinity: positive Infinity returns false" positive_infinity;
    test "negative_infinity: negative Infinity returns false" negative_infinity;
    (* NaN - returns false *)
    test "nan: NaN returns false" nan_value;
    test "nan_from_operations: NaN from operations returns false" nan_from_operations;
    (* Finite numbers - return true *)
    test "finite_numbers: zeros" zero_values;
    test "finite_numbers: positive integers" positive_integers;
    test "finite_numbers: negative integers" negative_integers;
    test "finite_numbers: decimals" decimals;
    test "finite_numbers: MAX/MIN_VALUE" max_min_values;
    test "finite_numbers: safe integer bounds" safe_integer_bounds;
    test "finite_numbers: epsilon" epsilon_value;
    test "finite_numbers: very small" very_small_numbers;
    test "finite_numbers: very large" very_large_numbers;
  ]

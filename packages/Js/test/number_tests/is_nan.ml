(** TC39 Test262: Number.isNaN tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/Number/isNaN

    ECMA-262 Section: Number.isNaN(number)

    Note: Number.isNaN is different from global isNaN:
    - Number.isNaN only returns true for the actual NaN value
    - It does NOT perform type coercion *)

open Helpers

(* ===================================================================
   Basic NaN detection
   =================================================================== *)

let nan_value () =
  (* NaN should return true *)
  assert_bool (Number.isNaN nan) true

let nan_from_operation () =
  (* NaN from operations should return true *)
  assert_bool (Number.isNaN (0.0 /. 0.0)) true;
  assert_bool (Number.isNaN (infinity -. infinity)) true;
  assert_bool (Number.isNaN (infinity *. 0.0)) true;
  assert_bool (Number.isNaN (sqrt (-1.0))) true

let nan_from_parseint () =
  (* NaN from parseInt should return true *)
  assert_bool (Number.isNaN (Number.parseInt "abc")) true;
  assert_bool (Number.isNaN (Number.parseInt "")) true

let nan_from_parsefloat () =
  (* NaN from parseFloat should return true *)
  assert_bool (Number.isNaN (Number.parseFloat "xyz")) true;
  assert_bool (Number.isNaN (Number.parseFloat "")) true

(* ===================================================================
   Non-NaN values should return false
   =================================================================== *)

let finite_numbers () =
  (* Finite numbers return false *)
  assert_bool (Number.isNaN 0.0) false;
  assert_bool (Number.isNaN 1.0) false;
  assert_bool (Number.isNaN (-1.0)) false;
  assert_bool (Number.isNaN 42.0) false;
  assert_bool (Number.isNaN 3.14159) false;
  assert_bool (Number.isNaN (-3.14159)) false

let zero_values () =
  (* Zero values return false *)
  assert_bool (Number.isNaN 0.0) false;
  assert_bool (Number.isNaN (-0.0)) false

let infinity_values () =
  (* Infinity returns false (Infinity is not NaN) *)
  assert_bool (Number.isNaN infinity) false;
  assert_bool (Number.isNaN neg_infinity) false

let max_min_values () =
  (* Extreme values return false *)
  assert_bool (Number.isNaN max_value) false;
  assert_bool (Number.isNaN min_value) false;
  assert_bool (Number.isNaN max_safe_integer) false;
  assert_bool (Number.isNaN min_safe_integer) false

let epsilon_value () =
  (* Epsilon returns false *)
  assert_bool (Number.isNaN epsilon) false

(* Note: In OCaml, Number.isNaN only takes float values, so we don't need
   to test non-number types like strings, objects, undefined, null, etc.
   Those would be type errors at compile time. *)

let tests =
  [
    (* NaN detection *)
    test "nan_value: NaN returns true" nan_value;
    test "nan_from_operation: NaN from operations" nan_from_operation;
    test "nan_from_parseInt: NaN from parseInt" nan_from_parseint;
    test "nan_from_parseFloat: NaN from parseFloat" nan_from_parsefloat;
    (* Non-NaN values *)
    test "finite_numbers: finite numbers return false" finite_numbers;
    test "zero_values: zeros return false" zero_values;
    test "infinity_values: Infinity returns false" infinity_values;
    test "max_min_values: extreme values return false" max_min_values;
    test "epsilon_value: epsilon returns false" epsilon_value;
  ]

open Helpers

let positive_infinity () = assert_bool (Number.isFinite infinity) false
let negative_infinity () = assert_bool (Number.isFinite neg_infinity) false
let nan_value () = assert_bool (Number.isFinite nan) false

let nan_from_operations () =
  assert_bool (Number.isFinite (0.0 /. 0.0)) false;
  assert_bool (Number.isFinite (infinity -. infinity)) false

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
  assert_bool (Number.isFinite max_value) true;
  assert_bool (Number.isFinite min_value) true;
  assert_bool (Number.isFinite (-.max_value)) true

let safe_integer_bounds () =
  assert_bool (Number.isFinite max_safe_integer) true;
  assert_bool (Number.isFinite min_safe_integer) true

let epsilon_value () = assert_bool (Number.isFinite epsilon) true

let very_small_numbers () =
  assert_bool (Number.isFinite 1e-300) true;
  assert_bool (Number.isFinite 5e-324) true

let very_large_numbers () =
  assert_bool (Number.isFinite 1e308) true;
  assert_bool (Number.isFinite (-1e308)) true

let tests =
  [
    test "infinity: positive Infinity returns false" positive_infinity;
    test "negative_infinity: negative Infinity returns false" negative_infinity;
    test "nan: NaN returns false" nan_value;
    test "nan_from_operations: NaN from operations returns false" nan_from_operations;
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

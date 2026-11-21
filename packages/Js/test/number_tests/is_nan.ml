open Helpers

let nan_value () = assert_bool (Number.isNaN nan) true

let nan_from_operation () =
  assert_bool (Number.isNaN (0.0 /. 0.0)) true;
  assert_bool (Number.isNaN (infinity -. infinity)) true;
  assert_bool (Number.isNaN (infinity *. 0.0)) true;
  assert_bool (Number.isNaN (sqrt (-1.0))) true

let nan_from_parseint () =
  assert_bool (Number.isNaN (Number.parseInt "abc")) true;
  assert_bool (Number.isNaN (Number.parseInt "")) true

let nan_from_parsefloat () =
  assert_bool (Number.isNaN (Number.parseFloat "xyz")) true;
  assert_bool (Number.isNaN (Number.parseFloat "")) true

let finite_numbers () =
  assert_bool (Number.isNaN 0.0) false;
  assert_bool (Number.isNaN 1.0) false;
  assert_bool (Number.isNaN (-1.0)) false;
  assert_bool (Number.isNaN 42.0) false;
  assert_bool (Number.isNaN 3.14159) false;
  assert_bool (Number.isNaN (-3.14159)) false

let zero_values () =
  assert_bool (Number.isNaN 0.0) false;
  assert_bool (Number.isNaN (-0.0)) false

let infinity_values () =
  assert_bool (Number.isNaN infinity) false;
  assert_bool (Number.isNaN neg_infinity) false

let max_min_values () =
  assert_bool (Number.isNaN max_value) false;
  assert_bool (Number.isNaN min_value) false;
  assert_bool (Number.isNaN max_safe_integer) false;
  assert_bool (Number.isNaN min_safe_integer) false

let epsilon_value () = assert_bool (Number.isNaN epsilon) false

let tests =
  [
    test "nan_value: NaN returns true" nan_value;
    test "nan_from_operation: NaN from operations" nan_from_operation;
    test "nan_from_parseInt: NaN from parseInt" nan_from_parseint;
    test "nan_from_parseFloat: NaN from parseFloat" nan_from_parsefloat;
    test "finite_numbers: finite numbers return false" finite_numbers;
    test "zero_values: zeros return false" zero_values;
    test "infinity_values: Infinity returns false" infinity_values;
    test "max_min_values: extreme values return false" max_min_values;
    test "epsilon_value: epsilon returns false" epsilon_value;
  ]

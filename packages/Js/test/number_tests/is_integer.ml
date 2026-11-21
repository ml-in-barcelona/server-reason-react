open Helpers

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
  assert_bool (Number.isInteger 9007199254740992.0) true

let decimal_zero_fraction () =
  assert_bool (Number.isInteger 5.0) true;
  assert_bool (Number.isInteger 123.0) true;
  assert_bool (Number.isInteger 1e10) true

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

let nan_value () = assert_bool (Number.isInteger nan) false

let infinity_values () =
  assert_bool (Number.isInteger infinity) false;
  assert_bool (Number.isInteger neg_infinity) false

let max_value_is_integer () =
  assert_bool (Number.isInteger max_value) true;
  assert_bool (Number.isInteger (-.max_value)) true

let min_value_is_not_integer () = assert_bool (Number.isInteger min_value) false
let epsilon_is_not_integer () = assert_bool (Number.isInteger epsilon) false

let powers_of_two () =
  assert_bool (Number.isInteger (2.0 ** 10.0)) true;
  assert_bool (Number.isInteger (2.0 ** 52.0)) true;
  assert_bool (Number.isInteger (2.0 ** 53.0)) true

let scientific_notation () =
  assert_bool (Number.isInteger 1e5) true;
  assert_bool (Number.isInteger 5e3) true;
  assert_bool (Number.isInteger 1e-5) false

let tests =
  [
    test "integers: zeros" zero_values;
    test "integers: positive" positive_integers;
    test "integers: negative" negative_integers;
    test "integers: large" large_integers;
    test "integers: decimal zero fraction" decimal_zero_fraction;
    test "non_integers: decimals" decimals;
    test "non_integers: small fractions" small_fractions;
    test "special: NaN" nan_value;
    test "special: Infinity" infinity_values;
    test "edge: MAX_VALUE is integer" max_value_is_integer;
    test "edge: MIN_VALUE is not integer" min_value_is_not_integer;
    test "edge: epsilon is not integer" epsilon_is_not_integer;
    test "edge: powers of two" powers_of_two;
    test "edge: scientific notation" scientific_notation;
  ]

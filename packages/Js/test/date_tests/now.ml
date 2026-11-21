open Helpers

let now_returns_number () =
  let result = Date.now () in
  assert_not_nan result;
  assert_bool (Float.is_finite result) true

let now_returns_positive () =
  let result = Date.now () in
  assert_bool (result > 0.) true

let now_is_recent () =
  let result = Date.now () in
  let year_2020 = 1577836800000. in
  assert_bool (result > year_2020) true

let now_increases () =
  let t1 = Date.now () in
  let t2 = Date.now () in
  assert_bool (t2 >= t1) true

let now_is_integer_like () =
  let result = Date.now () in
  assert_bool (Float.is_integer result) true

let tests =
  [
    test "now returns finite number" now_returns_number;
    test "now returns positive" now_returns_positive;
    test "now is recent (after 2020)" now_is_recent;
    test "now is monotonic" now_increases;
    test "now returns integer ms" now_is_integer_like;
  ]

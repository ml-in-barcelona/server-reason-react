(** TC39 Test262: Date.now tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/Date/now

    ECMA-262 Section: Date.now()

    Returns the current time as milliseconds since the Unix epoch. *)

open Helpers

(* ===================================================================
   Basic functionality
   =================================================================== *)

let now_returns_number () =
  (* Date.now() should return a finite number *)
  let result = Date.now () in
  assert_not_nan result;
  assert_bool (Float.is_finite result) true

let now_returns_positive () =
  (* Date.now() should be positive (we're well past 1970) *)
  let result = Date.now () in
  assert_bool (result > 0.) true

let now_is_recent () =
  (* Date.now() should be reasonably recent (after year 2020) *)
  let result = Date.now () in
  let year_2020 = 1577836800000. in
  (* Jan 1, 2020 00:00:00 UTC *)
  assert_bool (result > year_2020) true

let now_increases () =
  (* Two calls to Date.now() should not decrease *)
  let t1 = Date.now () in
  (* Small busy wait - not ideal but tests the concept *)
  let t2 = Date.now () in
  assert_bool (t2 >= t1) true

let now_is_integer_like () =
  (* Date.now() should return an integer value (no fractional ms) *)
  let result = Date.now () in
  assert_bool (Float.is_integer result) true

(* ===================================================================
   Test list
   =================================================================== *)

let tests =
  [
    test "now returns finite number" now_returns_number;
    test "now returns positive" now_returns_positive;
    test "now is recent (after 2020)" now_is_recent;
    test "now is monotonic" now_increases;
    test "now returns integer ms" now_is_integer_like;
  ]

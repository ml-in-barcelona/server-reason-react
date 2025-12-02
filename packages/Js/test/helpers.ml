(** Shared test helpers for test262 tests *)

module BigInt = Js.Bigint
module Date = Js.Date
module Number = Js.Float

let test title fn = Alcotest_lwt.test_case_sync title `Quick fn
let test_async title fn = Alcotest_lwt.test_case title `Quick fn
let assert_string left right = Alcotest.check Alcotest.string "should be equal" right left
let assert_int left right = Alcotest.check Alcotest.int "should be equal" right left
let assert_float left right = Alcotest.check (Alcotest.float 2.) "should be equal" right left
let assert_float_exact left right = Alcotest.check (Alcotest.float 0.) "should be equal" right left
let assert_bool left right = Alcotest.check Alcotest.bool "should be equal" right left

let assert_raises fn exn =
  match fn () with
  | exception exn -> assert_string (Printexc.to_string exn) (Printexc.to_string exn)
  | _ -> Alcotest.failf "Expected exception %s" (Printexc.to_string exn)

(* BigInt helpers *)
let bigint_testable = Alcotest.testable (Fmt.of_to_string BigInt.toString) (fun a b -> BigInt.compare a b = 0)
let assert_bigint left right = Alcotest.check bigint_testable "should be equal" right left

let assert_bigint_string left expected_str =
  let expected = BigInt.of_string expected_str in
  Alcotest.check bigint_testable "should be equal" expected left

let assert_bigint_raises fn = match fn () with exception _ -> () | _ -> Alcotest.fail "Expected exception"

(* Float/Number helpers *)
let nan = Float.nan
let infinity = Float.infinity
let neg_infinity = Float.neg_infinity
let max_value = Float.max_float
let min_value = Float.min_float
let max_safe_integer = 9007199254740991.
let min_safe_integer = -9007199254740991.
let epsilon = Float.epsilon
let assert_not_nan value = if Float.is_nan value then Alcotest.fail "Expected non-NaN value"
let assert_nan value = if not (Float.is_nan value) then Alcotest.fail "Expected NaN value"
let assert_infinity value = if not (value = infinity) then Alcotest.failf "Expected Infinity, got %f" value
let assert_neg_infinity value = if not (value = neg_infinity) then Alcotest.failf "Expected -Infinity, got %f" value
let assert_negative_zero value = if not (1. /. value = neg_infinity) then Alcotest.fail "Expected negative zero"

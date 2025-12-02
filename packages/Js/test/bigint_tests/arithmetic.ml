(** TC39 Test262: BigInt arithmetic tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/BigInt

    Tests for BigInt arithmetic operations: add, sub, mul, div, rem, pow, neg, abs *)

open Helpers

(* ===================================================================
   Addition
   =================================================================== *)

let add_positive () =
  let a = BigInt.of_int 10 in
  let b = BigInt.of_int 20 in
  assert_bigint (BigInt.add a b) (BigInt.of_int 30)

let add_negative () =
  let a = BigInt.of_int (-10) in
  let b = BigInt.of_int (-20) in
  assert_bigint (BigInt.add a b) (BigInt.of_int (-30))

let add_mixed () =
  let a = BigInt.of_int 10 in
  let b = BigInt.of_int (-20) in
  assert_bigint (BigInt.add a b) (BigInt.of_int (-10))

let add_zero () =
  let a = BigInt.of_int 42 in
  let b = BigInt.of_int 0 in
  assert_bigint (BigInt.add a b) (BigInt.of_int 42)

let add_large () =
  (* Large number addition *)
  let a = BigInt.of_string "9007199254740992" in
  (* 2^53 *)
  let b = BigInt.of_int 1 in
  assert_bigint_string (BigInt.add a b) "9007199254740993"

(* ===================================================================
   Subtraction
   =================================================================== *)

let sub_positive () =
  let a = BigInt.of_int 30 in
  let b = BigInt.of_int 10 in
  assert_bigint (BigInt.sub a b) (BigInt.of_int 20)

let sub_negative_result () =
  let a = BigInt.of_int 10 in
  let b = BigInt.of_int 30 in
  assert_bigint (BigInt.sub a b) (BigInt.of_int (-20))

let sub_zero () =
  let a = BigInt.of_int 42 in
  let b = BigInt.of_int 0 in
  assert_bigint (BigInt.sub a b) (BigInt.of_int 42)

let sub_self () =
  let a = BigInt.of_int 42 in
  assert_bigint (BigInt.sub a a) (BigInt.of_int 0)

(* ===================================================================
   Multiplication
   =================================================================== *)

let mul_positive () =
  let a = BigInt.of_int 6 in
  let b = BigInt.of_int 7 in
  assert_bigint (BigInt.mul a b) (BigInt.of_int 42)

let mul_negative () =
  let a = BigInt.of_int (-6) in
  let b = BigInt.of_int 7 in
  assert_bigint (BigInt.mul a b) (BigInt.of_int (-42))

let mul_both_negative () =
  let a = BigInt.of_int (-6) in
  let b = BigInt.of_int (-7) in
  assert_bigint (BigInt.mul a b) (BigInt.of_int 42)

let mul_zero () =
  let a = BigInt.of_int 42 in
  let b = BigInt.of_int 0 in
  assert_bigint (BigInt.mul a b) (BigInt.of_int 0)

let mul_one () =
  let a = BigInt.of_int 42 in
  let b = BigInt.of_int 1 in
  assert_bigint (BigInt.mul a b) (BigInt.of_int 42)

let mul_large () =
  (* From QuickJS: 3^100 *)
  let three = BigInt.of_int 3 in
  let result = ref (BigInt.of_int 1) in
  for _ = 1 to 100 do
    result := BigInt.mul !result three
  done;
  assert_bigint_string !result "515377520732011331036461129765621272702107522001"

(* ===================================================================
   Division (truncates toward zero)
   =================================================================== *)

let div_exact () =
  let a = BigInt.of_int 42 in
  let b = BigInt.of_int 6 in
  assert_bigint (BigInt.div a b) (BigInt.of_int 7)

let div_truncate_positive () =
  let a = BigInt.of_int 10 in
  let b = BigInt.of_int 3 in
  assert_bigint (BigInt.div a b) (BigInt.of_int 3)

let div_truncate_negative () =
  (* -10 / 3 = -3 (truncate toward zero, not floor) *)
  let a = BigInt.of_int (-10) in
  let b = BigInt.of_int 3 in
  assert_bigint (BigInt.div a b) (BigInt.of_int (-3))

let div_negative_divisor () =
  let a = BigInt.of_int 10 in
  let b = BigInt.of_int (-3) in
  assert_bigint (BigInt.div a b) (BigInt.of_int (-3))

let div_both_negative () =
  let a = BigInt.of_int (-10) in
  let b = BigInt.of_int (-3) in
  assert_bigint (BigInt.div a b) (BigInt.of_int 3)

let div_large () =
  (* From QuickJS test *)
  let a = BigInt.of_string "3213213213213213432453243" in
  let b = BigInt.of_string "123434343439" in
  assert_bigint_string (BigInt.div a b) "26031760073331"

let div_large_negative () =
  let a = BigInt.of_string "-3213213213213213432453243" in
  let b = BigInt.of_string "123434343439" in
  assert_bigint_string (BigInt.div a b) "-26031760073331"

let div_by_zero () =
  let a = BigInt.of_int 42 in
  let b = BigInt.of_int 0 in
  assert_bigint_raises (fun () -> ignore (BigInt.div a b))

(* ===================================================================
   Remainder
   =================================================================== *)

let rem_positive () =
  let a = BigInt.of_int 10 in
  let b = BigInt.of_int 3 in
  assert_bigint (BigInt.rem a b) (BigInt.of_int 1)

let rem_negative_dividend () =
  (* -10 % 3 = -1 (sign follows dividend in JS) *)
  let a = BigInt.of_int (-10) in
  let b = BigInt.of_int 3 in
  assert_bigint (BigInt.rem a b) (BigInt.of_int (-1))

let rem_negative_divisor () =
  (* 10 % -3 = 1 (sign follows dividend) *)
  let a = BigInt.of_int 10 in
  let b = BigInt.of_int (-3) in
  assert_bigint (BigInt.rem a b) (BigInt.of_int 1)

let rem_both_negative () =
  (* -10 % -3 = -1 *)
  let a = BigInt.of_int (-10) in
  let b = BigInt.of_int (-3) in
  assert_bigint (BigInt.rem a b) (BigInt.of_int (-1))

let rem_large () =
  (* From QuickJS test *)
  let a = BigInt.of_string "-3213213213213213432453243" in
  let b = BigInt.of_string "-123434343439" in
  assert_bigint_string (BigInt.rem a b) "-26953727934"

let rem_large_positive () =
  let a = BigInt.of_string "3213213213213213432453243" in
  let b = BigInt.of_string "123434343439" in
  assert_bigint_string (BigInt.rem a b) "26953727934"

let rem_by_zero () =
  let a = BigInt.of_int 42 in
  let b = BigInt.of_int 0 in
  assert_bigint_raises (fun () -> ignore (BigInt.rem a b))

(* ===================================================================
   Exponentiation
   =================================================================== *)

let pow_zero () =
  let a = BigInt.of_int 42 in
  let b = BigInt.of_int 0 in
  assert_bigint (BigInt.pow a b) (BigInt.of_int 1)

let pow_one () =
  let a = BigInt.of_int 42 in
  let b = BigInt.of_int 1 in
  assert_bigint (BigInt.pow a b) (BigInt.of_int 42)

let pow_positive () =
  let a = BigInt.of_int 2 in
  let b = BigInt.of_int 10 in
  assert_bigint (BigInt.pow a b) (BigInt.of_int 1024)

let pow_negative_base () =
  (* (-2)^127 *)
  let a = BigInt.of_int (-2) in
  let b = BigInt.of_int 127 in
  assert_bigint_string (BigInt.pow a b) "-170141183460469231731687303715884105728"

let pow_large () =
  (* 2^127 *)
  let a = BigInt.of_int 2 in
  let b = BigInt.of_int 127 in
  assert_bigint_string (BigInt.pow a b) "170141183460469231731687303715884105728"

let pow_negative_exponent () =
  (* Negative exponent should raise - BigInt doesn't support fractions *)
  let a = BigInt.of_int 2 in
  let b = BigInt.of_int (-1) in
  assert_bigint_raises (fun () -> ignore (BigInt.pow a b))

let pow_from_quickjs_1 () =
  (* (-256)^11 *)
  let a = BigInt.of_int (-256) in
  let b = BigInt.of_int 11 in
  assert_bigint_string (BigInt.pow a b) "-309485009821345068724781056"

let pow_from_quickjs_2 () =
  (* 7^20 *)
  let a = BigInt.of_int 7 in
  let b = BigInt.of_int 20 in
  assert_bigint_string (BigInt.pow a b) "79792266297612001"

(* ===================================================================
   Unary negation
   =================================================================== *)

let neg_positive () =
  let a = BigInt.of_int 42 in
  assert_bigint (BigInt.neg a) (BigInt.of_int (-42))

let neg_negative () =
  let a = BigInt.of_int (-42) in
  assert_bigint (BigInt.neg a) (BigInt.of_int 42)

let neg_zero () =
  let a = BigInt.of_int 0 in
  assert_bigint (BigInt.neg a) (BigInt.of_int 0)

(* ===================================================================
   Absolute value
   =================================================================== *)

let abs_positive () =
  let a = BigInt.of_int 42 in
  assert_bigint (BigInt.abs a) (BigInt.of_int 42)

let abs_negative () =
  let a = BigInt.of_int (-42) in
  assert_bigint (BigInt.abs a) (BigInt.of_int 42)

let abs_zero () =
  let a = BigInt.of_int 0 in
  assert_bigint (BigInt.abs a) (BigInt.of_int 0)

(* ===================================================================
   Test list
   =================================================================== *)

let tests =
  [
    (* Addition *)
    test "add: positive + positive" add_positive;
    test "add: negative + negative" add_negative;
    test "add: positive + negative" add_mixed;
    test "add: with zero" add_zero;
    test "add: large numbers" add_large;
    (* Subtraction *)
    test "sub: positive result" sub_positive;
    test "sub: negative result" sub_negative_result;
    test "sub: with zero" sub_zero;
    test "sub: self" sub_self;
    (* Multiplication *)
    test "mul: positive * positive" mul_positive;
    test "mul: negative * positive" mul_negative;
    test "mul: negative * negative" mul_both_negative;
    test "mul: with zero" mul_zero;
    test "mul: with one" mul_one;
    test "mul: 3^100" mul_large;
    (* Division *)
    test "div: exact division" div_exact;
    test "div: truncate positive" div_truncate_positive;
    test "div: truncate negative (toward zero)" div_truncate_negative;
    test "div: negative divisor" div_negative_divisor;
    test "div: both negative" div_both_negative;
    test "div: large numbers" div_large;
    test "div: large negative" div_large_negative;
    test "div: by zero throws" div_by_zero;
    (* Remainder *)
    test "rem: positive % positive" rem_positive;
    test "rem: negative dividend" rem_negative_dividend;
    test "rem: negative divisor" rem_negative_divisor;
    test "rem: both negative" rem_both_negative;
    test "rem: large numbers" rem_large;
    test "rem: large positive" rem_large_positive;
    test "rem: by zero throws" rem_by_zero;
    (* Exponentiation *)
    test "pow: exponent zero" pow_zero;
    test "pow: exponent one" pow_one;
    test "pow: 2^10" pow_positive;
    test "pow: (-2)^127" pow_negative_base;
    test "pow: 2^127" pow_large;
    test "pow: negative exponent throws" pow_negative_exponent;
    test "pow: (-256)^11" pow_from_quickjs_1;
    test "pow: 7^20" pow_from_quickjs_2;
    (* Negation *)
    test "neg: positive" neg_positive;
    test "neg: negative" neg_negative;
    test "neg: zero" neg_zero;
    (* Absolute value *)
    test "abs: positive" abs_positive;
    test "abs: negative" abs_negative;
    test "abs: zero" abs_zero;
  ]

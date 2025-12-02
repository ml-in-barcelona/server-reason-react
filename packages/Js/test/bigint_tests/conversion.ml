(** TC39 Test262: BigInt conversion tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/BigInt

    Tests for BigInt conversion operations:
    - toString with various radixes
    - toNumber (to float)
    - asIntN / asUintN (wrapping to fixed bit widths) *)

open Helpers

(* ===================================================================
   toString - decimal (default)
   =================================================================== *)

let to_string_zero () =
  let a = BigInt.of_int 0 in
  assert_string (BigInt.to_string a) "0"

let to_string_positive () =
  let a = BigInt.of_int 123 in
  assert_string (BigInt.to_string a) "123"

let to_string_negative () =
  let a = BigInt.of_int (-123) in
  assert_string (BigInt.to_string a) "-123"

let to_string_large () =
  (* From QuickJS test: (1 << 100).toString(10) *)
  let a = BigInt.shift_left (BigInt.of_int 1) 100 in
  assert_string (BigInt.to_string a) "1267650600228229401496703205376"

(* ===================================================================
   toString - with radix
   =================================================================== *)

let to_string_radix_2 () =
  let a = BigInt.of_int 10 in
  assert_string (BigInt.to_string ~radix:2 a) "1010"

let to_string_radix_8 () =
  (* From QuickJS: (1 << 100).toString(8) *)
  let a = BigInt.shift_left (BigInt.of_int 1) 100 in
  assert_string (BigInt.to_string ~radix:8 a) "2000000000000000000000000000000000"

let to_string_radix_16 () =
  let a = BigInt.of_int 255 in
  assert_string (BigInt.to_string ~radix:16 a) "ff"

let to_string_radix_36 () =
  (* From QuickJS: (-1 << 100).toString(36) *)
  let a = BigInt.shift_left (BigInt.of_int (-1)) 100 in
  assert_string (BigInt.to_string ~radix:36 a) "-3ewfdnca0n6ld1ggvfgg"

let to_string_radix_16_large () =
  let a = BigInt.of_string "515377520732011331036461129765621272702107522001" in
  assert_string (BigInt.to_string ~radix:16 a) "5a4653ca673768565b41f775d6947d55cf3813d1"

(* ===================================================================
   toNumber (to float) - with precision loss for large values
   =================================================================== *)

let to_float_small () =
  let a = BigInt.of_int 42 in
  assert_float (BigInt.to_float a) 42.0

let to_float_negative () =
  let a = BigInt.of_int (-42) in
  assert_float (BigInt.to_float a) (-42.0)

let to_float_zero () =
  let a = BigInt.of_int 0 in
  assert_float (BigInt.to_float a) 0.0

let to_float_max_safe_int () =
  let a = BigInt.of_string "9007199254740991" in
  assert_float (BigInt.to_float a) 9007199254740991.0

let to_float_large () =
  (* From QuickJS: Number(0xffffffffffffffffn) = 18446744073709552000 *)
  let a = BigInt.of_string "0xffffffffffffffff" in
  assert_float (BigInt.to_float a) 18446744073709552000.0

let to_float_large_negative () =
  (* From QuickJS: Number(-0xffffffffffffffffn) = -18446744073709552000 *)
  let a = BigInt.of_string "-0xffffffffffffffff" in
  assert_float (BigInt.to_float a) (-18446744073709552000.0)

(* ===================================================================
   asIntN - wraps BigInt to signed N-bit integer
   =================================================================== *)

let as_int_n_positive () =
  (* 127 fits in 8 bits signed *)
  let a = BigInt.of_int 127 in
  assert_bigint (BigInt.as_int_n 8 a) (BigInt.of_int 127)

let as_int_n_wrap_positive () =
  (* 128 in 8-bit signed wraps to -128 *)
  let a = BigInt.of_int 128 in
  assert_bigint (BigInt.as_int_n 8 a) (BigInt.of_int (-128))

let as_int_n_wrap_large () =
  (* 255 in 8-bit signed wraps to -1 *)
  let a = BigInt.of_int 255 in
  assert_bigint (BigInt.as_int_n 8 a) (BigInt.of_int (-1))

let as_int_n_negative () =
  (* -128 fits in 8 bits signed *)
  let a = BigInt.of_int (-128) in
  assert_bigint (BigInt.as_int_n 8 a) (BigInt.of_int (-128))

let as_int_n_wrap_negative () =
  (* -129 in 8-bit signed wraps to 127 *)
  let a = BigInt.of_int (-129) in
  assert_bigint (BigInt.as_int_n 8 a) (BigInt.of_int 127)

let as_int_n_64 () =
  let a = BigInt.of_int 42 in
  assert_bigint (BigInt.as_int_n 64 a) (BigInt.of_int 42)

(* ===================================================================
   asUintN - wraps BigInt to unsigned N-bit integer
   =================================================================== *)

let as_uint_n_fits () =
  let a = BigInt.of_int 255 in
  assert_bigint (BigInt.as_uint_n 8 a) (BigInt.of_int 255)

let as_uint_n_wrap () =
  (* 256 in 8-bit unsigned wraps to 0 *)
  let a = BigInt.of_int 256 in
  assert_bigint (BigInt.as_uint_n 8 a) (BigInt.of_int 0)

let as_uint_n_wrap_large () =
  (* 257 in 8-bit unsigned wraps to 1 *)
  let a = BigInt.of_int 257 in
  assert_bigint (BigInt.as_uint_n 8 a) (BigInt.of_int 1)

let as_uint_n_negative () =
  (* -1 in 8-bit unsigned wraps to 255 *)
  let a = BigInt.of_int (-1) in
  assert_bigint (BigInt.as_uint_n 8 a) (BigInt.of_int 255)

let as_uint_n_64 () =
  let a = BigInt.of_int 42 in
  assert_bigint (BigInt.as_uint_n 64 a) (BigInt.of_int 42)

(* ===================================================================
   Test list
   =================================================================== *)

let tests =
  [
    (* toString decimal *)
    test "toString: zero" to_string_zero;
    test "toString: positive" to_string_positive;
    test "toString: negative" to_string_negative;
    test "toString: large (1 << 100)" to_string_large;
    (* toString with radix *)
    test "toString: radix 2" to_string_radix_2;
    test "toString: radix 8" to_string_radix_8;
    test "toString: radix 16" to_string_radix_16;
    test "toString: radix 36" to_string_radix_36;
    test "toString: radix 16 large" to_string_radix_16_large;
    (* toFloat *)
    test "toFloat: small" to_float_small;
    test "toFloat: negative" to_float_negative;
    test "toFloat: zero" to_float_zero;
    test "toFloat: MAX_SAFE_INTEGER" to_float_max_safe_int;
    test "toFloat: large (0xffffffffffffffff)" to_float_large;
    test "toFloat: large negative" to_float_large_negative;
    (* asIntN *)
    test "asIntN: positive fits" as_int_n_positive;
    test "asIntN: positive wraps" as_int_n_wrap_positive;
    test "asIntN: 255 -> -1" as_int_n_wrap_large;
    test "asIntN: negative fits" as_int_n_negative;
    test "asIntN: negative wraps" as_int_n_wrap_negative;
    test "asIntN: 64 bits" as_int_n_64;
    (* asUintN *)
    test "asUintN: fits" as_uint_n_fits;
    test "asUintN: wraps to 0" as_uint_n_wrap;
    test "asUintN: wraps to 1" as_uint_n_wrap_large;
    test "asUintN: negative wraps" as_uint_n_negative;
    test "asUintN: 64 bits" as_uint_n_64;
  ]

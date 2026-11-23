open Helpers

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
  let a = BigInt.shift_left (BigInt.of_int 1) 100 in
  assert_string (BigInt.to_string a) "1267650600228229401496703205376"

let to_string_radix_2 () =
  let a = BigInt.of_int 10 in
  assert_string (BigInt.to_string ~radix:2 a) "1010"

let to_string_radix_8 () =
  let a = BigInt.shift_left (BigInt.of_int 1) 100 in
  assert_string (BigInt.to_string ~radix:8 a) "2000000000000000000000000000000000"

let to_string_radix_16 () =
  let a = BigInt.of_int 255 in
  assert_string (BigInt.to_string ~radix:16 a) "ff"

let to_string_radix_36 () =
  let a = BigInt.shift_left (BigInt.of_int (-1)) 100 in
  assert_string (BigInt.to_string ~radix:36 a) "-3ewfdnca0n6ld1ggvfgg"

let to_string_radix_16_large () =
  let a = BigInt.of_string "515377520732011331036461129765621272702107522001" in
  assert_string (BigInt.to_string ~radix:16 a) "5a4653ca673768565b41f775d6947d55cf3813d1"

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
  let a = BigInt.of_string "0xffffffffffffffff" in
  assert_float (BigInt.to_float a) 18446744073709552000.0

let to_float_large_negative () =
  let a = BigInt.of_string "-0xffffffffffffffff" in
  assert_float (BigInt.to_float a) (-18446744073709552000.0)

let as_int_n_positive () =
  let a = BigInt.of_int 127 in
  assert_bigint (BigInt.as_int_n 8 a) (BigInt.of_int 127)

let as_int_n_wrap_positive () =
  let a = BigInt.of_int 128 in
  assert_bigint (BigInt.as_int_n 8 a) (BigInt.of_int (-128))

let as_int_n_wrap_large () =
  let a = BigInt.of_int 255 in
  assert_bigint (BigInt.as_int_n 8 a) (BigInt.of_int (-1))

let as_int_n_negative () =
  let a = BigInt.of_int (-128) in
  assert_bigint (BigInt.as_int_n 8 a) (BigInt.of_int (-128))

let as_int_n_wrap_negative () =
  let a = BigInt.of_int (-129) in
  assert_bigint (BigInt.as_int_n 8 a) (BigInt.of_int 127)

let as_int_n_64 () =
  let a = BigInt.of_int 42 in
  assert_bigint (BigInt.as_int_n 64 a) (BigInt.of_int 42)

let as_uint_n_fits () =
  let a = BigInt.of_int 255 in
  assert_bigint (BigInt.as_uint_n 8 a) (BigInt.of_int 255)

let as_uint_n_wrap () =
  let a = BigInt.of_int 256 in
  assert_bigint (BigInt.as_uint_n 8 a) (BigInt.of_int 0)

let as_uint_n_wrap_large () =
  let a = BigInt.of_int 257 in
  assert_bigint (BigInt.as_uint_n 8 a) (BigInt.of_int 1)

let as_uint_n_negative () =
  let a = BigInt.of_int (-1) in
  assert_bigint (BigInt.as_uint_n 8 a) (BigInt.of_int 255)

let as_uint_n_64 () =
  let a = BigInt.of_int 42 in
  assert_bigint (BigInt.as_uint_n 64 a) (BigInt.of_int 42)

let tests =
  [
    test "toString: zero" to_string_zero;
    test "toString: positive" to_string_positive;
    test "toString: negative" to_string_negative;
    test "toString: large (1 << 100)" to_string_large;
    test "toString: radix 2" to_string_radix_2;
    test "toString: radix 8" to_string_radix_8;
    test "toString: radix 16" to_string_radix_16;
    test "toString: radix 36" to_string_radix_36;
    test "toString: radix 16 large" to_string_radix_16_large;
    test "toFloat: small" to_float_small;
    test "toFloat: negative" to_float_negative;
    test "toFloat: zero" to_float_zero;
    test "toFloat: MAX_SAFE_INTEGER" to_float_max_safe_int;
    test "toFloat: large (0xffffffffffffffff)" to_float_large;
    test "toFloat: large negative" to_float_large_negative;
    test "asIntN: positive fits" as_int_n_positive;
    test "asIntN: positive wraps" as_int_n_wrap_positive;
    test "asIntN: 255 -> -1" as_int_n_wrap_large;
    test "asIntN: negative fits" as_int_n_negative;
    test "asIntN: negative wraps" as_int_n_wrap_negative;
    test "asIntN: 64 bits" as_int_n_64;
    test "asUintN: fits" as_uint_n_fits;
    test "asUintN: wraps to 0" as_uint_n_wrap;
    test "asUintN: wraps to 1" as_uint_n_wrap_large;
    test "asUintN: negative wraps" as_uint_n_negative;
    test "asUintN: 64 bits" as_uint_n_64;
  ]

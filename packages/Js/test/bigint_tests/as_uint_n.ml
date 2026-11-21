open Helpers
module BigInt = Js.Bigint

let as_uint_n_zero_bits () =
  assert_bigint_equal (BigInt.as_uint_n 0 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 0 (BigInt.of_int 1)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 0 (BigInt.of_int (-1))) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 0 (BigInt.of_int 100)) (BigInt.of_int 0)

let as_uint_n_1_bit () =
  assert_bigint_equal (BigInt.as_uint_n 1 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 1 (BigInt.of_int 1)) (BigInt.of_int 1);
  assert_bigint_equal (BigInt.as_uint_n 1 (BigInt.of_int 2)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 1 (BigInt.of_int 3)) (BigInt.of_int 1);
  assert_bigint_equal (BigInt.as_uint_n 1 (BigInt.of_int (-1))) (BigInt.of_int 1);
  assert_bigint_equal (BigInt.as_uint_n 1 (BigInt.of_int (-2))) (BigInt.of_int 0)

let as_uint_n_8_bit () =
  assert_bigint_equal (BigInt.as_uint_n 8 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 8 (BigInt.of_int 127)) (BigInt.of_int 127);
  assert_bigint_equal (BigInt.as_uint_n 8 (BigInt.of_int 128)) (BigInt.of_int 128);
  assert_bigint_equal (BigInt.as_uint_n 8 (BigInt.of_int 255)) (BigInt.of_int 255);
  assert_bigint_equal (BigInt.as_uint_n 8 (BigInt.of_int 256)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 8 (BigInt.of_int 257)) (BigInt.of_int 1);
  assert_bigint_equal (BigInt.as_uint_n 8 (BigInt.of_int (-1))) (BigInt.of_int 255);
  assert_bigint_equal (BigInt.as_uint_n 8 (BigInt.of_int (-2))) (BigInt.of_int 254);
  assert_bigint_equal (BigInt.as_uint_n 8 (BigInt.of_int (-128))) (BigInt.of_int 128);
  assert_bigint_equal (BigInt.as_uint_n 8 (BigInt.of_int (-256))) (BigInt.of_int 0)

let as_uint_n_16_bit () =
  assert_bigint_equal (BigInt.as_uint_n 16 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 16 (BigInt.of_int 32767)) (BigInt.of_int 32767);
  assert_bigint_equal (BigInt.as_uint_n 16 (BigInt.of_int 32768)) (BigInt.of_int 32768);
  assert_bigint_equal (BigInt.as_uint_n 16 (BigInt.of_int 65535)) (BigInt.of_int 65535);
  assert_bigint_equal (BigInt.as_uint_n 16 (BigInt.of_int 65536)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 16 (BigInt.of_int (-1))) (BigInt.of_int 65535);
  assert_bigint_equal (BigInt.as_uint_n 16 (BigInt.of_int (-32768))) (BigInt.of_int 32768);
  assert_bigint_equal (BigInt.as_uint_n 16 (BigInt.of_int (-65536))) (BigInt.of_int 0)

let as_uint_n_32_bit () =
  assert_bigint_equal (BigInt.as_uint_n 32 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 32 (BigInt.of_int (-1))) (BigInt.of_string "4294967295");
  assert_bigint_equal (BigInt.as_uint_n 32 (BigInt.of_string "2147483647")) (BigInt.of_string "2147483647");
  assert_bigint_equal (BigInt.as_uint_n 32 (BigInt.of_string "2147483648")) (BigInt.of_string "2147483648");
  assert_bigint_equal (BigInt.as_uint_n 32 (BigInt.of_string "4294967295")) (BigInt.of_string "4294967295");
  assert_bigint_equal (BigInt.as_uint_n 32 (BigInt.of_string "4294967296")) (BigInt.of_int 0)

let as_uint_n_64_bit () =
  assert_bigint_equal (BigInt.as_uint_n 64 (BigInt.of_int 0)) (BigInt.of_int 0);
  let max_int63 = BigInt.of_string "9223372036854775807" in
  assert_bigint_equal (BigInt.as_uint_n 64 max_int63) max_int63;
  let max_uint64 = BigInt.of_string "18446744073709551615" in
  assert_bigint_equal (BigInt.as_uint_n 64 max_uint64) max_uint64;
  let two_64 = BigInt.of_string "18446744073709551616" in
  assert_bigint_equal (BigInt.as_uint_n 64 two_64) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 64 (BigInt.of_int (-1))) max_uint64

let as_uint_n_preserves_small_values () =
  for i = 0 to 255 do
    let n = BigInt.of_int i in
    assert_bigint_equal (BigInt.as_uint_n 8 n) n
  done

let as_uint_n_wrapping () =
  assert_bigint_equal (BigInt.as_uint_n 8 (BigInt.of_int 300)) (BigInt.of_int 44);
  assert_bigint_equal (BigInt.as_uint_n 8 (BigInt.of_int 512)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 8 (BigInt.of_int 513)) (BigInt.of_int 1)

let as_uint_n_large_bits () =
  let x = BigInt.of_string "123456789012345678901234567890" in
  assert_bigint_equal (BigInt.as_uint_n 256 x) x

let as_uint_n_negative_becomes_positive () =
  assert_bigint_equal (BigInt.as_uint_n 8 (BigInt.of_int (-1))) (BigInt.of_int 255);
  assert_bigint_equal (BigInt.as_uint_n 8 (BigInt.of_int (-128))) (BigInt.of_int 128);
  assert_bigint_equal (BigInt.as_uint_n 8 (BigInt.of_int (-129))) (BigInt.of_int 127)

let as_uint_n_bit_boundary_2 () =
  assert_bigint_equal (BigInt.as_uint_n 2 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 2 (BigInt.of_int 1)) (BigInt.of_int 1);
  assert_bigint_equal (BigInt.as_uint_n 2 (BigInt.of_int 2)) (BigInt.of_int 2);
  assert_bigint_equal (BigInt.as_uint_n 2 (BigInt.of_int 3)) (BigInt.of_int 3);
  assert_bigint_equal (BigInt.as_uint_n 2 (BigInt.of_int 4)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 2 (BigInt.of_int 5)) (BigInt.of_int 1);
  assert_bigint_equal (BigInt.as_uint_n 2 (BigInt.of_int (-1))) (BigInt.of_int 3);
  assert_bigint_equal (BigInt.as_uint_n 2 (BigInt.of_int (-2))) (BigInt.of_int 2)

let as_uint_n_bit_boundary_3 () =
  assert_bigint_equal (BigInt.as_uint_n 3 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 3 (BigInt.of_int 7)) (BigInt.of_int 7);
  assert_bigint_equal (BigInt.as_uint_n 3 (BigInt.of_int 8)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 3 (BigInt.of_int 9)) (BigInt.of_int 1);
  assert_bigint_equal (BigInt.as_uint_n 3 (BigInt.of_int (-1))) (BigInt.of_int 7)

let as_uint_n_bit_boundary_4 () =
  assert_bigint_equal (BigInt.as_uint_n 4 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 4 (BigInt.of_int 15)) (BigInt.of_int 15);
  assert_bigint_equal (BigInt.as_uint_n 4 (BigInt.of_int 16)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 4 (BigInt.of_int 17)) (BigInt.of_int 1);
  assert_bigint_equal (BigInt.as_uint_n 4 (BigInt.of_int (-1))) (BigInt.of_int 15)

let as_uint_n_identity_for_zero () =
  let zero = BigInt.of_int 0 in
  assert_bigint_equal (BigInt.as_uint_n 0 zero) zero;
  assert_bigint_equal (BigInt.as_uint_n 1 zero) zero;
  assert_bigint_equal (BigInt.as_uint_n 8 zero) zero;
  assert_bigint_equal (BigInt.as_uint_n 16 zero) zero;
  assert_bigint_equal (BigInt.as_uint_n 32 zero) zero;
  assert_bigint_equal (BigInt.as_uint_n 64 zero) zero;
  assert_bigint_equal (BigInt.as_uint_n 128 zero) zero

let as_uint_n_one () =
  let one = BigInt.of_int 1 in
  assert_bigint_equal (BigInt.as_uint_n 1 one) one;
  assert_bigint_equal (BigInt.as_uint_n 8 one) one;
  assert_bigint_equal (BigInt.as_uint_n 16 one) one;
  assert_bigint_equal (BigInt.as_uint_n 32 one) one;
  assert_bigint_equal (BigInt.as_uint_n 64 one) one

let as_uint_n_power_of_two () =
  assert_bigint_equal (BigInt.as_uint_n 1 (BigInt.of_int 2)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 2 (BigInt.of_int 4)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 3 (BigInt.of_int 8)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 4 (BigInt.of_int 16)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_uint_n 8 (BigInt.of_int 256)) (BigInt.of_int 0)

let as_uint_n_power_of_two_minus_one () =
  assert_bigint_equal (BigInt.as_uint_n 1 (BigInt.of_int 1)) (BigInt.of_int 1);
  assert_bigint_equal (BigInt.as_uint_n 2 (BigInt.of_int 3)) (BigInt.of_int 3);
  assert_bigint_equal (BigInt.as_uint_n 3 (BigInt.of_int 7)) (BigInt.of_int 7);
  assert_bigint_equal (BigInt.as_uint_n 4 (BigInt.of_int 15)) (BigInt.of_int 15);
  assert_bigint_equal (BigInt.as_uint_n 8 (BigInt.of_int 255)) (BigInt.of_int 255)

let tests =
  [
    test "asUintN 0 bits" as_uint_n_zero_bits;
    test "asUintN 1 bit" as_uint_n_1_bit;
    test "asUintN 8 bit" as_uint_n_8_bit;
    test "asUintN 16 bit" as_uint_n_16_bit;
    test "asUintN 32 bit" as_uint_n_32_bit;
    test "asUintN 64 bit" as_uint_n_64_bit;
    test "asUintN preserves small values" as_uint_n_preserves_small_values;
    test "asUintN wrapping" as_uint_n_wrapping;
    test "asUintN large bits" as_uint_n_large_bits;
    test "asUintN negative becomes positive" as_uint_n_negative_becomes_positive;
    test "asUintN 2-bit boundary" as_uint_n_bit_boundary_2;
    test "asUintN 3-bit boundary" as_uint_n_bit_boundary_3;
    test "asUintN 4-bit boundary" as_uint_n_bit_boundary_4;
    test "asUintN identity for zero" as_uint_n_identity_for_zero;
    test "asUintN one" as_uint_n_one;
    test "asUintN power of two" as_uint_n_power_of_two;
    test "asUintN power of two minus one" as_uint_n_power_of_two_minus_one;
  ]

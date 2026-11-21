open Helpers
module BigInt = Js.Bigint

let as_int_n_zero_bits () =
  assert_bigint_equal (BigInt.as_int_n 0 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 0 (BigInt.of_int 1)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 0 (BigInt.of_int (-1))) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 0 (BigInt.of_int 100)) (BigInt.of_int 0)

let as_int_n_1_bit () =
  assert_bigint_equal (BigInt.as_int_n 1 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 1 (BigInt.of_int 1)) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 1 (BigInt.of_int 2)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 1 (BigInt.of_int 3)) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 1 (BigInt.of_int (-1))) (BigInt.of_int (-1))

let as_int_n_8_bit () =
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int 127)) (BigInt.of_int 127);
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int 128)) (BigInt.of_int (-128));
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int 255)) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int 256)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int (-1))) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int (-128))) (BigInt.of_int (-128));
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int (-129))) (BigInt.of_int 127)

let as_int_n_16_bit () =
  assert_bigint_equal (BigInt.as_int_n 16 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 16 (BigInt.of_int 32767)) (BigInt.of_int 32767);
  assert_bigint_equal (BigInt.as_int_n 16 (BigInt.of_int 32768)) (BigInt.of_int (-32768));
  assert_bigint_equal (BigInt.as_int_n 16 (BigInt.of_int 65535)) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 16 (BigInt.of_int 65536)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 16 (BigInt.of_int (-1))) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 16 (BigInt.of_int (-32768))) (BigInt.of_int (-32768));
  assert_bigint_equal (BigInt.as_int_n 16 (BigInt.of_int (-32769))) (BigInt.of_int 32767)

let as_int_n_32_bit () =
  assert_bigint_equal (BigInt.as_int_n 32 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 32 (BigInt.of_int (-1))) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 32 (BigInt.of_string "2147483647")) (BigInt.of_string "2147483647");
  assert_bigint_equal (BigInt.as_int_n 32 (BigInt.of_string "2147483648")) (BigInt.of_string "-2147483648");
  assert_bigint_equal (BigInt.as_int_n 32 (BigInt.of_string "4294967295")) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 32 (BigInt.of_string "4294967296")) (BigInt.of_int 0)

let as_int_n_64_bit () =
  assert_bigint_equal (BigInt.as_int_n 64 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 64 (BigInt.of_int (-1))) (BigInt.of_int (-1));
  let max_int64 = BigInt.of_string "9223372036854775807" in
  assert_bigint_equal (BigInt.as_int_n 64 max_int64) max_int64;
  let two_63 = BigInt.of_string "9223372036854775808" in
  let neg_two_63 = BigInt.of_string "-9223372036854775808" in
  assert_bigint_equal (BigInt.as_int_n 64 two_63) neg_two_63

let as_int_n_preserves_small_positive () =
  for i = 0 to 127 do
    let n = BigInt.of_int i in
    assert_bigint_equal (BigInt.as_int_n 8 n) n
  done

let as_int_n_preserves_small_negative () =
  for i = -128 to -1 do
    let n = BigInt.of_int i in
    assert_bigint_equal (BigInt.as_int_n 8 n) n
  done

let as_int_n_wrapping () =
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int 300)) (BigInt.of_int 44);
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int (-300))) (BigInt.of_int (-44))

let as_int_n_large_bits () =
  let x = BigInt.of_string "123456789012345678901234567890" in
  assert_bigint_equal (BigInt.as_int_n 256 x) x

let as_int_n_negative_input () =
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int (-1))) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int (-128))) (BigInt.of_int (-128));
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int (-129))) (BigInt.of_int 127);
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int (-256))) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int (-257))) (BigInt.of_int (-1))

let as_int_n_bit_boundary_2 () =
  assert_bigint_equal (BigInt.as_int_n 2 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 2 (BigInt.of_int 1)) (BigInt.of_int 1);
  assert_bigint_equal (BigInt.as_int_n 2 (BigInt.of_int 2)) (BigInt.of_int (-2));
  assert_bigint_equal (BigInt.as_int_n 2 (BigInt.of_int 3)) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 2 (BigInt.of_int 4)) (BigInt.of_int 0)

let as_int_n_bit_boundary_3 () =
  assert_bigint_equal (BigInt.as_int_n 3 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 3 (BigInt.of_int 3)) (BigInt.of_int 3);
  assert_bigint_equal (BigInt.as_int_n 3 (BigInt.of_int 4)) (BigInt.of_int (-4));
  assert_bigint_equal (BigInt.as_int_n 3 (BigInt.of_int 7)) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 3 (BigInt.of_int 8)) (BigInt.of_int 0)

let as_int_n_bit_boundary_4 () =
  assert_bigint_equal (BigInt.as_int_n 4 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 4 (BigInt.of_int 7)) (BigInt.of_int 7);
  assert_bigint_equal (BigInt.as_int_n 4 (BigInt.of_int 8)) (BigInt.of_int (-8));
  assert_bigint_equal (BigInt.as_int_n 4 (BigInt.of_int 15)) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 4 (BigInt.of_int 16)) (BigInt.of_int 0)

let as_int_n_identity_for_zero () =
  let zero = BigInt.of_int 0 in
  assert_bigint_equal (BigInt.as_int_n 1 zero) zero;
  assert_bigint_equal (BigInt.as_int_n 8 zero) zero;
  assert_bigint_equal (BigInt.as_int_n 16 zero) zero;
  assert_bigint_equal (BigInt.as_int_n 32 zero) zero;
  assert_bigint_equal (BigInt.as_int_n 64 zero) zero;
  assert_bigint_equal (BigInt.as_int_n 128 zero) zero

let as_int_n_minus_one () =
  let neg_one = BigInt.of_int (-1) in
  assert_bigint_equal (BigInt.as_int_n 1 neg_one) neg_one;
  assert_bigint_equal (BigInt.as_int_n 8 neg_one) neg_one;
  assert_bigint_equal (BigInt.as_int_n 16 neg_one) neg_one;
  assert_bigint_equal (BigInt.as_int_n 32 neg_one) neg_one;
  assert_bigint_equal (BigInt.as_int_n 64 neg_one) neg_one

let tests =
  [
    test "asIntN 0 bits" as_int_n_zero_bits;
    test "asIntN 1 bit" as_int_n_1_bit;
    test "asIntN 8 bit" as_int_n_8_bit;
    test "asIntN 16 bit" as_int_n_16_bit;
    test "asIntN 32 bit" as_int_n_32_bit;
    test "asIntN 64 bit" as_int_n_64_bit;
    test "asIntN preserves small positive" as_int_n_preserves_small_positive;
    test "asIntN preserves small negative" as_int_n_preserves_small_negative;
    test "asIntN wrapping" as_int_n_wrapping;
    test "asIntN large bits" as_int_n_large_bits;
    test "asIntN negative input" as_int_n_negative_input;
    test "asIntN 2-bit boundary" as_int_n_bit_boundary_2;
    test "asIntN 3-bit boundary" as_int_n_bit_boundary_3;
    test "asIntN 4-bit boundary" as_int_n_bit_boundary_4;
    test "asIntN identity for zero" as_int_n_identity_for_zero;
    test "asIntN minus one" as_int_n_minus_one;
  ]

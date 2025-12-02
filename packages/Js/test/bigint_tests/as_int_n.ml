(** TC39 Test262: BigInt.asIntN tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/BigInt/asIntN

    BigInt.asIntN(bits, bigint) wraps a BigInt value to a signed integer
    within the given number of bits. *)

open Helpers

module BigInt = Js.Bigint

(* ===================================================================
   Basic asIntN tests
   =================================================================== *)

let as_int_n_zero_bits () =
  (* asIntN(0, x) always returns 0n *)
  assert_bigint_equal (BigInt.as_int_n 0 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 0 (BigInt.of_int 1)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 0 (BigInt.of_int (-1))) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 0 (BigInt.of_int 100)) (BigInt.of_int 0)

let as_int_n_1_bit () =
  (* asIntN(1, x) returns 0n or -1n (sign bit only) *)
  assert_bigint_equal (BigInt.as_int_n 1 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 1 (BigInt.of_int 1)) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 1 (BigInt.of_int 2)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 1 (BigInt.of_int 3)) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 1 (BigInt.of_int (-1))) (BigInt.of_int (-1))

let as_int_n_8_bit () =
  (* asIntN(8, x) wraps to signed 8-bit integer (-128 to 127) *)
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int 127)) (BigInt.of_int 127);
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int 128)) (BigInt.of_int (-128));
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int 255)) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int 256)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int (-1))) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int (-128))) (BigInt.of_int (-128));
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int (-129))) (BigInt.of_int 127)

let as_int_n_16_bit () =
  (* asIntN(16, x) wraps to signed 16-bit integer (-32768 to 32767) *)
  assert_bigint_equal (BigInt.as_int_n 16 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 16 (BigInt.of_int 32767)) (BigInt.of_int 32767);
  assert_bigint_equal (BigInt.as_int_n 16 (BigInt.of_int 32768)) (BigInt.of_int (-32768));
  assert_bigint_equal (BigInt.as_int_n 16 (BigInt.of_int 65535)) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 16 (BigInt.of_int 65536)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 16 (BigInt.of_int (-1))) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 16 (BigInt.of_int (-32768))) (BigInt.of_int (-32768));
  assert_bigint_equal (BigInt.as_int_n 16 (BigInt.of_int (-32769))) (BigInt.of_int 32767)

let as_int_n_32_bit () =
  (* asIntN(32, x) wraps to signed 32-bit integer *)
  assert_bigint_equal (BigInt.as_int_n 32 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 32 (BigInt.of_int (-1))) (BigInt.of_int (-1));
  (* 2^31 - 1 = 2147483647 *)
  assert_bigint_equal (BigInt.as_int_n 32 (BigInt.of_string "2147483647")) (BigInt.of_string "2147483647");
  (* 2^31 = 2147483648 -> -2147483648 *)
  assert_bigint_equal (BigInt.as_int_n 32 (BigInt.of_string "2147483648")) (BigInt.of_string "-2147483648");
  (* 2^32 - 1 = 4294967295 -> -1 *)
  assert_bigint_equal (BigInt.as_int_n 32 (BigInt.of_string "4294967295")) (BigInt.of_int (-1));
  (* 2^32 = 4294967296 -> 0 *)
  assert_bigint_equal (BigInt.as_int_n 32 (BigInt.of_string "4294967296")) (BigInt.of_int 0)

let as_int_n_64_bit () =
  (* asIntN(64, x) wraps to signed 64-bit integer *)
  assert_bigint_equal (BigInt.as_int_n 64 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 64 (BigInt.of_int (-1))) (BigInt.of_int (-1));
  (* 2^63 - 1 stays the same *)
  let max_int64 = BigInt.of_string "9223372036854775807" in
  assert_bigint_equal (BigInt.as_int_n 64 max_int64) max_int64;
  (* 2^63 wraps to negative *)
  let two_63 = BigInt.of_string "9223372036854775808" in
  let neg_two_63 = BigInt.of_string "-9223372036854775808" in
  assert_bigint_equal (BigInt.as_int_n 64 two_63) neg_two_63

let as_int_n_preserves_small_positive () =
  (* Small positive values within range are preserved *)
  for i = 0 to 127 do
    let n = BigInt.of_int i in
    assert_bigint_equal (BigInt.as_int_n 8 n) n
  done

let as_int_n_preserves_small_negative () =
  (* Small negative values within range are preserved *)
  for i = -128 to -1 do
    let n = BigInt.of_int i in
    assert_bigint_equal (BigInt.as_int_n 8 n) n
  done

let as_int_n_wrapping () =
  (* Test wrapping behavior *)
  (* 300 in 8-bit signed = 300 - 256 = 44 *)
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int 300)) (BigInt.of_int 44);
  (* -300 in 8-bit signed = -300 + 256 = -44 *)
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int (-300))) (BigInt.of_int (-44))

let as_int_n_large_bits () =
  (* Test with larger bit sizes *)
  let x = BigInt.of_string "123456789012345678901234567890" in
  (* With very large bits, value should be preserved *)
  assert_bigint_equal (BigInt.as_int_n 256 x) x

let as_int_n_negative_input () =
  (* asIntN with negative input *)
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int (-1))) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int (-128))) (BigInt.of_int (-128));
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int (-129))) (BigInt.of_int 127);
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int (-256))) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 8 (BigInt.of_int (-257))) (BigInt.of_int (-1))

(* ===================================================================
   Edge cases
   =================================================================== *)

let as_int_n_bit_boundary_2 () =
  (* 2-bit signed: -2 to 1 *)
  assert_bigint_equal (BigInt.as_int_n 2 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 2 (BigInt.of_int 1)) (BigInt.of_int 1);
  assert_bigint_equal (BigInt.as_int_n 2 (BigInt.of_int 2)) (BigInt.of_int (-2));
  assert_bigint_equal (BigInt.as_int_n 2 (BigInt.of_int 3)) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 2 (BigInt.of_int 4)) (BigInt.of_int 0)

let as_int_n_bit_boundary_3 () =
  (* 3-bit signed: -4 to 3 *)
  assert_bigint_equal (BigInt.as_int_n 3 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 3 (BigInt.of_int 3)) (BigInt.of_int 3);
  assert_bigint_equal (BigInt.as_int_n 3 (BigInt.of_int 4)) (BigInt.of_int (-4));
  assert_bigint_equal (BigInt.as_int_n 3 (BigInt.of_int 7)) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 3 (BigInt.of_int 8)) (BigInt.of_int 0)

let as_int_n_bit_boundary_4 () =
  (* 4-bit signed: -8 to 7 *)
  assert_bigint_equal (BigInt.as_int_n 4 (BigInt.of_int 0)) (BigInt.of_int 0);
  assert_bigint_equal (BigInt.as_int_n 4 (BigInt.of_int 7)) (BigInt.of_int 7);
  assert_bigint_equal (BigInt.as_int_n 4 (BigInt.of_int 8)) (BigInt.of_int (-8));
  assert_bigint_equal (BigInt.as_int_n 4 (BigInt.of_int 15)) (BigInt.of_int (-1));
  assert_bigint_equal (BigInt.as_int_n 4 (BigInt.of_int 16)) (BigInt.of_int 0)

let as_int_n_identity_for_zero () =
  (* asIntN(n, 0) = 0 for any n > 0 *)
  let zero = BigInt.of_int 0 in
  assert_bigint_equal (BigInt.as_int_n 1 zero) zero;
  assert_bigint_equal (BigInt.as_int_n 8 zero) zero;
  assert_bigint_equal (BigInt.as_int_n 16 zero) zero;
  assert_bigint_equal (BigInt.as_int_n 32 zero) zero;
  assert_bigint_equal (BigInt.as_int_n 64 zero) zero;
  assert_bigint_equal (BigInt.as_int_n 128 zero) zero

let as_int_n_minus_one () =
  (* asIntN(n, -1) = -1 for any n > 0 *)
  let neg_one = BigInt.of_int (-1) in
  assert_bigint_equal (BigInt.as_int_n 1 neg_one) neg_one;
  assert_bigint_equal (BigInt.as_int_n 8 neg_one) neg_one;
  assert_bigint_equal (BigInt.as_int_n 16 neg_one) neg_one;
  assert_bigint_equal (BigInt.as_int_n 32 neg_one) neg_one;
  assert_bigint_equal (BigInt.as_int_n 64 neg_one) neg_one

(* ===================================================================
   Test list
   =================================================================== *)

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


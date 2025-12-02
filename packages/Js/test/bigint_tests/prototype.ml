(** TC39 Test262: BigInt.prototype tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/BigInt/prototype

    Tests for BigInt.prototype.toString, BigInt.prototype.valueOf,
    BigInt.prototype.toLocaleString *)

open Helpers

module BigInt = Js.Bigint

(* ===================================================================
   BigInt.prototype.toString tests
   =================================================================== *)

let to_string_default_radix () =
  (* Default radix is 10 *)
  assert_string_equal (BigInt.toString (BigInt.of_int 0)) "0";
  assert_string_equal (BigInt.toString (BigInt.of_int 1)) "1";
  assert_string_equal (BigInt.toString (BigInt.of_int 10)) "10";
  assert_string_equal (BigInt.toString (BigInt.of_int 100)) "100";
  assert_string_equal (BigInt.toString (BigInt.of_int (-1))) "-1";
  assert_string_equal (BigInt.toString (BigInt.of_int (-10))) "-10"

let to_string_radix_2 () =
  (* Binary representation *)
  assert_string_equal (BigInt.to_string ~radix:2 (BigInt.of_int 0)) "0";
  assert_string_equal (BigInt.to_string ~radix:2 (BigInt.of_int 1)) "1";
  assert_string_equal (BigInt.to_string ~radix:2 (BigInt.of_int 2)) "10";
  assert_string_equal (BigInt.to_string ~radix:2 (BigInt.of_int 3)) "11";
  assert_string_equal (BigInt.to_string ~radix:2 (BigInt.of_int 4)) "100";
  assert_string_equal (BigInt.to_string ~radix:2 (BigInt.of_int 255)) "11111111";
  assert_string_equal (BigInt.to_string ~radix:2 (BigInt.of_int (-1))) "-1";
  assert_string_equal (BigInt.to_string ~radix:2 (BigInt.of_int (-2))) "-10"

let to_string_radix_8 () =
  (* Octal representation *)
  assert_string_equal (BigInt.to_string ~radix:8 (BigInt.of_int 0)) "0";
  assert_string_equal (BigInt.to_string ~radix:8 (BigInt.of_int 7)) "7";
  assert_string_equal (BigInt.to_string ~radix:8 (BigInt.of_int 8)) "10";
  assert_string_equal (BigInt.to_string ~radix:8 (BigInt.of_int 63)) "77";
  assert_string_equal (BigInt.to_string ~radix:8 (BigInt.of_int 64)) "100";
  assert_string_equal (BigInt.to_string ~radix:8 (BigInt.of_int (-8))) "-10"

let to_string_radix_10 () =
  (* Decimal representation (explicit) *)
  assert_string_equal (BigInt.to_string ~radix:10 (BigInt.of_int 0)) "0";
  assert_string_equal (BigInt.to_string ~radix:10 (BigInt.of_int 123)) "123";
  assert_string_equal (BigInt.to_string ~radix:10 (BigInt.of_int (-456))) "-456";
  assert_string_equal (BigInt.to_string ~radix:10 (BigInt.of_string "9999999999")) "9999999999"

let to_string_radix_16 () =
  (* Hexadecimal representation *)
  assert_string_equal (BigInt.to_string ~radix:16 (BigInt.of_int 0)) "0";
  assert_string_equal (BigInt.to_string ~radix:16 (BigInt.of_int 10)) "a";
  assert_string_equal (BigInt.to_string ~radix:16 (BigInt.of_int 15)) "f";
  assert_string_equal (BigInt.to_string ~radix:16 (BigInt.of_int 16)) "10";
  assert_string_equal (BigInt.to_string ~radix:16 (BigInt.of_int 255)) "ff";
  assert_string_equal (BigInt.to_string ~radix:16 (BigInt.of_int 256)) "100";
  assert_string_equal (BigInt.to_string ~radix:16 (BigInt.of_int (-1))) "-1";
  assert_string_equal (BigInt.to_string ~radix:16 (BigInt.of_int (-255))) "-ff"

let to_string_radix_36 () =
  (* Base 36 (max radix) *)
  assert_string_equal (BigInt.to_string ~radix:36 (BigInt.of_int 0)) "0";
  assert_string_equal (BigInt.to_string ~radix:36 (BigInt.of_int 35)) "z";
  assert_string_equal (BigInt.to_string ~radix:36 (BigInt.of_int 36)) "10";
  assert_string_equal (BigInt.to_string ~radix:36 (BigInt.of_int 1295)) "zz";
  assert_string_equal (BigInt.to_string ~radix:36 (BigInt.of_int 1296)) "100"

let to_string_various_radixes () =
  (* Test various radixes *)
  let n = BigInt.of_int 100 in
  assert_string_equal (BigInt.to_string ~radix:2 n) "1100100";
  assert_string_equal (BigInt.to_string ~radix:3 n) "10201";
  assert_string_equal (BigInt.to_string ~radix:4 n) "1210";
  assert_string_equal (BigInt.to_string ~radix:5 n) "400";
  assert_string_equal (BigInt.to_string ~radix:6 n) "244";
  assert_string_equal (BigInt.to_string ~radix:7 n) "202";
  assert_string_equal (BigInt.to_string ~radix:8 n) "144";
  assert_string_equal (BigInt.to_string ~radix:9 n) "121";
  assert_string_equal (BigInt.to_string ~radix:10 n) "100"

let to_string_large_numbers () =
  (* Test large numbers *)
  let large = BigInt.of_string "123456789012345678901234567890" in
  let s10 = BigInt.to_string ~radix:10 large in
  assert_string_equal s10 "123456789012345678901234567890";
  (* Verify hex conversion works *)
  let s16 = BigInt.to_string ~radix:16 large in
  assert_true "hex string non-empty" (String.length s16 > 0)

let to_string_negative_large () =
  let neg_large = BigInt.of_string "-123456789012345678901234567890" in
  let s = BigInt.to_string ~radix:10 neg_large in
  assert_string_equal s "-123456789012345678901234567890"

let to_string_zero () =
  (* Zero in various radixes *)
  let zero = BigInt.of_int 0 in
  for r = 2 to 36 do
    assert_string_equal (BigInt.to_string ~radix:r zero) "0"
  done

(* ===================================================================
   BigInt conversion tests (to_float)
   =================================================================== *)

let to_float_small () =
  assert_float_exact (BigInt.to_float (BigInt.of_int 0)) 0.;
  assert_float_exact (BigInt.to_float (BigInt.of_int 1)) 1.;
  assert_float_exact (BigInt.to_float (BigInt.of_int (-1))) (-1.);
  assert_float_exact (BigInt.to_float (BigInt.of_int 100)) 100.;
  assert_float_exact (BigInt.to_float (BigInt.of_int (-100))) (-100.)

let to_float_large () =
  (* Large numbers may lose precision *)
  let large = BigInt.of_string "9007199254740992" in (* 2^53 *)
  let f = BigInt.to_float large in
  assert_true "large to_float is finite" (Float.is_finite f)

let to_float_very_large () =
  (* Very large numbers become infinity *)
  let huge = BigInt.of_string "1" in
  let shifted = BigInt.shift_left huge 10000 in
  let f = BigInt.to_float shifted in
  assert_true "huge number becomes infinity" (f = Float.infinity || f = Float.neg_infinity)

(* ===================================================================
   Constructor edge cases
   =================================================================== *)

let of_string_edge_cases () =
  (* Empty string *)
  assert_bigint_equal (BigInt.of_string "") (BigInt.of_int 0);
  (* Whitespace *)
  assert_bigint_equal (BigInt.of_string "  123  ") (BigInt.of_int 123);
  (* Leading zeros *)
  assert_bigint_equal (BigInt.of_string "00123") (BigInt.of_int 123);
  (* Negative with leading zeros *)
  assert_bigint_equal (BigInt.of_string "-00123") (BigInt.of_int (-123))

let of_string_hex () =
  assert_bigint_equal (BigInt.of_string "0x10") (BigInt.of_int 16);
  assert_bigint_equal (BigInt.of_string "0xFF") (BigInt.of_int 255);
  assert_bigint_equal (BigInt.of_string "0xABCD") (BigInt.of_int 43981)

let of_string_binary () =
  assert_bigint_equal (BigInt.of_string "0b1010") (BigInt.of_int 10);
  assert_bigint_equal (BigInt.of_string "0b11111111") (BigInt.of_int 255)

let of_string_octal () =
  assert_bigint_equal (BigInt.of_string "0o10") (BigInt.of_int 8);
  assert_bigint_equal (BigInt.of_string "0o777") (BigInt.of_int 511)

(* ===================================================================
   Comparison with different representations
   =================================================================== *)

let compare_equal () =
  let a = BigInt.of_int 42 in
  let b = BigInt.of_string "42" in
  assert_true "42 == 42" (BigInt.equal a b);
  assert_true "compare returns 0" (BigInt.compare a b = 0)

let compare_less () =
  let a = BigInt.of_int 10 in
  let b = BigInt.of_int 20 in
  assert_true "10 < 20" (BigInt.lt a b);
  assert_true "compare returns negative" (BigInt.compare a b < 0)

let compare_greater () =
  let a = BigInt.of_int 20 in
  let b = BigInt.of_int 10 in
  assert_true "20 > 10" (BigInt.gt a b);
  assert_true "compare returns positive" (BigInt.compare a b > 0)

let compare_negative () =
  let a = BigInt.of_int (-10) in
  let b = BigInt.of_int 10 in
  assert_true "-10 < 10" (BigInt.lt a b);
  let c = BigInt.of_int (-20) in
  assert_true "-20 < -10" (BigInt.lt c a)

let compare_large () =
  let a = BigInt.of_string "123456789012345678901234567890" in
  let b = BigInt.of_string "123456789012345678901234567891" in
  assert_true "large a < large b" (BigInt.lt a b);
  assert_true "large b > large a" (BigInt.gt b a)

(* ===================================================================
   Test list
   =================================================================== *)

let tests =
  [
    (* toString *)
    test "toString default radix" to_string_default_radix;
    test "toString radix 2 (binary)" to_string_radix_2;
    test "toString radix 8 (octal)" to_string_radix_8;
    test "toString radix 10 (decimal)" to_string_radix_10;
    test "toString radix 16 (hex)" to_string_radix_16;
    test "toString radix 36 (max)" to_string_radix_36;
    test "toString various radixes" to_string_various_radixes;
    test "toString large numbers" to_string_large_numbers;
    test "toString negative large" to_string_negative_large;
    test "toString zero all radixes" to_string_zero;
    (* to_float *)
    test "to_float small" to_float_small;
    test "to_float large" to_float_large;
    test "to_float very large" to_float_very_large;
    (* of_string edge cases *)
    test "of_string edge cases" of_string_edge_cases;
    test "of_string hex" of_string_hex;
    test "of_string binary" of_string_binary;
    test "of_string octal" of_string_octal;
    (* comparison *)
    test "compare equal" compare_equal;
    test "compare less" compare_less;
    test "compare greater" compare_greater;
    test "compare negative" compare_negative;
    test "compare large" compare_large;
  ]


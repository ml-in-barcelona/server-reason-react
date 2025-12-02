(** TC39 Test262: BigInt bitwise operation tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/BigInt

    Tests for BigInt bitwise operations:
    - Bitwise AND (&)
    - Bitwise OR (|)
    - Bitwise XOR (^)
    - Bitwise NOT (~)
    - Left shift (<<)
    - Right shift (>>) - arithmetic shift, sign-extending *)

open Helpers

(* ===================================================================
   Bitwise AND
   =================================================================== *)

let and_basic () =
  (* From QuickJS: 0x5a463ca6 & 0x67376856 = 1107699718 *)
  let a = BigInt.of_string "0x5a463ca6" in
  let b = BigInt.of_string "0x67376856" in
  assert_bigint (BigInt.logand a b) (BigInt.of_int 1107699718)

let and_zero () =
  let a = BigInt.of_int 0xFF in
  let b = BigInt.of_int 0 in
  assert_bigint (BigInt.logand a b) (BigInt.of_int 0)

let and_all_ones () =
  let a = BigInt.of_int 0b1010 in
  let b = BigInt.of_int 0b1111 in
  assert_bigint (BigInt.logand a b) (BigInt.of_int 0b1010)

let and_negative () =
  (* -1 in two's complement is all 1s *)
  let a = BigInt.of_int 0xFF in
  let b = BigInt.of_int (-1) in
  assert_bigint (BigInt.logand a b) (BigInt.of_int 0xFF)

(* ===================================================================
   Bitwise OR
   =================================================================== *)

let or_basic () =
  (* From QuickJS: 0x5a463ca6 | 0x67376856 = 2138537206 *)
  let a = BigInt.of_string "0x5a463ca6" in
  let b = BigInt.of_string "0x67376856" in
  assert_bigint (BigInt.logor a b) (BigInt.of_int 2138537206)

let or_zero () =
  let a = BigInt.of_int 0b1010 in
  let b = BigInt.of_int 0 in
  assert_bigint (BigInt.logor a b) (BigInt.of_int 0b1010)

let or_disjoint () =
  let a = BigInt.of_int 0b1010 in
  let b = BigInt.of_int 0b0101 in
  assert_bigint (BigInt.logor a b) (BigInt.of_int 0b1111)

(* ===================================================================
   Bitwise XOR
   =================================================================== *)

let xor_basic () =
  (* From QuickJS: 0x5a463ca6 ^ 0x67376856 = 1030837488 *)
  let a = BigInt.of_string "0x5a463ca6" in
  let b = BigInt.of_string "0x67376856" in
  assert_bigint (BigInt.logxor a b) (BigInt.of_int 1030837488)

let xor_same () =
  let a = BigInt.of_int 42 in
  assert_bigint (BigInt.logxor a a) (BigInt.of_int 0)

let xor_zero () =
  let a = BigInt.of_int 42 in
  let b = BigInt.of_int 0 in
  assert_bigint (BigInt.logxor a b) (BigInt.of_int 42)

(* ===================================================================
   Bitwise NOT
   =================================================================== *)

let not_basic () =
  (* From QuickJS: ~0x5a653ca6 = -1516584103 *)
  let a = BigInt.of_string "0x5a653ca6" in
  assert_bigint (BigInt.lognot a) (BigInt.of_int (-1516584103))

let not_zero () =
  let a = BigInt.of_int 0 in
  assert_bigint (BigInt.lognot a) (BigInt.of_int (-1))

let not_negative_one () =
  let a = BigInt.of_int (-1) in
  assert_bigint (BigInt.lognot a) (BigInt.of_int 0)

let not_positive () =
  (* ~5 = -6 *)
  let a = BigInt.of_int 5 in
  assert_bigint (BigInt.lognot a) (BigInt.of_int (-6))

let not_negative () =
  (* ~(-6) = 5 *)
  let a = BigInt.of_int (-6) in
  assert_bigint (BigInt.lognot a) (BigInt.of_int 5)

(* ===================================================================
   Left shift
   =================================================================== *)

let shift_left_basic () =
  let a = BigInt.of_int 1 in
  assert_bigint (BigInt.shift_left a 10) (BigInt.of_int 1024)

let shift_left_31 () =
  (* From QuickJS: 1 << 31 = 2147483648 *)
  let a = BigInt.of_int 1 in
  assert_bigint_string (BigInt.shift_left a 31) "2147483648"

let shift_left_32 () =
  (* From QuickJS: 1 << 32 = 4294967296 *)
  let a = BigInt.of_int 1 in
  assert_bigint_string (BigInt.shift_left a 32) "4294967296"

let shift_left_100 () =
  (* From QuickJS: 1 << 100 = 1267650600228229401496703205376 *)
  let a = BigInt.of_int 1 in
  assert_bigint_string (BigInt.shift_left a 100) "1267650600228229401496703205376"

let shift_left_large () =
  (* From QuickJS: 0x5a4653ca673768565b41f775 << 78 *)
  let a = BigInt.of_string "0x5a4653ca673768565b41f775" in
  assert_bigint_string (BigInt.shift_left a 78) "8443945299673273647701379149826607537748959488376832"

let shift_left_negative () =
  (* From QuickJS: -0x5a4653ca673768565b41f775 << 78 *)
  let a = BigInt.of_string "-0x5a4653ca673768565b41f775" in
  assert_bigint_string (BigInt.shift_left a 78) "-8443945299673273647701379149826607537748959488376832"

let shift_left_zero () =
  let a = BigInt.of_int 42 in
  assert_bigint (BigInt.shift_left a 0) (BigInt.of_int 42)

(* ===================================================================
   Right shift (arithmetic - sign extending)
   =================================================================== *)

let shift_right_basic () =
  let a = BigInt.of_int 1024 in
  assert_bigint (BigInt.shift_right a 5) (BigInt.of_int 32)

let shift_right_large () =
  (* From QuickJS: 0x5a4653ca673768565b41f775 >> 78 = 92441 *)
  let a = BigInt.of_string "0x5a4653ca673768565b41f775" in
  assert_bigint (BigInt.shift_right a 78) (BigInt.of_int 92441)

let shift_right_negative () =
  (* From QuickJS: -0x5a4653ca673768565b41f775 >> 78 = -92442 *)
  (* Arithmetic shift extends sign bit *)
  let a = BigInt.of_string "-0x5a4653ca673768565b41f775" in
  assert_bigint (BigInt.shift_right a 78) (BigInt.of_int (-92442))

let shift_right_zero () =
  let a = BigInt.of_int 42 in
  assert_bigint (BigInt.shift_right a 0) (BigInt.of_int 42)

let shift_right_negative_small () =
  (* -8 >> 2 = -2 (arithmetic shift) *)
  let a = BigInt.of_int (-8) in
  assert_bigint (BigInt.shift_right a 2) (BigInt.of_int (-2))

(* ===================================================================
   Test list
   =================================================================== *)

let tests =
  [
    (* AND *)
    test "and: basic" and_basic;
    test "and: with zero" and_zero;
    test "and: with all ones" and_all_ones;
    test "and: negative (two's complement)" and_negative;
    (* OR *)
    test "or: basic" or_basic;
    test "or: with zero" or_zero;
    test "or: disjoint bits" or_disjoint;
    (* XOR *)
    test "xor: basic" xor_basic;
    test "xor: same value" xor_same;
    test "xor: with zero" xor_zero;
    (* NOT *)
    test "not: basic" not_basic;
    test "not: zero" not_zero;
    test "not: -1" not_negative_one;
    test "not: positive" not_positive;
    test "not: negative" not_negative;
    (* Left shift *)
    test "shift_left: basic" shift_left_basic;
    test "shift_left: 1 << 31" shift_left_31;
    test "shift_left: 1 << 32" shift_left_32;
    test "shift_left: 1 << 100" shift_left_100;
    test "shift_left: large number" shift_left_large;
    test "shift_left: negative number" shift_left_negative;
    test "shift_left: by zero" shift_left_zero;
    (* Right shift *)
    test "shift_right: basic" shift_right_basic;
    test "shift_right: large number" shift_right_large;
    test "shift_right: negative (arithmetic)" shift_right_negative;
    test "shift_right: by zero" shift_right_zero;
    test "shift_right: small negative" shift_right_negative_small;
  ]

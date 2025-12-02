(** TC39 Test262: BigInt constructor tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/BigInt

    ECMA-262 Section: BigInt(value)

    The BigInt constructor:
    - Converts strings to BigInt (decimal, hex with 0x prefix)
    - Converts integers to BigInt
    - Throws for non-integer numbers
    - Throws for invalid string formats *)

open Helpers

(* ===================================================================
   From string - basic decimal parsing
   =================================================================== *)

let from_string_empty () =
  (* BigInt("") should return 0n in JavaScript *)
  assert_bigint (BigInt.of_string "") (BigInt.of_int 0)

let from_string_zero () = assert_bigint (BigInt.of_string "0") (BigInt.of_int 0)
let from_string_positive () = assert_bigint (BigInt.of_string "123") (BigInt.of_int 123)
let from_string_negative () = assert_bigint (BigInt.of_string "-123") (BigInt.of_int (-123))
let from_string_positive_sign () = assert_bigint (BigInt.of_string "+456") (BigInt.of_int 456)

let from_string_large () =
  (* A number larger than MAX_SAFE_INTEGER *)
  let large = BigInt.of_string "9007199254740993" in
  assert_bigint_string large "9007199254740993"

let from_string_very_large () =
  (* 3^100 from QuickJS test *)
  let expected = "515377520732011331036461129765621272702107522001" in
  let result = BigInt.of_string expected in
  assert_bigint_string result expected

(* ===================================================================
   From string - whitespace handling
   =================================================================== *)

let from_string_leading_space () = assert_bigint (BigInt.of_string "  123") (BigInt.of_int 123)
let from_string_trailing_space () = assert_bigint (BigInt.of_string "123   ") (BigInt.of_int 123)
let from_string_both_space () = assert_bigint (BigInt.of_string "  123   ") (BigInt.of_int 123)
let from_string_tabs () = assert_bigint (BigInt.of_string "\t123\t") (BigInt.of_int 123)
let from_string_newlines () = assert_bigint (BigInt.of_string "\n123\n") (BigInt.of_int 123)

(* ===================================================================
   From string - hexadecimal
   =================================================================== *)

let from_string_hex_lower () = assert_bigint (BigInt.of_string "0xff") (BigInt.of_int 255)
let from_string_hex_upper () = assert_bigint (BigInt.of_string "0XFF") (BigInt.of_int 255)

let from_string_hex_large () =
  (* From QuickJS test *)
  let result = BigInt.of_string "0x5a4653ca673768565b41f775d6947d55cf3813d1" in
  assert_bigint_string result "515377520732011331036461129765621272702107522001"

let from_string_hex_negative () = assert_bigint (BigInt.of_string "-0x10") (BigInt.of_int (-16))

(* ===================================================================
   From string - binary (0b prefix)
   =================================================================== *)

let from_string_binary () = assert_bigint (BigInt.of_string "0b1010") (BigInt.of_int 10)
let from_string_binary_upper () = assert_bigint (BigInt.of_string "0B1111") (BigInt.of_int 15)

(* ===================================================================
   From string - octal (0o prefix)
   =================================================================== *)

let from_string_octal () = assert_bigint (BigInt.of_string "0o77") (BigInt.of_int 63)
let from_string_octal_upper () = assert_bigint (BigInt.of_string "0O777") (BigInt.of_int 511)

(* ===================================================================
   From string - invalid inputs (should raise)
   =================================================================== *)

let from_string_invalid_sign_only () =
  (* BigInt("+") and BigInt("-") should throw SyntaxError *)
  assert_bigint_raises (fun () -> BigInt.of_string_exn "+");
  assert_bigint_raises (fun () -> BigInt.of_string_exn "-")

let from_string_invalid_trailing_chars () =
  (* BigInt("  123  r") should throw SyntaxError *)
  assert_bigint_raises (fun () -> BigInt.of_string_exn "123r");
  assert_bigint_raises (fun () -> BigInt.of_string_exn "  123  r")

let from_string_invalid_null_char () =
  (* BigInt("\x00a") should throw SyntaxError *)
  assert_bigint_raises (fun () -> BigInt.of_string_exn "\x00a")

let from_string_invalid_decimal_point () =
  (* BigInt("1.5") should throw - no decimals allowed *)
  assert_bigint_raises (fun () -> BigInt.of_string_exn "1.5")

let from_string_invalid_float_notation () =
  (* BigInt("1e10") should throw *)
  assert_bigint_raises (fun () -> BigInt.of_string_exn "1e10")

(* ===================================================================
   From integers
   =================================================================== *)

let from_int_zero () = assert_bigint (BigInt.of_int 0) (BigInt.of_string "0")
let from_int_positive () = assert_bigint (BigInt.of_int 42) (BigInt.of_string "42")
let from_int_negative () = assert_bigint (BigInt.of_int (-42)) (BigInt.of_string "-42")

let from_int_max_int () =
  let max = max_int in
  assert_bigint (BigInt.of_int max) (BigInt.of_string (string_of_int max))

let from_int_min_int () =
  let min = min_int in
  assert_bigint (BigInt.of_int min) (BigInt.of_string (string_of_int min))

(* ===================================================================
   From int64
   =================================================================== *)

let from_int64_large () =
  let large = 9007199254740993L in
  (* larger than MAX_SAFE_INTEGER *)
  assert_bigint (BigInt.of_int64 large) (BigInt.of_string "9007199254740993")

let from_int64_negative () = assert_bigint (BigInt.of_int64 (-9007199254740993L)) (BigInt.of_string "-9007199254740993")

(* ===================================================================
   Test list
   =================================================================== *)

let tests =
  [
    (* From string - basic *)
    test "from_string: empty string returns 0" from_string_empty;
    test "from_string: zero" from_string_zero;
    test "from_string: positive decimal" from_string_positive;
    test "from_string: negative decimal" from_string_negative;
    test "from_string: positive sign" from_string_positive_sign;
    test "from_string: large number" from_string_large;
    test "from_string: very large number (3^100)" from_string_very_large;
    (* From string - whitespace *)
    test "from_string: leading whitespace" from_string_leading_space;
    test "from_string: trailing whitespace" from_string_trailing_space;
    test "from_string: both whitespace" from_string_both_space;
    test "from_string: tabs" from_string_tabs;
    test "from_string: newlines" from_string_newlines;
    (* From string - hex *)
    test "from_string: hex lowercase" from_string_hex_lower;
    test "from_string: hex uppercase" from_string_hex_upper;
    test "from_string: hex large" from_string_hex_large;
    test "from_string: hex negative" from_string_hex_negative;
    (* From string - binary *)
    test "from_string: binary lowercase" from_string_binary;
    test "from_string: binary uppercase" from_string_binary_upper;
    (* From string - octal *)
    test "from_string: octal lowercase" from_string_octal;
    test "from_string: octal uppercase" from_string_octal_upper;
    (* From string - invalid *)
    test "from_string: sign only throws" from_string_invalid_sign_only;
    test "from_string: trailing chars throws" from_string_invalid_trailing_chars;
    test "from_string: null char throws" from_string_invalid_null_char;
    test "from_string: decimal point throws" from_string_invalid_decimal_point;
    test "from_string: float notation throws" from_string_invalid_float_notation;
    (* From integers *)
    test "from_int: zero" from_int_zero;
    test "from_int: positive" from_int_positive;
    test "from_int: negative" from_int_negative;
    test "from_int: max_int" from_int_max_int;
    test "from_int: min_int" from_int_min_int;
    (* From int64 *)
    test "from_int64: large positive" from_int64_large;
    test "from_int64: large negative" from_int64_negative;
  ]

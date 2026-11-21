open Helpers

let a1_t1 () = assert_nan (Number.parseInt "")
let a1_t2 () = assert_nan (Number.parseInt "   ")
let a1_t3 () = assert_nan (Number.parseInt "abc")
let a1_t4 () = assert_nan (Number.parseInt "$1234")

let a1_t5 () =
  assert_nan (Number.parseInt "+");
  assert_nan (Number.parseInt "-")

let a1_t6 () =
  assert_float (Number.parseInt "123abc") 123.0;
  assert_float (Number.parseInt "456.789") 456.0

let a1_t7 () =
  assert_nan (Number.parseInt "NaN");
  assert_nan (Number.parseInt "Infinity")

let a2_t1 () =
  assert_float (Number.parseInt "  123") 123.0;
  assert_float (Number.parseInt "   456") 456.0

let a2_t2 () =
  assert_float (Number.parseInt "\t123") 123.0;
  assert_float (Number.parseInt "\t\t456") 456.0

let a2_t3 () =
  assert_float (Number.parseInt "\n123") 123.0;
  assert_float (Number.parseInt "\n\n456") 456.0

let a2_t4 () = assert_float (Number.parseInt "\r123") 123.0
let a2_t5 () = assert_float (Number.parseInt "\x0C123") 123.0
let a2_t6 () = assert_float (Number.parseInt "\x0B123") 123.0
let a2_t7 () = assert_float (Number.parseInt " \t\n\r123") 123.0
let a2_t8 () = assert_float (Number.parseInt "\xC2\xA0123") 123.0
let a2_t9 () = assert_float (Number.parseInt "123   ") 123.0

let a2_t10 () =
  assert_nan (Number.parseInt "- 123");
  assert_nan (Number.parseInt "+ 123")

let a3_1_t1 () = assert_float (Number.parseInt "+123") 123.0
let a3_1_t2 () = assert_float (Number.parseInt "-123") (-123.0)

let a3_1_t3 () =
  assert_float (Number.parseInt "  +123") 123.0;
  assert_float (Number.parseInt "  -456") (-456.0)

let a3_1_t4 () =
  assert_nan (Number.parseInt "++123");
  assert_nan (Number.parseInt "--123");
  assert_nan (Number.parseInt "+-123")

let a3_1_t5 () =
  assert_float (Number.parseInt "+0") 0.0;
  assert_float (Number.parseInt "-0") 0.0

let a3_1_t6 () =
  assert_float (Number.parseInt "-0x10") (-16.0);
  assert_float (Number.parseInt "+0x10") 16.0

let a3_1_t7 () =
  assert_nan (Number.parseInt "+");
  assert_nan (Number.parseInt "-")

let a3_2_t1 () =
  assert_float (Number.parseInt ~radix:16 "-ff") (-255.0);
  assert_float (Number.parseInt ~radix:16 "+ff") 255.0

let a3_2_t2 () =
  assert_float (Number.parseInt ~radix:2 "-1010") (-10.0);
  assert_float (Number.parseInt ~radix:2 "+1010") 10.0

let a3_2_t3 () = assert_float (Number.parseInt ~radix:8 "-77") (-63.0)

let a4_1_t1 () =
  assert_float (Number.parseInt ~radix:2 "1010") 10.0;
  assert_float (Number.parseInt ~radix:2 "1111") 15.0;
  assert_float (Number.parseInt ~radix:2 "0") 0.0

let a4_1_t2 () =
  assert_float (Number.parseInt ~radix:8 "77") 63.0;
  assert_float (Number.parseInt ~radix:8 "10") 8.0;
  assert_float (Number.parseInt ~radix:8 "777") 511.0

let a4_2_t1 () =
  assert_float (Number.parseInt ~radix:16 "ff") 255.0;
  assert_float (Number.parseInt ~radix:16 "FF") 255.0;
  assert_float (Number.parseInt ~radix:16 "10") 16.0;
  assert_float (Number.parseInt ~radix:16 "abc") 2748.0

let a4_2_t2 () =
  assert_float (Number.parseInt ~radix:36 "z") 35.0;
  assert_float (Number.parseInt ~radix:36 "Z") 35.0;
  assert_float (Number.parseInt ~radix:36 "10") 36.0

let a5_1_t1 () =
  assert_float (Number.parseInt "0x10") 16.0;
  assert_float (Number.parseInt "0X10") 16.0;
  assert_float (Number.parseInt "0xff") 255.0;
  assert_float (Number.parseInt "0XFF") 255.0

let a5_2_t1 () =
  assert_float (Number.parseInt ~radix:16 "0x10") 16.0;
  assert_float (Number.parseInt ~radix:16 "0XFF") 255.0

let a5_2_t2 () =
  assert_float (Number.parseInt ~radix:10 "0x10") 0.0;
  assert_float (Number.parseInt ~radix:8 "0x10") 0.0

let a6_1_t1 () =
  assert_float (Number.parseInt ~radix:0 "123") 123.0;
  assert_float (Number.parseInt ~radix:0 "0x10") 16.0

let a6_1_t2 () = assert_nan (Number.parseInt ~radix:1 "123")
let a6_1_t3 () = assert_nan (Number.parseInt ~radix:37 "123")

let a6_1_t4 () =
  assert_nan (Number.parseInt ~radix:100 "123");
  assert_nan (Number.parseInt ~radix:1000 "123")

let a6_1_t5 () =
  assert_nan (Number.parseInt ~radix:(-1) "123");
  assert_nan (Number.parseInt ~radix:(-16) "ff")

let a6_1_t6 () =
  assert_float (Number.parseInt ~radix:2 "1") 1.0;
  assert_float (Number.parseInt ~radix:36 "z") 35.0

let a7_1_t1 () =
  assert_float (Number.parseInt ~radix:2 "102") 2.0;
  assert_float (Number.parseInt ~radix:8 "789") 7.0;
  assert_float (Number.parseInt ~radix:10 "12abc") 12.0

let a7_1_t2 () =
  assert_nan (Number.parseInt ~radix:2 "234");
  assert_nan (Number.parseInt ~radix:8 "89");
  assert_nan (Number.parseInt ~radix:10 "abc")

let a7_2_t1 () =
  assert_float (Number.parseInt "9007199254740991") 9007199254740991.0;
  assert_float (Number.parseInt "9007199254740992") 9007199254740992.0

let a7_2_t2 () = assert_float (Number.parseInt "0x1FFFFFFFFFFFFF") 9007199254740991.0

let a7_2_t3 () =
  let result = Number.parseInt "12345678901234567890" in
  assert_bool (result > 1.23e19 && result < 1.24e19) true;
  assert_float_exact (Number.parseInt ~radix:10 "99999999999999999999999999") 1e26;
  assert_float_exact (Number.parseInt "99999999999999999999999999") 1e26

let a7_3_t1 () =
  assert_float (Number.parseInt "00123") 123.0;
  assert_float (Number.parseInt "0000") 0.0;
  assert_float (Number.parseInt "007") 7.0

let a7_3_t2 () =
  assert_float (Number.parseInt ~radix:10 "00123") 123.0;
  assert_float (Number.parseInt ~radix:8 "00123") 83.0

let a7_3_t3 () =
  assert_float (Number.parseInt "0") 0.0;
  assert_float (Number.parseInt "00") 0.0;
  assert_float (Number.parseInt "000") 0.0

let a8 () =
  assert_float (Number.parseInt "3.14159") 3.0;
  assert_float (Number.parseInt "2.71828") 2.0;
  assert_nan (Number.parseInt ".5")

let misc_t1 () =
  assert_float (Number.parseInt "1e10") 1.0;
  assert_float (Number.parseInt "1E10") 1.0

let misc_t2 () = assert_nan (Number.parseInt "\xEF\xBC\x91\xEF\xBC\x92\xEF\xBC\x93")

let misc_t3 () =
  assert_float (Number.parseInt "0o123") 0.0;
  assert_float (Number.parseInt "0O123") 0.0

let misc_t4 () =
  assert_float (Number.parseInt "0b101") 0.0;
  assert_float (Number.parseInt "0B101") 0.0

let misc_t5 () =
  assert_float (Number.parseInt "0") 0.0;
  assert_float (Number.parseInt "1") 1.0;
  assert_float (Number.parseInt "9") 9.0

let misc_t6 () =
  assert_float (Number.parseInt ~radix:2 "1") 1.0;
  assert_float (Number.parseInt ~radix:2 "0") 0.0;
  assert_float (Number.parseInt ~radix:36 "0") 0.0;
  assert_float (Number.parseInt ~radix:36 "zz") 1295.0

let misc_t7 () =
  assert_float (Number.parseInt ~radix:16 "AbCdEf") 11259375.0;
  assert_float (Number.parseInt ~radix:36 "Hello") 29234652.0

let misc_t8 () = assert_float (Number.parseInt "\t\n\x0B\x0C\r 123") 123.0

let tests =
  [
    test "S15.1.2.2_A1_T1: empty string returns NaN" a1_t1;
    test "S15.1.2.2_A1_T2: whitespace only returns NaN" a1_t2;
    test "S15.1.2.2_A1_T3: non-numeric returns NaN" a1_t3;
    test "S15.1.2.2_A1_T4: invalid start char returns NaN" a1_t4;
    test "S15.1.2.2_A1_T5: sign only returns NaN" a1_t5;
    test "S15.1.2.2_A1_T6: stops at invalid chars" a1_t6;
    test "S15.1.2.2_A1_T7: NaN/Infinity strings return NaN" a1_t7;
    test "S15.1.2.2_A2_T1: leading spaces" a2_t1;
    test "S15.1.2.2_A2_T2: leading tabs" a2_t2;
    test "S15.1.2.2_A2_T3: leading newlines" a2_t3;
    test "S15.1.2.2_A2_T4: leading carriage return" a2_t4;
    test "S15.1.2.2_A2_T5: leading form feed" a2_t5;
    test "S15.1.2.2_A2_T6: leading vertical tab" a2_t6;
    test "S15.1.2.2_A2_T7: mixed whitespace" a2_t7;
    test "S15.1.2.2_A2_T8: non-breaking space" a2_t8;
    test "S15.1.2.2_A2_T9: trailing whitespace" a2_t9;
    test "S15.1.2.2_A2_T10: whitespace between sign and digits" a2_t10;
    test "S15.1.2.2_A3.1_T1: positive sign" a3_1_t1;
    test "S15.1.2.2_A3.1_T2: negative sign" a3_1_t2;
    test "S15.1.2.2_A3.1_T3: sign with whitespace" a3_1_t3;
    test "S15.1.2.2_A3.1_T4: multiple signs" a3_1_t4;
    test "S15.1.2.2_A3.1_T5: sign with zero" a3_1_t5;
    test "S15.1.2.2_A3.1_T6: sign with hex prefix" a3_1_t6;
    test "S15.1.2.2_A3.1_T7: sign alone" a3_1_t7;
    test "S15.1.2.2_A3.2_T1: negative hex" a3_2_t1;
    test "S15.1.2.2_A3.2_T2: negative binary" a3_2_t2;
    test "S15.1.2.2_A3.2_T3: negative octal" a3_2_t3;
    test "S15.1.2.2_A4.1_T1: radix 2" a4_1_t1;
    test "S15.1.2.2_A4.1_T2: radix 8" a4_1_t2;
    test "S15.1.2.2_A4.2_T1: radix 16" a4_2_t1;
    test "S15.1.2.2_A4.2_T2: radix 36" a4_2_t2;
    test "S15.1.2.2_A5.1_T1: 0x prefix auto-detection" a5_1_t1;
    test "S15.1.2.2_A5.2_T1: 0x with explicit radix 16" a5_2_t1;
    test "S15.1.2.2_A5.2_T2: 0x with non-16 radix" a5_2_t2;
    test "S15.1.2.2_A6.1_T1: radix 0 auto-detects" a6_1_t1;
    test "S15.1.2.2_A6.1_T2: radix 1 invalid" a6_1_t2;
    test "S15.1.2.2_A6.1_T3: radix 37 invalid" a6_1_t3;
    test "S15.1.2.2_A6.1_T4: large radix invalid" a6_1_t4;
    test "S15.1.2.2_A6.1_T5: negative radix invalid" a6_1_t5;
    test "S15.1.2.2_A6.1_T6: boundary radix valid" a6_1_t6;
    test "S15.1.2.2_A7.1_T1: digits beyond radix" a7_1_t1;
    test "S15.1.2.2_A7.1_T2: all digits invalid" a7_1_t2;
    test "S15.1.2.2_A7.2_T1: large numbers" a7_2_t1;
    test "S15.1.2.2_A7.2_T2: large hex numbers" a7_2_t2;
    test "S15.1.2.2_A7.2_T3: many digits" a7_2_t3;
    test "S15.1.2.2_A7.3_T1: leading zeros" a7_3_t1;
    test "S15.1.2.2_A7.3_T2: leading zeros with radix" a7_3_t2;
    test "S15.1.2.2_A7.3_T3: only zeros" a7_3_t3;
    test "S15.1.2.2_A8: decimal point" a8;
    test "misc_t1: scientific notation not parsed" misc_t1;
    test "misc_t2: unicode digits not supported" misc_t2;
    test "misc_t3: 0o octal prefix not auto-detected" misc_t3;
    test "misc_t4: 0b binary prefix not auto-detected" misc_t4;
    test "misc_t5: single digits" misc_t5;
    test "misc_t6: radix boundaries" misc_t6;
    test "misc_t7: case insensitivity" misc_t7;
    test "misc_t8: comprehensive whitespace" misc_t8;
  ]

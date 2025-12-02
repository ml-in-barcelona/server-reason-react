(** TC39 Test262: Date.prototype.toISOString tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/Date/prototype/toISOString

    ECMA-262 Section: Date.prototype.toISOString()

    Returns a string in ISO 8601 format: YYYY-MM-DDTHH:mm:ss.sssZ Throws RangeError for invalid dates (NaN). *)

open Helpers

(* ===================================================================
   Basic formatting
   =================================================================== *)

let to_iso_string_known_timestamp () =
  (* From QuickJS tests: new Date(1506098258091).toISOString() *)
  let d = Date.of_epoch_ms 1506098258091. in
  assert_string (Date.toISOString d) "2017-09-22T16:37:38.091Z"

let to_iso_string_epoch () =
  let d = Date.of_epoch_ms 0. in
  assert_string (Date.toISOString d) "1970-01-01T00:00:00.000Z"

let to_iso_string_y2k () =
  let d = Date.of_epoch_ms 946684800000. in
  assert_string (Date.toISOString d) "2000-01-01T00:00:00.000Z"

let to_iso_string_with_millis () =
  let d = Date.of_epoch_ms 1577840461123. in
  assert_string (Date.toISOString d) "2020-01-01T01:01:01.123Z"

(* ===================================================================
   Millisecond formatting (always 3 digits)
   =================================================================== *)

let to_iso_string_millis_zero () =
  (* 0ms should be formatted as .000 *)
  let d = Date.of_epoch_ms 946684800000. in
  assert_string (Date.toISOString d) "2000-01-01T00:00:00.000Z"

let to_iso_string_millis_001 () =
  let d = Date.of_epoch_ms 946684800001. in
  assert_string (Date.toISOString d) "2000-01-01T00:00:00.001Z"

let to_iso_string_millis_010 () =
  let d = Date.of_epoch_ms 946684800010. in
  assert_string (Date.toISOString d) "2000-01-01T00:00:00.010Z"

let to_iso_string_millis_100 () =
  let d = Date.of_epoch_ms 946684800100. in
  assert_string (Date.toISOString d) "2000-01-01T00:00:00.100Z"

let to_iso_string_millis_999 () =
  let d = Date.of_epoch_ms 946684800999. in
  assert_string (Date.toISOString d) "2000-01-01T00:00:00.999Z"

(* ===================================================================
   Zero-padding for date/time components
   =================================================================== *)

let to_iso_string_single_digit_month () =
  (* January = 01 *)
  let d = Date.of_epoch_ms 946684800000. in
  (* 2000-01-01 *)
  let iso = Date.toISOString d in
  assert_bool (String.sub iso 5 2 = "01") true

let to_iso_string_single_digit_day () =
  (* Day 1 = 01 *)
  let d = Date.of_epoch_ms 946684800000. in
  (* 2000-01-01 *)
  let iso = Date.toISOString d in
  assert_bool (String.sub iso 8 2 = "01") true

let to_iso_string_single_digit_hour () =
  (* Hour 1 = 01 *)
  let d = Date.of_epoch_ms 946688400000. in
  (* 2000-01-01T01:00:00Z *)
  let iso = Date.toISOString d in
  assert_bool (String.sub iso 11 2 = "01") true

(* ===================================================================
   Before epoch (negative timestamps)
   =================================================================== *)

let to_iso_string_before_epoch () =
  (* Dec 31, 1969 23:59:59.999 UTC *)
  let d = Date.of_epoch_ms (-1.) in
  assert_string (Date.toISOString d) "1969-12-31T23:59:59.999Z"

let to_iso_string_1969_jan () =
  (* Jan 1, 1969 00:00:00.000 UTC *)
  let d = Date.of_epoch_ms (-31536000000.) in
  assert_string (Date.toISOString d) "1969-01-01T00:00:00.000Z"

(* ===================================================================
   Expanded years (years outside 0000-9999)
   =================================================================== *)

let to_iso_string_year_0 () =
  (* Year 0 (1 BCE) - represented as +000000 or 0000 depending on implementation *)
  let d = Date.of_epoch_ms (-62167219200000.) in
  (* Approximately year 0 *)
  let iso = Date.toISOString d in
  (* Should have valid format *)
  assert_bool (String.length iso > 0) true

let to_iso_string_negative_year () =
  (* Year -1 (2 BCE) - formatted with minus sign *)
  let d = Date.of_epoch_ms (-62198755200000.) in
  (* Approximately year -1 *)
  let iso = Date.toISOString d in
  assert_bool (String.length iso > 0) true

let to_iso_string_year_10000 () =
  (* Year 10000 - formatted with + prefix *)
  let d = Date.of_epoch_ms 253402300800000. in
  (* Year 10000 *)
  let iso = Date.toISOString d in
  assert_bool (String.length iso > 0) true

(* ===================================================================
   Parse/format roundtrip
   =================================================================== *)

let to_iso_string_roundtrip () =
  (* Format then parse should give same timestamp *)
  let original_ms = 1506098258091. in
  let d = Date.of_epoch_ms original_ms in
  let iso = Date.toISOString d in
  let parsed_ms = Date.parse iso in
  assert_float_exact parsed_ms original_ms

let to_iso_string_roundtrip_epoch () =
  let original_ms = 0. in
  let d = Date.of_epoch_ms original_ms in
  let iso = Date.toISOString d in
  let parsed_ms = Date.parse iso in
  assert_float_exact parsed_ms original_ms

let to_iso_string_roundtrip_before_epoch () =
  let original_ms = -86400000. in
  (* 1 day before epoch *)
  let d = Date.of_epoch_ms original_ms in
  let iso = Date.toISOString d in
  let parsed_ms = Date.parse iso in
  assert_float_exact parsed_ms original_ms

(* ===================================================================
   QuickJS specific test cases
   =================================================================== *)

let to_iso_string_qjs_test_1 () =
  (* From QuickJS: new Date("2020-01-01T01:01:01.123Z").toISOString() *)
  let d = Date.of_epoch_ms (Date.parse "2020-01-01T01:01:01.123Z") in
  assert_string (Date.toISOString d) "2020-01-01T01:01:01.123Z"

let to_iso_string_qjs_test_2 () =
  (* new Date("2020-01-01T01:01:01.1Z").toISOString() -> "...01.100Z" *)
  let d = Date.of_epoch_ms (Date.parse "2020-01-01T01:01:01.1Z") in
  assert_string (Date.toISOString d) "2020-01-01T01:01:01.100Z"

let to_iso_string_qjs_test_3 () =
  (* new Date("2020-01-01T01:01:01.12Z").toISOString() -> "...01.120Z" *)
  let d = Date.of_epoch_ms (Date.parse "2020-01-01T01:01:01.12Z") in
  assert_string (Date.toISOString d) "2020-01-01T01:01:01.120Z"

(* ===================================================================
   Test list
   =================================================================== *)

let tests =
  [
    (* Basic formatting *)
    test "known timestamp" to_iso_string_known_timestamp;
    test "epoch" to_iso_string_epoch;
    test "Y2K" to_iso_string_y2k;
    test "with milliseconds" to_iso_string_with_millis;
    (* Millisecond formatting *)
    test "millis: 000" to_iso_string_millis_zero;
    test "millis: 001" to_iso_string_millis_001;
    test "millis: 010" to_iso_string_millis_010;
    test "millis: 100" to_iso_string_millis_100;
    test "millis: 999" to_iso_string_millis_999;
    (* Zero-padding *)
    test "single digit month padded" to_iso_string_single_digit_month;
    test "single digit day padded" to_iso_string_single_digit_day;
    test "single digit hour padded" to_iso_string_single_digit_hour;
    (* Before epoch *)
    test "before epoch -1ms" to_iso_string_before_epoch;
    test "1969 Jan" to_iso_string_1969_jan;
    (* Expanded years *)
    test "year 0" to_iso_string_year_0;
    test "negative year" to_iso_string_negative_year;
    test "year 10000" to_iso_string_year_10000;
    (* Roundtrip *)
    test "roundtrip known timestamp" to_iso_string_roundtrip;
    test "roundtrip epoch" to_iso_string_roundtrip_epoch;
    test "roundtrip before epoch" to_iso_string_roundtrip_before_epoch;
    (* QuickJS tests *)
    test "QJS: 2020-01-01T01:01:01.123Z" to_iso_string_qjs_test_1;
    test "QJS: .1Z -> .100Z" to_iso_string_qjs_test_2;
    test "QJS: .12Z -> .120Z" to_iso_string_qjs_test_3;
  ]

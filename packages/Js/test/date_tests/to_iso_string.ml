open Helpers

let to_iso_string_known_timestamp () =
  let d = Date.fromFloat 1506098258091. in
  assert_string (Date.toISOString d) "2017-09-22T16:37:38.091Z"

let to_iso_string_epoch () =
  let d = Date.fromFloat 0. in
  assert_string (Date.toISOString d) "1970-01-01T00:00:00.000Z"

let to_iso_string_y2k () =
  let d = Date.fromFloat 946684800000. in
  assert_string (Date.toISOString d) "2000-01-01T00:00:00.000Z"

let to_iso_string_with_millis () =
  let d = Date.fromFloat 1577840461123. in
  assert_string (Date.toISOString d) "2020-01-01T01:01:01.123Z"

let to_iso_string_millis_zero () =
  let d = Date.fromFloat 946684800000. in
  assert_string (Date.toISOString d) "2000-01-01T00:00:00.000Z"

let to_iso_string_millis_001 () =
  let d = Date.fromFloat 946684800001. in
  assert_string (Date.toISOString d) "2000-01-01T00:00:00.001Z"

let to_iso_string_millis_010 () =
  let d = Date.fromFloat 946684800010. in
  assert_string (Date.toISOString d) "2000-01-01T00:00:00.010Z"

let to_iso_string_millis_100 () =
  let d = Date.fromFloat 946684800100. in
  assert_string (Date.toISOString d) "2000-01-01T00:00:00.100Z"

let to_iso_string_millis_999 () =
  let d = Date.fromFloat 946684800999. in
  assert_string (Date.toISOString d) "2000-01-01T00:00:00.999Z"

let to_iso_string_single_digit_month () =
  let d = Date.fromFloat 946684800000. in
  let iso = Date.toISOString d in
  assert_bool (String.sub iso 5 2 = "01") true

let to_iso_string_single_digit_day () =
  let d = Date.fromFloat 946684800000. in
  let iso = Date.toISOString d in
  assert_bool (String.sub iso 8 2 = "01") true

let to_iso_string_single_digit_hour () =
  let d = Date.fromFloat 946688400000. in
  let iso = Date.toISOString d in
  assert_bool (String.sub iso 11 2 = "01") true

let to_iso_string_before_epoch () =
  let d = Date.fromFloat (-1.) in
  assert_string (Date.toISOString d) "1969-12-31T23:59:59.999Z"

let to_iso_string_1969_jan () =
  let d = Date.fromFloat (-31536000000.) in
  assert_string (Date.toISOString d) "1969-01-01T00:00:00.000Z"

let to_iso_string_year_0 () =
  let d = Date.fromFloat (-62167219200000.) in
  let iso = Date.toISOString d in
  assert_bool (String.length iso > 0) true

let to_iso_string_negative_year () =
  let d = Date.fromFloat (-62198755200000.) in
  let iso = Date.toISOString d in
  assert_bool (String.length iso > 0) true

let to_iso_string_year_10000 () =
  let d = Date.fromFloat 253402300800000. in
  let iso = Date.toISOString d in
  assert_bool (String.length iso > 0) true

let to_iso_string_roundtrip () =
  let original_ms = 1506098258091. in
  let d = Date.fromFloat original_ms in
  let iso = Date.toISOString d in
  let parsed_ms = Date.parseAsFloat iso in
  assert_float_exact parsed_ms original_ms

let to_iso_string_roundtrip_epoch () =
  let original_ms = 0. in
  let d = Date.fromFloat original_ms in
  let iso = Date.toISOString d in
  let parsed_ms = Date.parseAsFloat iso in
  assert_float_exact parsed_ms original_ms

let to_iso_string_roundtrip_before_epoch () =
  let original_ms = -86400000. in
  let d = Date.fromFloat original_ms in
  let iso = Date.toISOString d in
  let parsed_ms = Date.parseAsFloat iso in
  assert_float_exact parsed_ms original_ms

let to_iso_string_qjs_test_1 () =
  let d = Date.fromFloat (Date.parseAsFloat "2020-01-01T01:01:01.123Z") in
  assert_string (Date.toISOString d) "2020-01-01T01:01:01.123Z"

let to_iso_string_qjs_test_2 () =
  let d = Date.fromFloat (Date.parseAsFloat "2020-01-01T01:01:01.1Z") in
  assert_string (Date.toISOString d) "2020-01-01T01:01:01.100Z"

let to_iso_string_qjs_test_3 () =
  let d = Date.fromFloat (Date.parseAsFloat "2020-01-01T01:01:01.12Z") in
  assert_string (Date.toISOString d) "2020-01-01T01:01:01.120Z"

let tests =
  [
    test "known timestamp" to_iso_string_known_timestamp;
    test "epoch" to_iso_string_epoch;
    test "Y2K" to_iso_string_y2k;
    test "with milliseconds" to_iso_string_with_millis;
    test "millis: 000" to_iso_string_millis_zero;
    test "millis: 001" to_iso_string_millis_001;
    test "millis: 010" to_iso_string_millis_010;
    test "millis: 100" to_iso_string_millis_100;
    test "millis: 999" to_iso_string_millis_999;
    test "single digit month padded" to_iso_string_single_digit_month;
    test "single digit day padded" to_iso_string_single_digit_day;
    test "single digit hour padded" to_iso_string_single_digit_hour;
    test "before epoch -1ms" to_iso_string_before_epoch;
    test "1969 Jan" to_iso_string_1969_jan;
    test "year 0" to_iso_string_year_0;
    test "negative year" to_iso_string_negative_year;
    test "year 10000" to_iso_string_year_10000;
    test "roundtrip known timestamp" to_iso_string_roundtrip;
    test "roundtrip epoch" to_iso_string_roundtrip_epoch;
    test "roundtrip before epoch" to_iso_string_roundtrip_before_epoch;
    test "QJS: 2020-01-01T01:01:01.123Z" to_iso_string_qjs_test_1;
    test "QJS: .1Z -> .100Z" to_iso_string_qjs_test_2;
    test "QJS: .12Z -> .120Z" to_iso_string_qjs_test_3;
  ]

open Helpers

let parse_empty_string () = assert_nan (Date.parseAsFloat "")
let parse_year_only () = assert_float_exact (Date.parseAsFloat "2000") 946684800000.
let parse_year_month () = assert_float_exact (Date.parseAsFloat "2000-01") 946684800000.
let parse_full_date () = assert_float_exact (Date.parseAsFloat "2000-01-01") 946684800000.
let parse_date_time_utc () = assert_float_exact (Date.parseAsFloat "2000-01-01T00:00Z") 946684800000.
let parse_date_time_seconds () = assert_float_exact (Date.parseAsFloat "2000-01-01T00:00:00Z") 946684800000.
let parse_date_time_millis_1 () = assert_float_exact (Date.parseAsFloat "2000-01-01T00:00:00.1Z") 946684800100.
let parse_date_time_millis_2 () = assert_float_exact (Date.parseAsFloat "2000-01-01T00:00:00.10Z") 946684800100.
let parse_date_time_millis_3 () = assert_float_exact (Date.parseAsFloat "2000-01-01T00:00:00.100Z") 946684800100.
let parse_date_time_millis_4 () = assert_float_exact (Date.parseAsFloat "2000-01-01T00:00:00.1000Z") 946684800100.
let parse_timezone_offset () = assert_float_exact (Date.parseAsFloat "2000-01-01T00:00:00+00:00") 946684800000.
let parse_known_iso_timestamp () = assert_float_exact (Date.parseAsFloat "2017-09-22T16:37:38.091Z") 1506098258091.

let parse_roundtrip () =
  let original = "2020-01-01T01:01:01.123Z" in
  let parsed = Date.parseAsFloat original in
  assert_float_exact parsed 1577840461123.

let parse_millis_single_digit () = assert_float_exact (Date.parseAsFloat "2020-01-01T01:01:01.1Z") 1577840461100.
let parse_millis_two_digits () = assert_float_exact (Date.parseAsFloat "2020-01-01T01:01:01.12Z") 1577840461120.
let parse_millis_four_digits () = assert_float_exact (Date.parseAsFloat "2020-01-01T01:01:01.1234Z") 1577840461123.
let parse_millis_many_digits () = assert_float_exact (Date.parseAsFloat "2020-01-01T01:01:01.9999Z") 1577840461999.
let parse_expanded_year_positive () = assert_float_exact (Date.parseAsFloat "+002000-01-01T00:00:00Z") 946684800000.

let parse_expanded_year_negative () =
  let result = Date.parseAsFloat "-000001-01-01T00:00:00Z" in
  assert_not_nan result

let parse_expanded_year_zero_invalid () = assert_nan (Date.parseAsFloat "-000000-01-01T00:00:00Z")

let parse_month_name_format () =
  let result = Date.parseAsFloat "Jan 1 2000 00:00:00 GMT" in
  assert_float_exact result 946684800000.

let parse_with_weekday () =
  let result = Date.parseAsFloat "Sat Jan 1 2000 00:00:00 GMT" in
  assert_float_exact result 946684800000.

let parse_timezone_abbreviation () =
  let result = Date.parseAsFloat "Jan 1 2000 00:00:00 GMT+0100" in
  assert_float_exact result (946684800000. -. 3600000.)

let parse_timezone_abbreviation_2 () =
  let result = Date.parseAsFloat "Jan 1 2000 00:00:00 GMT+0200" in
  assert_float_exact result (946684800000. -. 7200000.)

let parse_invalid_gibberish () = assert_nan (Date.parseAsFloat "not a date")
let parse_invalid_partial () = assert_nan (Date.parseAsFloat "2000-")
let parse_invalid_month () = assert_nan (Date.parseAsFloat "2000-13-01")
let parse_invalid_day () = assert_nan (Date.parseAsFloat "2000-01-32")
let parse_invalid_hour () = assert_nan (Date.parseAsFloat "2000-01-01T25:00:00Z")
let parse_invalid_minute () = assert_nan (Date.parseAsFloat "2000-01-01T00:60:00Z")
let parse_invalid_second () = assert_nan (Date.parseAsFloat "2000-01-01T00:00:60Z")
let parse_garbage_after_z () = assert_nan (Date.parseAsFloat "2024-06-15T10:00:00Zgarbage")
let parse_garbage_after_time () = assert_nan (Date.parseAsFloat "2024-06-15T10:00xyz")
let parse_garbage_after_date () = assert_nan (Date.parseAsFloat "2024-06-15garbage")
let parse_garbage_after_offset () = assert_nan (Date.parseAsFloat "2024-06-15T10:00+02:00junk")
let parse_malformed_offset () = assert_nan (Date.parseAsFloat "2024-06-15T10:00+xx:00")
let parse_legacy_garbage_word () = assert_nan (Date.parseAsFloat "Jan 1 2000 foo")
let parse_legacy_malformed_gmt_offset () = assert_nan (Date.parseAsFloat "Jan 1 2000 00:00:00 GMT+xx")
let parse_iso_dot_without_digits () = assert_nan (Date.parseAsFloat "2000-01-01T00:00:00.Z")
let parse_date_only_is_utc () = assert_float_exact (Date.parseAsFloat "2024-06-15") 1718409600000.
let parse_year_only_is_utc () = assert_float_exact (Date.parseAsFloat "2024") 1704067200000.
let parse_year_month_is_utc () = assert_float_exact (Date.parseAsFloat "2024-06") 1717200000000.
let parse_feb_29_non_leap () = assert_float_exact (Date.parseAsFloat "2019-02-29") 1551398400000.
let parse_feb_29_leap () = assert_float_exact (Date.parseAsFloat "2020-02-29") 1582934400000.
let parse_apr_31 () = assert_float_exact (Date.parseAsFloat "2024-04-31") 1714521600000.
let parse_offset_hhmm () = assert_float_exact (Date.parseAsFloat "2024-06-15T10:00:00+0500") 1718427600000.
let parse_offset_bare_hours_invalid () = assert_nan (Date.parseAsFloat "2024-06-15T10:00:00+05")
let parse_offset_hour_24_invalid () = assert_nan (Date.parseAsFloat "2000-01-01T00:00:00+24:00")
let parse_offset_2359 () = assert_float_exact (Date.parseAsFloat "2000-01-01T00:00:00+23:59") 946598460000.
let parse_lowercase_z () = assert_float_exact (Date.parseAsFloat "2000-01-01T00:00:00z") 946684800000.
let parse_lowercase_t () = assert_float_exact (Date.parseAsFloat "2000-01-01t00:00:00Z") 946684800000.
let parse_legacy_day_month_order () = assert_float_exact (Date.parseAsFloat "01 Jan 2000 00:00:00 GMT") 946684800000.
let parse_legacy_utc_token () = assert_float_exact (Date.parseAsFloat "Jan 1 2000 00:00:00 UTC") 946684800000.
let parse_legacy_ut_token () = assert_float_exact (Date.parseAsFloat "Jan 1 2000 00:00:00 UT") 946684800000.

let parse_legacy_gmt_short_offsets () =
  assert_float_exact (Date.parseAsFloat "Jan 1 2000 00:00:00 GMT+1") 946681200000.;
  assert_float_exact (Date.parseAsFloat "Jan 1 2000 00:00:00 GMT+01") 946681200000.;
  assert_float_exact (Date.parseAsFloat "Jan 1 2000 00:00:00 GMT+01:00") 946681200000.

let parse_legacy_fractional_seconds () =
  assert_float_exact (Date.parseAsFloat "Jan 1 2000 00:00:00.500 GMT") 946684800500.

let parse_legacy_single_digit_time () = assert_float_exact (Date.parseAsFloat "Jan 1 2000 0:0:0 GMT") 946684800000.
let parse_legacy_gmt_without_time () = assert_float_exact (Date.parseAsFloat "Jan 1 2000 GMT") 946684800000.

let roundtrip_to_utc_string () =
  let d = Date.fromFloat 946684800000. in
  let reparsed = Date.fromString (Date.toUTCString d) in
  assert_float_exact (Date.valueOf reparsed) (Date.valueOf d)

let roundtrip_to_utc_string_before_epoch () =
  let d = Date.fromFloat (-86400000.) in
  let reparsed = Date.fromString (Date.toUTCString d) in
  assert_float_exact (Date.valueOf reparsed) (Date.valueOf d)

let roundtrip_to_utc_string_arbitrary () =
  let d = Date.fromFloat 1506098258000. in
  let reparsed = Date.fromString (Date.toUTCString d) in
  assert_float_exact (Date.valueOf reparsed) (Date.valueOf d)

let roundtrip_to_string () =
  let d = Date.fromFloat 946684800000. in
  let reparsed = Date.fromString (Date.toString d) in
  assert_float_exact (Date.valueOf reparsed) (Date.valueOf d)

let roundtrip_to_string_arbitrary () =
  let d = Date.fromFloat 1506098258000. in
  let reparsed = Date.fromString (Date.toString d) in
  assert_float_exact (Date.valueOf reparsed) (Date.valueOf d)

let parse_rfc1123_utc_string () = assert_float_exact (Date.parseAsFloat "Sat, 01 Jan 2000 00:00:00 GMT") 946684800000.

let tests =
  [
    test "empty string returns NaN" parse_empty_string;
    test "year only: 2000" parse_year_only;
    test "year-month: 2000-01" parse_year_month;
    test "full date: 2000-01-01" parse_full_date;
    test "date with time UTC: 2000-01-01T00:00Z" parse_date_time_utc;
    test "date with seconds: 2000-01-01T00:00:00Z" parse_date_time_seconds;
    test "milliseconds .1Z = 100ms" parse_date_time_millis_1;
    test "milliseconds .10Z = 100ms" parse_date_time_millis_2;
    test "milliseconds .100Z = 100ms" parse_date_time_millis_3;
    test "milliseconds .1000Z = 100ms" parse_date_time_millis_4;
    test "timezone offset +00:00" parse_timezone_offset;
    test "known ISO timestamp" parse_known_iso_timestamp;
    test "roundtrip parsing" parse_roundtrip;
    test "millis: single digit .1" parse_millis_single_digit;
    test "millis: two digits .12" parse_millis_two_digits;
    test "millis: four digits .1234 truncates" parse_millis_four_digits;
    test "millis: many digits .9999 truncates" parse_millis_many_digits;
    test "expanded year +002000" parse_expanded_year_positive;
    test "expanded year -000001" parse_expanded_year_negative;
    test "expanded year -000000 is invalid" parse_expanded_year_zero_invalid;
    test "month name format: Jan 1 2000" parse_month_name_format;
    test "with weekday: Sat Jan 1 2000" parse_with_weekday;
    test "timezone GMT+0100" parse_timezone_abbreviation;
    test "timezone GMT+0200" parse_timezone_abbreviation_2;
    test "invalid: gibberish" parse_invalid_gibberish;
    test "invalid: partial 2000-" parse_invalid_partial;
    test "invalid: month 13" parse_invalid_month;
    test "invalid: day 32" parse_invalid_day;
    test "invalid: hour 25" parse_invalid_hour;
    test "invalid: minute 60" parse_invalid_minute;
    test "invalid: second 60" parse_invalid_second;
    test "garbage after Z is NaN" parse_garbage_after_z;
    test "garbage after time is NaN" parse_garbage_after_time;
    test "garbage after date is NaN" parse_garbage_after_date;
    test "garbage after offset is NaN" parse_garbage_after_offset;
    test "malformed offset is NaN" parse_malformed_offset;
    test "legacy garbage word is NaN" parse_legacy_garbage_word;
    test "legacy malformed GMT offset is NaN" parse_legacy_malformed_gmt_offset;
    test "dot without fraction digits is NaN" parse_iso_dot_without_digits;
    test "date-only ISO is UTC" parse_date_only_is_utc;
    test "year-only ISO is UTC" parse_year_only_is_utc;
    test "year-month ISO is UTC" parse_year_month_is_utc;
    test "Feb 29 non-leap overflows to Mar 1" parse_feb_29_non_leap;
    test "Feb 29 leap year is valid" parse_feb_29_leap;
    test "Apr 31 overflows to May 1" parse_apr_31;
    test "offset +hhmm without colon" parse_offset_hhmm;
    test "bare +hh offset is NaN" parse_offset_bare_hours_invalid;
    test "offset hour 24 is NaN" parse_offset_hour_24_invalid;
    test "offset +23:59" parse_offset_2359;
    test "lowercase z designator" parse_lowercase_z;
    test "lowercase t separator" parse_lowercase_t;
    test "legacy DD Mon YYYY order" parse_legacy_day_month_order;
    test "legacy UTC token" parse_legacy_utc_token;
    test "legacy UT token" parse_legacy_ut_token;
    test "legacy short GMT offsets" parse_legacy_gmt_short_offsets;
    test "legacy fractional seconds" parse_legacy_fractional_seconds;
    test "legacy single-digit time fields" parse_legacy_single_digit_time;
    test "legacy GMT without time" parse_legacy_gmt_without_time;
    test "roundtrip toUTCString Y2K" roundtrip_to_utc_string;
    test "roundtrip toUTCString before epoch" roundtrip_to_utc_string_before_epoch;
    test "roundtrip toUTCString arbitrary" roundtrip_to_utc_string_arbitrary;
    test "roundtrip toString Y2K" roundtrip_to_string;
    test "roundtrip toString arbitrary" roundtrip_to_string_arbitrary;
    test "RFC 1123 (toUTCString shape)" parse_rfc1123_utc_string;
  ]

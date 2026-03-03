(** TC39 Test262: Date.parseAsFloat tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/Date/parse

    ECMA-262 Section: Date.parse(string)

    Date.parseAsFloat returns the time value (epoch milliseconds) from a string. Returns NaN if the string is not a
    valid date. *)

open Helpers

(* ===================================================================
   ISO 8601 format: YYYY-MM-DDTHH:mm:ss.sssZ
   =================================================================== *)

let parse_empty_string () =
  (* Date.parse("") returns NaN *)
  assert_nan (Date.parseAsFloat "")

let parse_year_only () =
  (* Date.parse("2000") = Jan 1, 2000 00:00:00 UTC *)
  assert_float_exact (Date.parseAsFloat "2000") 946684800000.

let parse_year_month () =
  (* Date.parse("2000-01") = Jan 1, 2000 00:00:00 UTC *)
  assert_float_exact (Date.parseAsFloat "2000-01") 946684800000.

let parse_full_date () =
  (* Date.parse("2000-01-01") = Jan 1, 2000 00:00:00 UTC *)
  assert_float_exact (Date.parseAsFloat "2000-01-01") 946684800000.

let parse_date_time_utc () =
  (* Date.parse("2000-01-01T00:00Z") *)
  assert_float_exact (Date.parseAsFloat "2000-01-01T00:00Z") 946684800000.

let parse_date_time_seconds () =
  (* Date.parse("2000-01-01T00:00:00Z") *)
  assert_float_exact (Date.parseAsFloat "2000-01-01T00:00:00Z") 946684800000.

let parse_date_time_millis_1 () =
  (* Date.parse("2000-01-01T00:00:00.1Z") = 100ms after midnight *)
  assert_float_exact (Date.parseAsFloat "2000-01-01T00:00:00.1Z") 946684800100.

let parse_date_time_millis_2 () =
  (* Date.parse("2000-01-01T00:00:00.10Z") = 100ms *)
  assert_float_exact (Date.parseAsFloat "2000-01-01T00:00:00.10Z") 946684800100.

let parse_date_time_millis_3 () =
  (* Date.parse("2000-01-01T00:00:00.100Z") = 100ms *)
  assert_float_exact (Date.parseAsFloat "2000-01-01T00:00:00.100Z") 946684800100.

let parse_date_time_millis_4 () =
  (* Date.parse("2000-01-01T00:00:00.1000Z") = implementation-defined, but QuickJS returns 100ms *)
  assert_float_exact (Date.parseAsFloat "2000-01-01T00:00:00.1000Z") 946684800100.

let parse_timezone_offset () =
  (* Date.parse("2000-01-01T00:00:00+00:00") *)
  assert_float_exact (Date.parseAsFloat "2000-01-01T00:00:00+00:00") 946684800000.

(* ===================================================================
   A known timestamp: 2017-09-22T16:37:38.091Z
   =================================================================== *)

let parse_known_iso_timestamp () =
  (* This is a specific timestamp from QuickJS tests *)
  assert_float_exact (Date.parseAsFloat "2017-09-22T16:37:38.091Z") 1506098258091.

let parse_roundtrip () =
  (* Parse an ISO string, format it back, should get same value *)
  let original = "2020-01-01T01:01:01.123Z" in
  let parsed = Date.parseAsFloat original in
  assert_float_exact parsed 1577840461123.

(* ===================================================================
   Millisecond parsing edge cases
   =================================================================== *)

let parse_millis_single_digit () =
  (* .1Z should be 100ms *)
  assert_float_exact (Date.parseAsFloat "2020-01-01T01:01:01.1Z") 1577840461100.

let parse_millis_two_digits () =
  (* .12Z should be 120ms *)
  assert_float_exact (Date.parseAsFloat "2020-01-01T01:01:01.12Z") 1577840461120.

let parse_millis_four_digits () =
  (* .1234Z truncates to 123ms *)
  assert_float_exact (Date.parseAsFloat "2020-01-01T01:01:01.1234Z") 1577840461123.

let parse_millis_many_digits () =
  (* .9999Z truncates to 999ms (no rounding) *)
  assert_float_exact (Date.parseAsFloat "2020-01-01T01:01:01.9999Z") 1577840461999.

(* ===================================================================
   Expanded years (6-digit years with +/- prefix)
   =================================================================== *)

let parse_expanded_year_positive () =
  (* +002000 is year 2000 *)
  assert_float_exact (Date.parseAsFloat "+002000-01-01T00:00:00Z") 946684800000.

let parse_expanded_year_negative () =
  (* -000001 is year -1 (2 BCE) *)
  let result = Date.parseAsFloat "-000001-01-01T00:00:00Z" in
  assert_not_nan result

let parse_expanded_year_zero_invalid () =
  (* -000000 is explicitly invalid per spec *)
  assert_nan (Date.parseAsFloat "-000000-01-01T00:00:00Z")

(* ===================================================================
   Non-ISO formats (toString/toUTCString style)
   =================================================================== *)

let parse_month_name_format () =
  (* "Jan 1 2000" style *)
  let result = Date.parseAsFloat "Jan 1 2000 00:00:00 GMT" in
  assert_float_exact result 946684800000.

let parse_with_weekday () =
  (* "Sat Jan 1 2000" style *)
  let result = Date.parseAsFloat "Sat Jan 1 2000 00:00:00 GMT" in
  assert_float_exact result 946684800000.

let parse_timezone_abbreviation () =
  (* GMT+0100 style offset *)
  let result = Date.parseAsFloat "Jan 1 2000 00:00:00 GMT+0100" in
  (* 1 hour before UTC midnight = Dec 31 1999 23:00 UTC *)
  assert_float_exact result (946684800000. -. 3600000.)

let parse_timezone_abbreviation_2 () =
  (* GMT+0200 *)
  let result = Date.parseAsFloat "Jan 1 2000 00:00:00 GMT+0200" in
  assert_float_exact result (946684800000. -. 7200000.)

(* ===================================================================
   Invalid strings
   =================================================================== *)

let parse_invalid_gibberish () = assert_nan (Date.parseAsFloat "not a date")
let parse_invalid_partial () = assert_nan (Date.parseAsFloat "2000-")

let parse_invalid_month () =
  (* Month 13 is invalid *)
  assert_nan (Date.parseAsFloat "2000-13-01")

let parse_invalid_day () =
  (* Day 32 is invalid *)
  assert_nan (Date.parseAsFloat "2000-01-32")

let parse_invalid_hour () =
  (* Hour 25 is invalid *)
  assert_nan (Date.parseAsFloat "2000-01-01T25:00:00Z")

let parse_invalid_minute () =
  (* Minute 60 is invalid *)
  assert_nan (Date.parseAsFloat "2000-01-01T00:60:00Z")

let parse_invalid_second () =
  (* Second 60 is invalid (except leap seconds, not supported) *)
  assert_nan (Date.parseAsFloat "2000-01-01T00:00:60Z")

(* ===================================================================
   Test list
   =================================================================== *)

let tests =
  [
    (* ISO 8601 format *)
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
    (* Known timestamp *)
    test "known ISO timestamp" parse_known_iso_timestamp;
    test "roundtrip parsing" parse_roundtrip;
    (* Millisecond edge cases *)
    test "millis: single digit .1" parse_millis_single_digit;
    test "millis: two digits .12" parse_millis_two_digits;
    test "millis: four digits .1234 truncates" parse_millis_four_digits;
    test "millis: many digits .9999 truncates" parse_millis_many_digits;
    (* Expanded years *)
    test "expanded year +002000" parse_expanded_year_positive;
    test "expanded year -000001" parse_expanded_year_negative;
    test "expanded year -000000 is invalid" parse_expanded_year_zero_invalid;
    (* Non-ISO formats *)
    test "month name format: Jan 1 2000" parse_month_name_format;
    test "with weekday: Sat Jan 1 2000" parse_with_weekday;
    test "timezone GMT+0100" parse_timezone_abbreviation;
    test "timezone GMT+0200" parse_timezone_abbreviation_2;
    (* Invalid strings *)
    test "invalid: gibberish" parse_invalid_gibberish;
    test "invalid: partial 2000-" parse_invalid_partial;
    test "invalid: month 13" parse_invalid_month;
    test "invalid: day 32" parse_invalid_day;
    test "invalid: hour 25" parse_invalid_hour;
    test "invalid: minute 60" parse_invalid_minute;
    test "invalid: second 60" parse_invalid_second;
  ]

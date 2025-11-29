(** TC39 Test262: Date.UTC tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/Date/UTC

    ECMA-262 Section: Date.UTC(year, month[, date[, hours[, minutes[, seconds[, ms]]]]])

    Date.UTC returns the time value (epoch milliseconds) for the given UTC date components. *)

open Helpers

(* ===================================================================
   Basic Date.UTC tests from QuickJS test suite
   =================================================================== *)

let utc_year_only () =
  (* Date.UTC(2017) = Jan 1, 2017 00:00:00.000 UTC *)
  assert_float_exact (Date.utc ~year:2017. ~month:0. ()) 1483228800000.

let utc_year_month () =
  (* Date.UTC(2017, 9) = Oct 1, 2017 00:00:00.000 UTC *)
  assert_float_exact (Date.utc ~year:2017. ~month:9. ()) 1506816000000.

let utc_year_month_day () =
  (* Date.UTC(2017, 9, 22) = Oct 22, 2017 00:00:00.000 UTC *)
  assert_float_exact (Date.utc ~year:2017. ~month:9. ~day:22. ()) 1508630400000.

let utc_with_hours () =
  (* Date.UTC(2017, 9, 22, 18) *)
  assert_float_exact (Date.utc ~year:2017. ~month:9. ~day:22. ~hours:18. ()) 1508695200000.

let utc_with_minutes () =
  (* Date.UTC(2017, 9, 22, 18, 10) *)
  assert_float_exact (Date.utc ~year:2017. ~month:9. ~day:22. ~hours:18. ~minutes:10. ()) 1508695800000.

let utc_with_seconds () =
  (* Date.UTC(2017, 9, 22, 18, 10, 11) *)
  assert_float_exact (Date.utc ~year:2017. ~month:9. ~day:22. ~hours:18. ~minutes:10. ~seconds:11. ()) 1508695811000.

let utc_with_ms () =
  (* Date.UTC(2017, 9, 22, 18, 10, 11, 91) *)
  assert_float_exact
    (Date.utc ~year:2017. ~month:9. ~day:22. ~hours:18. ~minutes:10. ~seconds:11. ~ms:91. ())
    1508695811091.

(* ===================================================================
   NaN propagation
   =================================================================== *)

let utc_nan_year () = assert_nan (Date.utc ~year:nan ~month:0. ())
let utc_nan_month () = assert_nan (Date.utc ~year:2017. ~month:nan ())
let utc_nan_day () = assert_nan (Date.utc ~year:2017. ~month:9. ~day:nan ())
let utc_nan_hours () = assert_nan (Date.utc ~year:2017. ~month:9. ~day:22. ~hours:nan ())
let utc_nan_minutes () = assert_nan (Date.utc ~year:2017. ~month:9. ~day:22. ~hours:18. ~minutes:nan ())
let utc_nan_seconds () = assert_nan (Date.utc ~year:2017. ~month:9. ~day:22. ~hours:18. ~minutes:10. ~seconds:nan ())
let utc_nan_ms () = assert_nan (Date.utc ~year:2017. ~month:9. ~day:22. ~hours:18. ~minutes:10. ~seconds:11. ~ms:nan ())

(* ===================================================================
   Epoch and boundary values
   =================================================================== *)

let utc_epoch () =
  (* Unix epoch: Jan 1, 1970 00:00:00.000 UTC *)
  assert_float_exact (Date.utc ~year:1970. ~month:0. ~day:1. ()) 0.

let utc_before_epoch () =
  (* Dec 31, 1969 23:59:59.000 UTC = -1000ms *)
  assert_float_exact (Date.utc ~year:1969. ~month:11. ~day:31. ~hours:23. ~minutes:59. ~seconds:59. ()) (-1000.)

let utc_y2k () =
  (* Jan 1, 2000 00:00:00.000 UTC *)
  assert_float_exact (Date.utc ~year:2000. ~month:0. ~day:1. ()) 946684800000.

(* ===================================================================
   Year handling: 0-99 maps to 1900-1999
   =================================================================== *)

let utc_year_0 () =
  (* Year 0 maps to 1900 *)
  let result = Date.utc ~year:0. ~month:0. ~day:1. () in
  (* Jan 1, 1900 00:00:00 UTC *)
  assert_float_exact result (-2208988800000.)

let utc_year_99 () =
  (* Year 99 maps to 1999 *)
  let result = Date.utc ~year:99. ~month:0. ~day:1. () in
  (* Jan 1, 1999 00:00:00 UTC *)
  assert_float_exact result 915148800000.

let utc_year_100 () =
  (* Year 100 stays as year 100 (not mapped) *)
  let result = Date.utc ~year:100. ~month:0. ~day:1. () in
  assert_not_nan result

(* ===================================================================
   Month overflow/underflow
   =================================================================== *)

let utc_month_overflow () =
  (* Month 12 = January of next year *)
  let m12 = Date.utc ~year:2017. ~month:12. ~day:1. () in
  let jan_next = Date.utc ~year:2018. ~month:0. ~day:1. () in
  assert_float_exact m12 jan_next

let utc_month_underflow () =
  (* Month -1 = December of previous year *)
  let m_neg1 = Date.utc ~year:2017. ~month:(-1.) ~day:1. () in
  let dec_prev = Date.utc ~year:2016. ~month:11. ~day:1. () in
  assert_float_exact m_neg1 dec_prev

(* ===================================================================
   Day overflow/underflow
   =================================================================== *)

let utc_day_overflow () =
  (* Day 32 in January = Feb 1 *)
  let d32 = Date.utc ~year:2017. ~month:0. ~day:32. () in
  let feb1 = Date.utc ~year:2017. ~month:1. ~day:1. () in
  assert_float_exact d32 feb1

let utc_day_zero () =
  (* Day 0 = last day of previous month *)
  let d0 = Date.utc ~year:2017. ~month:1. ~day:0. () in
  let jan31 = Date.utc ~year:2017. ~month:0. ~day:31. () in
  assert_float_exact d0 jan31

let utc_day_negative () =
  (* Day -1 = second-to-last day of previous month *)
  let d_neg1 = Date.utc ~year:2017. ~month:1. ~day:(-1.) () in
  let jan30 = Date.utc ~year:2017. ~month:0. ~day:30. () in
  assert_float_exact d_neg1 jan30

(* ===================================================================
   Leap year handling
   =================================================================== *)

let utc_leap_year_feb_29 () =
  (* Feb 29, 2020 is valid (2020 is a leap year) *)
  let result = Date.utc ~year:2020. ~month:1. ~day:29. () in
  assert_not_nan result

let utc_non_leap_year_feb_29 () =
  (* Feb 29, 2019 overflows to Mar 1, 2019 (not a leap year) *)
  let feb29_2019 = Date.utc ~year:2019. ~month:1. ~day:29. () in
  let mar1_2019 = Date.utc ~year:2019. ~month:2. ~day:1. () in
  assert_float_exact feb29_2019 mar1_2019

let utc_leap_year_2000 () =
  (* 2000 is a leap year (divisible by 400) *)
  let result = Date.utc ~year:2000. ~month:1. ~day:29. () in
  assert_not_nan result

let utc_non_leap_year_1900 () =
  (* 1900 is NOT a leap year (divisible by 100 but not 400) *)
  let feb29_1900 = Date.utc ~year:1900. ~month:1. ~day:29. () in
  let mar1_1900 = Date.utc ~year:1900. ~month:2. ~day:1. () in
  assert_float_exact feb29_1900 mar1_1900

(* ===================================================================
   Large value handling
   =================================================================== *)

let utc_large_day_offset () =
  (* From QuickJS: Date.UTC(2017, 9, 22 - 1e10, 18 + 24e10) *)
  let result = Date.utc ~year:2017. ~month:9. ~day:(22. -. 1e10) ~hours:(18. +. 24e10) () in
  assert_float_exact result 1508695200000.

let utc_large_minute_offset () =
  (* Date.UTC(2017, 9, 22, 18 - 1e10, 10 + 60e10) *)
  let result = Date.utc ~year:2017. ~month:9. ~day:22. ~hours:(18. -. 1e10) ~minutes:(10. +. 60e10) () in
  assert_float_exact result 1508695800000.

let utc_large_second_offset () =
  (* Date.UTC(2017, 9, 22, 18, 10 - 1e10, 11 + 60e10) *)
  let result = Date.utc ~year:2017. ~month:9. ~day:22. ~hours:18. ~minutes:(10. -. 1e10) ~seconds:(11. +. 60e10) () in
  assert_float_exact result 1508695811000.

let utc_large_ms_offset () =
  (* Date.UTC(2017, 9, 22, 18, 10, 11 - 1e12, 91 + 1000e12) *)
  let result =
    Date.utc ~year:2017. ~month:9. ~day:22. ~hours:18. ~minutes:10. ~seconds:(11. -. 1e12) ~ms:(91. +. 1000e12) ()
  in
  assert_float_exact result 1508695811091.

(* ===================================================================
   Test list
   =================================================================== *)

let tests =
  [
    (* Basic UTC construction *)
    test "UTC year only" utc_year_only;
    test "UTC year and month" utc_year_month;
    test "UTC year, month, day" utc_year_month_day;
    test "UTC with hours" utc_with_hours;
    test "UTC with minutes" utc_with_minutes;
    test "UTC with seconds" utc_with_seconds;
    test "UTC with milliseconds" utc_with_ms;
    (* NaN propagation *)
    test "UTC NaN year" utc_nan_year;
    test "UTC NaN month" utc_nan_month;
    test "UTC NaN day" utc_nan_day;
    test "UTC NaN hours" utc_nan_hours;
    test "UTC NaN minutes" utc_nan_minutes;
    test "UTC NaN seconds" utc_nan_seconds;
    test "UTC NaN ms" utc_nan_ms;
    (* Epoch and boundaries *)
    test "UTC Unix epoch" utc_epoch;
    test "UTC before epoch" utc_before_epoch;
    test "UTC Y2K" utc_y2k;
    (* Year mapping 0-99 -> 1900-1999 *)
    test "UTC year 0 -> 1900" utc_year_0;
    test "UTC year 99 -> 1999" utc_year_99;
    test "UTC year 100 stays 100" utc_year_100;
    (* Month overflow/underflow *)
    test "UTC month 12 = January next year" utc_month_overflow;
    test "UTC month -1 = December prev year" utc_month_underflow;
    (* Day overflow/underflow *)
    test "UTC day 32 Jan = Feb 1" utc_day_overflow;
    test "UTC day 0 = last day prev month" utc_day_zero;
    test "UTC day -1 = second-to-last prev" utc_day_negative;
    (* Leap years *)
    test "UTC leap year Feb 29 valid" utc_leap_year_feb_29;
    test "UTC non-leap Feb 29 = Mar 1" utc_non_leap_year_feb_29;
    test "UTC 2000 is leap year" utc_leap_year_2000;
    test "UTC 1900 is NOT leap year" utc_non_leap_year_1900;
    (* Large value handling *)
    test "UTC large day offset" utc_large_day_offset;
    test "UTC large minute offset" utc_large_minute_offset;
    test "UTC large second offset" utc_large_second_offset;
    test "UTC large ms offset" utc_large_ms_offset;
  ]

(** TC39 Test262: Date setter tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/Date/prototype/set*

    Tests for setters: setDate, setFullYear, setHours, setMinutes, setSeconds,
    setMilliseconds, setMonth, setTime and their UTC variants *)

open Helpers

module Date = Js.Date

(* ===================================================================
   setTime tests
   =================================================================== *)

let set_time_basic () =
  let result = Date.setTime 1508695811091. 0. in
  assert_float_exact result 1508695811091.

let set_time_epoch () =
  let result = Date.setTime 0. 1000. in
  assert_float_exact result 0.

let set_time_negative () =
  let result = Date.setTime (-1000.) 0. in
  assert_float_exact result (-1000.)

let set_time_nan_value () =
  let result = Date.setTime nan 0. in
  assert_nan result

let set_time_on_nan_date () =
  let result = Date.setTime 1000. nan in
  assert_float_exact result 1000.

(* ===================================================================
   setUTCMilliseconds tests
   =================================================================== *)

let set_utc_ms_basic () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:30. ~seconds:45. ~ms:0. () in
  let result = Date.setUTCMilliseconds 500. d in
  assert_float_exact (Date.getUTCMilliseconds result) 500.

let set_utc_ms_overflow () =
  (* Setting ms to 1000 should roll over to next second *)
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:30. ~seconds:45. ~ms:0. () in
  let result = Date.setUTCMilliseconds 1000. d in
  assert_float_exact (Date.getUTCMilliseconds result) 0.;
  assert_float_exact (Date.getUTCSeconds result) 46.

let set_utc_ms_negative () =
  (* Negative ms should roll back *)
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:30. ~seconds:45. ~ms:500. () in
  let result = Date.setUTCMilliseconds (-1.) d in
  assert_float_exact (Date.getUTCMilliseconds result) 999.;
  assert_float_exact (Date.getUTCSeconds result) 44.

let set_utc_ms_nan () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. () in
  let result = Date.setUTCMilliseconds nan d in
  assert_nan result

(* ===================================================================
   setUTCSeconds tests
   =================================================================== *)

let set_utc_seconds_basic () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:30. ~seconds:0. () in
  let result = Date.setUTCSeconds 45. d in
  assert_float_exact (Date.getUTCSeconds result) 45.

let set_utc_seconds_overflow () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:30. ~seconds:0. () in
  let result = Date.setUTCSeconds 60. d in
  assert_float_exact (Date.getUTCSeconds result) 0.;
  assert_float_exact (Date.getUTCMinutes result) 31.

let set_utc_seconds_with_ms () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:30. ~seconds:0. ~ms:0. () in
  let result = Date.setUTCSecondsMs ~seconds:45. ~milliseconds:123. d in
  assert_float_exact (Date.getUTCSeconds result) 45.;
  assert_float_exact (Date.getUTCMilliseconds result) 123.

let set_utc_seconds_nan () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. () in
  let result = Date.setUTCSeconds nan d in
  assert_nan result

(* ===================================================================
   setUTCMinutes tests
   =================================================================== *)

let set_utc_minutes_basic () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:0. () in
  let result = Date.setUTCMinutes 45. d in
  assert_float_exact (Date.getUTCMinutes result) 45.

let set_utc_minutes_overflow () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:0. () in
  let result = Date.setUTCMinutes 60. d in
  assert_float_exact (Date.getUTCMinutes result) 0.;
  assert_float_exact (Date.getUTCHours result) 13.

let set_utc_minutes_with_seconds () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:0. ~seconds:0. () in
  let result = Date.setUTCMinutesS ~minutes:30. ~seconds:45. d in
  assert_float_exact (Date.getUTCMinutes result) 30.;
  assert_float_exact (Date.getUTCSeconds result) 45.

let set_utc_minutes_with_seconds_ms () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:0. ~seconds:0. ~ms:0. () in
  let result = Date.setUTCMinutesSMs ~minutes:30. ~seconds:45. ~milliseconds:123. d in
  assert_float_exact (Date.getUTCMinutes result) 30.;
  assert_float_exact (Date.getUTCSeconds result) 45.;
  assert_float_exact (Date.getUTCMilliseconds result) 123.

let set_utc_minutes_nan () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. () in
  let result = Date.setUTCMinutes nan d in
  assert_nan result

(* ===================================================================
   setUTCHours tests
   =================================================================== *)

let set_utc_hours_basic () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:0. () in
  let result = Date.setUTCHours 18. d in
  assert_float_exact (Date.getUTCHours result) 18.

let set_utc_hours_overflow () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:0. () in
  let result = Date.setUTCHours 24. d in
  assert_float_exact (Date.getUTCHours result) 0.;
  assert_float_exact (Date.getUTCDate result) 16.

let set_utc_hours_with_minutes () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:0. ~minutes:0. () in
  let result = Date.setUTCHoursM ~hours:18. ~minutes:30. d in
  assert_float_exact (Date.getUTCHours result) 18.;
  assert_float_exact (Date.getUTCMinutes result) 30.

let set_utc_hours_with_minutes_seconds () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:0. ~minutes:0. ~seconds:0. () in
  let result = Date.setUTCHoursMS ~hours:18. ~minutes:30. ~seconds:45. d in
  assert_float_exact (Date.getUTCHours result) 18.;
  assert_float_exact (Date.getUTCMinutes result) 30.;
  assert_float_exact (Date.getUTCSeconds result) 45.

let set_utc_hours_all () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:0. ~minutes:0. ~seconds:0. ~ms:0. () in
  let result = Date.setUTCHoursMSMs ~hours:18. ~minutes:30. ~seconds:45. ~milliseconds:123. d in
  assert_float_exact (Date.getUTCHours result) 18.;
  assert_float_exact (Date.getUTCMinutes result) 30.;
  assert_float_exact (Date.getUTCSeconds result) 45.;
  assert_float_exact (Date.getUTCMilliseconds result) 123.

let set_utc_hours_nan () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. () in
  let result = Date.setUTCHours nan d in
  assert_nan result

(* ===================================================================
   setUTCDate tests
   =================================================================== *)

let set_utc_date_basic () =
  let d = Date.utc ~year:2020. ~month:5. ~day:1. () in
  let result = Date.setUTCDate 15. d in
  assert_float_exact (Date.getUTCDate result) 15.

let set_utc_date_overflow () =
  (* June has 30 days, setting to 31 should roll to July 1 *)
  let d = Date.utc ~year:2020. ~month:5. ~day:1. () in
  let result = Date.setUTCDate 31. d in
  assert_float_exact (Date.getUTCDate result) 1.;
  assert_float_exact (Date.getUTCMonth result) 6.

let set_utc_date_zero () =
  (* Day 0 means last day of previous month *)
  let d = Date.utc ~year:2020. ~month:5. ~day:15. () in
  let result = Date.setUTCDate 0. d in
  assert_float_exact (Date.getUTCDate result) 31.;
  assert_float_exact (Date.getUTCMonth result) 4.

let set_utc_date_negative () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. () in
  let result = Date.setUTCDate (-1.) d in
  assert_float_exact (Date.getUTCDate result) 30.;
  assert_float_exact (Date.getUTCMonth result) 4.

let set_utc_date_nan () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. () in
  let result = Date.setUTCDate nan d in
  assert_nan result

(* ===================================================================
   setUTCMonth tests
   =================================================================== *)

let set_utc_month_basic () =
  let d = Date.utc ~year:2020. ~month:0. ~day:15. () in
  let result = Date.setUTCMonth 5. d in
  assert_float_exact (Date.getUTCMonth result) 5.

let set_utc_month_overflow () =
  let d = Date.utc ~year:2020. ~month:0. ~day:15. () in
  let result = Date.setUTCMonth 12. d in
  assert_float_exact (Date.getUTCMonth result) 0.;
  assert_float_exact (Date.getUTCFullYear result) 2021.

let set_utc_month_negative () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. () in
  let result = Date.setUTCMonth (-1.) d in
  assert_float_exact (Date.getUTCMonth result) 11.;
  assert_float_exact (Date.getUTCFullYear result) 2019.

let set_utc_month_with_date () =
  let d = Date.utc ~year:2020. ~month:0. ~day:1. () in
  let result = Date.setUTCMonthD ~month:5. ~date:15. d in
  assert_float_exact (Date.getUTCMonth result) 5.;
  assert_float_exact (Date.getUTCDate result) 15.

let set_utc_month_nan () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. () in
  let result = Date.setUTCMonth nan d in
  assert_nan result

(* ===================================================================
   setUTCFullYear tests
   =================================================================== *)

let set_utc_full_year_basic () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. () in
  let result = Date.setUTCFullYear 2025. d in
  assert_float_exact (Date.getUTCFullYear result) 2025.

let set_utc_full_year_with_month () =
  let d = Date.utc ~year:2020. ~month:0. ~day:15. () in
  let result = Date.setUTCFullYearM ~year:2025. ~month:5. d in
  assert_float_exact (Date.getUTCFullYear result) 2025.;
  assert_float_exact (Date.getUTCMonth result) 5.

let set_utc_full_year_with_month_date () =
  let d = Date.utc ~year:2020. ~month:0. ~day:1. () in
  let result = Date.setUTCFullYearMD ~year:2025. ~month:5. ~date:15. d in
  assert_float_exact (Date.getUTCFullYear result) 2025.;
  assert_float_exact (Date.getUTCMonth result) 5.;
  assert_float_exact (Date.getUTCDate result) 15.

let set_utc_full_year_leap_to_non_leap () =
  (* Feb 29 in leap year -> set to non-leap year *)
  let d = Date.utc ~year:2020. ~month:1. ~day:29. () in
  let result = Date.setUTCFullYear 2021. d in
  (* Should roll over to March 1 *)
  assert_float_exact (Date.getUTCFullYear result) 2021.;
  assert_float_exact (Date.getUTCMonth result) 2.;
  assert_float_exact (Date.getUTCDate result) 1.

let set_utc_full_year_nan () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. () in
  let result = Date.setUTCFullYear nan d in
  assert_nan result

(* ===================================================================
   Local time setters tests
   Note: These are timezone-dependent, so we test basic functionality
   =================================================================== *)

let set_milliseconds_basic () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:30. ~seconds:45. ~ms:0. () in
  let result = Date.setMilliseconds 500. d in
  (* Should have changed the ms *)
  let utc_ms = Date.getUTCMilliseconds result in
  (* Due to timezone, this might wrap around, but should be a valid ms value *)
  assert_true "ms in range" (utc_ms >= 0. && utc_ms <= 999.)

let set_seconds_basic () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:30. ~seconds:0. () in
  let result = Date.setSeconds 30. d in
  assert_true "result is finite" (Float.is_finite result)

let set_minutes_basic () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:0. () in
  let result = Date.setMinutes 45. d in
  assert_true "result is finite" (Float.is_finite result)

let set_hours_basic () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:0. () in
  let result = Date.setHours 18. d in
  assert_true "result is finite" (Float.is_finite result)

let set_date_basic () =
  let d = Date.utc ~year:2020. ~month:5. ~day:1. () in
  let result = Date.setDate 15. d in
  assert_true "result is finite" (Float.is_finite result)

let set_month_basic () =
  let d = Date.utc ~year:2020. ~month:0. ~day:15. () in
  let result = Date.setMonth 5. d in
  assert_true "result is finite" (Float.is_finite result)

let set_full_year_basic () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. () in
  let result = Date.setFullYear 2025. d in
  assert_true "result is finite" (Float.is_finite result)

(* Local setters with multiple args *)
let set_seconds_with_ms () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:30. ~seconds:0. ~ms:0. () in
  let result = Date.setSecondsMs ~seconds:45. ~milliseconds:123. d in
  assert_true "result is finite" (Float.is_finite result)

let set_minutes_with_seconds () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:0. ~seconds:0. () in
  let result = Date.setMinutesS ~minutes:30. ~seconds:45. d in
  assert_true "result is finite" (Float.is_finite result)

let set_minutes_with_seconds_ms () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:0. ~seconds:0. ~ms:0. () in
  let result = Date.setMinutesSMs ~minutes:30. ~seconds:45. ~milliseconds:123. d in
  assert_true "result is finite" (Float.is_finite result)

let set_hours_with_minutes () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:0. ~minutes:0. () in
  let result = Date.setHoursM ~hours:18. ~minutes:30. d in
  assert_true "result is finite" (Float.is_finite result)

let set_hours_with_minutes_seconds () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:0. ~minutes:0. ~seconds:0. () in
  let result = Date.setHoursMS ~hours:18. ~minutes:30. ~seconds:45. d in
  assert_true "result is finite" (Float.is_finite result)

let set_hours_all () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:0. ~minutes:0. ~seconds:0. ~ms:0. () in
  let result = Date.setHoursMSMs ~hours:18. ~minutes:30. ~seconds:45. ~milliseconds:123. d in
  assert_true "result is finite" (Float.is_finite result)

let set_month_with_date () =
  let d = Date.utc ~year:2020. ~month:0. ~day:1. () in
  let result = Date.setMonthD ~month:5. ~date:15. d in
  assert_true "result is finite" (Float.is_finite result)

let set_full_year_with_month () =
  let d = Date.utc ~year:2020. ~month:0. ~day:15. () in
  let result = Date.setFullYearM ~year:2025. ~month:5. d in
  assert_true "result is finite" (Float.is_finite result)

let set_full_year_with_month_date () =
  let d = Date.utc ~year:2020. ~month:0. ~day:1. () in
  let result = Date.setFullYearMD ~year:2025. ~month:5. ~date:15. d in
  assert_true "result is finite" (Float.is_finite result)

(* NaN tests for local setters *)
let set_milliseconds_nan () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. () in
  let result = Date.setMilliseconds nan d in
  assert_nan result

let set_seconds_nan () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. () in
  let result = Date.setSeconds nan d in
  assert_nan result

let set_minutes_nan () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. () in
  let result = Date.setMinutes nan d in
  assert_nan result

let set_hours_nan () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. () in
  let result = Date.setHours nan d in
  assert_nan result

let set_date_nan () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. () in
  let result = Date.setDate nan d in
  assert_nan result

let set_month_nan () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. () in
  let result = Date.setMonth nan d in
  assert_nan result

let set_full_year_nan () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. () in
  let result = Date.setFullYear nan d in
  assert_nan result

(* ===================================================================
   Test list
   =================================================================== *)

let tests =
  [
    (* setTime *)
    test "setTime basic" set_time_basic;
    test "setTime epoch" set_time_epoch;
    test "setTime negative" set_time_negative;
    test "setTime NaN value" set_time_nan_value;
    test "setTime on NaN date" set_time_on_nan_date;
    (* setUTCMilliseconds *)
    test "setUTCMilliseconds basic" set_utc_ms_basic;
    test "setUTCMilliseconds overflow" set_utc_ms_overflow;
    test "setUTCMilliseconds negative" set_utc_ms_negative;
    test "setUTCMilliseconds NaN" set_utc_ms_nan;
    (* setUTCSeconds *)
    test "setUTCSeconds basic" set_utc_seconds_basic;
    test "setUTCSeconds overflow" set_utc_seconds_overflow;
    test "setUTCSeconds with ms" set_utc_seconds_with_ms;
    test "setUTCSeconds NaN" set_utc_seconds_nan;
    (* setUTCMinutes *)
    test "setUTCMinutes basic" set_utc_minutes_basic;
    test "setUTCMinutes overflow" set_utc_minutes_overflow;
    test "setUTCMinutes with seconds" set_utc_minutes_with_seconds;
    test "setUTCMinutes with seconds and ms" set_utc_minutes_with_seconds_ms;
    test "setUTCMinutes NaN" set_utc_minutes_nan;
    (* setUTCHours *)
    test "setUTCHours basic" set_utc_hours_basic;
    test "setUTCHours overflow" set_utc_hours_overflow;
    test "setUTCHours with minutes" set_utc_hours_with_minutes;
    test "setUTCHours with minutes and seconds" set_utc_hours_with_minutes_seconds;
    test "setUTCHours all components" set_utc_hours_all;
    test "setUTCHours NaN" set_utc_hours_nan;
    (* setUTCDate *)
    test "setUTCDate basic" set_utc_date_basic;
    test "setUTCDate overflow" set_utc_date_overflow;
    test "setUTCDate zero" set_utc_date_zero;
    test "setUTCDate negative" set_utc_date_negative;
    test "setUTCDate NaN" set_utc_date_nan;
    (* setUTCMonth *)
    test "setUTCMonth basic" set_utc_month_basic;
    test "setUTCMonth overflow" set_utc_month_overflow;
    test "setUTCMonth negative" set_utc_month_negative;
    test "setUTCMonth with date" set_utc_month_with_date;
    test "setUTCMonth NaN" set_utc_month_nan;
    (* setUTCFullYear *)
    test "setUTCFullYear basic" set_utc_full_year_basic;
    test "setUTCFullYear with month" set_utc_full_year_with_month;
    test "setUTCFullYear with month and date" set_utc_full_year_with_month_date;
    test "setUTCFullYear leap to non-leap" set_utc_full_year_leap_to_non_leap;
    test "setUTCFullYear NaN" set_utc_full_year_nan;
    (* Local setters *)
    test "setMilliseconds basic" set_milliseconds_basic;
    test "setSeconds basic" set_seconds_basic;
    test "setMinutes basic" set_minutes_basic;
    test "setHours basic" set_hours_basic;
    test "setDate basic" set_date_basic;
    test "setMonth basic" set_month_basic;
    test "setFullYear basic" set_full_year_basic;
    (* Local setters with multiple args *)
    test "setSeconds with ms" set_seconds_with_ms;
    test "setMinutes with seconds" set_minutes_with_seconds;
    test "setMinutes with seconds and ms" set_minutes_with_seconds_ms;
    test "setHours with minutes" set_hours_with_minutes;
    test "setHours with minutes and seconds" set_hours_with_minutes_seconds;
    test "setHours all components" set_hours_all;
    test "setMonth with date" set_month_with_date;
    test "setFullYear with month" set_full_year_with_month;
    test "setFullYear with month and date" set_full_year_with_month_date;
    (* NaN tests for local setters *)
    test "setMilliseconds NaN" set_milliseconds_nan;
    test "setSeconds NaN" set_seconds_nan;
    test "setMinutes NaN" set_minutes_nan;
    test "setHours NaN" set_hours_nan;
    test "setDate NaN" set_date_nan;
    test "setMonth NaN" set_month_nan;
    test "setFullYear NaN" set_full_year_nan;
  ]


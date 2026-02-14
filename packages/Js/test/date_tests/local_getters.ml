(** TC39 Test262: Date local time getter tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/Date/prototype/get*

    Tests for local time getters: getDate, getDay, getFullYear, getHours, getMinutes, getSeconds, getMilliseconds,
    getMonth, getTime, getTimezoneOffset *)

open Helpers
module Date = Js.Date

(* ===================================================================
   Helper: Create dates in UTC and test local getters
   Note: These tests use UTC dates to avoid timezone dependency
   =================================================================== *)

(* ===================================================================
   getTime tests
   =================================================================== *)

let get_time_basic () =
  let d = Date.utc ~year:2017. ~month:9. ~date:22. ~hours:18. ~minutes:10. ~seconds:11. () +. 91. in
  assert_float_exact (Date.getTime d) 1508695811091.

let get_time_epoch () = assert_float_exact (Date.getTime 0.) 0.

let get_time_negative () =
  (* 1969-12-31T23:59:59.000Z = -1000 ms *)
  assert_float_exact (Date.getTime (-1000.)) (-1000.)

let get_time_nan () = assert_nan (Date.getTime nan)

(* ===================================================================
   valueOf tests - should be identical to getTime
   =================================================================== *)

let valueof_basic () =
  let d = Date.utc ~year:2017. ~month:9. ~date:22. ~hours:18. ~minutes:10. ~seconds:11. () +. 91. in
  assert_float_exact (Date.valueOf d) 1508695811091.

let valueof_epoch () = assert_float_exact (Date.valueOf 0.) 0.
let valueof_nan () = assert_nan (Date.valueOf nan)

let valueof_equals_gettime () =
  let d = Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:30. () in
  assert_float_exact (Date.valueOf d) (Date.getTime d)

(* ===================================================================
   getUTCFullYear tests (comprehensive - already partially covered)
   =================================================================== *)

let get_utc_full_year_2017 () =
  let d = Date.utc ~year:2017. ~month:9. ~date:22. () in
  assert_float_exact (Date.getUTCFullYear d) 2017.

let get_utc_full_year_1970 () = assert_float_exact (Date.getUTCFullYear 0.) 1970.

let get_utc_full_year_1969 () =
  let d = Date.utc ~year:1969. ~month:11. ~date:31. ~hours:23. ~minutes:59. ~seconds:59. () in
  assert_float_exact (Date.getUTCFullYear d) 1969.

let get_utc_full_year_nan () = assert_nan (Date.getUTCFullYear nan)

let get_utc_full_year_y2k () =
  let d = Date.utc ~year:2000. ~month:0. ~date:1. () in
  assert_float_exact (Date.getUTCFullYear d) 2000.

let get_utc_full_year_leap () =
  let d = Date.utc ~year:2024. ~month:1. ~date:29. () in
  assert_float_exact (Date.getUTCFullYear d) 2024.

(* ===================================================================
   getUTCMonth tests
   =================================================================== *)

let get_utc_month_january () =
  let d = Date.utc ~year:2020. ~month:0. ~date:15. () in
  assert_float_exact (Date.getUTCMonth d) 0.

let get_utc_month_december () =
  let d = Date.utc ~year:2020. ~month:11. ~date:25. () in
  assert_float_exact (Date.getUTCMonth d) 11.

let get_utc_month_nan () = assert_nan (Date.getUTCMonth nan)
let get_utc_month_epoch () = assert_float_exact (Date.getUTCMonth 0.) 0.

(* ===================================================================
   getUTCDate tests
   =================================================================== *)

let get_utc_date_first () =
  let d = Date.utc ~year:2020. ~month:5. ~date:1. () in
  assert_float_exact (Date.getUTCDate d) 1.

let get_utc_date_31st () =
  let d = Date.utc ~year:2020. ~month:0. ~date:31. () in
  assert_float_exact (Date.getUTCDate d) 31.

let get_utc_date_nan () = assert_nan (Date.getUTCDate nan)
let get_utc_date_epoch () = assert_float_exact (Date.getUTCDate 0.) 1.

(* ===================================================================
   getUTCDay tests (day of week)
   =================================================================== *)

let get_utc_day_thursday_epoch () =
  (* Jan 1, 1970 was a Thursday (day 4) *)
  assert_float_exact (Date.getUTCDay 0.) 4.

let get_utc_day_sunday () =
  (* Find a known Sunday - Jan 3, 2021 was Sunday *)
  let d = Date.utc ~year:2021. ~month:0. ~date:3. () in
  assert_float_exact (Date.getUTCDay d) 0.

let get_utc_day_saturday () =
  (* Jan 2, 2021 was Saturday *)
  let d = Date.utc ~year:2021. ~month:0. ~date:2. () in
  assert_float_exact (Date.getUTCDay d) 6.

let get_utc_day_nan () = assert_nan (Date.getUTCDay nan)

(* ===================================================================
   getUTCHours tests
   =================================================================== *)

let get_utc_hours_zero () =
  let d = Date.utc ~year:2020. ~month:5. ~date:15. ~hours:0. () in
  assert_float_exact (Date.getUTCHours d) 0.

let get_utc_hours_23 () =
  let d = Date.utc ~year:2020. ~month:5. ~date:15. ~hours:23. () in
  assert_float_exact (Date.getUTCHours d) 23.

let get_utc_hours_nan () = assert_nan (Date.getUTCHours nan)
let get_utc_hours_epoch () = assert_float_exact (Date.getUTCHours 0.) 0.

(* ===================================================================
   getUTCMinutes tests
   =================================================================== *)

let get_utc_minutes_zero () =
  let d = Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:0. () in
  assert_float_exact (Date.getUTCMinutes d) 0.

let get_utc_minutes_59 () =
  let d = Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:59. () in
  assert_float_exact (Date.getUTCMinutes d) 59.

let get_utc_minutes_nan () = assert_nan (Date.getUTCMinutes nan)

(* ===================================================================
   getUTCSeconds tests
   =================================================================== *)

let get_utc_seconds_zero () =
  let d = Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:30. ~seconds:0. () in
  assert_float_exact (Date.getUTCSeconds d) 0.

let get_utc_seconds_59 () =
  let d = Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:30. ~seconds:59. () in
  assert_float_exact (Date.getUTCSeconds d) 59.

let get_utc_seconds_nan () = assert_nan (Date.getUTCSeconds nan)

(* ===================================================================
   getUTCMilliseconds tests
   =================================================================== *)

let get_utc_ms_zero () =
  let d = Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:30. ~seconds:45. () in
  assert_float_exact (Date.getUTCMilliseconds d) 0.

let get_utc_ms_999 () =
  let d = Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:30. ~seconds:45. () +. 999. in
  assert_float_exact (Date.getUTCMilliseconds d) 999.

let get_utc_ms_nan () = assert_nan (Date.getUTCMilliseconds nan)

let get_utc_ms_middle () =
  let d = Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:30. ~seconds:45. () +. 456. in
  assert_float_exact (Date.getUTCMilliseconds d) 456.

(* ===================================================================
   getTimezoneOffset tests
   Note: This is timezone-dependent, so we just verify it returns a number
   =================================================================== *)

let get_timezone_offset_returns_number () =
  let d = Date.utc ~year:2020. ~month:5. ~date:15. () in
  let offset = Date.getTimezoneOffset d in
  (* Offset should be a finite number *)
  assert_true "timezone offset should be finite" (Float.is_finite offset)

let get_timezone_offset_nan () = assert_nan (Date.getTimezoneOffset nan)

let get_timezone_offset_range () =
  let d = Date.utc ~year:2020. ~month:5. ~date:15. () in
  let offset = Date.getTimezoneOffset d in
  (* Timezone offsets range from -720 (UTC+12) to +840 (UTC-14) *)
  assert_true "offset in valid range" (offset >= -720. && offset <= 840.)

(* ===================================================================
   Local time getter tests
   Note: These depend on the system timezone, so we test consistency
   =================================================================== *)

let local_getters_consistent () =
  (* Create a date and verify local getters return consistent values *)
  let d = Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:30. ~seconds:45. () +. 123. in
  let year = Date.getFullYear d in
  let month = Date.getMonth d in
  let date = Date.getDate d in
  let hours = Date.getHours d in
  let minutes = Date.getMinutes d in
  let seconds = Date.getSeconds d in
  let ms = Date.getMilliseconds d in
  (* All should be finite *)
  assert_true "year finite" (Float.is_finite year);
  assert_true "month finite" (Float.is_finite month);
  assert_true "date finite" (Float.is_finite date);
  assert_true "hours finite" (Float.is_finite hours);
  assert_true "minutes finite" (Float.is_finite minutes);
  assert_true "seconds finite" (Float.is_finite seconds);
  assert_true "ms finite" (Float.is_finite ms);
  (* Check ranges *)
  assert_true "month 0-11" (month >= 0. && month <= 11.);
  assert_true "date 1-31" (date >= 1. && date <= 31.);
  assert_true "hours 0-23" (hours >= 0. && hours <= 23.);
  assert_true "minutes 0-59" (minutes >= 0. && minutes <= 59.);
  assert_true "seconds 0-59" (seconds >= 0. && seconds <= 59.);
  assert_true "ms 0-999" (ms >= 0. && ms <= 999.)

let local_getters_nan () =
  (* All local getters should return NaN for invalid dates *)
  assert_nan (Date.getFullYear nan);
  assert_nan (Date.getMonth nan);
  assert_nan (Date.getDate nan);
  assert_nan (Date.getDay nan);
  assert_nan (Date.getHours nan);
  assert_nan (Date.getMinutes nan);
  assert_nan (Date.getSeconds nan);
  assert_nan (Date.getMilliseconds nan)

let get_day_range () =
  (* getDay should return 0-6 *)
  let d = Date.utc ~year:2020. ~month:5. ~date:15. () in
  let day = Date.getDay d in
  assert_true "day 0-6" (day >= 0. && day <= 6.)

(* ===================================================================
   Edge case tests
   =================================================================== *)

let getters_large_positive_date () =
  (* Test with a large date - year 275760 (near max) *)
  let d = Date.utc ~year:275760. ~month:8. ~date:13. () in
  assert_float_exact (Date.getUTCFullYear d) 275760.

let getters_large_negative_date () =
  (* Test with a date before epoch *)
  let d = Date.utc ~year:1900. ~month:0. ~date:1. () in
  assert_float_exact (Date.getUTCFullYear d) 1900.

let getters_boundary_milliseconds () =
  (* Test at millisecond boundary *)
  let d = Date.utc ~year:2020. ~month:0. ~date:1. ~hours:0. ~minutes:0. ~seconds:0. () +. 999. in
  assert_float_exact (Date.getUTCMilliseconds d) 999.

(* ===================================================================
   Test list
   =================================================================== *)

let tests =
  [
    (* getTime *)
    test "getTime basic" get_time_basic;
    test "getTime epoch" get_time_epoch;
    test "getTime negative" get_time_negative;
    test "getTime NaN" get_time_nan;
    (* valueOf *)
    test "valueOf basic" valueof_basic;
    test "valueOf epoch" valueof_epoch;
    test "valueOf NaN" valueof_nan;
    test "valueOf equals getTime" valueof_equals_gettime;
    (* getUTCFullYear *)
    test "getUTCFullYear 2017" get_utc_full_year_2017;
    test "getUTCFullYear 1970 (epoch)" get_utc_full_year_1970;
    test "getUTCFullYear 1969" get_utc_full_year_1969;
    test "getUTCFullYear NaN" get_utc_full_year_nan;
    test "getUTCFullYear Y2K" get_utc_full_year_y2k;
    test "getUTCFullYear leap year" get_utc_full_year_leap;
    (* getUTCMonth *)
    test "getUTCMonth January (0)" get_utc_month_january;
    test "getUTCMonth December (11)" get_utc_month_december;
    test "getUTCMonth NaN" get_utc_month_nan;
    test "getUTCMonth epoch" get_utc_month_epoch;
    (* getUTCDate *)
    test "getUTCDate first" get_utc_date_first;
    test "getUTCDate 31st" get_utc_date_31st;
    test "getUTCDate NaN" get_utc_date_nan;
    test "getUTCDate epoch" get_utc_date_epoch;
    (* getUTCDay *)
    test "getUTCDay Thursday (epoch)" get_utc_day_thursday_epoch;
    test "getUTCDay Sunday" get_utc_day_sunday;
    test "getUTCDay Saturday" get_utc_day_saturday;
    test "getUTCDay NaN" get_utc_day_nan;
    (* getUTCHours *)
    test "getUTCHours zero" get_utc_hours_zero;
    test "getUTCHours 23" get_utc_hours_23;
    test "getUTCHours NaN" get_utc_hours_nan;
    test "getUTCHours epoch" get_utc_hours_epoch;
    (* getUTCMinutes *)
    test "getUTCMinutes zero" get_utc_minutes_zero;
    test "getUTCMinutes 59" get_utc_minutes_59;
    test "getUTCMinutes NaN" get_utc_minutes_nan;
    (* getUTCSeconds *)
    test "getUTCSeconds zero" get_utc_seconds_zero;
    test "getUTCSeconds 59" get_utc_seconds_59;
    test "getUTCSeconds NaN" get_utc_seconds_nan;
    (* getUTCMilliseconds *)
    test "getUTCMilliseconds zero" get_utc_ms_zero;
    test "getUTCMilliseconds 999" get_utc_ms_999;
    test "getUTCMilliseconds NaN" get_utc_ms_nan;
    test "getUTCMilliseconds middle" get_utc_ms_middle;
    (* getTimezoneOffset *)
    test "getTimezoneOffset returns number" get_timezone_offset_returns_number;
    test "getTimezoneOffset NaN" get_timezone_offset_nan;
    test "getTimezoneOffset in valid range" get_timezone_offset_range;
    (* Local getters *)
    test "local getters consistent" local_getters_consistent;
    test "local getters NaN" local_getters_nan;
    test "getDay range 0-6" get_day_range;
    (* Edge cases *)
    test "getters large positive date" getters_large_positive_date;
    test "getters large negative date" getters_large_negative_date;
    test "getters boundary milliseconds" getters_boundary_milliseconds;
  ]

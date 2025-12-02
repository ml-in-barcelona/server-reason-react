(** TC39 Test262: Date getter tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/Date/prototype

    Tests for Date.prototype getter methods:
    - getFullYear, getUTCFullYear
    - getMonth, getUTCMonth
    - getDate, getUTCDate
    - getDay, getUTCDay
    - getHours, getUTCHours
    - getMinutes, getUTCMinutes
    - getSeconds, getUTCSeconds
    - getMilliseconds, getUTCMilliseconds
    - getTime
    - getTimezoneOffset *)

open Helpers

(* A known timestamp for testing: 2017-09-22T16:37:38.091Z (Friday)
   epoch ms: 1506098258091 *)
let known_timestamp = 1506098258091.

(* ===================================================================
   getTime / valueOf
   =================================================================== *)

let get_time_returns_epoch_ms () =
  let d = Date.of_epoch_ms known_timestamp in
  assert_float_exact (Date.getTime d) known_timestamp

let get_time_nan_for_invalid () =
  let d = Date.of_epoch_ms nan in
  assert_nan (Date.getTime d)

(* ===================================================================
   UTC Getters - these don't depend on timezone
   =================================================================== *)

let get_utc_full_year () =
  let d = Date.of_epoch_ms known_timestamp in
  assert_float_exact (Date.getUTCFullYear d) 2017.

let get_utc_month () =
  (* September = month 8 (0-indexed) *)
  let d = Date.of_epoch_ms known_timestamp in
  assert_float_exact (Date.getUTCMonth d) 8.

let get_utc_date () =
  let d = Date.of_epoch_ms known_timestamp in
  assert_float_exact (Date.getUTCDate d) 22.

let get_utc_day () =
  (* Friday = day 5 (0 = Sunday) *)
  let d = Date.of_epoch_ms known_timestamp in
  assert_float_exact (Date.getUTCDay d) 5.

let get_utc_hours () =
  let d = Date.of_epoch_ms known_timestamp in
  assert_float_exact (Date.getUTCHours d) 16.

let get_utc_minutes () =
  let d = Date.of_epoch_ms known_timestamp in
  assert_float_exact (Date.getUTCMinutes d) 37.

let get_utc_seconds () =
  let d = Date.of_epoch_ms known_timestamp in
  assert_float_exact (Date.getUTCSeconds d) 38.

let get_utc_milliseconds () =
  let d = Date.of_epoch_ms known_timestamp in
  assert_float_exact (Date.getUTCMilliseconds d) 91.

(* ===================================================================
   UTC Getters - boundary cases
   =================================================================== *)

let get_utc_epoch () =
  (* Jan 1, 1970 00:00:00.000 UTC *)
  let d = Date.of_epoch_ms 0. in
  assert_float_exact (Date.getUTCFullYear d) 1970.;
  assert_float_exact (Date.getUTCMonth d) 0.;
  assert_float_exact (Date.getUTCDate d) 1.;
  assert_float_exact (Date.getUTCDay d) 4.;
  (* Thursday *)
  assert_float_exact (Date.getUTCHours d) 0.;
  assert_float_exact (Date.getUTCMinutes d) 0.;
  assert_float_exact (Date.getUTCSeconds d) 0.;
  assert_float_exact (Date.getUTCMilliseconds d) 0.

let get_utc_before_epoch () =
  (* Dec 31, 1969 23:59:59.999 UTC = -1ms *)
  let d = Date.of_epoch_ms (-1.) in
  assert_float_exact (Date.getUTCFullYear d) 1969.;
  assert_float_exact (Date.getUTCMonth d) 11.;
  (* December *)
  assert_float_exact (Date.getUTCDate d) 31.;
  assert_float_exact (Date.getUTCHours d) 23.;
  assert_float_exact (Date.getUTCMinutes d) 59.;
  assert_float_exact (Date.getUTCSeconds d) 59.;
  assert_float_exact (Date.getUTCMilliseconds d) 999.

let get_utc_y2k () =
  (* Jan 1, 2000 00:00:00.000 UTC *)
  let d = Date.of_epoch_ms 946684800000. in
  assert_float_exact (Date.getUTCFullYear d) 2000.;
  assert_float_exact (Date.getUTCMonth d) 0.;
  assert_float_exact (Date.getUTCDate d) 1.;
  assert_float_exact (Date.getUTCDay d) 6. (* Saturday *)

let get_utc_leap_day () =
  (* Feb 29, 2020 12:00:00.000 UTC *)
  let d = Date.of_epoch_ms 1582977600000. in
  assert_float_exact (Date.getUTCFullYear d) 2020.;
  assert_float_exact (Date.getUTCMonth d) 1.;
  (* February *)
  assert_float_exact (Date.getUTCDate d) 29.

(* ===================================================================
   NaN handling - all getters return NaN for invalid date
   =================================================================== *)

let get_utc_nan_full_year () =
  let d = Date.of_epoch_ms nan in
  assert_nan (Date.getUTCFullYear d)

let get_utc_nan_month () =
  let d = Date.of_epoch_ms nan in
  assert_nan (Date.getUTCMonth d)

let get_utc_nan_date () =
  let d = Date.of_epoch_ms nan in
  assert_nan (Date.getUTCDate d)

let get_utc_nan_day () =
  let d = Date.of_epoch_ms nan in
  assert_nan (Date.getUTCDay d)

let get_utc_nan_hours () =
  let d = Date.of_epoch_ms nan in
  assert_nan (Date.getUTCHours d)

let get_utc_nan_minutes () =
  let d = Date.of_epoch_ms nan in
  assert_nan (Date.getUTCMinutes d)

let get_utc_nan_seconds () =
  let d = Date.of_epoch_ms nan in
  assert_nan (Date.getUTCSeconds d)

let get_utc_nan_milliseconds () =
  let d = Date.of_epoch_ms nan in
  assert_nan (Date.getUTCMilliseconds d)

(* ===================================================================
   End of year / start of year transitions
   =================================================================== *)

let get_utc_new_year_transition () =
  (* Dec 31, 2019 23:59:59.999 UTC *)
  let d1 = Date.of_epoch_ms 1577836799999. in
  assert_float_exact (Date.getUTCFullYear d1) 2019.;
  assert_float_exact (Date.getUTCMonth d1) 11.;
  assert_float_exact (Date.getUTCDate d1) 31.;
  (* Jan 1, 2020 00:00:00.000 UTC *)
  let d2 = Date.of_epoch_ms 1577836800000. in
  assert_float_exact (Date.getUTCFullYear d2) 2020.;
  assert_float_exact (Date.getUTCMonth d2) 0.;
  assert_float_exact (Date.getUTCDate d2) 1.

(* ===================================================================
   Month boundaries
   =================================================================== *)

let get_utc_month_lengths () =
  (* Jan has 31 days, Feb 28/29, etc *)
  (* Last day of January 2020 *)
  let jan31 = Date.of_epoch_ms (Date.utc ~year:2020. ~month:0. ~day:31. ()) in
  assert_float_exact (Date.getUTCMonth jan31) 0.;
  assert_float_exact (Date.getUTCDate jan31) 31.;
  (* Feb 1 *)
  let feb1 = Date.of_epoch_ms (Date.utc ~year:2020. ~month:1. ~day:1. ()) in
  assert_float_exact (Date.getUTCMonth feb1) 1.;
  assert_float_exact (Date.getUTCDate feb1) 1.

(* ===================================================================
   Test list
   =================================================================== *)

let tests =
  [
    (* getTime *)
    test "getTime returns epoch ms" get_time_returns_epoch_ms;
    test "getTime NaN for invalid date" get_time_nan_for_invalid;
    (* UTC getters for known timestamp *)
    test "getUTCFullYear" get_utc_full_year;
    test "getUTCMonth" get_utc_month;
    test "getUTCDate" get_utc_date;
    test "getUTCDay" get_utc_day;
    test "getUTCHours" get_utc_hours;
    test "getUTCMinutes" get_utc_minutes;
    test "getUTCSeconds" get_utc_seconds;
    test "getUTCMilliseconds" get_utc_milliseconds;
    (* UTC getters - boundary cases *)
    test "UTC getters at epoch" get_utc_epoch;
    test "UTC getters before epoch" get_utc_before_epoch;
    test "UTC getters at Y2K" get_utc_y2k;
    test "UTC getters on leap day" get_utc_leap_day;
    (* NaN handling *)
    test "getUTCFullYear NaN" get_utc_nan_full_year;
    test "getUTCMonth NaN" get_utc_nan_month;
    test "getUTCDate NaN" get_utc_nan_date;
    test "getUTCDay NaN" get_utc_nan_day;
    test "getUTCHours NaN" get_utc_nan_hours;
    test "getUTCMinutes NaN" get_utc_nan_minutes;
    test "getUTCSeconds NaN" get_utc_nan_seconds;
    test "getUTCMilliseconds NaN" get_utc_nan_milliseconds;
    (* Transitions *)
    test "new year transition" get_utc_new_year_transition;
    test "month lengths" get_utc_month_lengths;
  ]

open Helpers

let known_timestamp = 1506098258091.

let get_time_returns_epoch_ms () =
  let d = Date.fromFloat known_timestamp in
  assert_float_exact (Date.getTime d) known_timestamp

let get_time_nan_for_invalid () =
  let d = Date.fromFloat nan in
  assert_nan (Date.getTime d)

let get_utc_full_year () =
  let d = Date.fromFloat known_timestamp in
  assert_float_exact (Date.getUTCFullYear d) 2017.

let get_utc_month () =
  let d = Date.fromFloat known_timestamp in
  assert_float_exact (Date.getUTCMonth d) 8.

let get_utc_date () =
  let d = Date.fromFloat known_timestamp in
  assert_float_exact (Date.getUTCDate d) 22.

let get_utc_day () =
  let d = Date.fromFloat known_timestamp in
  assert_float_exact (Date.getUTCDay d) 5.

let get_utc_hours () =
  let d = Date.fromFloat known_timestamp in
  assert_float_exact (Date.getUTCHours d) 16.

let get_utc_minutes () =
  let d = Date.fromFloat known_timestamp in
  assert_float_exact (Date.getUTCMinutes d) 37.

let get_utc_seconds () =
  let d = Date.fromFloat known_timestamp in
  assert_float_exact (Date.getUTCSeconds d) 38.

let get_utc_milliseconds () =
  let d = Date.fromFloat known_timestamp in
  assert_float_exact (Date.getUTCMilliseconds d) 91.

let get_utc_epoch () =
  let d = Date.fromFloat 0. in
  assert_float_exact (Date.getUTCFullYear d) 1970.;
  assert_float_exact (Date.getUTCMonth d) 0.;
  assert_float_exact (Date.getUTCDate d) 1.;
  assert_float_exact (Date.getUTCDay d) 4.;
  assert_float_exact (Date.getUTCHours d) 0.;
  assert_float_exact (Date.getUTCMinutes d) 0.;
  assert_float_exact (Date.getUTCSeconds d) 0.;
  assert_float_exact (Date.getUTCMilliseconds d) 0.

let get_utc_before_epoch () =
  let d = Date.fromFloat (-1.) in
  assert_float_exact (Date.getUTCFullYear d) 1969.;
  assert_float_exact (Date.getUTCMonth d) 11.;
  assert_float_exact (Date.getUTCDate d) 31.;
  assert_float_exact (Date.getUTCHours d) 23.;
  assert_float_exact (Date.getUTCMinutes d) 59.;
  assert_float_exact (Date.getUTCSeconds d) 59.;
  assert_float_exact (Date.getUTCMilliseconds d) 999.

let get_utc_y2k () =
  let d = Date.fromFloat 946684800000. in
  assert_float_exact (Date.getUTCFullYear d) 2000.;
  assert_float_exact (Date.getUTCMonth d) 0.;
  assert_float_exact (Date.getUTCDate d) 1.;
  assert_float_exact (Date.getUTCDay d) 6.

let get_utc_leap_day () =
  let d = Date.fromFloat 1582977600000. in
  assert_float_exact (Date.getUTCFullYear d) 2020.;
  assert_float_exact (Date.getUTCMonth d) 1.;
  assert_float_exact (Date.getUTCDate d) 29.

let get_utc_nan_full_year () =
  let d = Date.fromFloat nan in
  assert_nan (Date.getUTCFullYear d)

let get_utc_nan_month () =
  let d = Date.fromFloat nan in
  assert_nan (Date.getUTCMonth d)

let get_utc_nan_date () =
  let d = Date.fromFloat nan in
  assert_nan (Date.getUTCDate d)

let get_utc_nan_day () =
  let d = Date.fromFloat nan in
  assert_nan (Date.getUTCDay d)

let get_utc_nan_hours () =
  let d = Date.fromFloat nan in
  assert_nan (Date.getUTCHours d)

let get_utc_nan_minutes () =
  let d = Date.fromFloat nan in
  assert_nan (Date.getUTCMinutes d)

let get_utc_nan_seconds () =
  let d = Date.fromFloat nan in
  assert_nan (Date.getUTCSeconds d)

let get_utc_nan_milliseconds () =
  let d = Date.fromFloat nan in
  assert_nan (Date.getUTCMilliseconds d)

let get_utc_new_year_transition () =
  let d1 = Date.fromFloat 1577836799999. in
  assert_float_exact (Date.getUTCFullYear d1) 2019.;
  assert_float_exact (Date.getUTCMonth d1) 11.;
  assert_float_exact (Date.getUTCDate d1) 31.;
  let d2 = Date.fromFloat 1577836800000. in
  assert_float_exact (Date.getUTCFullYear d2) 2020.;
  assert_float_exact (Date.getUTCMonth d2) 0.;
  assert_float_exact (Date.getUTCDate d2) 1.

let get_utc_month_lengths () =
  let jan31 = Date.fromFloat (Date.utc ~year:2020. ~month:0. ~date:31. ()) in
  assert_float_exact (Date.getUTCMonth jan31) 0.;
  assert_float_exact (Date.getUTCDate jan31) 31.;
  let feb1 = Date.fromFloat (Date.utc ~year:2020. ~month:1. ~date:1. ()) in
  assert_float_exact (Date.getUTCMonth feb1) 1.;
  assert_float_exact (Date.getUTCDate feb1) 1.

let tests =
  [
    test "getTime returns epoch ms" get_time_returns_epoch_ms;
    test "getTime NaN for invalid date" get_time_nan_for_invalid;
    test "getUTCFullYear" get_utc_full_year;
    test "getUTCMonth" get_utc_month;
    test "getUTCDate" get_utc_date;
    test "getUTCDay" get_utc_day;
    test "getUTCHours" get_utc_hours;
    test "getUTCMinutes" get_utc_minutes;
    test "getUTCSeconds" get_utc_seconds;
    test "getUTCMilliseconds" get_utc_milliseconds;
    test "UTC getters at epoch" get_utc_epoch;
    test "UTC getters before epoch" get_utc_before_epoch;
    test "UTC getters at Y2K" get_utc_y2k;
    test "UTC getters on leap day" get_utc_leap_day;
    test "getUTCFullYear NaN" get_utc_nan_full_year;
    test "getUTCMonth NaN" get_utc_nan_month;
    test "getUTCDate NaN" get_utc_nan_date;
    test "getUTCDay NaN" get_utc_nan_day;
    test "getUTCHours NaN" get_utc_nan_hours;
    test "getUTCMinutes NaN" get_utc_nan_minutes;
    test "getUTCSeconds NaN" get_utc_nan_seconds;
    test "getUTCMilliseconds NaN" get_utc_nan_milliseconds;
    test "new year transition" get_utc_new_year_transition;
    test "month lengths" get_utc_month_lengths;
  ]

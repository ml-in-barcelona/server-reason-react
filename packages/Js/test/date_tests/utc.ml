open Helpers

let utc_year_only () = assert_float_exact (Date.utc ~year:2017. ~month:0. ()) 1483228800000.
let utc_year_month () = assert_float_exact (Date.utc ~year:2017. ~month:9. ()) 1506816000000.
let utc_year_month_day () = assert_float_exact (Date.utc ~year:2017. ~month:9. ~date:22. ()) 1508630400000.
let utc_with_hours () = assert_float_exact (Date.utc ~year:2017. ~month:9. ~date:22. ~hours:18. ()) 1508695200000.

let utc_with_minutes () =
  assert_float_exact (Date.utc ~year:2017. ~month:9. ~date:22. ~hours:18. ~minutes:10. ()) 1508695800000.

let utc_with_seconds () =
  assert_float_exact (Date.utc ~year:2017. ~month:9. ~date:22. ~hours:18. ~minutes:10. ~seconds:11. ()) 1508695811000.

let utc_with_ms () =
  assert_float_exact
    (Date.utc ~year:2017. ~month:9. ~date:22. ~hours:18. ~minutes:10. ~seconds:11. () +. 91.)
    1508695811091.

let utc_nan_year () = assert_nan (Date.utc ~year:nan ~month:0. ())
let utc_nan_month () = assert_nan (Date.utc ~year:2017. ~month:nan ())
let utc_nan_day () = assert_nan (Date.utc ~year:2017. ~month:9. ~date:nan ())
let utc_nan_hours () = assert_nan (Date.utc ~year:2017. ~month:9. ~date:22. ~hours:nan ())
let utc_nan_minutes () = assert_nan (Date.utc ~year:2017. ~month:9. ~date:22. ~hours:18. ~minutes:nan ())
let utc_nan_seconds () = assert_nan (Date.utc ~year:2017. ~month:9. ~date:22. ~hours:18. ~minutes:10. ~seconds:nan ())
let utc_epoch () = assert_float_exact (Date.utc ~year:1970. ~month:0. ~date:1. ()) 0.

let utc_before_epoch () =
  assert_float_exact (Date.utc ~year:1969. ~month:11. ~date:31. ~hours:23. ~minutes:59. ~seconds:59. ()) (-1000.)

let utc_y2k () = assert_float_exact (Date.utc ~year:2000. ~month:0. ~date:1. ()) 946684800000.

let utc_year_0 () =
  let result = Date.utc ~year:0. ~month:0. ~date:1. () in
  assert_float_exact result (-2208988800000.)

let utc_year_99 () =
  let result = Date.utc ~year:99. ~month:0. ~date:1. () in
  assert_float_exact result 915148800000.

let utc_year_100 () =
  let result = Date.utc ~year:100. ~month:0. ~date:1. () in
  assert_not_nan result

let utc_month_overflow () =
  let m12 = Date.utc ~year:2017. ~month:12. ~date:1. () in
  let jan_next = Date.utc ~year:2018. ~month:0. ~date:1. () in
  assert_float_exact m12 jan_next

let utc_month_underflow () =
  let m_neg1 = Date.utc ~year:2017. ~month:(-1.) ~date:1. () in
  let dec_prev = Date.utc ~year:2016. ~month:11. ~date:1. () in
  assert_float_exact m_neg1 dec_prev

let utc_day_overflow () =
  let d32 = Date.utc ~year:2017. ~month:0. ~date:32. () in
  let feb1 = Date.utc ~year:2017. ~month:1. ~date:1. () in
  assert_float_exact d32 feb1

let utc_day_zero () =
  let d0 = Date.utc ~year:2017. ~month:1. ~date:0. () in
  let jan31 = Date.utc ~year:2017. ~month:0. ~date:31. () in
  assert_float_exact d0 jan31

let utc_day_negative () =
  let d_neg1 = Date.utc ~year:2017. ~month:1. ~date:(-1.) () in
  let jan30 = Date.utc ~year:2017. ~month:0. ~date:30. () in
  assert_float_exact d_neg1 jan30

let utc_leap_year_feb_29 () =
  let result = Date.utc ~year:2020. ~month:1. ~date:29. () in
  assert_not_nan result

let utc_non_leap_year_feb_29 () =
  let feb29_2019 = Date.utc ~year:2019. ~month:1. ~date:29. () in
  let mar1_2019 = Date.utc ~year:2019. ~month:2. ~date:1. () in
  assert_float_exact feb29_2019 mar1_2019

let utc_leap_year_2000 () =
  let result = Date.utc ~year:2000. ~month:1. ~date:29. () in
  assert_not_nan result

let utc_non_leap_year_1900 () =
  let feb29_1900 = Date.utc ~year:1900. ~month:1. ~date:29. () in
  let mar1_1900 = Date.utc ~year:1900. ~month:2. ~date:1. () in
  assert_float_exact feb29_1900 mar1_1900

let utc_large_day_offset () =
  let result = Date.utc ~year:2017. ~month:9. ~date:(22. -. 1e10) ~hours:(18. +. 24e10) () in
  assert_float_exact result 1508695200000.

let utc_large_minute_offset () =
  let result = Date.utc ~year:2017. ~month:9. ~date:22. ~hours:(18. -. 1e10) ~minutes:(10. +. 60e10) () in
  assert_float_exact result 1508695800000.

let utc_large_second_offset () =
  let result = Date.utc ~year:2017. ~month:9. ~date:22. ~hours:18. ~minutes:(10. -. 1e10) ~seconds:(11. +. 60e10) () in
  assert_float_exact result 1508695811000.

let tests =
  [
    test "UTC year only" utc_year_only;
    test "UTC year and month" utc_year_month;
    test "UTC year, month, day" utc_year_month_day;
    test "UTC with hours" utc_with_hours;
    test "UTC with minutes" utc_with_minutes;
    test "UTC with seconds" utc_with_seconds;
    test "UTC with milliseconds" utc_with_ms;
    test "UTC NaN year" utc_nan_year;
    test "UTC NaN month" utc_nan_month;
    test "UTC NaN day" utc_nan_day;
    test "UTC NaN hours" utc_nan_hours;
    test "UTC NaN minutes" utc_nan_minutes;
    test "UTC NaN seconds" utc_nan_seconds;
    test "UTC Unix epoch" utc_epoch;
    test "UTC before epoch" utc_before_epoch;
    test "UTC Y2K" utc_y2k;
    test "UTC year 0 -> 1900" utc_year_0;
    test "UTC year 99 -> 1999" utc_year_99;
    test "UTC year 100 stays 100" utc_year_100;
    test "UTC month 12 = January next year" utc_month_overflow;
    test "UTC month -1 = December prev year" utc_month_underflow;
    test "UTC day 32 Jan = Feb 1" utc_day_overflow;
    test "UTC day 0 = last day prev month" utc_day_zero;
    test "UTC day -1 = second-to-last prev" utc_day_negative;
    test "UTC leap year Feb 29 valid" utc_leap_year_feb_29;
    test "UTC non-leap Feb 29 = Mar 1" utc_non_leap_year_feb_29;
    test "UTC 2000 is leap year" utc_leap_year_2000;
    test "UTC 1900 is NOT leap year" utc_non_leap_year_1900;
    test "UTC large day offset" utc_large_day_offset;
    test "UTC large minute offset" utc_large_minute_offset;
    test "UTC large second offset" utc_large_second_offset;
  ]

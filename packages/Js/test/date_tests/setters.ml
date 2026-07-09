(** TC39 Test262: Date setter tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/Date/prototype/set*

    Tests for setters: setDate, setFullYear, setHours, setMinutes, setSeconds, setMilliseconds, setMonth, setTime and
    their UTC variants.

    Setters MUTATE the receiver (like JS Date objects) and return the new timestamp as float. *)

open Helpers
module Date = Js.Date

let date_of_utc ms = Date.fromFloat ms

(* ===================================================================
   setTime tests
   =================================================================== *)

let set_time_basic () =
  let d = date_of_utc 0. in
  let ret = Date.setTime ~time:1508695811091. d in
  assert_float_exact ret 1508695811091.;
  assert_float_exact (Date.valueOf d) 1508695811091.

let set_time_epoch () =
  let d = date_of_utc 1000. in
  let ret = Date.setTime ~time:0. d in
  assert_float_exact ret 0.;
  assert_float_exact (Date.valueOf d) 0.

let set_time_negative () =
  let d = date_of_utc 0. in
  let ret = Date.setTime ~time:(-1000.) d in
  assert_float_exact ret (-1000.);
  assert_float_exact (Date.valueOf d) (-1000.)

let set_time_nan_value () =
  let d = date_of_utc 0. in
  let ret = Date.setTime ~time:nan d in
  assert_nan ret;
  assert_nan (Date.valueOf d)

let set_time_on_nan_date () =
  let d = date_of_utc nan in
  let ret = Date.setTime ~time:1000. d in
  assert_float_exact ret 1000.;
  assert_float_exact (Date.valueOf d) 1000.

(* ===================================================================
   Mutation semantics: the receiver is updated in place and the return
   value equals the receiver's new time value
   =================================================================== *)

let setter_mutates_receiver () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:30. ~seconds:45. ()) in
  let ret = Date.setUTCHours ~hours:5. d in
  assert_float_exact (Date.getUTCHours d) 5.;
  assert_float_exact ret (Date.valueOf d)

let local_setter_mutates_receiver () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:30. ~seconds:45. ()) in
  let ret = Date.setHours ~hours:5. d in
  assert_float_exact (Date.getHours d) 5.;
  assert_float_exact ret (Date.valueOf d)

let setter_chain_mutates_receiver () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:0. ~date:1. ()) in
  let (_ : float) = Date.setUTCFullYear ~year:2021. d in
  let (_ : float) = Date.setUTCMonth ~month:11. d in
  let ret = Date.setUTCDate ~date:25. d in
  assert_float_exact (Date.getUTCFullYear d) 2021.;
  assert_float_exact (Date.getUTCMonth d) 11.;
  assert_float_exact (Date.getUTCDate d) 25.;
  assert_float_exact ret (Date.utc ~year:2021. ~month:11. ~date:25. ())

let setter_nan_arg_invalidates_receiver () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ()) in
  let ret = Date.setUTCHours ~hours:nan d in
  assert_nan ret;
  assert_nan (Date.valueOf d)

(* ===================================================================
   setUTCMilliseconds tests
   =================================================================== *)

let set_utc_ms_basic () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:30. ~seconds:45. ()) in
  let ret = Date.setUTCMilliseconds ~milliseconds:500. d in
  assert_float_exact (Date.getUTCMilliseconds d) 500.;
  assert_float_exact ret (Date.valueOf d)

let set_utc_ms_overflow () =
  (* Setting ms to 1000 should roll over to next second *)
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:30. ~seconds:45. ()) in
  let (_ : float) = Date.setUTCMilliseconds ~milliseconds:1000. d in
  assert_float_exact (Date.getUTCMilliseconds d) 0.;
  assert_float_exact (Date.getUTCSeconds d) 46.

let set_utc_ms_negative () =
  (* Negative ms should roll back *)
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:30. ~seconds:45. () +. 500.) in
  let (_ : float) = Date.setUTCMilliseconds ~milliseconds:(-1.) d in
  assert_float_exact (Date.getUTCMilliseconds d) 999.;
  assert_float_exact (Date.getUTCSeconds d) 44.

let set_utc_ms_nan () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ()) in
  let ret = Date.setUTCMilliseconds ~milliseconds:nan d in
  assert_nan ret;
  assert_nan (Date.valueOf d)

(* ===================================================================
   setUTCSeconds tests
   =================================================================== *)

let set_utc_seconds_basic () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:30. ~seconds:0. ()) in
  let ret = Date.setUTCSeconds ~seconds:45. d in
  assert_float_exact (Date.getUTCSeconds d) 45.;
  assert_float_exact ret (Date.valueOf d)

let set_utc_seconds_overflow () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:30. ~seconds:0. ()) in
  let (_ : float) = Date.setUTCSeconds ~seconds:60. d in
  assert_float_exact (Date.getUTCSeconds d) 0.;
  assert_float_exact (Date.getUTCMinutes d) 31.

let set_utc_seconds_with_ms () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:30. ~seconds:0. ()) in
  let (_ : float) = Date.setUTCSeconds ~seconds:45. ~milliseconds:123. d in
  assert_float_exact (Date.getUTCSeconds d) 45.;
  assert_float_exact (Date.getUTCMilliseconds d) 123.

let set_utc_seconds_nan () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ()) in
  let ret = Date.setUTCSeconds ~seconds:nan d in
  assert_nan ret;
  assert_nan (Date.valueOf d)

(* ===================================================================
   setUTCMinutes tests
   =================================================================== *)

let set_utc_minutes_basic () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:0. ()) in
  let ret = Date.setUTCMinutes ~minutes:45. d in
  assert_float_exact (Date.getUTCMinutes d) 45.;
  assert_float_exact ret (Date.valueOf d)

let set_utc_minutes_overflow () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:0. ()) in
  let (_ : float) = Date.setUTCMinutes ~minutes:60. d in
  assert_float_exact (Date.getUTCMinutes d) 0.;
  assert_float_exact (Date.getUTCHours d) 13.

let set_utc_minutes_with_seconds () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:0. ~seconds:0. ()) in
  let (_ : float) = Date.setUTCMinutes ~minutes:30. ~seconds:45. d in
  assert_float_exact (Date.getUTCMinutes d) 30.;
  assert_float_exact (Date.getUTCSeconds d) 45.

let set_utc_minutes_with_seconds_ms () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:0. ~seconds:0. ()) in
  let (_ : float) = Date.setUTCMinutes ~minutes:30. ~seconds:45. ~milliseconds:123. d in
  assert_float_exact (Date.getUTCMinutes d) 30.;
  assert_float_exact (Date.getUTCSeconds d) 45.;
  assert_float_exact (Date.getUTCMilliseconds d) 123.

let set_utc_minutes_nan () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ()) in
  let ret = Date.setUTCMinutes ~minutes:nan d in
  assert_nan ret;
  assert_nan (Date.valueOf d)

(* ===================================================================
   setUTCHours tests
   =================================================================== *)

let set_utc_hours_basic () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:0. ()) in
  let ret = Date.setUTCHours ~hours:18. d in
  assert_float_exact (Date.getUTCHours d) 18.;
  assert_float_exact ret (Date.valueOf d)

let set_utc_hours_overflow () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:0. ()) in
  let (_ : float) = Date.setUTCHours ~hours:24. d in
  assert_float_exact (Date.getUTCHours d) 0.;
  assert_float_exact (Date.getUTCDate d) 16.

let set_utc_hours_with_minutes () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:0. ~minutes:0. ()) in
  let (_ : float) = Date.setUTCHours ~hours:18. ~minutes:30. d in
  assert_float_exact (Date.getUTCHours d) 18.;
  assert_float_exact (Date.getUTCMinutes d) 30.

let set_utc_hours_with_minutes_seconds () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:0. ~minutes:0. ~seconds:0. ()) in
  let (_ : float) = Date.setUTCHours ~hours:18. ~minutes:30. ~seconds:45. d in
  assert_float_exact (Date.getUTCHours d) 18.;
  assert_float_exact (Date.getUTCMinutes d) 30.;
  assert_float_exact (Date.getUTCSeconds d) 45.

let set_utc_hours_all () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:0. ~minutes:0. ~seconds:0. ()) in
  let (_ : float) = Date.setUTCHours ~hours:18. ~minutes:30. ~seconds:45. ~milliseconds:123. d in
  assert_float_exact (Date.getUTCHours d) 18.;
  assert_float_exact (Date.getUTCMinutes d) 30.;
  assert_float_exact (Date.getUTCSeconds d) 45.;
  assert_float_exact (Date.getUTCMilliseconds d) 123.

let set_utc_hours_nan () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ()) in
  let ret = Date.setUTCHours ~hours:nan d in
  assert_nan ret;
  assert_nan (Date.valueOf d)

(* ===================================================================
   setUTCDate tests
   =================================================================== *)

let set_utc_date_basic () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:1. ()) in
  let ret = Date.setUTCDate ~date:15. d in
  assert_float_exact (Date.getUTCDate d) 15.;
  assert_float_exact ret (Date.valueOf d)

let set_utc_date_overflow () =
  (* June has 30 days, setting to 31 should roll to July 1 *)
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:1. ()) in
  let (_ : float) = Date.setUTCDate ~date:31. d in
  assert_float_exact (Date.getUTCDate d) 1.;
  assert_float_exact (Date.getUTCMonth d) 6.

let set_utc_date_zero () =
  (* Day 0 means last day of previous month *)
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ()) in
  let (_ : float) = Date.setUTCDate ~date:0. d in
  assert_float_exact (Date.getUTCDate d) 31.;
  assert_float_exact (Date.getUTCMonth d) 4.

let set_utc_date_negative () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ()) in
  let (_ : float) = Date.setUTCDate ~date:(-1.) d in
  assert_float_exact (Date.getUTCDate d) 30.;
  assert_float_exact (Date.getUTCMonth d) 4.

let set_utc_date_nan () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ()) in
  let ret = Date.setUTCDate ~date:nan d in
  assert_nan ret;
  assert_nan (Date.valueOf d)

(* ===================================================================
   setUTCMonth tests
   =================================================================== *)

let set_utc_month_basic () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:0. ~date:15. ()) in
  let ret = Date.setUTCMonth ~month:5. d in
  assert_float_exact (Date.getUTCMonth d) 5.;
  assert_float_exact ret (Date.valueOf d)

let set_utc_month_overflow () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:0. ~date:15. ()) in
  let (_ : float) = Date.setUTCMonth ~month:12. d in
  assert_float_exact (Date.getUTCMonth d) 0.;
  assert_float_exact (Date.getUTCFullYear d) 2021.

let set_utc_month_negative () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ()) in
  let (_ : float) = Date.setUTCMonth ~month:(-1.) d in
  assert_float_exact (Date.getUTCMonth d) 11.;
  assert_float_exact (Date.getUTCFullYear d) 2019.

let set_utc_month_with_date () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:0. ~date:1. ()) in
  let (_ : float) = Date.setUTCMonth ~month:5. ~date:15. d in
  assert_float_exact (Date.getUTCMonth d) 5.;
  assert_float_exact (Date.getUTCDate d) 15.

let set_utc_month_nan () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ()) in
  let ret = Date.setUTCMonth ~month:nan d in
  assert_nan ret;
  assert_nan (Date.valueOf d)

(* ===================================================================
   setUTCFullYear tests
   =================================================================== *)

let set_utc_full_year_basic () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ()) in
  let ret = Date.setUTCFullYear ~year:2025. d in
  assert_float_exact (Date.getUTCFullYear d) 2025.;
  assert_float_exact ret (Date.valueOf d)

let set_utc_full_year_with_month () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:0. ~date:15. ()) in
  let (_ : float) = Date.setUTCFullYear ~year:2025. ~month:5. d in
  assert_float_exact (Date.getUTCFullYear d) 2025.;
  assert_float_exact (Date.getUTCMonth d) 5.

let set_utc_full_year_with_month_date () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:0. ~date:1. ()) in
  let (_ : float) = Date.setUTCFullYear ~year:2025. ~month:5. ~date:15. d in
  assert_float_exact (Date.getUTCFullYear d) 2025.;
  assert_float_exact (Date.getUTCMonth d) 5.;
  assert_float_exact (Date.getUTCDate d) 15.

let set_utc_full_year_leap_to_non_leap () =
  (* Feb 29 in leap year -> set to non-leap year *)
  let d = date_of_utc (Date.utc ~year:2020. ~month:1. ~date:29. ()) in
  let (_ : float) = Date.setUTCFullYear ~year:2021. d in
  (* Should roll over to March 1 *)
  assert_float_exact (Date.getUTCFullYear d) 2021.;
  assert_float_exact (Date.getUTCMonth d) 2.;
  assert_float_exact (Date.getUTCDate d) 1.

let set_utc_full_year_on_nan_date () =
  (* setUTCFullYear on an Invalid Date treats the receiver as epoch (+0) *)
  let d = date_of_utc nan in
  let (_ : float) = Date.setUTCFullYear ~year:2021. d in
  assert_float_exact (Date.getUTCFullYear d) 2021.;
  assert_float_exact (Date.getUTCMonth d) 0.;
  assert_float_exact (Date.getUTCDate d) 1.

let set_utc_full_year_nan () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ()) in
  let ret = Date.setUTCFullYear ~year:nan d in
  assert_nan ret;
  assert_nan (Date.valueOf d)

(* ===================================================================
   Local time setters tests
   These assert against the local getters, so they hold in any timezone
   =================================================================== *)

let set_milliseconds_basic () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:30. ~seconds:45. ()) in
  let ret = Date.setMilliseconds ~milliseconds:500. d in
  assert_float_exact (Date.getMilliseconds d) 500.;
  assert_float_exact ret (Date.valueOf d)

let set_seconds_basic () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:30. ~seconds:0. ()) in
  let ret = Date.setSeconds ~seconds:30. d in
  assert_float_exact (Date.getSeconds d) 30.;
  assert_float_exact ret (Date.valueOf d)

let set_minutes_basic () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:0. ()) in
  let ret = Date.setMinutes ~minutes:45. d in
  assert_float_exact (Date.getMinutes d) 45.;
  assert_float_exact ret (Date.valueOf d)

let set_hours_basic () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:0. ()) in
  let ret = Date.setHours ~hours:18. d in
  assert_float_exact (Date.getHours d) 18.;
  assert_float_exact ret (Date.valueOf d)

let set_date_basic () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:1. ~hours:12. ()) in
  let ret = Date.setDate ~date:15. d in
  assert_float_exact (Date.getDate d) 15.;
  assert_float_exact ret (Date.valueOf d)

let set_month_basic () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:0. ~date:15. ~hours:12. ()) in
  let ret = Date.setMonth ~month:5. d in
  assert_float_exact (Date.getMonth d) 5.;
  assert_float_exact ret (Date.valueOf d)

let set_full_year_basic () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ()) in
  let ret = Date.setFullYear ~year:2025. d in
  assert_float_exact (Date.getFullYear d) 2025.;
  assert_float_exact ret (Date.valueOf d)

(* Local setters with multiple args *)
let set_seconds_with_ms () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:30. ~seconds:0. ()) in
  let (_ : float) = Date.setSeconds ~seconds:45. ~milliseconds:123. d in
  assert_float_exact (Date.getSeconds d) 45.;
  assert_float_exact (Date.getMilliseconds d) 123.

let set_minutes_with_seconds () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:0. ~seconds:0. ()) in
  let (_ : float) = Date.setMinutes ~minutes:30. ~seconds:45. d in
  assert_float_exact (Date.getMinutes d) 30.;
  assert_float_exact (Date.getSeconds d) 45.

let set_minutes_with_seconds_ms () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:12. ~minutes:0. ~seconds:0. ()) in
  let (_ : float) = Date.setMinutes ~minutes:30. ~seconds:45. ~milliseconds:123. d in
  assert_float_exact (Date.getMinutes d) 30.;
  assert_float_exact (Date.getSeconds d) 45.;
  assert_float_exact (Date.getMilliseconds d) 123.

let set_hours_with_minutes () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:0. ~minutes:0. ()) in
  let (_ : float) = Date.setHours ~hours:18. ~minutes:30. d in
  assert_float_exact (Date.getHours d) 18.;
  assert_float_exact (Date.getMinutes d) 30.

let set_hours_with_minutes_seconds () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:0. ~minutes:0. ~seconds:0. ()) in
  let (_ : float) = Date.setHours ~hours:18. ~minutes:30. ~seconds:45. d in
  assert_float_exact (Date.getHours d) 18.;
  assert_float_exact (Date.getMinutes d) 30.;
  assert_float_exact (Date.getSeconds d) 45.

let set_hours_all () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ~hours:0. ~minutes:0. ~seconds:0. ()) in
  let (_ : float) = Date.setHours ~hours:18. ~minutes:30. ~seconds:45. ~milliseconds:123. d in
  assert_float_exact (Date.getHours d) 18.;
  assert_float_exact (Date.getMinutes d) 30.;
  assert_float_exact (Date.getSeconds d) 45.;
  assert_float_exact (Date.getMilliseconds d) 123.

let set_month_with_date () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:0. ~date:1. ~hours:12. ()) in
  let (_ : float) = Date.setMonth ~month:5. ~date:15. d in
  assert_float_exact (Date.getMonth d) 5.;
  assert_float_exact (Date.getDate d) 15.

let set_full_year_with_month () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:0. ~date:15. ~hours:12. ()) in
  let (_ : float) = Date.setFullYear ~year:2025. ~month:5. d in
  assert_float_exact (Date.getFullYear d) 2025.;
  assert_float_exact (Date.getMonth d) 5.

let set_full_year_with_month_date () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:0. ~date:1. ~hours:12. ()) in
  let (_ : float) = Date.setFullYear ~year:2025. ~month:5. ~date:15. d in
  assert_float_exact (Date.getFullYear d) 2025.;
  assert_float_exact (Date.getMonth d) 5.;
  assert_float_exact (Date.getDate d) 15.

(* NaN tests for local setters *)
let set_milliseconds_nan () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ()) in
  let ret = Date.setMilliseconds ~milliseconds:nan d in
  assert_nan ret;
  assert_nan (Date.valueOf d)

let set_seconds_nan () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ()) in
  let ret = Date.setSeconds ~seconds:nan d in
  assert_nan ret;
  assert_nan (Date.valueOf d)

let set_minutes_nan () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ()) in
  let ret = Date.setMinutes ~minutes:nan d in
  assert_nan ret;
  assert_nan (Date.valueOf d)

let set_hours_nan () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ()) in
  let ret = Date.setHours ~hours:nan d in
  assert_nan ret;
  assert_nan (Date.valueOf d)

let set_date_nan () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ()) in
  let ret = Date.setDate ~date:nan d in
  assert_nan ret;
  assert_nan (Date.valueOf d)

let set_month_nan () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ()) in
  let ret = Date.setMonth ~month:nan d in
  assert_nan ret;
  assert_nan (Date.valueOf d)

let set_full_year_nan () =
  let d = date_of_utc (Date.utc ~year:2020. ~month:5. ~date:15. ()) in
  let ret = Date.setFullYear ~year:nan d in
  assert_nan ret;
  assert_nan (Date.valueOf d)

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
    (* mutation semantics *)
    test "setter mutates receiver" setter_mutates_receiver;
    test "local setter mutates receiver" local_setter_mutates_receiver;
    test "setter chain mutates receiver" setter_chain_mutates_receiver;
    test "NaN arg invalidates receiver" setter_nan_arg_invalidates_receiver;
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
    test "setUTCFullYear on NaN date" set_utc_full_year_on_nan_date;
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

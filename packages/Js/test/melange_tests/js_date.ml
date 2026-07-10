(** Ported from Melange's test suite: jscomp/test/js_date_test.ml (melange 6.0.1-54).

    Melange's suite already comments out the locale/timezone-dependent cases (getDate, getHours, toLocaleString,
    toString, ...); those stay skipped here for the same reason. [toDateString] formats the LOCAL date, so it is pinned
    to TZ=UTC (at 11:11Z the UTC calendar date matches Melange's expectation) the same way
    packages/Js/test/date_tests/local_time.ml pins TZ. The remaining local getter/setter cases are TZ-independent: they
    construct and read back through the same local-time lens. *)

open Helpers
module N = Js.Date

let ok cond = assert_true "expected true" cond
let date () = N.fromString "1976-03-08T12:34:56.789+01:23"

(* Same TZ pinning approach as packages/Js/test/date_tests/local_time.ml. *)
let with_tz tz f =
  let original = Sys.getenv_opt "TZ" in
  Unix.putenv "TZ" tz;
  Fun.protect ~finally:(fun () -> Unix.putenv "TZ" (match original with Some v -> v | None -> "UTC")) f

let tests =
  [
    test "valueOf" (fun () -> assert_float_exact (N.valueOf (date ())) 195131516789.);
    test "make" (fun () -> ok (N.make () |> N.getTime > 1487223505382.));
    test "parseAsFloat" (fun () -> assert_float_exact (N.parseAsFloat "1976-03-08T12:34:56.789+01:23") 195131516789.);
    test "parseAsFloat_invalid" (fun () -> assert_nan (N.parseAsFloat "gibberish"));
    test "fromFloat" (fun () -> assert_string (N.fromFloat 195131516789. |> N.toISOString) "1976-03-08T11:11:56.789Z");
    test "fromString_valid" (fun () ->
        assert_float_exact (N.fromString "1976-03-08T12:34:56.789+01:23" |> N.getTime) 195131516789.);
    test "fromString_invalid" (fun () -> assert_nan (N.fromString "gibberish" |> N.getTime));
    test "makeWithYM" (fun () ->
        let d = N.make ~year:1984. ~month:4. () in
        assert_float_exact (N.getFullYear d) 1984.;
        assert_float_exact (N.getMonth d) 4.);
    test "makeWithYMD" (fun () ->
        let d = N.make ~year:1984. ~month:4. ~date:6. () in
        assert_float_exact (N.getFullYear d) 1984.;
        assert_float_exact (N.getMonth d) 4.;
        assert_float_exact (N.getDate d) 6.);
    test "makeWithYMDH" (fun () ->
        let d = N.make ~year:1984. ~month:4. ~date:6. ~hours:3. () in
        assert_float_exact (N.getFullYear d) 1984.;
        assert_float_exact (N.getMonth d) 4.;
        assert_float_exact (N.getDate d) 6.;
        assert_float_exact (N.getHours d) 3.);
    test "makeWithYMDHM" (fun () ->
        let d = N.make ~year:1984. ~month:4. ~date:6. ~hours:3. ~minutes:59. () in
        assert_float_exact (N.getFullYear d) 1984.;
        assert_float_exact (N.getMonth d) 4.;
        assert_float_exact (N.getDate d) 6.;
        assert_float_exact (N.getHours d) 3.;
        assert_float_exact (N.getMinutes d) 59.);
    test "makeWithYMDHMS" (fun () ->
        let d = N.make ~year:1984. ~month:4. ~date:6. ~hours:3. ~minutes:59. ~seconds:27. () in
        assert_float_exact (N.getFullYear d) 1984.;
        assert_float_exact (N.getMonth d) 4.;
        assert_float_exact (N.getDate d) 6.;
        assert_float_exact (N.getHours d) 3.;
        assert_float_exact (N.getMinutes d) 59.;
        assert_float_exact (N.getSeconds d) 27.);
    test "utcWithYM" (fun () ->
        let d = N.utc ~year:1984. ~month:4. () in
        let d = N.fromFloat d in
        assert_float_exact (N.getUTCFullYear d) 1984.;
        assert_float_exact (N.getUTCMonth d) 4.);
    test "utcWithYMD" (fun () ->
        let d = N.utc ~year:1984. ~month:4. ~date:6. () in
        let d = N.fromFloat d in
        assert_float_exact (N.getUTCFullYear d) 1984.;
        assert_float_exact (N.getUTCMonth d) 4.;
        assert_float_exact (N.getUTCDate d) 6.);
    test "utcWithYMDH" (fun () ->
        let d = N.utc ~year:1984. ~month:4. ~date:6. ~hours:3. () in
        let d = N.fromFloat d in
        assert_float_exact (N.getUTCFullYear d) 1984.;
        assert_float_exact (N.getUTCMonth d) 4.;
        assert_float_exact (N.getUTCDate d) 6.;
        assert_float_exact (N.getUTCHours d) 3.);
    test "utcWithYMDHM" (fun () ->
        let d = N.utc ~year:1984. ~month:4. ~date:6. ~hours:3. ~minutes:59. () in
        let d = N.fromFloat d in
        assert_float_exact (N.getUTCFullYear d) 1984.;
        assert_float_exact (N.getUTCMonth d) 4.;
        assert_float_exact (N.getUTCDate d) 6.;
        assert_float_exact (N.getUTCHours d) 3.;
        assert_float_exact (N.getUTCMinutes d) 59.);
    test "utcWithYMDHMS" (fun () ->
        let d = N.utc ~year:1984. ~month:4. ~date:6. ~hours:3. ~minutes:59. ~seconds:27. () in
        let d = N.fromFloat d in
        assert_float_exact (N.getUTCFullYear d) 1984.;
        assert_float_exact (N.getUTCMonth d) 4.;
        assert_float_exact (N.getUTCDate d) 6.;
        assert_float_exact (N.getUTCHours d) 3.;
        assert_float_exact (N.getUTCMinutes d) 59.;
        assert_float_exact (N.getUTCSeconds d) 27.);
    (* skipped (TZ-dependent, also commented out in Melange's suite): getDate, getDay, getHours, getMinutes, getMonth,
       getTimezoneOffset *)
    test "getFullYear" (fun () -> assert_float_exact (N.getFullYear (date ())) 1976.);
    test "getMilliseconds" (fun () -> assert_float_exact (N.getMilliseconds (date ())) 789.);
    test "getSeconds" (fun () -> assert_float_exact (N.getSeconds (date ())) 56.);
    test "getTime" (fun () -> assert_float_exact (N.getTime (date ())) 195131516789.);
    test "getUTCDate" (fun () -> assert_float_exact (N.getUTCDate (date ())) 8.);
    test "getUTCDay" (fun () -> assert_float_exact (N.getUTCDay (date ())) 1.);
    test "getUTCFUllYear" (fun () -> assert_float_exact (N.getUTCFullYear (date ())) 1976.);
    test "getUTCHours" (fun () -> assert_float_exact (N.getUTCHours (date ())) 11.);
    test "getUTCMilliseconds" (fun () -> assert_float_exact (N.getUTCMilliseconds (date ())) 789.);
    test "getUTCMinutes" (fun () -> assert_float_exact (N.getUTCMinutes (date ())) 11.);
    test "getUTCMonth" (fun () -> assert_float_exact (N.getUTCMonth (date ())) 2.);
    test "getUTCSeconds" (fun () -> assert_float_exact (N.getUTCSeconds (date ())) 56.);
    test "getYear" (fun () -> assert_float_exact (N.getFullYear (date ())) 1976.);
    test "setDate" (fun () ->
        let d = date () in
        let _ = N.setDate ~date:12. d in
        assert_float_exact (N.getDate d) 12.);
    test "setFullYear" (fun () ->
        let d = date () in
        let _ = N.setFullYear ~year:1986. d in
        assert_float_exact (N.getFullYear d) 1986.);
    test "setFullYearM" (fun () ->
        let d = date () in
        let _ = N.setFullYear d ~year:1986. ~month:7. in
        assert_float_exact (N.getFullYear d) 1986.;
        assert_float_exact (N.getMonth d) 7.);
    test "setFullYearMD" (fun () ->
        let d = date () in
        let _ = N.setFullYear d ~year:1986. ~month:7. ~date:23. in
        assert_float_exact (N.getFullYear d) 1986.;
        assert_float_exact (N.getMonth d) 7.;
        assert_float_exact (N.getDate d) 23.);
    test "setHours" (fun () ->
        let d = date () in
        let _ = N.setHours ~hours:22. d in
        assert_float_exact (N.getHours d) 22.);
    test "setHoursM" (fun () ->
        let d = date () in
        let _ = N.setHours d ~hours:22. ~minutes:48. in
        assert_float_exact (N.getHours d) 22.;
        assert_float_exact (N.getMinutes d) 48.);
    test "setHoursMS" (fun () ->
        let d = date () in
        let _ = N.setHours d ~hours:22. ~minutes:48. ~seconds:54. in
        assert_float_exact (N.getHours d) 22.;
        assert_float_exact (N.getMinutes d) 48.;
        assert_float_exact (N.getSeconds d) 54.);
    test "setMilliseconds" (fun () ->
        let d = date () in
        let _ = N.setMilliseconds ~milliseconds:543. d in
        assert_float_exact (N.getMilliseconds d) 543.);
    test "setMinutes" (fun () ->
        let d = date () in
        let _ = N.setMinutes ~minutes:18. d in
        assert_float_exact (N.getMinutes d) 18.);
    test "setMinutesS" (fun () ->
        let d = date () in
        let _ = N.setMinutes d ~minutes:18. ~seconds:42. in
        assert_float_exact (N.getMinutes d) 18.;
        assert_float_exact (N.getSeconds d) 42.);
    test "setMinutesSMs" (fun () ->
        let d = date () in
        let _ = N.setMinutes d ~minutes:18. ~seconds:42. ~milliseconds:311. in
        assert_float_exact (N.getMinutes d) 18.;
        assert_float_exact (N.getSeconds d) 42.;
        assert_float_exact (N.getMilliseconds d) 311.);
    test "setMonth" (fun () ->
        let d = date () in
        let _ = N.setMonth ~month:10. d in
        assert_float_exact (N.getMonth d) 10.);
    test "setMonthD" (fun () ->
        let d = date () in
        let _ = N.setMonth d ~month:10. ~date:14. in
        assert_float_exact (N.getMonth d) 10.;
        assert_float_exact (N.getDate d) 14.);
    test "setSeconds" (fun () ->
        let d = date () in
        let _ = N.setSeconds ~seconds:36. d in
        assert_float_exact (N.getSeconds d) 36.);
    test "setSecondsMs" (fun () ->
        let d = date () in
        let _ = N.setSeconds d ~seconds:36. ~milliseconds:420. in
        assert_float_exact (N.getSeconds d) 36.;
        assert_float_exact (N.getMilliseconds d) 420.);
    test "setUTCDate" (fun () ->
        let d = date () in
        let _ = N.setUTCDate ~date:12. d in
        assert_float_exact (N.getUTCDate d) 12.);
    test "setUTCFullYear" (fun () ->
        let d = date () in
        let _ = N.setUTCFullYear ~year:1986. d in
        assert_float_exact (N.getUTCFullYear d) 1986.);
    test "setUTCFullYearM" (fun () ->
        let d = date () in
        let _ = N.setUTCFullYear d ~year:1986. ~month:7. in
        assert_float_exact (N.getUTCFullYear d) 1986.;
        assert_float_exact (N.getUTCMonth d) 7.);
    test "setUTCFullYearMD" (fun () ->
        let d = date () in
        let _ = N.setUTCFullYear d ~year:1986. ~month:7. ~date:23. in
        assert_float_exact (N.getUTCFullYear d) 1986.;
        assert_float_exact (N.getUTCMonth d) 7.;
        assert_float_exact (N.getUTCDate d) 23.);
    test "setUTCHours" (fun () ->
        let d = date () in
        let _ = N.setUTCHours ~hours:22. d in
        assert_float_exact (N.getUTCHours d) 22.);
    test "setUTCHoursM" (fun () ->
        let d = date () in
        let _ = N.setUTCHours d ~hours:22. ~minutes:48. in
        assert_float_exact (N.getUTCHours d) 22.;
        assert_float_exact (N.getUTCMinutes d) 48.);
    test "setUTCHoursMS" (fun () ->
        let d = date () in
        let _ = N.setUTCHours d ~hours:22. ~minutes:48. ~seconds:54. in
        assert_float_exact (N.getUTCHours d) 22.;
        assert_float_exact (N.getUTCMinutes d) 48.;
        assert_float_exact (N.getUTCSeconds d) 54.);
    test "setUTCMilliseconds" (fun () ->
        let d = date () in
        let _ = N.setUTCMilliseconds ~milliseconds:543. d in
        assert_float_exact (N.getUTCMilliseconds d) 543.);
    test "setUTCMinutes" (fun () ->
        let d = date () in
        let _ = N.setUTCMinutes ~minutes:18. d in
        assert_float_exact (N.getUTCMinutes d) 18.);
    test "setUTCMinutesS" (fun () ->
        let d = date () in
        let _ = N.setUTCMinutes d ~minutes:18. ~seconds:42. in
        assert_float_exact (N.getUTCMinutes d) 18.;
        assert_float_exact (N.getUTCSeconds d) 42.);
    test "setUTCMinutesSMs" (fun () ->
        let d = date () in
        let _ = N.setUTCMinutes d ~minutes:18. ~seconds:42. ~milliseconds:311. in
        assert_float_exact (N.getUTCMinutes d) 18.;
        assert_float_exact (N.getUTCSeconds d) 42.;
        assert_float_exact (N.getUTCMilliseconds d) 311.);
    test "setUTCMonth" (fun () ->
        let d = date () in
        let _ = N.setUTCMonth ~month:10. d in
        assert_float_exact (N.getUTCMonth d) 10.);
    test "setUTCMonthD" (fun () ->
        let d = date () in
        let _ = N.setUTCMonth d ~month:10. ~date:14. in
        assert_float_exact (N.getUTCMonth d) 10.;
        assert_float_exact (N.getUTCDate d) 14.);
    test "setUTCSeconds" (fun () ->
        let d = date () in
        let _ = N.setUTCSeconds ~seconds:36. d in
        assert_float_exact (N.getUTCSeconds d) 36.);
    test "setUTCSecondsMs" (fun () ->
        let d = date () in
        let _ = N.setUTCSeconds d ~seconds:36. ~milliseconds:420. in
        assert_float_exact (N.getUTCSeconds d) 36.;
        assert_float_exact (N.getUTCMilliseconds d) 420.);
    (* toDateString formats the LOCAL date, so pin TZ=UTC: at 11:11:56Z the UTC calendar date is Melange's expected
       "Mon Mar 08 1976". *)
    test "toDateString" (fun () -> with_tz "UTC" (fun () -> assert_string (N.toDateString (date ())) "Mon Mar 08 1976"));
    test "toGMTString" (fun () -> assert_string (N.toUTCString (date ())) "Mon, 08 Mar 1976 11:11:56 GMT");
    test "toISOString" (fun () -> assert_string (N.toISOString (date ())) "1976-03-08T11:11:56.789Z");
    test "toJSON" (fun () -> assert_string (N.toJSON (date ()) |> Option.get) "1976-03-08T11:11:56.789Z");
    test "toJSONUnsafe" (fun () -> assert_string (N.toJSONUnsafe (date ())) "1976-03-08T11:11:56.789Z");
    (* skipped (TZ/locale-dependent, also commented out in Melange's suite): toLocaleDateString, toLocaleString,
       toLocaleTimeString, toString, toTimeString. Natively toLocale* are aliased to the non-locale versions anyway
       (documented divergence: no ICU locale support). *)
    test "toUTCString" (fun () -> assert_string (N.toUTCString (date ())) "Mon, 08 Mar 1976 11:11:56 GMT");
    test "eq" (fun () ->
        let a = N.fromString "2013-03-01T01:10:00" in
        let b = N.fromString "2013-03-01T01:10:00" in
        let c = N.fromString "2013-03-01T01:10:01" in
        ok (a = b && b <> c && c > b));
  ]

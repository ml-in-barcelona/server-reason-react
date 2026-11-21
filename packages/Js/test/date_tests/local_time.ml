open Helpers
module Date = Js.Date

let with_tz tz f =
  let original = Sys.getenv_opt "TZ" in
  Unix.putenv "TZ" tz;
  Fun.protect ~finally:(fun () -> Unix.putenv "TZ" (match original with Some v -> v | None -> "UTC")) f

let in_madrid f () = with_tz "Europe/Madrid" f

let tz_pinning_works () =
  let d = Date.fromFloat 1718438400000. in
  assert_float_exact (Date.getTimezoneOffset d) (-120.);
  assert_float_exact (Date.getHours d) 10.

let iso_datetime_without_tz_is_local () = assert_float_exact (Date.parseAsFloat "2024-06-15T10:00:00") 1718438400000.
let iso_datetime_without_seconds_is_local () = assert_float_exact (Date.parseAsFloat "2024-06-15T10:00") 1718438400000.

let iso_datetime_space_separator_is_local () =
  assert_float_exact (Date.parseAsFloat "2024-06-15 10:00:00") 1718438400000.

let iso_datetime_with_offset_ignores_local_tz () =
  assert_float_exact (Date.parseAsFloat "2024-06-15T10:00:00+02:00") 1718438400000.;
  assert_float_exact (Date.parseAsFloat "2024-06-15T08:00:00Z") 1718438400000.

let iso_date_only_stays_utc () =
  assert_float_exact (Date.parseAsFloat "2024-06-15") 1718409600000.;
  assert_float_exact (Date.parseAsFloat "2024") 1704067200000.;
  assert_float_exact (Date.parseAsFloat "2024-06") 1717200000000.

let legacy_without_gmt_is_local () = assert_float_exact (Date.parseAsFloat "Jan 1 2000 00:00:00") 946681200000.
let legacy_without_time_is_local () = assert_float_exact (Date.parseAsFloat "Jan 1 2000") 946681200000.
let legacy_with_gmt_is_utc () = assert_float_exact (Date.parseAsFloat "Jan 1 2000 00:00:00 GMT") 946684800000.

let legacy_two_digit_years () =
  assert_float_exact (Date.parseAsFloat "Jan 1 00") 946681200000.;
  assert_float_exact (Date.parseAsFloat "Jan 1 49") 2493068400000.;
  assert_float_exact (Date.parseAsFloat "Jan 1 50") (-631155600000.);
  assert_float_exact (Date.parseAsFloat "Jan 1 99") 915145200000.

let legacy_day_overflows_month () =
  assert_float_exact (Date.parseAsFloat "Feb 30 2019") 1551481200000.;
  assert_nan (Date.parseAsFloat "Jan 32 2000")

let dst_spring_before_transition () = assert_float_exact (Date.parseAsFloat "2024-03-31T01:30") 1711845000000.
let dst_spring_gap () = assert_float_exact (Date.parseAsFloat "2024-03-31T02:30") 1711848600000.
let dst_spring_after_transition () = assert_float_exact (Date.parseAsFloat "2024-03-31T03:30") 1711848600000.
let dst_fall_before_transition () = assert_float_exact (Date.parseAsFloat "2024-10-27T01:30") 1729985400000.
let dst_fall_ambiguous () = assert_float_exact (Date.parseAsFloat "2024-10-27T02:30") 1729989000000.
let dst_fall_after_transition () = assert_float_exact (Date.parseAsFloat "2024-10-27T03:30") 1729996200000.

let make_uses_local_tza () =
  let d = Date.make ~year:2024. ~month:5. ~date:15. ~hours:10. ~minutes:0. ~seconds:0. () in
  assert_float_exact (Date.valueOf d) 1718438400000.

let make_in_dst_gap_uses_pre_transition_offset () =
  let d = Date.make ~year:2024. ~month:2. ~date:31. ~hours:2. ~minutes:30. ~seconds:0. () in
  assert_float_exact (Date.valueOf d) 1711848600000.

let make_in_dst_ambiguity_uses_earlier_instant () =
  let d = Date.make ~year:2024. ~month:9. ~date:27. ~hours:2. ~minutes:30. ~seconds:0. () in
  assert_float_exact (Date.valueOf d) 1729989000000.

let set_hours_across_dst () =
  let d = Date.make ~year:2024. ~month:2. ~date:31. ~hours:0. ~minutes:0. ~seconds:0. () in
  let ret = Date.setHours ~hours:12. d in
  assert_float_exact (Date.getHours d) 12.;
  assert_float_exact ret (Date.valueOf d);
  assert_float_exact (Date.getUTCHours d) 10.

let to_string_roundtrip_in_madrid () =
  let d = Date.fromFloat 1718438400000. in
  assert_string_equal (Date.toString d) "Sat Jun 15 2024 10:00:00 GMT+0200";
  let reparsed = Date.fromString (Date.toString d) in
  assert_float_exact (Date.valueOf reparsed) 1718438400000.

let to_utc_string_roundtrip_in_madrid () =
  let d = Date.fromFloat 1718438400000. in
  assert_string_equal (Date.toUTCString d) "Sat, 15 Jun 2024 08:00:00 GMT";
  let reparsed = Date.fromString (Date.toUTCString d) in
  assert_float_exact (Date.valueOf reparsed) 1718438400000.

let tests =
  [
    test "TZ pinning is effective" (in_madrid tz_pinning_works);
    test "ISO date-time without offset is local" (in_madrid iso_datetime_without_tz_is_local);
    test "ISO date-time without seconds is local" (in_madrid iso_datetime_without_seconds_is_local);
    test "ISO date-time with space separator is local" (in_madrid iso_datetime_space_separator_is_local);
    test "ISO date-time with offset ignores local tz" (in_madrid iso_datetime_with_offset_ignores_local_tz);
    test "ISO date-only stays UTC" (in_madrid iso_date_only_stays_utc);
    test "legacy without GMT is local" (in_madrid legacy_without_gmt_is_local);
    test "legacy without time is local" (in_madrid legacy_without_time_is_local);
    test "legacy with GMT is UTC" (in_madrid legacy_with_gmt_is_utc);
    test "legacy two-digit years" (in_madrid legacy_two_digit_years);
    test "legacy day overflows month" (in_madrid legacy_day_overflows_month);
    test "spring: before transition" (in_madrid dst_spring_before_transition);
    test "spring: gap uses pre-transition offset" (in_madrid dst_spring_gap);
    test "spring: after transition" (in_madrid dst_spring_after_transition);
    test "fall: before transition" (in_madrid dst_fall_before_transition);
    test "fall: ambiguity uses earlier instant" (in_madrid dst_fall_ambiguous);
    test "fall: after transition" (in_madrid dst_fall_after_transition);
    test "make uses LocalTZA" (in_madrid make_uses_local_tza);
    test "make in DST gap" (in_madrid make_in_dst_gap_uses_pre_transition_offset);
    test "make in DST ambiguity" (in_madrid make_in_dst_ambiguity_uses_earlier_instant);
    test "setHours across DST" (in_madrid set_hours_across_dst);
    test "toString roundtrip in Madrid" (in_madrid to_string_roundtrip_in_madrid);
    test "toUTCString roundtrip in Madrid" (in_madrid to_utc_string_roundtrip_in_madrid);
  ]

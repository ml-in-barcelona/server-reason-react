(** Local-time semantics tests (parsing + LocalTZA/DST edges).

    These tests pin the process timezone to Europe/Madrid via [Unix.putenv "TZ"], which OCaml's [Unix.localtime] honours
    on glibc (it calls [localtime(3)], which re-reads TZ via tzset). Every test restores the previous TZ.

    Reference behavior is V8/SpiderMonkey/JSC (ES2016+):
    - ISO date-time without an offset ("2024-06-15T10:00") is LOCAL time;
    - ISO date-only ("2024-06-15") is UTC;
    - legacy formats without a GMT designator are LOCAL time;
    - spring-forward gap and fall-back ambiguity both resolve with the offset in effect BEFORE the transition.

    Europe/Madrid 2024 transitions:
    - 2024-03-31 01:00Z: +01:00 (CET) -> +02:00 (CEST), local clocks jump 02:00 -> 03:00;
    - 2024-10-27 01:00Z: +02:00 (CEST) -> +01:00 (CET), local clocks fall back 03:00 -> 02:00. *)

open Helpers
module Date = Js.Date

(* Restores the original TZ afterwards; when TZ was unset we restore to "UTC"
   (there is no unsetenv in Unix), which keeps the rest of the suite
   deterministic — all other tests are timezone-agnostic. *)
let with_tz tz f =
  let original = Sys.getenv_opt "TZ" in
  Unix.putenv "TZ" tz;
  Fun.protect ~finally:(fun () -> Unix.putenv "TZ" (match original with Some v -> v | None -> "UTC")) f

let in_madrid f () = with_tz "Europe/Madrid" f

(* ===================================================================
   Sanity: TZ pinning is effective in this process
   =================================================================== *)

let tz_pinning_works () =
  (* 2024-06-15T08:00Z is 10:00 CEST: getTimezoneOffset must be -120 *)
  let d = Date.fromFloat 1718438400000. in
  assert_float_exact (Date.getTimezoneOffset d) (-120.);
  assert_float_exact (Date.getHours d) 10.

(* ===================================================================
   ISO date-time without offset is LOCAL; date-only stays UTC
   =================================================================== *)

let iso_datetime_without_tz_is_local () =
  (* node (TZ=Europe/Madrid): Date.parse("2024-06-15T10:00:00") = 1718438400000 *)
  assert_float_exact (Date.parseAsFloat "2024-06-15T10:00:00") 1718438400000.

let iso_datetime_without_seconds_is_local () = assert_float_exact (Date.parseAsFloat "2024-06-15T10:00") 1718438400000.

let iso_datetime_space_separator_is_local () =
  assert_float_exact (Date.parseAsFloat "2024-06-15 10:00:00") 1718438400000.

let iso_datetime_with_offset_ignores_local_tz () =
  assert_float_exact (Date.parseAsFloat "2024-06-15T10:00:00+02:00") 1718438400000.;
  assert_float_exact (Date.parseAsFloat "2024-06-15T08:00:00Z") 1718438400000.

let iso_date_only_stays_utc () =
  (* midnight UTC, not midnight Madrid *)
  assert_float_exact (Date.parseAsFloat "2024-06-15") 1718409600000.;
  assert_float_exact (Date.parseAsFloat "2024") 1704067200000.;
  assert_float_exact (Date.parseAsFloat "2024-06") 1717200000000.

(* ===================================================================
   Legacy formats without GMT are LOCAL
   =================================================================== *)

let legacy_without_gmt_is_local () =
  (* node (TZ=Europe/Madrid): Date.parse("Jan 1 2000 00:00:00") = 946681200000 (CET, +01:00) *)
  assert_float_exact (Date.parseAsFloat "Jan 1 2000 00:00:00") 946681200000.

let legacy_without_time_is_local () = assert_float_exact (Date.parseAsFloat "Jan 1 2000") 946681200000.

let legacy_with_gmt_is_utc () =
  (* explicit GMT: independent of the pinned zone *)
  assert_float_exact (Date.parseAsFloat "Jan 1 2000 00:00:00 GMT") 946684800000.

let legacy_two_digit_years () =
  (* V8 maps two-digit legacy years: 0-49 -> 2000s, 50-99 -> 1900s (local time) *)
  assert_float_exact (Date.parseAsFloat "Jan 1 00") 946681200000.;
  assert_float_exact (Date.parseAsFloat "Jan 1 49") 2493068400000.;
  assert_float_exact (Date.parseAsFloat "Jan 1 50") (-631155600000.);
  assert_float_exact (Date.parseAsFloat "Jan 1 99") 915145200000.

let legacy_day_overflows_month () =
  (* "Feb 30 2019" is Mar 2 local midnight, like V8 *)
  assert_float_exact (Date.parseAsFloat "Feb 30 2019") 1551481200000.;
  assert_nan (Date.parseAsFloat "Jan 32 2000")

(* ===================================================================
   DST edges (LocalTZA(t, false)): Europe/Madrid 2024
   =================================================================== *)

(* --- spring forward: 2024-03-31, clocks jump 02:00 -> 03:00 (local) --- *)

let dst_spring_before_transition () =
  (* local 01:30 CET (+01:00) -> 00:30Z *)
  assert_float_exact (Date.parseAsFloat "2024-03-31T01:30") 1711845000000.

let dst_spring_gap () =
  (* local 02:30 does not exist; pre-transition offset (+01:00) applies -> 01:30Z *)
  assert_float_exact (Date.parseAsFloat "2024-03-31T02:30") 1711848600000.

let dst_spring_after_transition () =
  (* local 03:30 CEST (+02:00) -> 01:30Z *)
  assert_float_exact (Date.parseAsFloat "2024-03-31T03:30") 1711848600000.

(* --- fall back: 2024-10-27, clocks fall back 03:00 -> 02:00 (local) --- *)

let dst_fall_before_transition () =
  (* local 01:30 CEST (+02:00) -> 2024-10-26T23:30Z *)
  assert_float_exact (Date.parseAsFloat "2024-10-27T01:30") 1729985400000.

let dst_fall_ambiguous () =
  (* local 02:30 happens twice; the earlier instant (pre-transition, +02:00) wins -> 00:30Z *)
  assert_float_exact (Date.parseAsFloat "2024-10-27T02:30") 1729989000000.

let dst_fall_after_transition () =
  (* local 03:30 CET (+01:00) -> 02:30Z *)
  assert_float_exact (Date.parseAsFloat "2024-10-27T03:30") 1729996200000.

(* ===================================================================
   Constructors go through the same LocalTZA logic
   =================================================================== *)

let make_uses_local_tza () =
  (* new Date(2024, 5, 15, 10, 0, 0) in Madrid -> 08:00Z *)
  let d = Date.make ~year:2024. ~month:5. ~date:15. ~hours:10. ~minutes:0. ~seconds:0. () in
  assert_float_exact (Date.valueOf d) 1718438400000.

let make_in_dst_gap_uses_pre_transition_offset () =
  (* new Date(2024, 2, 31, 2, 30) in Madrid -> 01:30Z (skipped local time overflows) *)
  let d = Date.make ~year:2024. ~month:2. ~date:31. ~hours:2. ~minutes:30. ~seconds:0. () in
  assert_float_exact (Date.valueOf d) 1711848600000.

let make_in_dst_ambiguity_uses_earlier_instant () =
  (* new Date(2024, 9, 27, 2, 30) in Madrid -> 00:30Z (first occurrence) *)
  let d = Date.make ~year:2024. ~month:9. ~date:27. ~hours:2. ~minutes:30. ~seconds:0. () in
  assert_float_exact (Date.valueOf d) 1729989000000.

let set_hours_across_dst () =
  (* start at 2024-03-31T00:00 local (23:00Z the day before, CET),
     set local hours to 12: 12:00 CEST -> 10:00Z *)
  let d = Date.make ~year:2024. ~month:2. ~date:31. ~hours:0. ~minutes:0. ~seconds:0. () in
  let ret = Date.setHours ~hours:12. d in
  assert_float_exact (Date.getHours d) 12.;
  assert_float_exact ret (Date.valueOf d);
  assert_float_exact (Date.getUTCHours d) 10.

(* ===================================================================
   toString round-trip under a pinned zone
   =================================================================== *)

let to_string_roundtrip_in_madrid () =
  (* toString includes GMT+0200, so it re-parses to the same instant *)
  let d = Date.fromFloat 1718438400000. in
  assert_string_equal (Date.toString d) "Sat Jun 15 2024 10:00:00 GMT+0200";
  let reparsed = Date.fromString (Date.toString d) in
  assert_float_exact (Date.valueOf reparsed) 1718438400000.

let to_utc_string_roundtrip_in_madrid () =
  let d = Date.fromFloat 1718438400000. in
  assert_string_equal (Date.toUTCString d) "Sat, 15 Jun 2024 08:00:00 GMT";
  let reparsed = Date.fromString (Date.toUTCString d) in
  assert_float_exact (Date.valueOf reparsed) 1718438400000.

(* ===================================================================
   Test list
   =================================================================== *)

let tests =
  [
    test "TZ pinning is effective" (in_madrid tz_pinning_works);
    (* ISO local/UTC split *)
    test "ISO date-time without offset is local" (in_madrid iso_datetime_without_tz_is_local);
    test "ISO date-time without seconds is local" (in_madrid iso_datetime_without_seconds_is_local);
    test "ISO date-time with space separator is local" (in_madrid iso_datetime_space_separator_is_local);
    test "ISO date-time with offset ignores local tz" (in_madrid iso_datetime_with_offset_ignores_local_tz);
    test "ISO date-only stays UTC" (in_madrid iso_date_only_stays_utc);
    (* legacy local/UTC split *)
    test "legacy without GMT is local" (in_madrid legacy_without_gmt_is_local);
    test "legacy without time is local" (in_madrid legacy_without_time_is_local);
    test "legacy with GMT is UTC" (in_madrid legacy_with_gmt_is_utc);
    test "legacy two-digit years" (in_madrid legacy_two_digit_years);
    test "legacy day overflows month" (in_madrid legacy_day_overflows_month);
    (* DST edges *)
    test "spring: before transition" (in_madrid dst_spring_before_transition);
    test "spring: gap uses pre-transition offset" (in_madrid dst_spring_gap);
    test "spring: after transition" (in_madrid dst_spring_after_transition);
    test "fall: before transition" (in_madrid dst_fall_before_transition);
    test "fall: ambiguity uses earlier instant" (in_madrid dst_fall_ambiguous);
    test "fall: after transition" (in_madrid dst_fall_after_transition);
    (* constructors and setters *)
    test "make uses LocalTZA" (in_madrid make_uses_local_tza);
    test "make in DST gap" (in_madrid make_in_dst_gap_uses_pre_transition_offset);
    test "make in DST ambiguity" (in_madrid make_in_dst_ambiguity_uses_earlier_instant);
    test "setHours across DST" (in_madrid set_hours_across_dst);
    (* formatter round-trips *)
    test "toString roundtrip in Madrid" (in_madrid to_string_roundtrip_in_madrid);
    test "toUTCString roundtrip in Madrid" (in_madrid to_utc_string_roundtrip_in_madrid);
  ]

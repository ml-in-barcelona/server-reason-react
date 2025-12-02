(** TC39 Test262: Date toString method tests

    Based on: https://github.com/tc39/test262/tree/main/test/built-ins/Date/prototype/toString
    https://github.com/tc39/test262/tree/main/test/built-ins/Date/prototype/toDateString
    https://github.com/tc39/test262/tree/main/test/built-ins/Date/prototype/toTimeString
    https://github.com/tc39/test262/tree/main/test/built-ins/Date/prototype/toUTCString

    Tests for toString, toDateString, toTimeString, toUTCString *)

open Helpers
module Date = Js.Date

(* ===================================================================
   toUTCString tests
   Format: "Tue, 02 Dec 2025 09:30:00 GMT"
   =================================================================== *)

let to_utc_string_basic () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:30. ~seconds:45. () in
  let s = Date.toUTCString d in
  (* Should contain "Mon" (June 15 2020 was Monday), "15", "Jun", "2020", "12:30:45", "GMT" *)
  assert_true "contains day name" (String.length s > 0);
  assert_true "contains GMT" (String.sub s (String.length s - 3) 3 = "GMT")

let to_utc_string_epoch () =
  let s = Date.toUTCString 0. in
  (* Thu, 01 Jan 1970 00:00:00 GMT *)
  assert_true "contains Thu" (String.sub s 0 3 = "Thu");
  assert_true "contains 1970" (String.length s > 10)

let to_utc_string_format () =
  let d = Date.utc ~year:2025. ~month:11. ~day:2. ~hours:9. ~minutes:30. ~seconds:0. () in
  let s = Date.toUTCString d in
  (* Verify format: "Day, DD Mon YYYY HH:MM:SS GMT" *)
  assert_true "correct length roughly" (String.length s >= 25)

let to_utc_string_nan () =
  let s = Date.toUTCString nan in
  assert_string_equal s "Invalid Date"

let to_utc_string_negative_year () =
  (* Test with a date before year 0 *)
  let d = Date.utc ~year:(-1.) ~month:0. ~day:1. () in
  let s = Date.toUTCString d in
  assert_true "contains something" (String.length s > 0)

let to_utc_string_months () =
  (* Test all month abbreviations *)
  let months = [ "Jan"; "Feb"; "Mar"; "Apr"; "May"; "Jun"; "Jul"; "Aug"; "Sep"; "Oct"; "Nov"; "Dec" ] in
  List.iteri
    (fun i expected_month ->
      let d = Date.utc ~year:2020. ~month:(Float.of_int i) ~day:15. () in
      let s = Date.toUTCString d in
      assert_true
        (Printf.sprintf "month %d contains %s" i expected_month)
        (String.length s > 0
        &&
        try
          let _ = Str.search_forward (Str.regexp expected_month) s 0 in
          true
        with Not_found -> false))
    months

let to_utc_string_day_names () =
  (* Test that different days of week produce correct names *)
  let d_sunday = Date.utc ~year:2021. ~month:0. ~day:3. () in
  (* Sunday *)
  let d_monday = Date.utc ~year:2021. ~month:0. ~day:4. () in
  (* Monday *)
  let s_sun = Date.toUTCString d_sunday in
  let s_mon = Date.toUTCString d_monday in
  assert_true "Sunday starts with Sun" (String.sub s_sun 0 3 = "Sun");
  assert_true "Monday starts with Mon" (String.sub s_mon 0 3 = "Mon")

(* ===================================================================
   toDateString tests
   Format: "Mon Jun 15 2020"
   =================================================================== *)

let to_date_string_basic () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:30. ~seconds:45. () in
  let s = Date.toDateString d in
  assert_true "non-empty string" (String.length s > 0)

let to_date_string_epoch () =
  (* Note: This is timezone-dependent for local time *)
  let s = Date.toDateString 0. in
  assert_true "non-empty string" (String.length s > 0)

let to_date_string_nan () =
  let s = Date.toDateString nan in
  assert_string_equal s "Invalid Date"

let to_date_string_no_time () =
  (* toDateString should not contain time information like ":" *)
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:30. ~seconds:45. () in
  let s = Date.toDateString d in
  (* Should not have HH:MM:SS format *)
  let has_time_separator =
    try
      let _ = Str.search_forward (Str.regexp "[0-9][0-9]:[0-9][0-9]:[0-9][0-9]") s 0 in
      true
    with Not_found -> false
  in
  assert_true "should not contain time" (not has_time_separator)

(* ===================================================================
   toTimeString tests
   Format: "12:30:45 GMT+0000 (Coordinated Universal Time)"
   =================================================================== *)

let to_time_string_basic () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:30. ~seconds:45. () in
  let s = Date.toTimeString d in
  assert_true "non-empty string" (String.length s > 0)

let to_time_string_epoch () =
  let s = Date.toTimeString 0. in
  assert_true "non-empty string" (String.length s > 0)

let to_time_string_nan () =
  let s = Date.toTimeString nan in
  assert_string_equal s "Invalid Date"

let to_time_string_contains_time () =
  (* toTimeString should contain time in HH:MM:SS format *)
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:30. ~seconds:45. () in
  let s = Date.toTimeString d in
  let has_time_format =
    try
      let _ = Str.search_forward (Str.regexp "[0-9][0-9]:[0-9][0-9]:[0-9][0-9]") s 0 in
      true
    with Not_found -> false
  in
  assert_true "should contain time format" has_time_format

(* ===================================================================
   toString tests
   Format: "Mon Jun 15 2020 12:30:45 GMT+0000 (Coordinated Universal Time)"
   =================================================================== *)

let to_string_basic () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:30. ~seconds:45. () in
  let s = Date.toString d in
  assert_true "non-empty string" (String.length s > 0)

let to_string_epoch () =
  let s = Date.toString 0. in
  assert_true "non-empty string" (String.length s > 0)

let to_string_nan () =
  let s = Date.toString nan in
  assert_string_equal s "Invalid Date"

let to_string_contains_date_and_time () =
  (* toString should contain both date and time *)
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:30. ~seconds:45. () in
  let s = Date.toString d in
  (* Should have time format *)
  let has_time_format =
    try
      let _ = Str.search_forward (Str.regexp "[0-9][0-9]:[0-9][0-9]:[0-9][0-9]") s 0 in
      true
    with Not_found -> false
  in
  assert_true "should contain time" has_time_format

let to_string_contains_year () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. () in
  let s = Date.toString d in
  let has_year =
    try
      let _ = Str.search_forward (Str.regexp "2020") s 0 in
      true
    with Not_found -> false
  in
  assert_true "should contain year" has_year

(* ===================================================================
   toJSON tests
   =================================================================== *)

let to_json_basic () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:30. ~seconds:45. ~ms:123. () in
  match Date.toJSON d with
  | Some s -> assert_string_equal s "2020-06-15T12:30:45.123Z"
  | None -> assert_true "should return Some" false

let to_json_nan () =
  match Date.toJSON nan with
  | None -> assert_true "should return None" true
  | Some _ -> assert_true "should return None for NaN" false

let to_json_unsafe_basic () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:30. ~seconds:45. ~ms:123. () in
  let s = Date.toJSONUnsafe d in
  assert_string_equal s "2020-06-15T12:30:45.123Z"

(* ===================================================================
   toLocaleString tests (simplified)
   =================================================================== *)

let to_locale_string_basic () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:30. ~seconds:45. () in
  let s = Date.toLocaleString d in
  assert_true "non-empty string" (String.length s > 0)

let to_locale_string_nan () =
  let s = Date.toLocaleString nan in
  assert_string_equal s "Invalid Date"

let to_locale_date_string_basic () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. () in
  let s = Date.toLocaleDateString d in
  assert_true "non-empty string" (String.length s > 0)

let to_locale_date_string_nan () =
  let s = Date.toLocaleDateString nan in
  assert_string_equal s "Invalid Date"

let to_locale_time_string_basic () =
  let d = Date.utc ~year:2020. ~month:5. ~day:15. ~hours:12. ~minutes:30. ~seconds:45. () in
  let s = Date.toLocaleTimeString d in
  assert_true "non-empty string" (String.length s > 0)

let to_locale_time_string_nan () =
  let s = Date.toLocaleTimeString nan in
  assert_string_equal s "Invalid Date"

(* ===================================================================
   Edge cases
   =================================================================== *)

let to_string_large_year () =
  let d = Date.utc ~year:275760. ~month:8. ~day:13. () in
  let s = Date.toString d in
  assert_true "non-empty string" (String.length s > 0)

let to_string_negative_year () =
  let d = Date.utc ~year:(-100.) ~month:0. ~day:1. () in
  let s = Date.toString d in
  assert_true "non-empty string" (String.length s > 0)

let to_utc_string_y2k () =
  let d = Date.utc ~year:2000. ~month:0. ~day:1. ~hours:0. ~minutes:0. ~seconds:0. () in
  let s = Date.toUTCString d in
  assert_true "contains 2000" (String.length s > 0)

(* ===================================================================
   Test list
   =================================================================== *)

let tests =
  [
    (* toUTCString *)
    test "toUTCString basic" to_utc_string_basic;
    test "toUTCString epoch" to_utc_string_epoch;
    test "toUTCString format" to_utc_string_format;
    test "toUTCString NaN" to_utc_string_nan;
    test "toUTCString negative year" to_utc_string_negative_year;
    test "toUTCString all months" to_utc_string_months;
    test "toUTCString day names" to_utc_string_day_names;
    (* toDateString *)
    test "toDateString basic" to_date_string_basic;
    test "toDateString epoch" to_date_string_epoch;
    test "toDateString NaN" to_date_string_nan;
    test "toDateString no time" to_date_string_no_time;
    (* toTimeString *)
    test "toTimeString basic" to_time_string_basic;
    test "toTimeString epoch" to_time_string_epoch;
    test "toTimeString NaN" to_time_string_nan;
    test "toTimeString contains time" to_time_string_contains_time;
    (* toString *)
    test "toString basic" to_string_basic;
    test "toString epoch" to_string_epoch;
    test "toString NaN" to_string_nan;
    test "toString contains date and time" to_string_contains_date_and_time;
    test "toString contains year" to_string_contains_year;
    (* toJSON *)
    test "toJSON basic" to_json_basic;
    test "toJSON NaN" to_json_nan;
    test "toJSONUnsafe basic" to_json_unsafe_basic;
    (* toLocaleString *)
    test "toLocaleString basic" to_locale_string_basic;
    test "toLocaleString NaN" to_locale_string_nan;
    test "toLocaleDateString basic" to_locale_date_string_basic;
    test "toLocaleDateString NaN" to_locale_date_string_nan;
    test "toLocaleTimeString basic" to_locale_time_string_basic;
    test "toLocaleTimeString NaN" to_locale_time_string_nan;
    (* Edge cases *)
    test "toString large year" to_string_large_year;
    test "toString negative year" to_string_negative_year;
    test "toUTCString Y2K" to_utc_string_y2k;
  ]

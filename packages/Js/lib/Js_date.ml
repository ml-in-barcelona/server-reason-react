(** JavaScript Date implementation following ECMA-262 §21.4

    This is a spec-compliant implementation using only OCaml stdlib + Unix. Internal representation: float (milliseconds
    since Unix epoch, or NaN for invalid dates). *)

type t = float
(** Milliseconds since Unix epoch (1970-01-01T00:00:00.000Z), or NaN for invalid dates *)

(* Time constants (§21.4.1.3) *)

let ms_per_second = 1000.
let ms_per_minute = 60000.
let ms_per_hour = 3600000.
let ms_per_day = 86400000.

(* Validity checking *)

(** Maximum time value: ±8.64e15 ms (±100 million days from epoch) *)
let max_time_value = 8.64e15

let is_valid_time t = (not (Float.is_nan t)) && Float.abs t <= max_time_value

(* Day/Time decomposition (§21.4.1.3-13) *)

(** Day(t) = floor(t / msPerDay) - day number since epoch *)
let day t = Float.floor (t /. ms_per_day)

(** TimeWithinDay(t) = t modulo msPerDay *)
let time_within_day t =
  let r = Float.rem t ms_per_day in
  if r < 0. then r +. ms_per_day else r

(** DaysInYear(y) = 365 or 366 *)
let days_in_year y =
  if Float.rem y 4. <> 0. then 365
  else if Float.rem y 100. <> 0. then 366
  else if Float.rem y 400. <> 0. then 365
  else 366

(** DayFromYear(y) = days since epoch for Jan 1 of year y *)
let day_from_year y =
  let y = y -. 1970. in
  (365. *. y) +. Float.floor ((y +. 1.) /. 4.) -. Float.floor ((y +. 69.) /. 100.) +. Float.floor ((y +. 369.) /. 400.)

(** YearFromTime(t) - extract year from timestamp using binary search *)
let year_from_time t =
  if Float.is_nan t then nan
  else
    let d = day t in
    (* Estimate year: Unix epoch is 1970, ~365.25 days per year *)
    let estimate = 1970. +. Float.floor (d /. 365.2425) in
    (* Binary search for the correct year *)
    let rec search lo hi =
      if lo >= hi then lo
      else
        let mid = Float.floor ((lo +. hi +. 1.) /. 2.) in
        if day_from_year mid <= d then search mid hi else search lo (mid -. 1.)
    in
    (* Search in a reasonable range around the estimate *)
    search (estimate -. 2.) (estimate +. 2.)

(** InLeapYear(t) - is the year containing t a leap year? *)
let in_leap_year t = days_in_year (year_from_time t) = 366

(** DayWithinYear(t) = day number within the year (0 = Jan 1) *)
let day_within_year t =
  let d = day t in
  let y = year_from_time t in
  d -. day_from_year y

(** Days in each month for non-leap years (cumulative from start of year) *)
let month_start_days = [| 0; 31; 59; 90; 120; 151; 181; 212; 243; 273; 304; 334; 365 |]

let month_start_days_leap = [| 0; 31; 60; 91; 121; 152; 182; 213; 244; 274; 305; 335; 366 |]

(** MonthFromTime(t) - returns month 0-11 *)
let month_from_time t =
  if Float.is_nan t then nan
  else
    let d = int_of_float (day_within_year t) in
    let table = if in_leap_year t then month_start_days_leap else month_start_days in
    let rec find_month m = if m >= 11 then 11 else if d < table.(m + 1) then m else find_month (m + 1) in
    Float.of_int (find_month 0)

(** DateFromTime(t) - returns day of month 1-31 *)
let date_from_time t =
  if Float.is_nan t then nan
  else
    let d = int_of_float (day_within_year t) in
    let m = int_of_float (month_from_time t) in
    let table = if in_leap_year t then month_start_days_leap else month_start_days in
    Float.of_int (d - table.(m) + 1)

(** WeekDay(t) - returns 0=Sunday through 6=Saturday *)
let week_day t =
  if Float.is_nan t then nan
  else
    let d = day t +. 4. in
    (* Jan 1, 1970 was Thursday (day 4) *)
    let r = Float.rem d 7. in
    if r < 0. then r +. 7. else r

(** HourFromTime(t) - returns 0-23 *)
let hour_from_time t =
  if Float.is_nan t then nan
  else
    let r = Float.rem (Float.floor (t /. ms_per_hour)) 24. in
    if r < 0. then r +. 24. else r

(** MinFromTime(t) - returns 0-59 *)
let min_from_time t =
  if Float.is_nan t then nan
  else
    let r = Float.rem (Float.floor (t /. ms_per_minute)) 60. in
    if r < 0. then r +. 60. else r

(** SecFromTime(t) - returns 0-59 *)
let sec_from_time t =
  if Float.is_nan t then nan
  else
    let r = Float.rem (Float.floor (t /. ms_per_second)) 60. in
    if r < 0. then r +. 60. else r

(** msFromTime(t) - returns 0-999 *)
let ms_from_time t =
  if Float.is_nan t then nan
  else
    let r = Float.rem t ms_per_second in
    if r < 0. then r +. ms_per_second else r

(* MakeTime / MakeDay / MakeDate (§21.4.1.14-16) *)

(** MakeTime(hour, min, sec, ms) - combines time components into ms *)
let make_time ~hour ~min ~sec ~ms =
  if Float.is_nan hour || Float.is_nan min || Float.is_nan sec || Float.is_nan ms then nan
  else
    let h = Float.trunc hour in
    let m = Float.trunc min in
    let s = Float.trunc sec in
    let milli = Float.trunc ms in
    (h *. ms_per_hour) +. (m *. ms_per_minute) +. (s *. ms_per_second) +. milli

(** MakeDay(year, month, date) - returns day number *)
let make_day ~year ~month ~date =
  if Float.is_nan year || Float.is_nan month || Float.is_nan date then nan
  else if (not (Float.is_finite year)) || (not (Float.is_finite month)) || not (Float.is_finite date) then nan
  else
    let y = Float.trunc year in
    let m = Float.trunc month in
    let dt = Float.trunc date in
    (* Normalize month: add years for month overflow *)
    let ym = y +. Float.floor (m /. 12.) in
    let mn = Float.rem m 12. in
    let mn = if mn < 0. then mn +. 12. else mn in
    (* Get day number for start of year *)
    let d = day_from_year ym in
    (* Add days for months *)
    let is_leap = days_in_year ym = 366 in
    let month_table = if is_leap then month_start_days_leap else month_start_days in
    let d = d +. Float.of_int month_table.(int_of_float mn) in
    (* Add date (date is 1-based, so subtract 1) *)
    d +. dt -. 1.

(** MakeDate(day, time) - combines day and time into timestamp *)
let make_date ~day ~time =
  if Float.is_nan day || Float.is_nan time then nan
  else if (not (Float.is_finite day)) || not (Float.is_finite time) then nan
  else (day *. ms_per_day) +. time

(** TimeClip(time) - clamps to valid range or returns NaN *)
let time_clip t =
  if Float.is_nan t then nan
  else if not (Float.is_finite t) then nan
  else if Float.abs t > max_time_value then nan
  else Float.trunc t

(* Timezone handling (§21.4.1.18-19) *)

(** Get local timezone offset in milliseconds for a given UTC time. Uses Unix.localtime to determine DST-aware offset.
*)
let local_tz_offset_ms utc_time =
  if Float.is_nan utc_time then 0.
  else
    let seconds = utc_time /. 1000. in
    try
      let local_tm = Unix.localtime seconds in
      let utc_tm = Unix.gmtime seconds in
      (* Calculate difference in seconds *)
      let local_secs = (local_tm.Unix.tm_hour * 3600) + (local_tm.Unix.tm_min * 60) + local_tm.Unix.tm_sec in
      let utc_secs = (utc_tm.Unix.tm_hour * 3600) + (utc_tm.Unix.tm_min * 60) + utc_tm.Unix.tm_sec in
      let day_diff = local_tm.Unix.tm_yday - utc_tm.Unix.tm_yday in
      let day_diff = if day_diff > 1 then -1 else if day_diff < -1 then 1 else day_diff in
      Float.of_int ((day_diff * 86400) + local_secs - utc_secs) *. 1000.
    with _ -> 0.

(** Convert UTC time to local time *)
let utc_to_local t = if Float.is_nan t then nan else t +. local_tz_offset_ms t

(** Convert local time to UTC *)
let local_to_utc t = if Float.is_nan t then nan else t -. local_tz_offset_ms t

(* Constructors *)

(** Create a Date from epoch milliseconds *)
let of_epoch_ms ms = time_clip ms

(** Date.now() - returns current time as epoch ms *)
let now () =
  let t = Unix.gettimeofday () in
  Float.trunc (t *. 1000.)

(** Date.UTC(year, month[, date[, hours[, minutes[, seconds[, ms]]]]]) *)
let utc ~year ~month ?(day = 1.) ?(hours = 0.) ?(minutes = 0.) ?(seconds = 0.) ?(ms = 0.) () =
  (* Handle year 0-99 -> 1900-1999 mapping *)
  let y =
    if Float.is_nan year then nan
    else
      let y = Float.trunc year in
      if y >= 0. && y <= 99. then 1900. +. y else y
  in
  let m = if Float.is_nan month then nan else Float.trunc month in
  let d = make_day ~year:y ~month:m ~date:day in
  let t = make_time ~hour:hours ~min:minutes ~sec:seconds ~ms in
  time_clip (make_date ~day:d ~time:t)

(* Getters - UTC *)

let getTime t = t
let valueOf t = t
let getUTCFullYear t = if Float.is_nan t then nan else year_from_time t
let getUTCMonth t = if Float.is_nan t then nan else month_from_time t
let getUTCDate t = if Float.is_nan t then nan else date_from_time t
let getUTCDay t = if Float.is_nan t then nan else week_day t
let getUTCHours t = if Float.is_nan t then nan else hour_from_time t
let getUTCMinutes t = if Float.is_nan t then nan else min_from_time t
let getUTCSeconds t = if Float.is_nan t then nan else sec_from_time t
let getUTCMilliseconds t = if Float.is_nan t then nan else ms_from_time t

(* Getters - Local time *)

let getFullYear t = if Float.is_nan t then nan else year_from_time (utc_to_local t)
let getMonth t = if Float.is_nan t then nan else month_from_time (utc_to_local t)
let getDate t = if Float.is_nan t then nan else date_from_time (utc_to_local t)
let getDay t = if Float.is_nan t then nan else week_day (utc_to_local t)
let getHours t = if Float.is_nan t then nan else hour_from_time (utc_to_local t)
let getMinutes t = if Float.is_nan t then nan else min_from_time (utc_to_local t)
let getSeconds t = if Float.is_nan t then nan else sec_from_time (utc_to_local t)
let getMilliseconds t = if Float.is_nan t then nan else ms_from_time (utc_to_local t)

(** getTimezoneOffset() - returns offset in minutes (positive = west of UTC) *)
let getTimezoneOffset t = if Float.is_nan t then nan else -.local_tz_offset_ms t /. ms_per_minute

(* String formatting *)

(** Zero-pad an integer to n digits *)
let pad n i =
  let s = string_of_int (abs i) in
  let len = String.length s in
  if len >= n then s else String.make (n - len) '0' ^ s

(** Format year for ISO string: 4 digits normally, 6 with +/- for years outside 0-9999 *)
let format_year year =
  let y = int_of_float year in
  if y >= 0 && y <= 9999 then pad 4 y
  else if y < 0 then Printf.sprintf "-%s" (pad 6 (-y))
  else Printf.sprintf "+%s" (pad 6 y)

(** toISOString() - returns ISO 8601 format: YYYY-MM-DDTHH:mm:ss.sssZ *)
let toISOString t =
  if Float.is_nan t then raise (Invalid_argument "Invalid Date")
  else if not (is_valid_time t) then raise (Invalid_argument "Invalid Date")
  else
    let year = year_from_time t in
    let month = int_of_float (month_from_time t) + 1 in
    let day = int_of_float (date_from_time t) in
    let hours = int_of_float (hour_from_time t) in
    let minutes = int_of_float (min_from_time t) in
    let seconds = int_of_float (sec_from_time t) in
    let ms = int_of_float (ms_from_time t) in
    Printf.sprintf "%s-%s-%sT%s:%s:%s.%sZ" (format_year year) (pad 2 month) (pad 2 day) (pad 2 hours) (pad 2 minutes)
      (pad 2 seconds) (pad 3 ms)

(** toJSON() - returns ISO string or None for invalid date *)
let toJSON t = if Float.is_nan t || not (is_valid_time t) then None else Some (toISOString t)

(** toJSONUnsafe() - returns ISO string, throws for invalid *)
let toJSONUnsafe t = toISOString t

(** Helper: day name abbreviations *)
let day_names = [| "Sun"; "Mon"; "Tue"; "Wed"; "Thu"; "Fri"; "Sat" |]

(** Helper: month name abbreviations *)
let month_names = [| "Jan"; "Feb"; "Mar"; "Apr"; "May"; "Jun"; "Jul"; "Aug"; "Sep"; "Oct"; "Nov"; "Dec" |]

(** Format timezone offset as ±HHMM *)
let format_tz_offset offset_ms =
  let offset_min = int_of_float (offset_ms /. ms_per_minute) in
  let sign = if offset_min >= 0 then "+" else "-" in
  let abs_offset = abs offset_min in
  let hours = abs_offset / 60 in
  let mins = abs_offset mod 60 in
  Printf.sprintf "GMT%s%s%s" sign (pad 2 hours) (pad 2 mins)

(** toUTCString() - returns RFC 7231 format: "Tue, 02 Dec 2025 09:30:00 GMT" *)
let toUTCString t =
  if Float.is_nan t then "Invalid Date"
  else
    let day_name = day_names.(int_of_float (week_day t)) in
    let day = int_of_float (date_from_time t) in
    let month_name = month_names.(int_of_float (month_from_time t)) in
    let year = int_of_float (year_from_time t) in
    let hours = int_of_float (hour_from_time t) in
    let minutes = int_of_float (min_from_time t) in
    let seconds = int_of_float (sec_from_time t) in
    Printf.sprintf "%s, %s %s %d %s:%s:%s GMT" day_name (pad 2 day) month_name year (pad 2 hours) (pad 2 minutes)
      (pad 2 seconds)

(** toDateString() - returns "Tue Dec 02 2025" format *)
let toDateString t =
  if Float.is_nan t then "Invalid Date"
  else
    let local = utc_to_local t in
    let day_name = day_names.(int_of_float (week_day local)) in
    let month_name = month_names.(int_of_float (month_from_time local)) in
    let day = int_of_float (date_from_time local) in
    let year = int_of_float (year_from_time local) in
    Printf.sprintf "%s %s %s %d" day_name month_name (pad 2 day) year

(** toTimeString() - returns "10:30:00 GMT+0100" format *)
let toTimeString t =
  if Float.is_nan t then "Invalid Date"
  else
    let local = utc_to_local t in
    let hours = int_of_float (hour_from_time local) in
    let minutes = int_of_float (min_from_time local) in
    let seconds = int_of_float (sec_from_time local) in
    let tz = format_tz_offset (local_tz_offset_ms t) in
    Printf.sprintf "%s:%s:%s %s" (pad 2 hours) (pad 2 minutes) (pad 2 seconds) tz

(** toString() - returns "Tue Dec 02 2025 10:30:00 GMT+0100" format *)
let toString t = if Float.is_nan t then "Invalid Date" else Printf.sprintf "%s %s" (toDateString t) (toTimeString t)

(** toLocaleString, toLocaleDateString, toLocaleTimeString - simplified implementations *)
let toLocaleString t = toString t

let toLocaleDateString t = toDateString t
let toLocaleTimeString t = toTimeString t

(* Date parsing (§21.4.3.2) *)

(** Helper: parse integer from string, returns None on failure *)
let parse_int_opt s = try Some (int_of_string s) with _ -> None

(** Parse ISO 8601 date string. Formats:
    - YYYY
    - YYYY-MM
    - YYYY-MM-DD
    - YYYY-MM-DDTHH:mm
    - YYYY-MM-DDTHH:mm:ss
    - YYYY-MM-DDTHH:mm:ss.sss
    - Above with Z or ±HH:mm timezone

    The parsing proceeds in stages: year -> month -> day -> time -> timezone
    Each stage either returns early with a valid date or continues parsing. *)

(** Monadic bind for Option - allows flat chaining with let* *)
let ( let* ) = Option.bind

(** Guard: returns Some () if condition is true, None otherwise *)
let guard condition = if condition then Some () else None

(** Try to read n characters starting at pos, returns None if out of bounds *)
let read_chars s ~pos ~len:n =
  if pos + n > String.length s then None else Some (String.sub s pos n)

(** Parse an integer within bounds (inclusive) *)
let parse_int_in_range s ~min ~max =
  let* value = parse_int_opt s in
  let* () = guard (value >= min && value <= max) in
  Some value

(** Parse the year component (handles expanded years like +YYYYYY or -YYYYYY) *)
let parse_year s =
  let len = String.length s in
  if len = 0 then None
  else
    (* Determine year format: expanded (+/-YYYYYY) or standard (YYYY) *)
    let sign, start, digits =
      match s.[0] with
      | '+' -> (1., 1, 6)
      | '-' -> (-1., 1, 6)
      | _ -> (1., 0, 4)
    in
    let* year_str = read_chars s ~pos:start ~len:digits in
    let* year_int = parse_int_opt year_str in
    (* Reject -000000 as invalid *)
    let* () = guard (not (sign < 0. && year_int = 0)) in
    let year = sign *. Float.of_int year_int in
    let next_pos = start + digits in
    Some (year, next_pos)

(** Parse a 2-digit component with delimiter check *)
let parse_2digit_component s ~pos ~delimiter ~min ~max =
  let len = String.length s in
  if pos >= len then None
  else if s.[pos] <> delimiter then None
  else
    let pos = pos + 1 in
    let* component_str = read_chars s ~pos ~len:2 in
    let* value = parse_int_in_range component_str ~min ~max in
    Some (value, pos + 2)

(** Parse optional seconds (:SS) *)
let parse_seconds s ~pos =
  let len = String.length s in
  if pos >= len || s.[pos] <> ':' then Some (0., pos)
  else
    let pos = pos + 1 in
    match read_chars s ~pos ~len:2 with
    | None -> None (* Started with ':' but no digits - invalid *)
    | Some sec_str -> (
        match parse_int_in_range sec_str ~min:0 ~max:59 with
        | None -> None
        | Some sec -> Some (Float.of_int sec, pos + 2))

(** Parse optional milliseconds (.sss) - reads up to 3 digits, pads if needed *)
let parse_milliseconds s ~pos =
  let len = String.length s in
  if pos >= len || s.[pos] <> '.' then (0., pos)
  else
    let pos = pos + 1 in
    (* Read all consecutive digits *)
    let ms_start = pos in
    let rec count_digits p = if p < len && s.[p] >= '0' && s.[p] <= '9' then count_digits (p + 1) else p in
    let ms_end = count_digits ms_start in
    let digit_count = ms_end - ms_start in
    if digit_count = 0 then (0., ms_end)
    else
      (* Take up to 3 digits and pad to 3 if needed *)
      let ms_str = String.sub s ms_start (min digit_count 3) in
      let ms_str =
        let pad_len = 3 - String.length ms_str in
        if pad_len > 0 then ms_str ^ String.make pad_len '0' else ms_str
      in
      let ms = match parse_int_opt ms_str with Some v -> Float.of_int v | None -> 0. in
      (ms, ms_end)

(** Parse timezone: Z, +HH:mm, or -HH:mm. Returns offset in milliseconds *)
let parse_timezone s ~pos =
  let len = String.length s in
  if pos >= len then (0., pos)
  else
    match s.[pos] with
    | 'Z' -> (0., pos + 1)
    | ('+' | '-') as sign_char ->
        let sign = if sign_char = '-' then -1. else 1. in
        let pos = pos + 1 in
        (* Parse hours *)
        let tz_hours, pos =
          match read_chars s ~pos ~len:2 with
          | Some h_str -> (
              match parse_int_opt h_str with Some h -> (Float.of_int h, pos + 2) | None -> (0., pos))
          | None -> (0., pos)
        in
        (* Parse optional minutes *)
        let tz_minutes, pos =
          if pos < len && s.[pos] = ':' then
            let pos = pos + 1 in
            match read_chars s ~pos ~len:2 with
            | Some m_str -> (
                match parse_int_opt m_str with Some m -> (Float.of_int m, pos + 2) | None -> (0., pos))
            | None -> (0., pos)
          else (0., pos)
        in
        let offset_ms = sign *. ((tz_hours *. ms_per_hour) +. (tz_minutes *. ms_per_minute)) in
        (offset_ms, pos)
    | _ -> (0., pos)

(** Parse the time portion: HH:mm[:ss[.sss]][timezone] *)
let parse_time s ~pos ~year ~month ~day =
  let len = String.length s in
  (* Expect 'T' or space separator *)
  if pos >= len then Some (utc ~year ~month ~day ())
  else if s.[pos] <> 'T' && s.[pos] <> ' ' then None
  else
    let pos = pos + 1 in
    (* Parse hours *)
    let* hours_str = read_chars s ~pos ~len:2 in
    let* hours_int = parse_int_in_range hours_str ~min:0 ~max:24 in
    let hours = Float.of_int hours_int in
    let pos = pos + 2 in
    (* Expect ':' before minutes *)
    let* () = guard (pos < len && s.[pos] = ':') in
    let pos = pos + 1 in
    (* Parse minutes *)
    let* minutes_str = read_chars s ~pos ~len:2 in
    let* minutes_int = parse_int_in_range minutes_str ~min:0 ~max:59 in
    let minutes = Float.of_int minutes_int in
    let pos = pos + 2 in
    (* Parse optional seconds *)
    let* seconds, pos = parse_seconds s ~pos in
    (* Parse optional milliseconds *)
    let ms, pos = parse_milliseconds s ~pos in
    (* Parse optional timezone *)
    let tz_offset_ms, _pos = parse_timezone s ~pos in
    (* Validate: hour 24 is only valid with 00:00:00.000 *)
    let* () = guard (not (hours_int = 24 && (minutes_int <> 0 || seconds <> 0. || ms <> 0.))) in
    let result = utc ~year ~month ~day ~hours ~minutes ~seconds ~ms () in
    Some (result -. tz_offset_ms)

let parse_iso8601 s =
  let len = String.length s in
  if len = 0 then None
  else
    (* Step 1: Parse the year *)
    let* year, pos = parse_year s in
    (* If nothing left, we have just a year *)
    if pos >= len then Some (utc ~year ~month:0. ())
    else
      (* Step 2: Parse the month (expects '-MM') *)
      let* month_int, pos = parse_2digit_component s ~pos ~delimiter:'-' ~min:1 ~max:12 in
      let month = Float.of_int (month_int - 1) in
      (* If nothing left, we have year-month *)
      if pos >= len then Some (utc ~year ~month ())
      else
        (* Step 3: Parse the day (expects '-DD') *)
        let* day_int, pos = parse_2digit_component s ~pos ~delimiter:'-' ~min:1 ~max:31 in
        let day = Float.of_int day_int in
        (* Step 4: Parse optional time portion *)
        parse_time s ~pos ~year ~month ~day

(** Parse legacy date formats (toString/toUTCString style). Examples:
    - "Jan 1 2000"
    - "Jan 1 2000 00:00:00"
    - "Jan 1 2000 00:00:00 GMT"
    - "Sat Jan 1 2000 00:00:00 GMT"
    - "Jan 1 2000 00:00:00 GMT+0100"

    The format is: [Weekday] Month Day Year [HH:mm:ss] [GMT±HHMM] *)

let weekdays = [ "Sun"; "Mon"; "Tue"; "Wed"; "Thu"; "Fri"; "Sat" ]

(** Strip optional weekday prefix from legacy date string *)
let strip_weekday s =
  let parts = String.split_on_char ' ' (String.trim s) in
  match parts with
  | day :: rest when List.mem day weekdays -> String.concat " " rest
  | _ -> s

(** Parse month name to 0-indexed month number *)
let parse_month_name name =
  Array.find_index (fun m -> String.equal m name) month_names |> Option.map Float.of_int

(** Parse GMT±HHMM timezone offset string, returns offset in milliseconds *)
let parse_gmt_offset tz_str =
  let len = String.length tz_str in
  (* Must start with "GMT" *)
  if len < 3 || String.sub tz_str 0 3 <> "GMT" then 0.
  else
    let tz_part = String.sub tz_str 3 (len - 3) in
    (* Need at least ±HHMM (5 chars) *)
    if String.length tz_part < 5 then 0.
    else
      let sign = if tz_part.[0] = '-' then -1. else 1. in
      let h_str = String.sub tz_part 1 2 in
      let m_str = String.sub tz_part 3 2 in
      match (parse_int_opt h_str, parse_int_opt m_str) with
      | Some h, Some m -> sign *. ((Float.of_int h *. ms_per_hour) +. (Float.of_int m *. ms_per_minute))
      | _ -> 0.

(** Parse time string "HH:mm:ss" into (hours, minutes, seconds) *)
let parse_time_string time_str =
  match String.split_on_char ':' time_str with
  | [ h; m; s ] -> (
      match (parse_int_opt h, parse_int_opt m, parse_int_opt s) with
      | Some hi, Some mi, Some si -> Some (Float.of_int hi, Float.of_int mi, Float.of_int si)
      | _ -> None)
  | _ -> None

(** Parse optional time and timezone from remaining parts *)
let parse_legacy_time_and_tz rest =
  match rest with
  | [] -> (0., 0., 0., 0.)
  | time_str :: tz_rest -> (
      match parse_time_string time_str with
      | Some (hours, minutes, seconds) ->
          let tz_offset = match tz_rest with [] -> 0. | tz_str :: _ -> parse_gmt_offset tz_str in
          (hours, minutes, seconds, tz_offset)
      | None -> (0., 0., 0., 0.))

let parse_legacy s =
  (* Step 1: Strip optional weekday *)
  let s = strip_weekday s in
  let parts = String.split_on_char ' ' (String.trim s) in
  (* Step 2: Extract month, day, year from parts *)
  match parts with
  | month_str :: day_str :: year_str :: rest ->
      (* Step 3: Parse month name *)
      let* month = parse_month_name month_str in
      (* Step 4: Parse day and year as integers *)
      let* day_int = parse_int_opt day_str in
      let* year_int = parse_int_opt year_str in
      let day = Float.of_int day_int in
      let year = Float.of_int year_int in
      (* Step 5: Parse optional time and timezone *)
      let hours, minutes, seconds, tz_offset = parse_legacy_time_and_tz rest in
      (* Step 6: Construct the date and apply timezone offset *)
      let result = utc ~year ~month ~day ~hours ~minutes ~seconds () in
      Some (result -. tz_offset)
  | _ -> None

(** Date.parse(string) - parses a date string and returns epoch ms (or NaN) *)
let parse s =
  let s = String.trim s in
  if String.length s = 0 then nan
  else match parse_iso8601 s with Some t -> t | None -> ( match parse_legacy s with Some t -> t | None -> nan)

(** parseAsFloat - same as parse, for API compatibility *)
let parseAsFloat = parse

(* Additional constructors for API compatibility *)

let make () = of_epoch_ms (now ())
let fromFloat = of_epoch_ms
let fromString s = of_epoch_ms (parse s)

(** makeWith* - create Date with local time components *)
let makeWithYM ~year ~month =
  let y = if year >= 0. && year <= 99. then 1900. +. year else year in
  let d = make_day ~year:y ~month ~date:1. in
  let t = make_time ~hour:0. ~min:0. ~sec:0. ~ms:0. in
  time_clip (local_to_utc (make_date ~day:d ~time:t))

let makeWithYMD ~year ~month ~date =
  let y = if year >= 0. && year <= 99. then 1900. +. year else year in
  let d = make_day ~year:y ~month ~date in
  let t = make_time ~hour:0. ~min:0. ~sec:0. ~ms:0. in
  time_clip (local_to_utc (make_date ~day:d ~time:t))

let makeWithYMDH ~year ~month ~date ~hours =
  let y = if year >= 0. && year <= 99. then 1900. +. year else year in
  let d = make_day ~year:y ~month ~date in
  let t = make_time ~hour:hours ~min:0. ~sec:0. ~ms:0. in
  time_clip (local_to_utc (make_date ~day:d ~time:t))

let makeWithYMDHM ~year ~month ~date ~hours ~minutes =
  let y = if year >= 0. && year <= 99. then 1900. +. year else year in
  let d = make_day ~year:y ~month ~date in
  let t = make_time ~hour:hours ~min:minutes ~sec:0. ~ms:0. in
  time_clip (local_to_utc (make_date ~day:d ~time:t))

let makeWithYMDHMS ~year ~month ~date ~hours ~minutes ~seconds =
  let y = if year >= 0. && year <= 99. then 1900. +. year else year in
  let d = make_day ~year:y ~month ~date in
  let t = make_time ~hour:hours ~min:minutes ~sec:seconds ~ms:0. in
  time_clip (local_to_utc (make_date ~day:d ~time:t))

(** utcWith* - Date.UTC variants for API compatibility *)
let utcWithYM ~year ~month = utc ~year ~month ()

let utcWithYMD ~year ~month ~date = utc ~year ~month ~day:date ()
let utcWithYMDH ~year ~month ~date ~hours = utc ~year ~month ~day:date ~hours ()
let utcWithYMDHM ~year ~month ~date ~hours ~minutes = utc ~year ~month ~day:date ~hours ~minutes ()
let utcWithYMDHMS ~year ~month ~date ~hours ~minutes ~seconds = utc ~year ~month ~day:date ~hours ~minutes ~seconds ()

(* Setters - these return the new timestamp (JS mutates, but we keep it pure) *)

(** setTime - sets the time value directly *)
let setTime value _t = time_clip value

(** setUTCMilliseconds *)
let setUTCMilliseconds ms t =
  if Float.is_nan t then nan
  else
    let day = day t in
    let time = time_within_day t in
    let new_time = time -. ms_from_time t +. Float.trunc ms in
    time_clip (make_date ~day ~time:new_time)

(** setUTCSeconds *)
let setUTCSeconds sec t =
  if Float.is_nan t then nan
  else
    let day = day t in
    let time = time_within_day t in
    let old_sec = sec_from_time t in
    let new_time = time -. (old_sec *. ms_per_second) +. (Float.trunc sec *. ms_per_second) in
    time_clip (make_date ~day ~time:new_time)

let setUTCSecondsMs ~seconds ~milliseconds t =
  let t = setUTCSeconds seconds t in
  setUTCMilliseconds milliseconds t

(** setUTCMinutes *)
let setUTCMinutes min t =
  if Float.is_nan t then nan
  else
    let day = day t in
    let time = time_within_day t in
    let old_min = min_from_time t in
    let new_time = time -. (old_min *. ms_per_minute) +. (Float.trunc min *. ms_per_minute) in
    time_clip (make_date ~day ~time:new_time)

let setUTCMinutesS ~minutes ~seconds t =
  let t = setUTCMinutes minutes t in
  setUTCSeconds seconds t

let setUTCMinutesSMs ~minutes ~seconds ~milliseconds t =
  let t = setUTCMinutes minutes t in
  let t = setUTCSeconds seconds t in
  setUTCMilliseconds milliseconds t

(** setUTCHours *)
let setUTCHours hours t =
  if Float.is_nan t then nan
  else
    let day = day t in
    let time = time_within_day t in
    let old_hours = hour_from_time t in
    let new_time = time -. (old_hours *. ms_per_hour) +. (Float.trunc hours *. ms_per_hour) in
    time_clip (make_date ~day ~time:new_time)

let setUTCHoursM ~hours ~minutes t =
  let t = setUTCHours hours t in
  setUTCMinutes minutes t

let setUTCHoursMS ~hours ~minutes ~seconds t =
  let t = setUTCHours hours t in
  let t = setUTCMinutes minutes t in
  setUTCSeconds seconds t

let setUTCHoursMSMs ~hours ~minutes ~seconds ~milliseconds t =
  let t = setUTCHours hours t in
  let t = setUTCMinutes minutes t in
  let t = setUTCSeconds seconds t in
  setUTCMilliseconds milliseconds t

(** setUTCDate *)
let setUTCDate date t =
  if Float.is_nan t then nan
  else
    let year = year_from_time t in
    let month = month_from_time t in
    let day = make_day ~year ~month ~date:(Float.trunc date) in
    let time = time_within_day t in
    time_clip (make_date ~day ~time)

(** setUTCMonth *)
let setUTCMonth month t =
  if Float.is_nan t then nan
  else
    let year = year_from_time t in
    let date = date_from_time t in
    let day = make_day ~year ~month:(Float.trunc month) ~date in
    let time = time_within_day t in
    time_clip (make_date ~day ~time)

let setUTCMonthD ~month ~date t =
  let t = setUTCMonth month t in
  setUTCDate date t

(** setUTCFullYear *)
let setUTCFullYear year t =
  let t = if Float.is_nan t then 0. else t in
  let month = month_from_time t in
  let date = date_from_time t in
  let day = make_day ~year:(Float.trunc year) ~month ~date in
  let time = time_within_day t in
  time_clip (make_date ~day ~time)

let setUTCFullYearM ~year ~month t =
  let t = setUTCFullYear year t in
  setUTCMonth month t

let setUTCFullYearMD ~year ~month ~date t =
  let t = setUTCFullYear year t in
  let t = setUTCMonth month t in
  setUTCDate date t

(** setUTCTime - same as setTime *)
let setUTCTime = setTime

(* Local time setters - convert to local, modify, convert back *)

let setMilliseconds ms t =
  if Float.is_nan t then nan
  else
    let local = utc_to_local t in
    let day = day local in
    let time = time_within_day local in
    let new_time = time -. ms_from_time local +. Float.trunc ms in
    time_clip (local_to_utc (make_date ~day ~time:new_time))

let setSeconds sec t =
  if Float.is_nan t then nan
  else
    let local = utc_to_local t in
    let day = day local in
    let time = time_within_day local in
    let old_sec = sec_from_time local in
    let new_time = time -. (old_sec *. ms_per_second) +. (Float.trunc sec *. ms_per_second) in
    time_clip (local_to_utc (make_date ~day ~time:new_time))

let setSecondsMs ~seconds ~milliseconds t =
  let t = setSeconds seconds t in
  setMilliseconds milliseconds t

let setMinutes min t =
  if Float.is_nan t then nan
  else
    let local = utc_to_local t in
    let day = day local in
    let time = time_within_day local in
    let old_min = min_from_time local in
    let new_time = time -. (old_min *. ms_per_minute) +. (Float.trunc min *. ms_per_minute) in
    time_clip (local_to_utc (make_date ~day ~time:new_time))

let setMinutesS ~minutes ~seconds t =
  let t = setMinutes minutes t in
  setSeconds seconds t

let setMinutesSMs ~minutes ~seconds ~milliseconds t =
  let t = setMinutes minutes t in
  let t = setSeconds seconds t in
  setMilliseconds milliseconds t

let setHours hours t =
  if Float.is_nan t then nan
  else
    let local = utc_to_local t in
    let day = day local in
    let time = time_within_day local in
    let old_hours = hour_from_time local in
    let new_time = time -. (old_hours *. ms_per_hour) +. (Float.trunc hours *. ms_per_hour) in
    time_clip (local_to_utc (make_date ~day ~time:new_time))

let setHoursM ~hours ~minutes t =
  let t = setHours hours t in
  setMinutes minutes t

let setHoursMS ~hours ~minutes ~seconds t =
  let t = setHours hours t in
  let t = setMinutes minutes t in
  setSeconds seconds t

let setHoursMSMs ~hours ~minutes ~seconds ~milliseconds t =
  let t = setHours hours t in
  let t = setMinutes minutes t in
  let t = setSeconds seconds t in
  setMilliseconds milliseconds t

let setDate date t =
  if Float.is_nan t then nan
  else
    let local = utc_to_local t in
    let year = year_from_time local in
    let month = month_from_time local in
    let day = make_day ~year ~month ~date:(Float.trunc date) in
    let time = time_within_day local in
    time_clip (local_to_utc (make_date ~day ~time))

let setMonth month t =
  if Float.is_nan t then nan
  else
    let local = utc_to_local t in
    let year = year_from_time local in
    let date = date_from_time local in
    let day = make_day ~year ~month:(Float.trunc month) ~date in
    let time = time_within_day local in
    time_clip (local_to_utc (make_date ~day ~time))

let setMonthD ~month ~date t =
  let t = setMonth month t in
  setDate date t

let setFullYear year t =
  let t = if Float.is_nan t then 0. else t in
  let local = utc_to_local t in
  let month = month_from_time local in
  let date = date_from_time local in
  let day = make_day ~year:(Float.trunc year) ~month ~date in
  let time = time_within_day local in
  time_clip (local_to_utc (make_date ~day ~time))

let setFullYearM ~year ~month t =
  let t = setFullYear year t in
  setMonth month t

let setFullYearMD ~year ~month ~date t =
  let t = setFullYear year t in
  let t = setMonth month t in
  setDate date t

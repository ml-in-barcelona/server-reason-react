(* Server-side implementation of the JavaScript Date API. Melange's [Js.Date] *)

(* [t] mirrors a JS Date object: a mutable box holding the time value (epoch
   milliseconds, or NaN for an Invalid Date). Setters mutate the receiver and
   return the new time value. *)
type t = { mutable time : float }

let ms_per_second = 1000.
let ms_per_minute = 60000.
let ms_per_hour = 3600000.
let ms_per_day = 86400000.
let max_time_value = 8.64e15
let is_valid_time time = (not (Float.is_nan time)) && Float.abs time <= max_time_value
let day time = Float.floor (time /. ms_per_day)

let time_within_day time =
  let r = Float.rem time ms_per_day in
  if r < 0. then r +. ms_per_day else r

let days_in_year y =
  if Float.rem y 4. <> 0. then 365
  else if Float.rem y 100. <> 0. then 366
  else if Float.rem y 400. <> 0. then 365
  else 366

let day_from_year y =
  let y = y -. 1970. in
  (365. *. y) +. Float.floor ((y +. 1.) /. 4.) -. Float.floor ((y +. 69.) /. 100.) +. Float.floor ((y +. 369.) /. 400.)

let year_from_time time =
  if Float.is_nan time then nan
  else
    let d = day time in
    let estimate = 1970. +. Float.floor (d /. 365.2425) in
    let rec search lo hi =
      if lo >= hi then lo
      else
        let mid = Float.floor ((lo +. hi +. 1.) /. 2.) in
        if day_from_year mid <= d then search mid hi else search lo (mid -. 1.)
    in
    search (estimate -. 2.) (estimate +. 2.)

let in_leap_year time = days_in_year (year_from_time time) = 366

let day_within_year time =
  let d = day time in
  let y = year_from_time time in
  d -. day_from_year y

let month_start_days = [| 0; 31; 59; 90; 120; 151; 181; 212; 243; 273; 304; 334; 365 |]
let month_start_days_leap = [| 0; 31; 60; 91; 121; 152; 182; 213; 244; 274; 305; 335; 366 |]

let month_from_time time =
  if Float.is_nan time then nan
  else
    let d = int_of_float (day_within_year time) in
    let table = if in_leap_year time then month_start_days_leap else month_start_days in
    let rec find_month m = if m >= 11 then 11 else if d < table.(m + 1) then m else find_month (m + 1) in
    Float.of_int (find_month 0)

let date_from_time time =
  if Float.is_nan time then nan
  else
    let d = int_of_float (day_within_year time) in
    let m = int_of_float (month_from_time time) in
    let table = if in_leap_year time then month_start_days_leap else month_start_days in
    Float.of_int (d - table.(m) + 1)

let week_day time =
  if Float.is_nan time then nan
  else
    let d = day time +. 4. in
    let r = Float.rem d 7. in
    if r < 0. then r +. 7. else r

let hour_from_time time =
  if Float.is_nan time then nan
  else
    let r = Float.rem (Float.floor (time /. ms_per_hour)) 24. in
    if r < 0. then r +. 24. else r

let min_from_time time =
  if Float.is_nan time then nan
  else
    let r = Float.rem (Float.floor (time /. ms_per_minute)) 60. in
    if r < 0. then r +. 60. else r

let sec_from_time time =
  if Float.is_nan time then nan
  else
    let r = Float.rem (Float.floor (time /. ms_per_second)) 60. in
    if r < 0. then r +. 60. else r

let ms_from_time time =
  if Float.is_nan time then nan
  else
    let r = Float.rem time ms_per_second in
    if r < 0. then r +. ms_per_second else r

let make_time ~hour ~min ~sec ~ms =
  if Float.is_nan hour || Float.is_nan min || Float.is_nan sec || Float.is_nan ms then nan
  else
    let h = Float.trunc hour in
    let m = Float.trunc min in
    let s = Float.trunc sec in
    let milli = Float.trunc ms in
    (h *. ms_per_hour) +. (m *. ms_per_minute) +. (s *. ms_per_second) +. milli

let make_day ~year ~month ~date =
  if Float.is_nan year || Float.is_nan month || Float.is_nan date then nan
  else if (not (Float.is_finite year)) || (not (Float.is_finite month)) || not (Float.is_finite date) then nan
  else
    let y = Float.trunc year in
    let m = Float.trunc month in
    let dt = Float.trunc date in
    let ym = y +. Float.floor (m /. 12.) in
    let mn = Float.rem m 12. in
    let mn = if mn < 0. then mn +. 12. else mn in
    let d = day_from_year ym in
    let is_leap = days_in_year ym = 366 in
    let month_table = if is_leap then month_start_days_leap else month_start_days in
    let d = d +. Float.of_int month_table.(int_of_float mn) in
    d +. dt -. 1.

let make_date ~day ~time =
  if Float.is_nan day || Float.is_nan time then nan
  else if (not (Float.is_finite day)) || not (Float.is_finite time) then nan
  else (day *. ms_per_day) +. time

let time_clip time =
  if Float.is_nan time then nan
  else if not (Float.is_finite time) then nan
  else if Float.abs time > max_time_value then nan
  else Float.trunc time

(* ==== Local time zone (ES2015+ 21.4.1.7 LocalTZA) ======================= *)

(* Offset in ms between local time and UTC at the given UTC instant, i.e.
   LocalTZA(t, true). The tm_yday diff is clamped to ±1 day so the arithmetic
   stays correct across year boundaries. The [with _ -> 0.] guard only fires
   for instants outside the range representable by [Unix.localtime]. *)
let tz_offset_at_utc utc_ms =
  if Float.is_nan utc_ms then 0.
  else
    let seconds = utc_ms /. 1000. in
    try
      let local_tm = Unix.localtime seconds in
      let utc_tm = Unix.gmtime seconds in
      let local_secs = (local_tm.Unix.tm_hour * 3600) + (local_tm.Unix.tm_min * 60) + local_tm.Unix.tm_sec in
      let utc_secs = (utc_tm.Unix.tm_hour * 3600) + (utc_tm.Unix.tm_min * 60) + utc_tm.Unix.tm_sec in
      let day_diff = local_tm.Unix.tm_yday - utc_tm.Unix.tm_yday in
      let day_diff = if day_diff > 1 then -1 else if day_diff < -1 then 1 else day_diff in
      Float.of_int ((day_diff * 86400) + local_secs - utc_secs) *. 1000.
    with _ -> 0.

let utc_to_local time = if Float.is_nan time then nan else time +. tz_offset_at_utc time

(* LocalTZA(t, false): convert a local time value to UTC. Near a DST
   transition the naive "offset at t" answer is wrong, so we sample the zone
   offset one day before and one day after the local time value (transitions
   shift the clock by at most a couple of hours, so ±24h safely straddles the
   transition) and pick the offset the spec mandates:
   - exactly one candidate offset reconstructs the local time -> use it;
   - both do (fall-back ambiguity) -> use the pre-transition offset, which
     selects the earlier UTC instant;
   - neither does (spring-forward gap) -> also use the pre-transition offset,
     so the skipped local time overflows past the transition. *)
let local_to_utc local_ms =
  if Float.is_nan local_ms then nan
  else
    let offset_before = tz_offset_at_utc (local_ms -. ms_per_day) in
    let offset_after = tz_offset_at_utc (local_ms +. ms_per_day) in
    if offset_before = offset_after then local_ms -. offset_before
    else
      let reconstructs offset = tz_offset_at_utc (local_ms -. offset) = offset in
      let offset =
        match (reconstructs offset_before, reconstructs offset_after) with
        | false, true -> offset_after
        | true, false | true, true | false, false -> offset_before
      in
      local_ms -. offset

(* ==== Constructors ====================================================== *)

let compute_utc ~year ?(month = 0.) ?(date = 1.) ?(hours = 0.) ?(minutes = 0.) ?(seconds = 0.) ?(ms = 0.) () =
  let y =
    if Float.is_nan year then nan
    else
      let y = Float.trunc year in
      if y >= 0. && y <= 99. then 1900. +. y else y
  in
  let m = if Float.is_nan month then nan else Float.trunc month in
  let d = make_day ~year:y ~month:m ~date in
  let t = make_time ~hour:hours ~min:minutes ~sec:seconds ~ms in
  time_clip (make_date ~day:d ~time:t)

let now () =
  let t = Unix.gettimeofday () in
  Float.trunc (t *. 1000.)

let utc ~year ?(month = 0.) ?(date = 1.) ?(hours = 0.) ?(minutes = 0.) ?(seconds = 0.) () =
  compute_utc ~year ~month ~date ~hours ~minutes ~seconds ()

let make ?year ?month ?date ?hours ?minutes ?seconds () =
  match year with
  | None -> { time = time_clip (now ()) }
  | Some year ->
      let month = match month with Some m -> m | None -> 0. in
      let date = match date with Some d -> d | None -> 1. in
      let hours = match hours with Some h -> h | None -> 0. in
      let minutes = match minutes with Some m -> m | None -> 0. in
      let seconds = match seconds with Some s -> s | None -> 0. in
      let y = if year >= 0. && year <= 99. then 1900. +. year else year in
      let d = make_day ~year:y ~month ~date in
      let time = make_time ~hour:hours ~min:minutes ~sec:seconds ~ms:0. in
      { time = time_clip (local_to_utc (make_date ~day:d ~time)) }

let fromFloat ms = { time = time_clip ms }
let valueOf t = t.time
let getTime t = t.time
let getUTCFullYear t = year_from_time t.time
let getUTCMonth t = month_from_time t.time
let getUTCDate t = date_from_time t.time
let getUTCDay t = week_day t.time
let getUTCHours t = hour_from_time t.time
let getUTCMinutes t = min_from_time t.time
let getUTCSeconds t = sec_from_time t.time
let getUTCMilliseconds t = ms_from_time t.time
let getFullYear t = year_from_time (utc_to_local t.time)
let getMonth t = month_from_time (utc_to_local t.time)
let getDate t = date_from_time (utc_to_local t.time)
let getDay t = week_day (utc_to_local t.time)
let getHours t = hour_from_time (utc_to_local t.time)
let getMinutes t = min_from_time (utc_to_local t.time)
let getSeconds t = sec_from_time (utc_to_local t.time)
let getMilliseconds t = ms_from_time (utc_to_local t.time)
let getTimezoneOffset t = if Float.is_nan t.time then nan else -.tz_offset_at_utc t.time /. ms_per_minute

let pad n i =
  let s = string_of_int (abs i) in
  let len = String.length s in
  if len >= n then s else String.make (n - len) '0' ^ s

let format_year year =
  let y = int_of_float year in
  if y >= 0 && y <= 9999 then pad 4 y
  else if y < 0 then Printf.sprintf "-%s" (pad 6 (-y))
  else Printf.sprintf "+%s" (pad 6 y)

let toISOString t =
  let time = t.time in
  if Float.is_nan time then raise (Invalid_argument "Invalid Date")
  else if not (is_valid_time time) then raise (Invalid_argument "Invalid Date")
  else
    let year = year_from_time time in
    let month = int_of_float (month_from_time time) + 1 in
    let day = int_of_float (date_from_time time) in
    let hours = int_of_float (hour_from_time time) in
    let minutes = int_of_float (min_from_time time) in
    let seconds = int_of_float (sec_from_time time) in
    let ms = int_of_float (ms_from_time time) in
    Printf.sprintf "%s-%s-%sT%s:%s:%s.%sZ" (format_year year) (pad 2 month) (pad 2 day) (pad 2 hours) (pad 2 minutes)
      (pad 2 seconds) (pad 3 ms)

let toJSON t = if not (is_valid_time t.time) then None else Some (toISOString t)
let toJSONUnsafe t = toISOString t
let day_names = [| "Sun"; "Mon"; "Tue"; "Wed"; "Thu"; "Fri"; "Sat" |]
let month_names = [| "Jan"; "Feb"; "Mar"; "Apr"; "May"; "Jun"; "Jul"; "Aug"; "Sep"; "Oct"; "Nov"; "Dec" |]

let format_tz_offset offset_ms =
  let offset_min = int_of_float (offset_ms /. ms_per_minute) in
  let sign = if offset_min >= 0 then "+" else "-" in
  let abs_offset = abs offset_min in
  let hours = abs_offset / 60 in
  let mins = abs_offset mod 60 in
  Printf.sprintf "GMT%s%s%s" sign (pad 2 hours) (pad 2 mins)

let toUTCString t =
  let time = t.time in
  if Float.is_nan time then "Invalid Date"
  else
    let day_name = day_names.(int_of_float (week_day time)) in
    let day = int_of_float (date_from_time time) in
    let month_name = month_names.(int_of_float (month_from_time time)) in
    let year = int_of_float (year_from_time time) in
    let hours = int_of_float (hour_from_time time) in
    let minutes = int_of_float (min_from_time time) in
    let seconds = int_of_float (sec_from_time time) in
    Printf.sprintf "%s, %s %s %d %s:%s:%s GMT" day_name (pad 2 day) month_name year (pad 2 hours) (pad 2 minutes)
      (pad 2 seconds)

let toDateString t =
  let time = t.time in
  if Float.is_nan time then "Invalid Date"
  else
    let local = utc_to_local time in
    let day_name = day_names.(int_of_float (week_day local)) in
    let month_name = month_names.(int_of_float (month_from_time local)) in
    let day = int_of_float (date_from_time local) in
    let year = int_of_float (year_from_time local) in
    Printf.sprintf "%s %s %s %d" day_name month_name (pad 2 day) year

let toTimeString t =
  let time = t.time in
  if Float.is_nan time then "Invalid Date"
  else
    let local = utc_to_local time in
    let hours = int_of_float (hour_from_time local) in
    let minutes = int_of_float (min_from_time local) in
    let seconds = int_of_float (sec_from_time local) in
    let tz = format_tz_offset (tz_offset_at_utc time) in
    Printf.sprintf "%s:%s:%s %s" (pad 2 hours) (pad 2 minutes) (pad 2 seconds) tz

let toString t =
  if Float.is_nan t.time then "Invalid Date" else Printf.sprintf "%s %s" (toDateString t) (toTimeString t)

let toLocaleString t = toString t
let toLocaleDateString t = toDateString t
let toLocaleTimeString t = toTimeString t

(* ==== Date string parsing ================================================

   Two grammars, tried in order, mirroring JS engines:

   - the ISO 8601 date-time string format from the spec (21.4.1.15). Parsing
     is strict: the whole string must be consumed and malformed components
     yield NaN, matching V8's behavior for ISO strings. Like V8, days beyond
     the month length overflow into the next month;
   - a legacy "toString"/"toUTCString"-style format: optional weekday (with
     optional trailing comma), "Mon DD YYYY" or "DD Mon YYYY", optional
     "HH:MM[:SS[.fff]]" time and optional "GMT[±hhmm]" zone. Parsing is
     strict (full-string consumption, no silent defaults for malformed
     offsets): current V8 also rejects trailing garbage here
     ("Jan 1 2000 foo" is NaN in node). Known deliberate divergence: V8's
     legacy fallback accepts a few degenerate shapes like "2000-" (year 2000,
     local); we return NaN there, as the existing test suite requires.

   Time zone semantics (ES2016+):
   - ISO date-only forms ("2024", "2024-06", "2024-06-15") are UTC;
   - ISO date-time forms without an offset ("2024-06-15T10:00") are LOCAL;
   - explicit designators ("Z", "+02:00", "GMT+0200") are honored;
   - legacy forms without a GMT designator are LOCAL. *)

let ( let* ) = Option.bind
let guard condition = if condition then Some () else None
let is_ascii_digit c = c >= '0' && c <= '9'

(* Reads exactly [len] ASCII digits at [pos]; returns the value and the
   position after them. *)
let parse_fixed_digits s ~pos ~len =
  if pos + len > String.length s then None
  else
    let sub = String.sub s pos len in
    if String.for_all is_ascii_digit sub then Some (int_of_string sub, pos + len) else None

let parse_fixed_digits_in_range s ~pos ~len ~min ~max =
  let* value, pos = parse_fixed_digits s ~pos ~len in
  let* () = guard (value >= min && value <= max) in
  Some (value, pos)

(* YYYY or ±YYYYYY (expanded years). "-000000" is explicitly invalid. *)
let parse_iso_year s =
  if String.length s = 0 then None
  else
    let sign, start, digits = match s.[0] with '+' -> (1., 1, 6) | '-' -> (-1., 1, 6) | _ -> (1., 0, 4) in
    let* year_int, next_pos = parse_fixed_digits s ~pos:start ~len:digits in
    let* () = guard (not (sign < 0. && year_int = 0)) in
    Some (sign *. Float.of_int year_int, next_pos)

(* Raw field combination without Date.UTC's two-digit-year mapping and without
   clipping: parsed calendar years are absolute ("0001" is year 1). *)
let ms_from_fields ~year ~month ~date ~hours ~minutes ~seconds ~ms =
  let d = make_day ~year ~month ~date in
  let time = make_time ~hour:hours ~min:minutes ~sec:seconds ~ms in
  make_date ~day:d ~time

(* HH:mm[:ss[.fff...]] starting at [pos]. JS keeps millisecond precision:
   fractional digits beyond the third are parsed but ignored. *)
let parse_iso_clock s ~pos =
  let len = String.length s in
  let* hours, pos = parse_fixed_digits_in_range s ~pos ~len:2 ~min:0 ~max:24 in
  let* () = guard (pos < len && s.[pos] = ':') in
  let* minutes, pos = parse_fixed_digits_in_range s ~pos:(pos + 1) ~len:2 ~min:0 ~max:59 in
  let* seconds, pos =
    if pos < len && s.[pos] = ':' then parse_fixed_digits_in_range s ~pos:(pos + 1) ~len:2 ~min:0 ~max:59
    else Some (0, pos)
  in
  let* ms, pos =
    if pos < len && s.[pos] = '.' then
      let start = pos + 1 in
      let rec digits_end p = if p < len && is_ascii_digit s.[p] then digits_end (p + 1) else p in
      let stop = digits_end start in
      if stop = start then None
      else
        let frac = String.sub s start (min (stop - start) 3) in
        let frac = frac ^ String.make (3 - String.length frac) '0' in
        Some (int_of_string frac, stop)
    else Some (0, pos)
  in
  (* "24:00:00.000" is a valid end-of-day timestamp, anything past it is not *)
  let* () = guard (not (hours = 24 && (minutes <> 0 || seconds <> 0 || ms <> 0))) in
  Some (hours, minutes, seconds, ms, pos)

(* Z | ±hh:mm | ±hhmm — anything else is a parse error. V8 rejects a bare ±hh
   without minutes and accepts a lowercase 'z'. *)
let parse_tz_designator s ~pos =
  let len = String.length s in
  if pos >= len then None
  else
    match s.[pos] with
    | 'Z' | 'z' -> Some (0., pos + 1)
    | ('+' | '-') as sign_char ->
        let sign = if sign_char = '-' then -1. else 1. in
        let* hours, pos = parse_fixed_digits_in_range s ~pos:(pos + 1) ~len:2 ~min:0 ~max:23 in
        let* minutes, pos =
          if pos < len && s.[pos] = ':' then parse_fixed_digits_in_range s ~pos:(pos + 1) ~len:2 ~min:0 ~max:59
          else parse_fixed_digits_in_range s ~pos ~len:2 ~min:0 ~max:59
        in
        Some (sign *. ((Float.of_int hours *. ms_per_hour) +. (Float.of_int minutes *. ms_per_minute)), pos)
    | _ -> None

let parse_iso8601 s =
  let len = String.length s in
  let* year, pos = parse_iso_year s in
  let* month, date, pos =
    if pos < len && s.[pos] = '-' then
      let* month, pos = parse_fixed_digits_in_range s ~pos:(pos + 1) ~len:2 ~min:1 ~max:12 in
      if pos < len && s.[pos] = '-' then
        let* date, pos = parse_fixed_digits_in_range s ~pos:(pos + 1) ~len:2 ~min:1 ~max:31 in
        Some (month, date, pos)
      else Some (month, 1, pos)
    else Some (1, 1, pos)
  in
  (* days beyond the month length overflow into the next month, like V8
     ("2019-02-29" is 2019-03-01) *)
  let month = Float.of_int (month - 1) in
  let date = Float.of_int date in
  if pos = len then
    (* date-only form: interpreted as UTC *)
    Some (time_clip (ms_from_fields ~year ~month ~date ~hours:0. ~minutes:0. ~seconds:0. ~ms:0.))
  else if s.[pos] <> 'T' && s.[pos] <> 't' && s.[pos] <> ' ' then None
  else
    let* hours, minutes, seconds, ms, pos = parse_iso_clock s ~pos:(pos + 1) in
    let raw =
      ms_from_fields ~year ~month ~date ~hours:(Float.of_int hours) ~minutes:(Float.of_int minutes)
        ~seconds:(Float.of_int seconds) ~ms:(Float.of_int ms)
    in
    if pos = len then
      (* date-time without offset: interpreted as local time (ES2016+) *)
      Some (time_clip (local_to_utc raw))
    else
      let* offset_ms, pos = parse_tz_designator s ~pos in
      let* () = guard (pos = len) in
      Some (time_clip (raw -. offset_ms))

(* ---- legacy grammar ---- *)

let weekday_names = [ "Sun"; "Mon"; "Tue"; "Wed"; "Thu"; "Fri"; "Sat" ]

(* Drops a leading weekday token, with or without a trailing comma
   ("Sat Jan ..." from toString, "Sat, 01 Jan ..." from toUTCString). *)
let strip_weekday parts =
  match parts with
  | first :: rest ->
      let name =
        if String.length first > 0 && first.[String.length first - 1] = ',' then
          String.sub first 0 (String.length first - 1)
        else first
      in
      if List.mem name weekday_names then rest else parts
  | [] -> parts

let array_find_index pred arr =
  let len = Array.length arr in
  let rec loop i = if i >= len then None else if pred arr.(i) then Some i else loop (i + 1) in
  loop 0

let parse_month_name name = array_find_index (fun m -> String.equal m name) month_names
let parse_all_digits tok = if tok <> "" && String.for_all is_ascii_digit tok then int_of_string_opt tok else None

(* V8 maps two-digit legacy years: 0-49 -> 2000s, 50-99 -> 1900s. *)
let expand_legacy_year y = if y < 50 then y + 2000 else if y < 100 then y + 1900 else y

(* "H:MM" or "H:MM:SS[.fff]" with 1-2 digit fields; fractional digits beyond
   the third are parsed but ignored (millisecond precision), like ISO. *)
let parse_legacy_clock tok =
  let parse_field ~max str =
    let* () = guard (String.length str >= 1 && String.length str <= 2) in
    let* value = parse_all_digits str in
    let* () = guard (value <= max) in
    Some value
  in
  let split_seconds str =
    match String.index_opt str '.' with
    | None -> Some (str, 0)
    | Some i ->
        let frac = String.sub str (i + 1) (String.length str - i - 1) in
        let* () = guard (frac <> "" && String.for_all is_ascii_digit frac) in
        let frac = if String.length frac >= 3 then String.sub frac 0 3 else frac in
        let frac = frac ^ String.make (3 - String.length frac) '0' in
        Some (String.sub str 0 i, int_of_string frac)
  in
  match String.split_on_char ':' tok with
  | [ h; m ] ->
      let* hours = parse_field ~max:23 h in
      let* minutes = parse_field ~max:59 m in
      Some (hours, minutes, 0, 0)
  | [ h; m; s ] ->
      let* hours = parse_field ~max:23 h in
      let* minutes = parse_field ~max:59 m in
      let* s, ms = split_seconds s in
      let* seconds = parse_field ~max:59 s in
      Some (hours, minutes, seconds, ms)
  | _ -> None

(* "GMT" | "UTC" | "UT", optionally followed by an offset: ±h/±hh (hours),
   ±hhmm, or ±h:mm/±hh:mm. Following V8's legacy rule, a bare number smaller
   than 24 after the sign means hours, anything else is read as hhmm.
   Malformed offsets are parse errors (NaN), never silently treated as UTC. *)
let parse_gmt_offset tok =
  let* rest =
    if String.starts_with ~prefix:"GMT" tok then Some (String.sub tok 3 (String.length tok - 3))
    else if String.starts_with ~prefix:"UTC" tok then Some (String.sub tok 3 (String.length tok - 3))
    else if String.starts_with ~prefix:"UT" tok then Some (String.sub tok 2 (String.length tok - 2))
    else None
  in
  if String.equal rest "" then Some 0.
  else
    let* () = guard (rest.[0] = '+' || rest.[0] = '-') in
    let sign = if rest.[0] = '-' then -1. else 1. in
    let body = String.sub rest 1 (String.length rest - 1) in
    let* hours, minutes =
      match String.index_opt body ':' with
      | Some i ->
          let h = String.sub body 0 i in
          let m = String.sub body (i + 1) (String.length body - i - 1) in
          let* () = guard (String.length h >= 1 && String.length h <= 2 && String.length m = 2) in
          let* hours = parse_all_digits h in
          let* minutes = parse_all_digits m in
          Some (hours, minutes)
      | None ->
          let* () = guard (String.length body >= 1 && String.length body <= 4) in
          let* n = parse_all_digits body in
          if n < 24 then Some (n, 0) else Some (n / 100, n mod 100)
    in
    let* () = guard (hours <= 23 && minutes <= 59) in
    Some (sign *. ((Float.of_int hours *. ms_per_hour) +. (Float.of_int minutes *. ms_per_minute)))

let parse_legacy s =
  let parts = String.split_on_char ' ' s |> List.filter (fun p -> not (String.equal p "")) in
  let parts = strip_weekday parts in
  match parts with
  | first :: second :: year_tok :: rest ->
      (* both "Mon DD YYYY" (toString) and "DD Mon YYYY" (toUTCString / RFC 1123) *)
      let* month, day_tok =
        match parse_month_name first with
        | Some m -> Some (m, second)
        | None ->
            let* m = parse_month_name second in
            Some (m, first)
      in
      let* day = parse_all_digits day_tok in
      let* year_int = parse_all_digits year_tok in
      let year = Float.of_int (expand_legacy_year year_int) in
      (* days beyond the month length overflow, like V8 ("Feb 30" is Mar 2) *)
      let* () = guard (day >= 1 && day <= 31) in
      let* clock, tz_offset =
        match rest with
        | [] -> Some ((0, 0, 0, 0), None)
        | [ tok ] -> (
            match parse_legacy_clock tok with
            | Some clock -> Some (clock, None)
            | None ->
                let* offset = parse_gmt_offset tok in
                Some ((0, 0, 0, 0), Some offset))
        | [ time_tok; tz_tok ] ->
            let* clock = parse_legacy_clock time_tok in
            let* offset = parse_gmt_offset tz_tok in
            Some (clock, Some offset)
        | _ -> None
      in
      let hours, minutes, seconds, ms = clock in
      let raw =
        ms_from_fields ~year ~month:(Float.of_int month) ~date:(Float.of_int day) ~hours:(Float.of_int hours)
          ~minutes:(Float.of_int minutes) ~seconds:(Float.of_int seconds) ~ms:(Float.of_int ms)
      in
      let time =
        match tz_offset with Some offset -> time_clip (raw -. offset) | None -> time_clip (local_to_utc raw)
      in
      Some time
  | _ -> None

let parse s =
  let s = String.trim s in
  if String.length s = 0 then nan
  else match parse_iso8601 s with Some t -> t | None -> ( match parse_legacy s with Some t -> t | None -> nan)

let parseAsFloat = parse
let fromString s = { time = parse s }

(* ==== Setters ============================================================

   Like JS Date.prototype setters: store the clipped time value on the
   receiver and return it. *)

let update t value =
  let value = time_clip value in
  t.time <- value;
  value

let setTime ~time t = update t time
let setUTCTime ~time t = update t time

let setUTCMilliseconds ~milliseconds t =
  if Float.is_nan t.time then update t nan
  else
    let cur = t.time in
    let d = day cur in
    let time = time_within_day cur in
    let new_time = time -. ms_from_time cur +. Float.trunc milliseconds in
    update t (make_date ~day:d ~time:new_time)

let setUTCSeconds ~seconds ?milliseconds t =
  if Float.is_nan t.time then update t nan
  else
    let cur = t.time in
    let h = hour_from_time cur in
    let m = min_from_time cur in
    let s = Float.trunc seconds in
    let ms = match milliseconds with Some ms -> Float.trunc ms | None -> ms_from_time cur in
    let d = day cur in
    let time = make_time ~hour:h ~min:m ~sec:s ~ms in
    update t (make_date ~day:d ~time)

let setUTCMinutes ~minutes ?seconds ?milliseconds t =
  if Float.is_nan t.time then update t nan
  else
    let cur = t.time in
    let h = hour_from_time cur in
    let m = Float.trunc minutes in
    let s = match seconds with Some s -> Float.trunc s | None -> sec_from_time cur in
    let ms = match milliseconds with Some ms -> Float.trunc ms | None -> ms_from_time cur in
    let d = day cur in
    let time = make_time ~hour:h ~min:m ~sec:s ~ms in
    update t (make_date ~day:d ~time)

let setUTCHours ~hours ?minutes ?seconds ?milliseconds t =
  if Float.is_nan t.time then update t nan
  else
    let cur = t.time in
    let h = Float.trunc hours in
    let m = match minutes with Some m -> Float.trunc m | None -> min_from_time cur in
    let s = match seconds with Some s -> Float.trunc s | None -> sec_from_time cur in
    let ms = match milliseconds with Some ms -> Float.trunc ms | None -> ms_from_time cur in
    let d = day cur in
    let time = make_time ~hour:h ~min:m ~sec:s ~ms in
    update t (make_date ~day:d ~time)

let setUTCDate ~date t =
  if Float.is_nan t.time then update t nan
  else
    let cur = t.time in
    let year = year_from_time cur in
    let month = month_from_time cur in
    let d = make_day ~year ~month ~date:(Float.trunc date) in
    let time = time_within_day cur in
    update t (make_date ~day:d ~time)

let setUTCMonth ~month ?date t =
  if Float.is_nan t.time then update t nan
  else
    let cur = t.time in
    let year = year_from_time cur in
    let dt = match date with Some d -> Float.trunc d | None -> date_from_time cur in
    let d = make_day ~year ~month:(Float.trunc month) ~date:dt in
    let time = time_within_day cur in
    update t (make_date ~day:d ~time)

let setUTCFullYear ~year ?month ?date t =
  (* per spec, a NaN receiver is treated as +0 here *)
  let cur = if Float.is_nan t.time then 0. else t.time in
  let m = match month with Some m -> Float.trunc m | None -> month_from_time cur in
  let dt = match date with Some d -> Float.trunc d | None -> date_from_time cur in
  let d = make_day ~year:(Float.trunc year) ~month:m ~date:dt in
  let time = time_within_day cur in
  update t (make_date ~day:d ~time)

let setMilliseconds ~milliseconds t =
  if Float.is_nan t.time then update t nan
  else
    let local = utc_to_local t.time in
    let d = day local in
    let time = time_within_day local in
    let new_time = time -. ms_from_time local +. Float.trunc milliseconds in
    update t (local_to_utc (make_date ~day:d ~time:new_time))

let setSeconds ~seconds ?milliseconds t =
  if Float.is_nan t.time then update t nan
  else
    let local = utc_to_local t.time in
    let h = hour_from_time local in
    let m = min_from_time local in
    let s = Float.trunc seconds in
    let ms = match milliseconds with Some ms -> Float.trunc ms | None -> ms_from_time local in
    let d = day local in
    let time = make_time ~hour:h ~min:m ~sec:s ~ms in
    update t (local_to_utc (make_date ~day:d ~time))

let setMinutes ~minutes ?seconds ?milliseconds t =
  if Float.is_nan t.time then update t nan
  else
    let local = utc_to_local t.time in
    let h = hour_from_time local in
    let m = Float.trunc minutes in
    let s = match seconds with Some s -> Float.trunc s | None -> sec_from_time local in
    let ms = match milliseconds with Some ms -> Float.trunc ms | None -> ms_from_time local in
    let d = day local in
    let time = make_time ~hour:h ~min:m ~sec:s ~ms in
    update t (local_to_utc (make_date ~day:d ~time))

let setHours ~hours ?minutes ?seconds ?milliseconds t =
  if Float.is_nan t.time then update t nan
  else
    let local = utc_to_local t.time in
    let h = Float.trunc hours in
    let m = match minutes with Some m -> Float.trunc m | None -> min_from_time local in
    let s = match seconds with Some s -> Float.trunc s | None -> sec_from_time local in
    let ms = match milliseconds with Some ms -> Float.trunc ms | None -> ms_from_time local in
    let d = day local in
    let time = make_time ~hour:h ~min:m ~sec:s ~ms in
    update t (local_to_utc (make_date ~day:d ~time))

let setDate ~date t =
  if Float.is_nan t.time then update t nan
  else
    let local = utc_to_local t.time in
    let year = year_from_time local in
    let month = month_from_time local in
    let d = make_day ~year ~month ~date:(Float.trunc date) in
    let time = time_within_day local in
    update t (local_to_utc (make_date ~day:d ~time))

let setMonth ~month ?date t =
  if Float.is_nan t.time then update t nan
  else
    let local = utc_to_local t.time in
    let year = year_from_time local in
    let dt = match date with Some d -> Float.trunc d | None -> date_from_time local in
    let d = make_day ~year ~month:(Float.trunc month) ~date:dt in
    let time = time_within_day local in
    update t (local_to_utc (make_date ~day:d ~time))

let setFullYear ~year ?month ?date t =
  (* per spec, a NaN receiver is treated as +0 here *)
  let cur = if Float.is_nan t.time then 0. else t.time in
  let local = utc_to_local cur in
  let m = match month with Some m -> Float.trunc m | None -> month_from_time local in
  let dt = match date with Some d -> Float.trunc d | None -> date_from_time local in
  let d = make_day ~year:(Float.trunc year) ~month:m ~date:dt in
  let time = time_within_day local in
  update t (local_to_utc (make_date ~day:d ~time))

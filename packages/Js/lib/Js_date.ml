type t = float

let ms_per_second = 1000.
let ms_per_minute = 60000.
let ms_per_hour = 3600000.
let ms_per_day = 86400000.
let max_time_value = 8.64e15
let is_valid_time t = (not (Float.is_nan t)) && Float.abs t <= max_time_value
let day t = Float.floor (t /. ms_per_day)

let time_within_day t =
  let r = Float.rem t ms_per_day in
  if r < 0. then r +. ms_per_day else r

let days_in_year y =
  if Float.rem y 4. <> 0. then 365
  else if Float.rem y 100. <> 0. then 366
  else if Float.rem y 400. <> 0. then 365
  else 366

let day_from_year y =
  let y = y -. 1970. in
  (365. *. y) +. Float.floor ((y +. 1.) /. 4.) -. Float.floor ((y +. 69.) /. 100.) +. Float.floor ((y +. 369.) /. 400.)

let year_from_time t =
  if Float.is_nan t then nan
  else
    let d = day t in
    let estimate = 1970. +. Float.floor (d /. 365.2425) in
    let rec search lo hi =
      if lo >= hi then lo
      else
        let mid = Float.floor ((lo +. hi +. 1.) /. 2.) in
        if day_from_year mid <= d then search mid hi else search lo (mid -. 1.)
    in
    search (estimate -. 2.) (estimate +. 2.)

let in_leap_year t = days_in_year (year_from_time t) = 366

let day_within_year t =
  let d = day t in
  let y = year_from_time t in
  d -. day_from_year y

let month_start_days = [| 0; 31; 59; 90; 120; 151; 181; 212; 243; 273; 304; 334; 365 |]
let month_start_days_leap = [| 0; 31; 60; 91; 121; 152; 182; 213; 244; 274; 305; 335; 366 |]

let month_from_time t =
  if Float.is_nan t then nan
  else
    let d = int_of_float (day_within_year t) in
    let table = if in_leap_year t then month_start_days_leap else month_start_days in
    let rec find_month m = if m >= 11 then 11 else if d < table.(m + 1) then m else find_month (m + 1) in
    Float.of_int (find_month 0)

let date_from_time t =
  if Float.is_nan t then nan
  else
    let d = int_of_float (day_within_year t) in
    let m = int_of_float (month_from_time t) in
    let table = if in_leap_year t then month_start_days_leap else month_start_days in
    Float.of_int (d - table.(m) + 1)

let week_day t =
  if Float.is_nan t then nan
  else
    let d = day t +. 4. in
    let r = Float.rem d 7. in
    if r < 0. then r +. 7. else r

let hour_from_time t =
  if Float.is_nan t then nan
  else
    let r = Float.rem (Float.floor (t /. ms_per_hour)) 24. in
    if r < 0. then r +. 24. else r

let min_from_time t =
  if Float.is_nan t then nan
  else
    let r = Float.rem (Float.floor (t /. ms_per_minute)) 60. in
    if r < 0. then r +. 60. else r

let sec_from_time t =
  if Float.is_nan t then nan
  else
    let r = Float.rem (Float.floor (t /. ms_per_second)) 60. in
    if r < 0. then r +. 60. else r

let ms_from_time t =
  if Float.is_nan t then nan
  else
    let r = Float.rem t ms_per_second in
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

let time_clip t =
  if Float.is_nan t then nan
  else if not (Float.is_finite t) then nan
  else if Float.abs t > max_time_value then nan
  else Float.trunc t

let local_tz_offset_ms utc_time =
  if Float.is_nan utc_time then 0.
  else
    let seconds = utc_time /. 1000. in
    try
      let local_tm = Unix.localtime seconds in
      let utc_tm = Unix.gmtime seconds in
      let local_secs = (local_tm.Unix.tm_hour * 3600) + (local_tm.Unix.tm_min * 60) + local_tm.Unix.tm_sec in
      let utc_secs = (utc_tm.Unix.tm_hour * 3600) + (utc_tm.Unix.tm_min * 60) + utc_tm.Unix.tm_sec in
      let day_diff = local_tm.Unix.tm_yday - utc_tm.Unix.tm_yday in
      let day_diff = if day_diff > 1 then -1 else if day_diff < -1 then 1 else day_diff in
      Float.of_int ((day_diff * 86400) + local_secs - utc_secs) *. 1000.
    with _ -> 0.

let utc_to_local t = if Float.is_nan t then nan else t +. local_tz_offset_ms t
let local_to_utc t = if Float.is_nan t then nan else t -. local_tz_offset_ms t

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
  | None -> time_clip (now ())
  | Some year ->
      let month = match month with Some m -> m | None -> 0. in
      let date = match date with Some d -> d | None -> 1. in
      let hours = match hours with Some h -> h | None -> 0. in
      let minutes = match minutes with Some m -> m | None -> 0. in
      let seconds = match seconds with Some s -> s | None -> 0. in
      let y = if year >= 0. && year <= 99. then 1900. +. year else year in
      let d = make_day ~year:y ~month ~date in
      let t = make_time ~hour:hours ~min:minutes ~sec:seconds ~ms:0. in
      time_clip (local_to_utc (make_date ~day:d ~time:t))

let fromFloat ms = time_clip ms
let valueOf t = t
let getTime t = t
let getUTCFullYear t = if Float.is_nan t then nan else year_from_time t
let getUTCMonth t = if Float.is_nan t then nan else month_from_time t
let getUTCDate t = if Float.is_nan t then nan else date_from_time t
let getUTCDay t = if Float.is_nan t then nan else week_day t
let getUTCHours t = if Float.is_nan t then nan else hour_from_time t
let getUTCMinutes t = if Float.is_nan t then nan else min_from_time t
let getUTCSeconds t = if Float.is_nan t then nan else sec_from_time t
let getUTCMilliseconds t = if Float.is_nan t then nan else ms_from_time t
let getFullYear t = if Float.is_nan t then nan else year_from_time (utc_to_local t)
let getMonth t = if Float.is_nan t then nan else month_from_time (utc_to_local t)
let getDate t = if Float.is_nan t then nan else date_from_time (utc_to_local t)
let getDay t = if Float.is_nan t then nan else week_day (utc_to_local t)
let getHours t = if Float.is_nan t then nan else hour_from_time (utc_to_local t)
let getMinutes t = if Float.is_nan t then nan else min_from_time (utc_to_local t)
let getSeconds t = if Float.is_nan t then nan else sec_from_time (utc_to_local t)
let getMilliseconds t = if Float.is_nan t then nan else ms_from_time (utc_to_local t)
let getTimezoneOffset t = if Float.is_nan t then nan else -.local_tz_offset_ms t /. ms_per_minute

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

let toJSON t = if Float.is_nan t || not (is_valid_time t) then None else Some (toISOString t)
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

let toDateString t =
  if Float.is_nan t then "Invalid Date"
  else
    let local = utc_to_local t in
    let day_name = day_names.(int_of_float (week_day local)) in
    let month_name = month_names.(int_of_float (month_from_time local)) in
    let day = int_of_float (date_from_time local) in
    let year = int_of_float (year_from_time local) in
    Printf.sprintf "%s %s %s %d" day_name month_name (pad 2 day) year

let toTimeString t =
  if Float.is_nan t then "Invalid Date"
  else
    let local = utc_to_local t in
    let hours = int_of_float (hour_from_time local) in
    let minutes = int_of_float (min_from_time local) in
    let seconds = int_of_float (sec_from_time local) in
    let tz = format_tz_offset (local_tz_offset_ms t) in
    Printf.sprintf "%s:%s:%s %s" (pad 2 hours) (pad 2 minutes) (pad 2 seconds) tz

let toString t = if Float.is_nan t then "Invalid Date" else Printf.sprintf "%s %s" (toDateString t) (toTimeString t)
let toLocaleString t = toString t
let toLocaleDateString t = toDateString t
let toLocaleTimeString t = toTimeString t
let parse_int_opt s = try Some (int_of_string s) with _ -> None
let ( let* ) = Option.bind
let guard condition = if condition then Some () else None
let read_chars s ~pos ~len:n = if pos + n > String.length s then None else Some (String.sub s pos n)

let parse_int_in_range s ~min ~max =
  let* value = parse_int_opt s in
  let* () = guard (value >= min && value <= max) in
  Some value

let parse_year s =
  let len = String.length s in
  if len = 0 then None
  else
    let sign, start, digits = match s.[0] with '+' -> (1., 1, 6) | '-' -> (-1., 1, 6) | _ -> (1., 0, 4) in
    let* year_str = read_chars s ~pos:start ~len:digits in
    let* year_int = parse_int_opt year_str in
    let* () = guard (not (sign < 0. && year_int = 0)) in
    let year = sign *. Float.of_int year_int in
    let next_pos = start + digits in
    Some (year, next_pos)

let parse_2digit_component s ~pos ~delimiter ~min ~max =
  let len = String.length s in
  if pos >= len then None
  else if s.[pos] <> delimiter then None
  else
    let pos = pos + 1 in
    let* component_str = read_chars s ~pos ~len:2 in
    let* value = parse_int_in_range component_str ~min ~max in
    Some (value, pos + 2)

let parse_seconds s ~pos =
  let len = String.length s in
  if pos >= len || s.[pos] <> ':' then Some (0., pos)
  else
    let pos = pos + 1 in
    match read_chars s ~pos ~len:2 with
    | None -> None
    | Some sec_str -> (
        match parse_int_in_range sec_str ~min:0 ~max:59 with
        | None -> None
        | Some sec -> Some (Float.of_int sec, pos + 2))

let parse_milliseconds s ~pos =
  let len = String.length s in
  if pos >= len || s.[pos] <> '.' then (0., pos)
  else
    let pos = pos + 1 in
    let ms_start = pos in
    let rec count_digits p = if p < len && s.[p] >= '0' && s.[p] <= '9' then count_digits (p + 1) else p in
    let ms_end = count_digits ms_start in
    let digit_count = ms_end - ms_start in
    if digit_count = 0 then (0., ms_end)
    else
      let ms_str = String.sub s ms_start (min digit_count 3) in
      let ms_str =
        let pad_len = 3 - String.length ms_str in
        if pad_len > 0 then ms_str ^ String.make pad_len '0' else ms_str
      in
      let ms = match parse_int_opt ms_str with Some v -> Float.of_int v | None -> 0. in
      (ms, ms_end)

let parse_timezone s ~pos =
  let len = String.length s in
  if pos >= len then (0., pos)
  else
    match s.[pos] with
    | 'Z' -> (0., pos + 1)
    | ('+' | '-') as sign_char ->
        let sign = if sign_char = '-' then -1. else 1. in
        let pos = pos + 1 in
        let tz_hours, pos =
          match read_chars s ~pos ~len:2 with
          | Some h_str -> ( match parse_int_opt h_str with Some h -> (Float.of_int h, pos + 2) | None -> (0., pos))
          | None -> (0., pos)
        in
        let tz_minutes, pos =
          if pos < len && s.[pos] = ':' then
            let pos = pos + 1 in
            match read_chars s ~pos ~len:2 with
            | Some m_str -> ( match parse_int_opt m_str with Some m -> (Float.of_int m, pos + 2) | None -> (0., pos))
            | None -> (0., pos)
          else (0., pos)
        in
        let offset_ms = sign *. ((tz_hours *. ms_per_hour) +. (tz_minutes *. ms_per_minute)) in
        (offset_ms, pos)
    | _ -> (0., pos)

let parse_time_component s ~pos ~year ~month ~date =
  let len = String.length s in
  if pos >= len then Some (compute_utc ~year ~month ~date ())
  else if s.[pos] <> 'T' && s.[pos] <> ' ' then None
  else
    let pos = pos + 1 in
    let* hours_str = read_chars s ~pos ~len:2 in
    let* hours_int = parse_int_in_range hours_str ~min:0 ~max:24 in
    let hours = Float.of_int hours_int in
    let pos = pos + 2 in
    let* () = guard (pos < len && s.[pos] = ':') in
    let pos = pos + 1 in
    let* minutes_str = read_chars s ~pos ~len:2 in
    let* minutes_int = parse_int_in_range minutes_str ~min:0 ~max:59 in
    let minutes = Float.of_int minutes_int in
    let pos = pos + 2 in
    let* seconds, pos = parse_seconds s ~pos in
    let ms, pos = parse_milliseconds s ~pos in
    let tz_offset_ms, _pos = parse_timezone s ~pos in
    let* () = guard (not (hours_int = 24 && (minutes_int <> 0 || seconds <> 0. || ms <> 0.))) in
    let result = compute_utc ~year ~month ~date ~hours ~minutes ~seconds ~ms () in
    Some (result -. tz_offset_ms)

let parse_iso8601 s =
  let len = String.length s in
  if len = 0 then None
  else
    let* year, pos = parse_year s in
    if pos >= len then Some (compute_utc ~year ~month:0. ())
    else
      let* month_int, pos = parse_2digit_component s ~pos ~delimiter:'-' ~min:1 ~max:12 in
      let month = Float.of_int (month_int - 1) in
      if pos >= len then Some (compute_utc ~year ~month ())
      else
        let* date_int, pos = parse_2digit_component s ~pos ~delimiter:'-' ~min:1 ~max:31 in
        let date = Float.of_int date_int in
        parse_time_component s ~pos ~year ~month ~date

let weekdays = [ "Sun"; "Mon"; "Tue"; "Wed"; "Thu"; "Fri"; "Sat" ]

let strip_weekday s =
  let parts = String.split_on_char ' ' (String.trim s) in
  match parts with day :: rest when List.mem day weekdays -> String.concat " " rest | _ -> s

let array_find_index pred arr =
  let len = Array.length arr in
  let rec loop i = if i >= len then None else if pred arr.(i) then Some i else loop (i + 1) in
  loop 0

let parse_month_name name = array_find_index (fun m -> String.equal m name) month_names |> Option.map Float.of_int

let parse_gmt_offset tz_str =
  let len = String.length tz_str in
  if len < 3 || String.sub tz_str 0 3 <> "GMT" then 0.
  else
    let tz_part = String.sub tz_str 3 (len - 3) in
    if String.length tz_part < 5 then 0.
    else
      let sign = if tz_part.[0] = '-' then -1. else 1. in
      let h_str = String.sub tz_part 1 2 in
      let m_str = String.sub tz_part 3 2 in
      match (parse_int_opt h_str, parse_int_opt m_str) with
      | Some h, Some m -> sign *. ((Float.of_int h *. ms_per_hour) +. (Float.of_int m *. ms_per_minute))
      | _ -> 0.

let parse_time_string time_str =
  match String.split_on_char ':' time_str with
  | [ h; m; s ] -> (
      match (parse_int_opt h, parse_int_opt m, parse_int_opt s) with
      | Some hi, Some mi, Some si -> Some (Float.of_int hi, Float.of_int mi, Float.of_int si)
      | _ -> None)
  | _ -> None

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
  let s = strip_weekday s in
  let parts = String.split_on_char ' ' (String.trim s) in
  match parts with
  | month_str :: day_str :: year_str :: rest ->
      let* month = parse_month_name month_str in
      let* day_int = parse_int_opt day_str in
      let* year_int = parse_int_opt year_str in
      let date = Float.of_int day_int in
      let year = Float.of_int year_int in
      let hours, minutes, seconds, tz_offset = parse_legacy_time_and_tz rest in
      let result = compute_utc ~year ~month ~date ~hours ~minutes ~seconds () in
      Some (result -. tz_offset)
  | _ -> None

let parse s =
  let s = String.trim s in
  if String.length s = 0 then nan
  else match parse_iso8601 s with Some t -> t | None -> ( match parse_legacy s with Some t -> t | None -> nan)

let parseAsFloat = parse
let fromString s = time_clip (parse s)
let setTime ~time _t = time_clip time
let setUTCTime ~time _t = time_clip time

let setUTCMilliseconds ~milliseconds t =
  if Float.is_nan t then nan
  else
    let d = day t in
    let time = time_within_day t in
    let new_time = time -. ms_from_time t +. Float.trunc milliseconds in
    time_clip (make_date ~day:d ~time:new_time)

let setUTCSeconds ~seconds ?milliseconds t =
  if Float.is_nan t then nan
  else
    let h = hour_from_time t in
    let m = min_from_time t in
    let s = Float.trunc seconds in
    let ms = match milliseconds with Some ms -> Float.trunc ms | None -> ms_from_time t in
    let d = day t in
    let time = make_time ~hour:h ~min:m ~sec:s ~ms in
    time_clip (make_date ~day:d ~time)

let setUTCMinutes ~minutes ?seconds ?milliseconds t =
  if Float.is_nan t then nan
  else
    let h = hour_from_time t in
    let m = Float.trunc minutes in
    let s = match seconds with Some s -> Float.trunc s | None -> sec_from_time t in
    let ms = match milliseconds with Some ms -> Float.trunc ms | None -> ms_from_time t in
    let d = day t in
    let time = make_time ~hour:h ~min:m ~sec:s ~ms in
    time_clip (make_date ~day:d ~time)

let setUTCHours ~hours ?minutes ?seconds ?milliseconds t =
  if Float.is_nan t then nan
  else
    let h = Float.trunc hours in
    let m = match minutes with Some m -> Float.trunc m | None -> min_from_time t in
    let s = match seconds with Some s -> Float.trunc s | None -> sec_from_time t in
    let ms = match milliseconds with Some ms -> Float.trunc ms | None -> ms_from_time t in
    let d = day t in
    let time = make_time ~hour:h ~min:m ~sec:s ~ms in
    time_clip (make_date ~day:d ~time)

let setUTCDate ~date t =
  if Float.is_nan t then nan
  else
    let year = year_from_time t in
    let month = month_from_time t in
    let d = make_day ~year ~month ~date:(Float.trunc date) in
    let time = time_within_day t in
    time_clip (make_date ~day:d ~time)

let setUTCMonth ~month ?date t =
  if Float.is_nan t then nan
  else
    let year = year_from_time t in
    let dt = match date with Some d -> Float.trunc d | None -> date_from_time t in
    let d = make_day ~year ~month:(Float.trunc month) ~date:dt in
    let time = time_within_day t in
    time_clip (make_date ~day:d ~time)

let setUTCFullYear ~year ?month ?date t =
  let t = if Float.is_nan t then 0. else t in
  let m = match month with Some m -> Float.trunc m | None -> month_from_time t in
  let dt = match date with Some d -> Float.trunc d | None -> date_from_time t in
  let d = make_day ~year:(Float.trunc year) ~month:m ~date:dt in
  let time = time_within_day t in
  time_clip (make_date ~day:d ~time)

let setMilliseconds ~milliseconds t =
  if Float.is_nan t then nan
  else
    let local = utc_to_local t in
    let d = day local in
    let time = time_within_day local in
    let new_time = time -. ms_from_time local +. Float.trunc milliseconds in
    time_clip (local_to_utc (make_date ~day:d ~time:new_time))

let setSeconds ~seconds ?milliseconds t =
  if Float.is_nan t then nan
  else
    let local = utc_to_local t in
    let h = hour_from_time local in
    let m = min_from_time local in
    let s = Float.trunc seconds in
    let ms = match milliseconds with Some ms -> Float.trunc ms | None -> ms_from_time local in
    let d = day local in
    let time = make_time ~hour:h ~min:m ~sec:s ~ms in
    time_clip (local_to_utc (make_date ~day:d ~time))

let setMinutes ~minutes ?seconds ?milliseconds t =
  if Float.is_nan t then nan
  else
    let local = utc_to_local t in
    let h = hour_from_time local in
    let m = Float.trunc minutes in
    let s = match seconds with Some s -> Float.trunc s | None -> sec_from_time local in
    let ms = match milliseconds with Some ms -> Float.trunc ms | None -> ms_from_time local in
    let d = day local in
    let time = make_time ~hour:h ~min:m ~sec:s ~ms in
    time_clip (local_to_utc (make_date ~day:d ~time))

let setHours ~hours ?minutes ?seconds ?milliseconds t =
  if Float.is_nan t then nan
  else
    let local = utc_to_local t in
    let h = Float.trunc hours in
    let m = match minutes with Some m -> Float.trunc m | None -> min_from_time local in
    let s = match seconds with Some s -> Float.trunc s | None -> sec_from_time local in
    let ms = match milliseconds with Some ms -> Float.trunc ms | None -> ms_from_time local in
    let d = day local in
    let time = make_time ~hour:h ~min:m ~sec:s ~ms in
    time_clip (local_to_utc (make_date ~day:d ~time))

let setDate ~date t =
  if Float.is_nan t then nan
  else
    let local = utc_to_local t in
    let year = year_from_time local in
    let month = month_from_time local in
    let d = make_day ~year ~month ~date:(Float.trunc date) in
    let time = time_within_day local in
    time_clip (local_to_utc (make_date ~day:d ~time))

let setMonth ~month ?date t =
  if Float.is_nan t then nan
  else
    let local = utc_to_local t in
    let year = year_from_time local in
    let dt = match date with Some d -> Float.trunc d | None -> date_from_time local in
    let d = make_day ~year ~month:(Float.trunc month) ~date:dt in
    let time = time_within_day local in
    time_clip (local_to_utc (make_date ~day:d ~time))

let setFullYear ~year ?month ?date t =
  let t = if Float.is_nan t then 0. else t in
  let local = utc_to_local t in
  let m = match month with Some m -> Float.trunc m | None -> month_from_time local in
  let dt = match date with Some d -> Float.trunc d | None -> date_from_time local in
  let d = make_day ~year:(Float.trunc year) ~month:m ~date:dt in
  let time = time_within_day local in
  time_clip (local_to_utc (make_date ~day:d ~time))

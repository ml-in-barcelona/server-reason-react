(** JavaScript Date implementation following ECMA-262 §21.4

    This is a spec-compliant implementation using only OCaml stdlib + Unix. Internal representation: float (milliseconds
    since Unix epoch, or NaN for invalid dates). *)

type t = float
(** The Date type - represents milliseconds since Unix epoch, or NaN for invalid dates *)

(** {1 Constructors} *)

val make : unit -> t
(** Returns a date representing the current time *)

val fromFloat : float -> t
(** Create a Date from epoch milliseconds *)

val of_epoch_ms : float -> t
(** Alias for fromFloat *)

val fromString : string -> t
(** Create a Date by parsing a string *)

val makeWithYM : year:float -> month:float -> t
(** Create a Date from year and month (local time). Note: Years 0-99 are treated as 1900-1999 *)

val makeWithYMD : year:float -> month:float -> date:float -> t
(** Create a Date from year, month, date (local time) *)

val makeWithYMDH : year:float -> month:float -> date:float -> hours:float -> t
(** Create a Date from year, month, date, hours (local time) *)

val makeWithYMDHM : year:float -> month:float -> date:float -> hours:float -> minutes:float -> t
(** Create a Date from year, month, date, hours, minutes (local time) *)

val makeWithYMDHMS : year:float -> month:float -> date:float -> hours:float -> minutes:float -> seconds:float -> t
(** Create a Date from all components (local time) *)

(** {1 Date.UTC constructors} *)

val utc :
  year:float ->
  month:float ->
  ?day:float ->
  ?hours:float ->
  ?minutes:float ->
  ?seconds:float ->
  ?ms:float ->
  unit ->
  float
(** Date.UTC(year, month[, date[, hours[, minutes[, seconds[, ms]]]]]) Returns epoch milliseconds for the given UTC date
    components. Note: Years 0-99 are treated as 1900-1999 *)

val utcWithYM : year:float -> month:float -> float
(** Date.UTC with year and month only *)

val utcWithYMD : year:float -> month:float -> date:float -> float
(** Date.UTC with year, month, date *)

val utcWithYMDH : year:float -> month:float -> date:float -> hours:float -> float
(** Date.UTC with year, month, date, hours *)

val utcWithYMDHM : year:float -> month:float -> date:float -> hours:float -> minutes:float -> float
(** Date.UTC with year, month, date, hours, minutes *)

val utcWithYMDHMS : year:float -> month:float -> date:float -> hours:float -> minutes:float -> seconds:float -> float
(** Date.UTC with all components *)

(** {1 Date.now and Date.parse} *)

val now : unit -> float
(** Date.now() - returns current time as epoch milliseconds *)

val parse : string -> float
(** Date.parse(string) - parses a date string, returns NaN on failure. Supports ISO 8601 and legacy formats. *)

val parseAsFloat : string -> float
(** Alias for parse *)

(** {1 UTC Getters} *)

val valueOf : t -> float
(** Returns the primitive value (epoch ms), equivalent to getTime *)

val getTime : t -> float
(** Returns the epoch milliseconds *)

val getUTCDate : t -> float
(** Returns the day of the month (1-31) in UTC *)

val getUTCDay : t -> float
(** Returns the day of the week (0=Sunday, 6=Saturday) in UTC *)

val getUTCFullYear : t -> float
(** Returns the year in UTC *)

val getUTCHours : t -> float
(** Returns the hours (0-23) in UTC *)

val getUTCMilliseconds : t -> float
(** Returns the milliseconds (0-999) in UTC *)

val getUTCMinutes : t -> float
(** Returns the minutes (0-59) in UTC *)

val getUTCMonth : t -> float
(** Returns the month (0-11) in UTC *)

val getUTCSeconds : t -> float
(** Returns the seconds (0-59) in UTC *)

(** {1 Local Time Getters} *)

val getDate : t -> float
(** Returns the day of the month (1-31) in local time *)

val getDay : t -> float
(** Returns the day of the week (0=Sunday, 6=Saturday) in local time *)

val getFullYear : t -> float
(** Returns the year in local time *)

val getHours : t -> float
(** Returns the hours (0-23) in local time *)

val getMilliseconds : t -> float
(** Returns the milliseconds (0-999) in local time *)

val getMinutes : t -> float
(** Returns the minutes (0-59) in local time *)

val getMonth : t -> float
(** Returns the month (0-11) in local time *)

val getSeconds : t -> float
(** Returns the seconds (0-59) in local time *)

val getTimezoneOffset : t -> float
(** Returns the timezone offset in minutes (positive = west of UTC) *)

(** {1 UTC Setters}
    All setters return the new timestamp (milliseconds). *)

val setUTCDate : date:float -> t -> float
val setUTCFullYear : year:float -> t -> float
val setUTCFullYearM : year:float -> month:float -> t -> float
val setUTCFullYearMD : year:float -> month:float -> date:float -> t -> float
val setUTCHours : hours:float -> t -> float
val setUTCHoursM : hours:float -> minutes:float -> t -> float
val setUTCHoursMS : hours:float -> minutes:float -> seconds:float -> t -> float
val setUTCHoursMSMs : hours:float -> minutes:float -> seconds:float -> milliseconds:float -> t -> float
val setUTCMilliseconds : milliseconds:float -> t -> float
val setUTCMinutes : minutes:float -> t -> float
val setUTCMinutesS : minutes:float -> seconds:float -> t -> float
val setUTCMinutesSMs : minutes:float -> seconds:float -> milliseconds:float -> t -> float
val setUTCMonth : month:float -> t -> float
val setUTCMonthD : month:float -> date:float -> t -> float
val setUTCSeconds : seconds:float -> t -> float
val setUTCSecondsMs : seconds:float -> milliseconds:float -> t -> float
val setUTCTime : time:float -> t -> float

(** {1 Local Time Setters}
    All setters return the new timestamp (milliseconds). *)

val setDate : date:float -> t -> float
val setFullYear : year:float -> t -> float
val setFullYearM : year:float -> month:float -> t -> float
val setFullYearMD : year:float -> month:float -> date:float -> t -> float
val setHours : hours:float -> t -> float
val setHoursM : hours:float -> minutes:float -> t -> float
val setHoursMS : hours:float -> minutes:float -> seconds:float -> t -> float
val setHoursMSMs : hours:float -> minutes:float -> seconds:float -> milliseconds:float -> t -> float
val setMilliseconds : milliseconds:float -> t -> float
val setMinutes : minutes:float -> t -> float
val setMinutesS : minutes:float -> seconds:float -> t -> float
val setMinutesSMs : minutes:float -> seconds:float -> milliseconds:float -> t -> float
val setMonth : month:float -> t -> float
val setMonthD : month:float -> date:float -> t -> float
val setSeconds : seconds:float -> t -> float
val setSecondsMs : seconds:float -> milliseconds:float -> t -> float
val setTime : time:float -> t -> float

(** {1 String Conversion} *)

val toDateString : t -> string
(** Returns a human-readable date string (local time) *)

val toISOString : t -> string
(** Returns an ISO 8601 formatted string: "YYYY-MM-DDTHH:mm:ss.sssZ" Raises Invalid_argument for invalid dates *)

val toJSON : t -> string option
(** Returns ISO string wrapped in option, None for invalid dates *)

val toJSONUnsafe : t -> string
(** Same as toISOString - throws for invalid dates *)

val toLocaleDateString : t -> string
(** Returns locale-formatted date string (simplified implementation) *)

val toLocaleString : t -> string
(** Returns locale-formatted string (simplified implementation) *)

val toLocaleTimeString : t -> string
(** Returns locale-formatted time string (simplified implementation) *)

val toString : t -> string
(** Returns full string representation in local time *)

val toTimeString : t -> string
(** Returns time string in local time *)

val toUTCString : t -> string
(** Returns string in UTC: "Tue, 02 Dec 2025 09:30:00 GMT" *)

(** Provide bindings for JS Date *)

type t

val valueOf : t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val make : unit -> t [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val fromFloat : float -> t [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val fromString : string -> t [@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val makeWithYM : year:float -> month:float -> t
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val makeWithYMD : year:float -> month:float -> date:float -> t
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val makeWithYMDH : year:float -> month:float -> date:float -> hours:float -> t
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val makeWithYMDHM : year:float -> month:float -> date:float -> hours:float -> minutes:float -> t
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val makeWithYMDHMS : year:float -> month:float -> date:float -> hours:float -> minutes:float -> seconds:float -> t
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val utcWithYM : year:float -> month:float -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val utcWithYMD : year:float -> month:float -> date:float -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val utcWithYMDH : year:float -> month:float -> date:float -> hours:float -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val utcWithYMDHM : year:float -> month:float -> date:float -> hours:float -> minutes:float -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val utcWithYMDHMS : year:float -> month:float -> date:float -> hours:float -> minutes:float -> seconds:float -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val now : unit -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val parseAsFloat : string -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val getDate : t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val getDay : t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val getFullYear : t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val getHours : t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val getMilliseconds : t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val getMinutes : t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val getMonth : t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val getSeconds : t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val getTime : t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val getTimezoneOffset : t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val getUTCDate : t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val getUTCDay : t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val getUTCFullYear : t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val getUTCHours : t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val getUTCMilliseconds : t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val getUTCMinutes : t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val getUTCMonth : t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val getUTCSeconds : t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val setDate : float -> t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setFullYear : float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setFullYearM : year:float -> month:float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setFullYearMD : year:float -> month:float -> date:float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setHours : float -> t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setHoursM : hours:float -> minutes:float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setHoursMS : hours:float -> minutes:float -> seconds:float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setHoursMSMs : hours:float -> minutes:float -> seconds:float -> milliseconds:float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setMilliseconds : float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setMinutes : float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setMinutesS : minutes:float -> seconds:float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setMinutesSMs : minutes:float -> seconds:float -> milliseconds:float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setMonth : float -> t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setMonthD : month:float -> date:float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setSeconds : float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setSecondsMs : seconds:float -> milliseconds:float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setTime : float -> t -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setUTCDate : float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setUTCFullYear : float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setUTCFullYearM : year:float -> month:float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setUTCFullYearMD : year:float -> month:float -> date:float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setUTCHours : float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setUTCHoursM : hours:float -> minutes:float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setUTCHoursMS : hours:float -> minutes:float -> seconds:float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setUTCHoursMSMs : hours:float -> minutes:float -> seconds:float -> milliseconds:float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setUTCMilliseconds : float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setUTCMinutes : float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setUTCMinutesS : minutes:float -> seconds:float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setUTCMinutesSMs : minutes:float -> seconds:float -> milliseconds:float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setUTCMonth : float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setUTCMonthD : month:float -> date:float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setUTCSeconds : float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setUTCSecondsMs : seconds:float -> milliseconds:float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setUTCTime : float -> t -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val toDateString : t -> string [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val toISOString : t -> string [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val toJSON : t -> string option [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val toJSONUnsafe : t -> string [@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val toLocaleDateString : t -> string
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val toLocaleString : t -> string [@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val toLocaleTimeString : t -> string
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val toString : t -> string [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val toTimeString : t -> string [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val toUTCString : t -> string [@@alert not_implemented "is not implemented in native under server-reason-react.js"]

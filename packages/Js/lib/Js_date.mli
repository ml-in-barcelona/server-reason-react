(** JavaScript Date API *)

type t = float

val valueOf : t -> float
val fromFloat : float -> t
val fromString : string -> t
val make : ?year:float -> ?month:float -> ?date:float -> ?hours:float -> ?minutes:float -> ?seconds:float -> unit -> t
val utc : year:float -> ?month:float -> ?date:float -> ?hours:float -> ?minutes:float -> ?seconds:float -> unit -> float
val now : unit -> float
val parseAsFloat : string -> float
val getDate : t -> float
val getDay : t -> float
val getFullYear : t -> float
val getHours : t -> float
val getMilliseconds : t -> float
val getMinutes : t -> float
val getMonth : t -> float
val getSeconds : t -> float
val getTime : t -> float
val getTimezoneOffset : t -> float
val getUTCDate : t -> float
val getUTCDay : t -> float
val getUTCFullYear : t -> float
val getUTCHours : t -> float
val getUTCMilliseconds : t -> float
val getUTCMinutes : t -> float
val getUTCMonth : t -> float
val getUTCSeconds : t -> float
val makeWithYM : year:float -> month:float -> t
val makeWithYMD : year:float -> month:float -> date:float -> t
val makeWithYMDH : year:float -> month:float -> date:float -> hours:float -> t
val makeWithYMDHM : year:float -> month:float -> date:float -> hours:float -> minutes:float -> t
val makeWithYMDHMS : year:float -> month:float -> date:float -> hours:float -> minutes:float -> seconds:float -> t
val utcWithYM : year:float -> month:float -> float
val utcWithYMD : year:float -> month:float -> date:float -> float
val utcWithYMDH : year:float -> month:float -> date:float -> hours:float -> float
val utcWithYMDHM : year:float -> month:float -> date:float -> hours:float -> minutes:float -> float
val utcWithYMDHMS : year:float -> month:float -> date:float -> hours:float -> minutes:float -> seconds:float -> float
val setDate : date:float -> t -> float
val setFullYear : year:float -> ?month:float -> ?date:float -> t -> float
val setHours : hours:float -> ?minutes:float -> ?seconds:float -> ?milliseconds:float -> t -> float
val setMilliseconds : milliseconds:float -> t -> float
val setMinutes : minutes:float -> ?seconds:float -> ?milliseconds:float -> t -> float
val setMonth : month:float -> ?date:float -> t -> float
val setSeconds : seconds:float -> ?milliseconds:float -> t -> float
val setTime : time:float -> t -> float
val setUTCDate : date:float -> t -> float
val setUTCFullYear : year:float -> ?month:float -> ?date:float -> t -> float
val setUTCHours : hours:float -> ?minutes:float -> ?seconds:float -> ?milliseconds:float -> t -> float
val setUTCMilliseconds : milliseconds:float -> t -> float
val setUTCMinutes : minutes:float -> ?seconds:float -> ?milliseconds:float -> t -> float
val setUTCMonth : month:float -> ?date:float -> t -> float
val setUTCSeconds : seconds:float -> ?milliseconds:float -> t -> float
val setUTCTime : time:float -> t -> float
val toDateString : t -> string
val toISOString : t -> string
val toJSON : t -> string option
val toJSONUnsafe : t -> string
val toLocaleDateString : t -> string
val toLocaleString : t -> string
val toLocaleTimeString : t -> string
val toString : t -> string
val toTimeString : t -> string
val toUTCString : t -> string

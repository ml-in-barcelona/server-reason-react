(** Contains functions available in the global scope ([window] in a browser context) *)

type intervalId
(** Identify an interval started by {! setInterval} *)

type timeoutId
(** Identify timeout started by {! setTimeout} *)

val clearInterval : intervalId -> unit
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val clearTimeout : timeoutId -> unit
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setInterval : f:(unit -> unit) -> int -> intervalId
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setIntervalFloat : f:(unit -> unit) -> float -> intervalId
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setTimeout : f:(unit -> unit) -> int -> timeoutId
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val setTimeoutFloat : f:(unit -> unit) -> float -> timeoutId
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val encodeURI : string -> string
val decodeURI : string -> string
val encodeURIComponent : string -> string
val decodeURIComponent : string -> string

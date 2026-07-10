(** Contains functions available in the global scope ([window] in a browser context) *)

type intervalId
(** Identify an interval started by {! setInterval} *)

type timeoutId
(** Identify timeout started by {! setTimeout} *)

val clearInterval : intervalId -> unit
val clearTimeout : timeoutId -> unit
val setInterval : f:(unit -> unit) -> int -> intervalId
val setIntervalFloat : f:(unit -> unit) -> float -> intervalId
val setTimeout : f:(unit -> unit) -> int -> timeoutId
val setTimeoutFloat : f:(unit -> unit) -> float -> timeoutId
val encodeURI : string -> string
val decodeURI : string -> string
val encodeURIComponent : string -> string
val decodeURIComponent : string -> string

val parseFloat : string -> float
(** Parses a string and returns a floating point number. Returns NaN if parsing fails. *)

val parseInt : ?radix:int -> string -> float
(** Parses a string and returns an integer. Returns NaN if parsing fails.
    @param radix The base (2-36) to use for parsing. Default is 10. *)

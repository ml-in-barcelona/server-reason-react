(** Provides functions for inspecting and manipulating [float]s *)

type t = float

val _NaN : t
val isNaN : t -> bool
val isFinite : t -> bool

val toExponential : ?digits:int -> t -> string
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val toFixed : ?digits:int -> t -> string

val toPrecision : ?digits:int -> t -> string
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val toString : ?radix:int -> t -> string
val fromString : string -> t

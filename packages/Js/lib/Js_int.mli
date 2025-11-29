(** Provides functions for inspecting and manipulating [int]s *)

type t = int

val toExponential : ?digits:t -> t -> string
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val toPrecision : ?digits:t -> t -> string
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val toString : ?radix:t -> t -> string
val toFloat : int -> float
val equal : t -> t -> bool
val max : int
val min : int

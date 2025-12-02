(** Provides functions for inspecting and manipulating [float]s *)

type t = float

val _NaN : t
val isNaN : t -> bool
val isFinite : t -> bool

val isInteger : t -> bool
(** Returns true if the value is a finite number with no fractional part *)

val toExponential : ?digits:int -> t -> string
(** Formats a number in exponential notation.
    @raise Invalid_argument if digits is not in range 0-100 *)

val toFixed : ?digits:int -> t -> string
(** Formats a number with fixed-point notation.
    @raise Failure if digits is not in range 0-100 *)

val toPrecision : ?digits:int -> t -> string
(** Formats a number with the specified number of significant digits.
    @raise Invalid_argument if digits is not in range 1-100 *)

val toString : ?radix:int -> t -> string
(** Converts a number to a string. Optionally specify a radix (2-36).
    @raise Invalid_argument if radix is not in range 2-36 *)

val fromString : string -> t

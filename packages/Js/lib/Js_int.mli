(** Provides functions for inspecting and manipulating [int]s *)

type t = int

val toExponential : ?digits:t -> t -> string
(** Formats a number in exponential notation.
    @raise Invalid_argument if digits is not in range 0-100 *)

val toPrecision : ?digits:t -> t -> string
(** Formats a number with the specified number of significant digits.
    @raise Invalid_argument if digits is not in range 1-100 *)

val toString : ?radix:t -> t -> string
(** Converts an integer to a string. Optionally specify a radix (2-36).
    @raise Invalid_argument if radix is not in range 2-36 *)

val toFloat : int -> float
val equal : t -> t -> bool
val max : int
val min : int

(** Provide utilities for bigint *)

type t
(** The BigInt type, representing arbitrary precision integers *)

(** {1 Constructors} *)

val of_int : int -> t
(** [of_int n] creates a BigInt from an OCaml integer *)

val of_int64 : int64 -> t
(** [of_int64 n] creates a BigInt from an OCaml int64 *)

val of_string : string -> t
(** [of_string s] creates a BigInt from a string representation.
    Supports decimal, hexadecimal (0x prefix), binary (0b prefix),
    and octal (0o prefix) formats. Whitespace is trimmed.
    Empty string returns 0. Invalid strings return 0. *)

val of_string_exn : string -> t
(** [of_string_exn s] creates a BigInt from a string representation.
    Like [of_string] but raises [Failure] on invalid input. *)

(** {1 Conversions} *)

val to_string : ?radix:int -> t -> string
(** [to_string ?radix bigint] returns a string representation.
    [radix] can be 2-36 (default 10). *)

val toString : t -> string
(** Alias for [to_string] with default radix 10 *)

val to_float : t -> float
(** [to_float bigint] converts to float. May lose precision for large values. *)

(** {1 Arithmetic operations} *)

val neg : t -> t
(** [neg x] returns the negation of [x] *)

val abs : t -> t
(** [abs x] returns the absolute value of [x] *)

val add : t -> t -> t
(** [add x y] returns [x + y] *)

val sub : t -> t -> t
(** [sub x y] returns [x - y] *)

val mul : t -> t -> t
(** [mul x y] returns [x * y] *)

val div : t -> t -> t
(** [div x y] returns [x / y], truncated toward zero.
    Raises [Division_by_zero] if [y] is zero. *)

val rem : t -> t -> t
(** [rem x y] returns the remainder of [x / y].
    The sign follows the dividend (JavaScript semantics).
    Raises [Division_by_zero] if [y] is zero. *)

val pow : t -> t -> t
(** [pow base exp] returns [base] raised to the power [exp].
    Raises [Invalid_argument] if [exp] is negative. *)

(** {1 Bitwise operations} *)

val logand : t -> t -> t
(** [logand x y] returns the bitwise AND of [x] and [y] *)

val logor : t -> t -> t
(** [logor x y] returns the bitwise OR of [x] and [y] *)

val logxor : t -> t -> t
(** [logxor x y] returns the bitwise XOR of [x] and [y] *)

val lognot : t -> t
(** [lognot x] returns the bitwise NOT of [x] (two's complement) *)

val shift_left : t -> int -> t
(** [shift_left x n] returns [x] shifted left by [n] bits *)

val shift_right : t -> int -> t
(** [shift_right x n] returns [x] arithmetically shifted right by [n] bits.
    Sign-extending for negative numbers. *)

(** {1 Comparison operations} *)

val compare : t -> t -> int
(** [compare x y] returns -1 if [x < y], 0 if [x = y], 1 if [x > y] *)

val equal : t -> t -> bool
(** [equal x y] returns [true] if [x = y] *)

val lt : t -> t -> bool
(** [lt x y] returns [true] if [x < y] *)

val le : t -> t -> bool
(** [le x y] returns [true] if [x <= y] *)

val gt : t -> t -> bool
(** [gt x y] returns [true] if [x > y] *)

val ge : t -> t -> bool
(** [ge x y] returns [true] if [x >= y] *)

(** {1 Bit width conversion} *)

val as_int_n : int -> t -> t
(** [as_int_n bits x] wraps [x] to a signed integer of [bits] bits.
    Equivalent to JavaScript's BigInt.asIntN. *)

val as_uint_n : int -> t -> t
(** [as_uint_n bits x] wraps [x] to an unsigned integer of [bits] bits.
    Equivalent to JavaScript's BigInt.asUintN. *)

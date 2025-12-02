(** JavaScript Math API *)

val _E : float
val _LN2 : float
val _LN10 : float
val _LOG2E : float
val _LOG10E : float
val _PI : float
val _SQRT1_2 : float
val _SQRT2 : float
val abs_int : int -> int [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val abs_float : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val acos : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val acosh : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val asin : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val asinh : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val atan : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val atanh : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val atan2 : y:float -> x:float -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val cbrt : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val unsafe_ceil_int : float -> int [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val ceil_int : float -> int [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val ceil_float : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val clz32 : int -> int [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val cos : float -> float
val cosh : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val exp : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val expm1 : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val unsafe_floor_int : float -> int
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val floor_int : float -> int [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val floor_float : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val fround : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val hypot : float -> float -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val hypotMany : float array -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val imul : int -> int -> int [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val log : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val log1p : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val log10 : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val log2 : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val max_int : int -> int -> int
val maxMany_int : int array -> int [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val max_float : float -> float -> float

val maxMany_float : float array -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val min_int : int -> int -> int
val minMany_int : int array -> int [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val min_float : float -> float -> float

val minMany_float : float array -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val pow_float : base:float -> exp:float -> float
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val random : unit -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val random_int : int -> int -> int [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val unsafe_round : float -> int [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val round : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val sign_int : int -> int [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val sign_float : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val sin : float -> float
val sinh : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val sqrt : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val tan : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val tanh : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val unsafe_trunc : float -> int [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val trunc : float -> float [@@alert not_implemented "is not implemented in native under server-reason-react.js"]

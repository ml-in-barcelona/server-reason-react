(** JavaScript Math API *)

(** Euler's number *)
let _E = 2.718281828459045

(** natural logarithm of 2 *)
let _LN2 = 0.6931471805599453

(** natural logarithm of 10 *)
let _LN10 = 2.302585092994046

(** base 2 logarithm of E *)
let _LOG2E = 1.4426950408889634

(** base 10 logarithm of E *)
let _LOG10E = 0.4342944819032518

(** Pi... (ratio of the circumference and diameter of a circle) *)
let _PI = 3.141592653589793

(** square root of 1/2 *)
let _SQRT1_2 = 0.7071067811865476

(** square root of 2 *)
let _SQRT2 = 1.41421356237

(** absolute value *)
let abs_int _ = Js_internal.notImplemented "Js.Math" "abs_int"

let abs_float _ = Js_internal.notImplemented "Js.Math" "abs_float"
let acos _ = Js_internal.notImplemented "Js.Math" "acos"
let acosh _ = Js_internal.notImplemented "Js.Math" "acosh"
let asin _ = Js_internal.notImplemented "Js.Math" "asin"
let asinh _ = Js_internal.notImplemented "Js.Math" "asinh"
let atan _ = Js_internal.notImplemented "Js.Math" "atan"
let atanh _ = Js_internal.notImplemented "Js.Math" "atanh"
let atan2 ~y:_ ~x:_ = Js_internal.notImplemented "Js.Math" "atan2"
let cbrt _ = Js_internal.notImplemented "Js.Math" "cbrt"
let unsafe_ceil_int _ = Js_internal.notImplemented "Js.Math" "unsafe_ceil_int"
let ceil_int _ = Js_internal.notImplemented "Js.Math" "ceil_int"
let ceil_float _ = Js_internal.notImplemented "Js.Math" "ceil_float"
let clz32 _ = Js_internal.notImplemented "Js.Math" "clz32"
let cos = cos
let cosh _ = Js_internal.notImplemented "Js.Math" "cosh"
let exp _ = Js_internal.notImplemented "Js.Math" "exp"
let expm1 _ = Js_internal.notImplemented "Js.Math" "expm1"
let unsafe_floor_int _ = Js_internal.notImplemented "Js.Math" "unsafe_floor_int"
let floor_int _f = Js_internal.notImplemented "Js.Math" "floor_int"
let floor_float _ = Js_internal.notImplemented "Js.Math" "floor_float"
let fround _ = Js_internal.notImplemented "Js.Math" "fround"
let hypot _ = Js_internal.notImplemented "Js.Math" "hypot"
let hypotMany _ = Js_internal.notImplemented "Js.Math" "hypotMany"
let imul _ = Js_internal.notImplemented "Js.Math" "imul"
let log _ = Js_internal.notImplemented "Js.Math" "log"
let log1p _ = Js_internal.notImplemented "Js.Math" "log1p"
let log10 _ = Js_internal.notImplemented "Js.Math" "log10"
let log2 _ = Js_internal.notImplemented "Js.Math" "log2"
let max_int (a : int) (b : int) = Stdlib.max a b
let maxMany_int _ = Js_internal.notImplemented "Js.Math" "maxMany_int"
let max_float (a : float) (b : float) = Stdlib.max a b
let maxMany_float _ = Js_internal.notImplemented "Js.Math" "maxMany_float"
let min_int (a : int) (b : int) = Stdlib.min a b
let minMany_int _ = Js_internal.notImplemented "Js.Math" "minMany_int"
let min_float (a : float) (b : float) = Stdlib.min a b
let minMany_float _ = Js_internal.notImplemented "Js.Math" "minMany_float"
let pow_float ~base:_ ~exp:_ = Js_internal.notImplemented "Js.Math" "pow_float"
let random _ = Js_internal.notImplemented "Js.Math" "random"
let random_int _min _max = Js_internal.notImplemented "Js.Math" "random_int"
let unsafe_round _ = Js_internal.notImplemented "Js.Math" "unsafe_round"
let round _ = Js_internal.notImplemented "Js.Math" "round"
let sign_int _ = Js_internal.notImplemented "Js.Math" "sign_int"
let sign_float _ = Js_internal.notImplemented "Js.Math" "sign_float"
let sin = sin
let sinh _ = Js_internal.notImplemented "Js.Math" "sinh"
let sqrt _ = Js_internal.notImplemented "Js.Math" "sqrt"
let tan _ = Js_internal.notImplemented "Js.Math" "tan"
let tanh _ = Js_internal.notImplemented "Js.Math" "tanh"
let unsafe_trunc _ = Js_internal.notImplemented "Js.Math" "unsafe_trunc"
let trunc _ = Js_internal.notImplemented "Js.Math" "trunc"

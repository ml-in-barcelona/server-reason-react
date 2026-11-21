let _E = 2.718281828459045
let _LN2 = 0.6931471805599453
let _LN10 = 2.302585092994046
let _LOG2E = 1.4426950408889634
let _LOG10E = 0.4342944819032518
let _PI = 3.141592653589793
let _SQRT1_2 = 0.7071067811865476
let _SQRT2 = 1.4142135623730951
let abs_int = Stdlib.abs
let abs_float = Stdlib.abs_float
let acos = Stdlib.acos
let acosh = Float.acosh
let asin = Stdlib.asin
let asinh = Float.asinh
let atan = Stdlib.atan
let atanh = Float.atanh
let atan2 ~y ~x = Stdlib.atan2 y x
let cbrt = Float.cbrt
let unsafe_ceil_int f = Stdlib.int_of_float (Stdlib.ceil f)

let ceil_int (f : float) : int =
  if f > Stdlib.float_of_int Stdlib.max_int then Stdlib.max_int
  else if f < Stdlib.float_of_int Stdlib.min_int then Stdlib.min_int
  else unsafe_ceil_int f

let ceil_float = Stdlib.ceil

let clz32 n =
  let x = Int32.of_int n in
  if Int32.equal x 0l then 32
  else begin
    let x = ref x in
    let count = ref 0 in
    while Int32.compare (Int32.logand !x 0x80000000l) 0l = 0 do
      incr count;
      x := Int32.shift_left !x 1
    done;
    !count
  end

let cos = Stdlib.cos
let cosh = Stdlib.cosh
let exp = Stdlib.exp
let expm1 = Stdlib.expm1
let unsafe_floor_int f = Stdlib.int_of_float (Stdlib.floor f)

let floor_int f =
  if f > Stdlib.float_of_int Stdlib.max_int then Stdlib.max_int
  else if f < Stdlib.float_of_int Stdlib.min_int then Stdlib.min_int
  else unsafe_floor_int f

let floor_float = Stdlib.floor
let fround f = Int32.float_of_bits (Int32.bits_of_float f)
let hypot a b = Stdlib.hypot a b
let hypotMany values = Stdlib.Array.fold_left Stdlib.hypot 0. values
let imul a b = Int32.to_int (Int32.mul (Int32.of_int a) (Int32.of_int b))
let log = Stdlib.log
let log1p = Stdlib.log1p
let log10 = Stdlib.log10
let log2 = Float.log2
let max_int (a : int) (b : int) = Stdlib.max a b
let maxMany_int (values : int array) = Stdlib.Array.fold_left Stdlib.max Stdlib.min_int values

let js_max_float (a : float) (b : float) =
  if Float.is_nan a || Float.is_nan b then Float.nan
  else if a = 0. && b = 0. then if Float.sign_bit a then b else a
  else if a > b then a
  else b

let js_min_float (a : float) (b : float) =
  if Float.is_nan a || Float.is_nan b then Float.nan
  else if a = 0. && b = 0. then if Float.sign_bit a then a else b
  else if a < b then a
  else b

let max_float = js_max_float
let maxMany_float (values : float array) = Stdlib.Array.fold_left js_max_float Float.neg_infinity values
let min_int (a : int) (b : int) = Stdlib.min a b
let minMany_int (values : int array) = Stdlib.Array.fold_left Stdlib.min Stdlib.max_int values
let min_float = js_min_float
let minMany_float (values : float array) = Stdlib.Array.fold_left js_min_float Float.infinity values

let pow_float ~base ~exp =
  if Float.is_nan exp then Float.nan
  else if Stdlib.abs_float base = 1. && Float.abs exp = Float.infinity then Float.nan
  else base ** exp

let random_state = Stdlib.Lazy.from_fun Stdlib.Random.State.make_self_init
let random () = Stdlib.Random.State.float (Stdlib.Lazy.force random_state) 1.0
let random_int min max = floor_int (random () *. Stdlib.float_of_int (max - min)) + min

let round (x : float) =
  if Float.is_nan x || Float.is_integer x || Float.abs x = Float.infinity then x
  else begin
    let f = Stdlib.floor x in
    let r = if x -. f >= 0.5 then f +. 1. else f in
    if r = 0. && Float.sign_bit x then -0. else r
  end

let unsafe_round x = Stdlib.int_of_float (round x)
let sign_int (n : int) = Stdlib.compare n 0
let sign_float (x : float) = if Float.is_nan x then Float.nan else if x = 0. then x else if x > 0. then 1. else -1.
let sin = Stdlib.sin
let sinh = Stdlib.sinh
let sqrt = Stdlib.sqrt
let tan = Stdlib.tan
let tanh = Stdlib.tanh
let unsafe_trunc x = Stdlib.int_of_float x
let trunc = Float.trunc

type t = float

module SpecialValues = struct
  let _NaN = Stdlib.Float.nan
  let isNaN float = Stdlib.Float.is_nan float

  let fromString str =
    match str with
    | "NaN" -> _NaN
    | "Infinity" -> infinity
    | "-Infinity" -> neg_infinity
    | _ -> raise (Failure "Invalid special value")
end

let _NaN = SpecialValues._NaN
let isNaN = SpecialValues.isNaN
let isFinite float = Stdlib.Float.is_finite float
let isInteger float = Stdlib.Float.is_finite float && Stdlib.Float.is_integer float

let toExponential ?digits f =
  match digits with
  | None -> Quickjs.Number.Prototype.to_string f
  | Some d ->
      if d < 0 || d > 100 then raise (Invalid_argument "toExponential() digits argument must be between 0 and 100")
      else Quickjs.Number.Prototype.to_exponential d f

let toFixed ?(digits = 0) f =
  if digits < 0 || digits > 100 then raise (Failure "toFixed() digits argument must be between 0 and 100")
  else Quickjs.Number.Prototype.to_fixed digits f

let toPrecision ?digits f =
  match digits with
  | None -> Quickjs.Number.Prototype.to_string f
  | Some d ->
      if d < 1 || d > 100 then raise (Invalid_argument "toPrecision() digits argument must be between 1 and 100")
      else Quickjs.Number.Prototype.to_precision d f

let toString ?radix f =
  match radix with
  | None -> Quickjs.Number.Prototype.to_string f
  | Some r ->
      if r < 2 || r > 36 then raise (Invalid_argument "toString() radix must be between 2 and 36")
      else Quickjs.Number.Prototype.to_radix r f

let fromString str = try SpecialValues.fromString str with _ -> Stdlib.float_of_string str

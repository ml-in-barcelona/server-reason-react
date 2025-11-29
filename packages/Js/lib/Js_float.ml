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

  let toString = function
    | t when isNaN t -> "NaN"
    | t when t = infinity -> "Infinity"
    | t when t = neg_infinity -> "-Infinity"
    | _ -> raise (Failure "Invalid special value")
end

let _NaN = SpecialValues._NaN
let isNaN = SpecialValues.isNaN
let isFinite float = Stdlib.Float.is_finite float
let toExponential ?digits:_ _ = Js_internal.notImplemented "Js.Float" "toExponential"

let toFixed ?(digits = 0) f =
  try SpecialValues.toString f
  with _ ->
    if digits < 0 || digits > 100 then raise (Failure "toFixed() digits argument must be between 0 and 100")
    else Printf.sprintf "%.*f" digits f

let toPrecision ?digits:_ _ = Js_internal.notImplemented "Js.Float" "toPrecision"

let toString ?radix f =
  try SpecialValues.toString f
  with _ -> (
    match radix with
    | None ->
        (* round x rounds x to the nearest integer with ties (fractional values of 0.5) rounded away from zero, regardless of the current rounding direction.

           On 64-bit mingw-w64, this function may be emulated owing to a bug in the C runtime library (CRT) on this platform. *)
        (* if round(f) == f, print the integer (since string_of_float 1.0 => "1.") *)
        if Stdlib.Float.equal (Stdlib.Float.round f) f then f |> int_of_float |> string_of_int
        else Printf.sprintf "%g" f
    | Some _ -> Js_internal.notImplemented "Js.Float" "toString ~radix")

let fromString str = try SpecialValues.fromString str with _ -> Stdlib.float_of_string str

type t = int

let toExponential ?digits int =
  let f = Stdlib.float_of_int int in
  match digits with
  | None -> Quickjs.Number.Prototype.to_string f
  | Some d ->
      if d < 0 || d > 100 then raise (Invalid_argument "toExponential() digits argument must be between 0 and 100")
      else Quickjs.Number.Prototype.to_exponential d f

let toPrecision ?digits int =
  let f = Stdlib.float_of_int int in
  match digits with
  | None -> Quickjs.Number.Prototype.to_string f
  | Some d ->
      if d < 1 || d > 100 then raise (Invalid_argument "toPrecision() digits argument must be between 1 and 100")
      else Quickjs.Number.Prototype.to_precision d f

let toString ?radix int =
  match radix with
  | None -> Stdlib.string_of_int int
  | Some r ->
      if r < 2 || r > 36 then raise (Invalid_argument "toString() radix must be between 2 and 36")
      else Quickjs.Number.of_int_radix ~radix:r int

let toFloat int = Stdlib.float_of_int int
let equal = Stdlib.Int.equal
let max = 2147483647
let min = -2147483648

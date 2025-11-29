type t = int

let toExponential ?digits:_ _ = Js_internal.notImplemented "Js.Int" "toExponential"
let toPrecision ?digits:_ _ = Js_internal.notImplemented "Js.Int" "toPrecision"

let toString ?radix int =
  match radix with None -> Stdlib.string_of_int int | Some _ -> Js_internal.notImplemented "Js.Int" "toString ~radix"

let toFloat int = Stdlib.float_of_int int
let equal = Stdlib.Int.equal
let max = 2147483647
let min = -2147483648

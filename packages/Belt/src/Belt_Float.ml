let toInt = Stdlib.int_of_float
let fromInt = Stdlib.float_of_int
let fromString i = Quickjs.Global.parse_float i
let toString value = Quickjs.Number.Prototype.to_string value
let ( + ) = Stdlib.( +. )
let ( - ) = Stdlib.( -. )
let ( * ) = Stdlib.( *. )
let ( / ) = Stdlib.( /. )

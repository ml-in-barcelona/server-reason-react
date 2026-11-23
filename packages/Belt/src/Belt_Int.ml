let toFloat = Stdlib.float_of_int
let fromFloat = Stdlib.int_of_float
let fromString input = Quickjs.Global.parse_int ~radix:10 input
let toString = string_of_int
let ( + ) = Stdlib.( + )
let ( - ) = Stdlib.( - )
let ( * ) = Stdlib.( * )
let ( / ) = Stdlib.( / )

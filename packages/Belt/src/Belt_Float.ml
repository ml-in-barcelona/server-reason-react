let toInt = Stdlib.int_of_float
let fromInt = Stdlib.float_of_int
let fromString i = try Some (float_of_string i) with _ -> None
let toString = Stdlib.string_of_float
let ( + ) = Stdlib.( +. )
let ( - ) = Stdlib.( -. )
let ( * ) = Stdlib.( *. )
let ( / ) = Stdlib.( /. )

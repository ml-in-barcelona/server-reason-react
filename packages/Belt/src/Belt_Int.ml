let toFloat = Stdlib.float_of_int
let fromFloat = Stdlib.int_of_float
let fromString i = try Some (int_of_string i) with _ -> None
let toString = string_of_int
let ( + ) = Stdlib.( + )
let ( - ) = Stdlib.( - )
let ( * ) = Stdlib.( * )
let ( / ) = Stdlib.( / )

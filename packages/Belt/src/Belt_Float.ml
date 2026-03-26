let toInt = Stdlib.int_of_float
let fromInt = Stdlib.float_of_int
let fromString i = try Some (float_of_string i) with _ -> None

let toString value =
  let string = Stdlib.string_of_float value in
  let length = String.length string in
  if length > 0 && string.[length - 1] = '.' then String.sub string 0 (length - 1) else string

let ( + ) = Stdlib.( +. )
let ( - ) = Stdlib.( -. )
let ( * ) = Stdlib.( *. )
let ( / ) = Stdlib.( /. )

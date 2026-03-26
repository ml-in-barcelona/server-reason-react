let toFloat = Stdlib.float_of_int
let fromFloat = Stdlib.int_of_float

let fromString input =
  match int_of_string_opt input with
  | Some value -> Some value
  | None -> ( try Some (int_of_float (float_of_string input)) with _ -> None)

let toString = string_of_int
let ( + ) = Stdlib.( + )
let ( - ) = Stdlib.( - )
let ( * ) = Stdlib.( * )
let ( / ) = Stdlib.( / )

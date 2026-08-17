type t = int

let parse value =
  match int_of_string_opt value with Some value -> Ok value | None -> Error "expected an integer"

let to_string = string_of_int

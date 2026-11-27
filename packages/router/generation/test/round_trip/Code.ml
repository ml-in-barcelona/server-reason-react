type t = int

let parse value =
  if value <> "" && String.for_all (fun c -> c >= '0' && c <= '9') value then
    match int_of_string_opt value with Some v -> Ok v | None -> Error "too big"
  else Error "expected digits"

let to_string = string_of_int

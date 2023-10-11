external toFloat : int -> float = "%identity"
external fromFloat : float -> int = "%intoffloat"

let fromString = int_of_string
let fromString i = try Some (int_of_string i) with _ -> None
let toString = string_of_int

external ( + ) : int -> int -> int = "%addint"
external ( - ) : int -> int -> int = "%subint"
external ( * ) : int -> int -> int = "%mulint"
external ( / ) : int -> int -> int = "%divint"

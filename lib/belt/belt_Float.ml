external toFloat : float -> float = "%identity"
external fromInt : int -> float = "%identity"

let fromString = float_of_string
let fromString i = try Some (float_of_string i) with _ -> None
let toString = string_of_float

external ( + ) : float -> float -> float = "%addfloat"
external ( - ) : float -> float -> float = "%subfloat"
external ( * ) : float -> float -> float = "%mulfloat"
external ( / ) : float -> float -> float = "%divfloat"

external toFloat : float -> float = "%identity"
external fromInt : int -> float = "%identity"
val fromString : string -> float
val fromString : string -> float option
val toString : float -> string
external ( + ) : float -> float -> float = "%addfloat"
external ( - ) : float -> float -> float = "%subfloat"
external ( * ) : float -> float -> float = "%mulfloat"
external ( / ) : float -> float -> float = "%divfloat"

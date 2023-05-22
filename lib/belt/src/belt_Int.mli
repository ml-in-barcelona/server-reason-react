external toFloat : int -> float = "%identity"
external fromFloat : float -> int = "%intoffloat"
val fromString : string -> int
val fromString : string -> int option
val toString : int -> string
external ( + ) : int -> int -> int = "%addint"
external ( - ) : int -> int -> int = "%subint"
external ( * ) : int -> int -> int = "%mulint"
external ( / ) : int -> int -> int = "%divint"

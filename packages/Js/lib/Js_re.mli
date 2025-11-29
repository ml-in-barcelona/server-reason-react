type t
type result

val index : result -> int
val input : result -> string
val fromString : string -> t
val fromStringWithFlags : string -> flags:string -> t
val flags : t -> string
val global : t -> bool
val ignoreCase : t -> bool
val lastIndex : t -> int
val setLastIndex : t -> int -> unit
val multiline : t -> bool
val source : t -> string
val sticky : t -> bool
val unicode : t -> bool
val exec : str:string -> t -> result option
val test : str:string -> t -> bool
val captures : result -> string Js_internal.nullable array

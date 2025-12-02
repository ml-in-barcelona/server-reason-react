type 'a t = 'a Js_internal.nullable

external toOption : 'a t -> 'a Js_internal.nullable = "%identity"
external to_opt : 'a t -> 'a Js_internal.nullable = "%identity"
val return : 'a -> 'a t
val isNullable : 'a t -> bool
val null : 'a t
val undefined : 'a t
val bind : 'b t -> ('b -> 'b) -> 'b t
val iter : 'a t -> ('a -> unit) -> unit
val fromOption : 'a Js_internal.nullable -> 'a t
val from_opt : 'a Js_internal.nullable -> 'a t

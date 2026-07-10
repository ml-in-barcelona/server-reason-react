type 'a t = 'a Js_internal.nullable

external toOption : 'a t -> 'a Js_internal.nullable = "%identity"
external to_opt : 'a t -> 'a Js_internal.nullable = "%identity"
val return : 'a -> 'a t
val isNullable : 'a t -> bool

val null : 'a t
(** Natively [null] and [undefined] are both represented as [None]. *)

val undefined : 'a t
val map : f:('a -> 'b) -> 'a t -> 'b t
val bind : f:('a -> 'b t) -> 'a t -> 'b t
val iter : f:('a -> unit) -> 'a t -> unit
val fromOption : 'a Js_internal.nullable -> 'a t
val from_opt : 'a Js_internal.nullable -> 'a t

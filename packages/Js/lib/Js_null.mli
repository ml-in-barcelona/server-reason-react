type 'a t = 'a Js_internal.nullable

external toOption : 'a t -> 'a Js_internal.nullable = "%identity"
external fromOpt : 'a Js_internal.nullable -> 'a t = "%identity"
val empty : 'a Js_internal.nullable
val return : 'a -> 'a Js_internal.nullable
val getUnsafe : 'a t -> 'a

val getExn : 'a t -> 'a
(** @raise Js_exn.Error with message "Js.Null.getExn" when the value is empty, like Melange. *)

val map : f:('a -> 'b) -> 'a t -> 'b t
val bind : f:('a -> 'b t) -> 'a t -> 'b t
val iter : f:('a -> unit) -> 'a t -> unit
val fromOption : 'a Js_internal.nullable -> 'a t
val from_opt : 'a Js_internal.nullable -> 'a t

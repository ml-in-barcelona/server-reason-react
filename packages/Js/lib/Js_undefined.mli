type 'a t = 'a Js_internal.undefined

val return : 'a -> 'a t
val empty : 'a Js_internal.undefined
external toOption : 'a t -> 'a Js_internal.nullable = "%identity"
external fromOpt : 'a Js_internal.nullable -> 'a t = "%identity"

val getExn : 'a t -> 'a
(** @raise Js_exn.Error with message "Js.Undefined.getExn" when the value is empty, like Melange. *)

val getUnsafe : 'a t -> 'a
val map : f:('a -> 'b) -> 'a t -> 'b t
val bind : f:('a -> 'b t) -> 'a t -> 'b t
val iter : f:('a -> unit) -> 'a t -> unit

val testAny : 'a -> bool
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]
(** Requires JS runtime type tags: natively there is no way to check whether an arbitrary value is [undefined]. *)

val fromOption : 'a Js_internal.nullable -> 'a t
val from_opt : 'a Js_internal.nullable -> 'a t

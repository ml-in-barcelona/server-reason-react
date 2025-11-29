(** Provide utilities for Vector *)

type 'a t = 'a array

val filterInPlace : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val empty : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val pushBack : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val copy : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val memByRef : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val iter : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val iteri : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val toList : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val map : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val mapi : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val foldLeft : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val foldRight : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
external length : 'a t -> int = "%array_length"
external get : 'a t -> int -> 'a = "%array_safe_get"
external set : 'a t -> int -> 'a -> unit = "%array_safe_set"
external make : int -> 'a -> 'a t = "caml_make_vect"
val init : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val append : 'a -> 'b [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
external unsafe_get : 'a t -> int -> 'a = "%array_unsafe_get"
external unsafe_set : 'a t -> int -> 'a -> unit = "%array_unsafe_set"

type 'a t
type key = string

val get : 'a t -> key -> 'a option
(** [get dict key] returns [None] if the [key] is not found in the dictionary, [Some value] otherwise *)

val unsafeGet : 'a t -> key -> 'a
val set : 'a t -> key -> 'a -> unit
val keys : 'a t -> string array
val empty : unit -> 'a t

val unsafeDeleteKey : string t -> string -> unit
(** Experimental internal function *)

val entries : 'a t -> (key * 'a) array
val values : 'a t -> 'a array
val fromList : (key * 'a) list -> 'a t
val fromArray : (key * 'a) array -> 'a t
val map : f:('a -> 'b) -> 'a t -> 'b t

(** Provide utilities for JS dictionary object *)

type 'a t
(** Dictionary type *)

type key = string
(** Key type *)

val get : 'a t -> key -> 'a option
(** [get dict key] returns [None] if the [key] is not found in the dictionary, [Some value] otherwise *)

val unsafeGet : 'a t -> key -> 'a

val set : 'a t -> key -> 'a -> unit
(** [set dict key value] sets the [key]/[value] in [dict] *)

val keys : 'a t -> string array
(** [keys dict] returns all the keys in the dictionary [dict]*)

val empty : unit -> 'a t
(** [empty ()] returns an empty dictionary *)

val unsafeDeleteKey : string t -> string -> unit
(** Experimental internal function *)

val entries : 'a t -> (key * 'a) array
(** [entries dict] returns the key value pairs in [dict] *)

val values : 'a t -> 'a array
(** [values dict] returns the values in [dict] *)

val fromList : (key * 'a) list -> 'a t
(** [fromList entries] creates a new dictionary containing each [(key, value)] pair in [entries] *)

val fromArray : (key * 'a) array -> 'a t
(** [fromArray entries] creates a new dictionary containing each [(key, value)] pair in [entries] *)

val map : f:('a -> 'b) -> 'a t -> 'b t
(** [map f dict] maps [dict] to a new dictionary with the same keys, using [f] to map each value *)

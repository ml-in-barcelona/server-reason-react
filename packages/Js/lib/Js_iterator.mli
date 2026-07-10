(** JavaScript Iterator API *)

type 'a t
type 'a value = { done_ : bool option; value : 'a option }

val make : 'a Seq.t -> 'a t
(** [make seq] creates an iterator from a sequence. Native-only addition: melange has no constructor since iterators
    come from JavaScript itself. *)

val next : 'a t -> 'a value
(** [next it] advances the iterator. Once exhausted, it keeps returning [{ done_ = Some true; value = None }], matching
    JavaScript semantics. *)

val toArray : 'a t -> 'a array
val toArrayWithMapper : 'a t -> f:('a -> 'b) -> 'b array

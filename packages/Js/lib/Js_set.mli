(** Provides bindings for ES6 Set

    Mutable, insertion-ordered set matching JS Set semantics: iteration order is insertion order, re-adding an existing
    value keeps its position, and deleting then re-adding a value moves it to the end.

    Divergences from JavaScript:

    - Value equality is OCaml structural equality ([=]) instead of SameValueZero. Consequently [nan] compares unequal to
      itself ([has ~value:nan] is [false] after [add ~value:nan], whereas JS Sets treat [NaN] as a single value), and
      two structurally equal but physically distinct mutable values (e.g. two arrays [[|1|]]) are the same element here
      while JS would keep them separate.
    - [values]/[entries] return a snapshot iterator: mutations made after the iterator is created are not observed,
      whereas JS Set iterators are live. *)

type 'a t
(** The Set type *)

val make : unit -> 'a t
(** [make ()] creates a new empty set. *)

val fromArray : 'a array -> 'a t
(** [fromArray values] creates a set from an array, deduplicating values. A duplicated value keeps the position of its
    first occurrence, like JS [new Set(values)]. *)

val toArray : 'a t -> 'a array
(** [toArray set] returns the values in insertion order, like JS [Array.from(set)]. *)

val size : 'a t -> int
(** [size set] returns the number of values in [set]. *)

val add : value:'a -> 'a t -> 'a t
(** [add ~value set] adds [value] to [set] (mutating it) and returns [set] for chaining. Adding an existing value is a
    no-op that keeps its original position. *)

val clear : 'a t -> unit
(** [clear set] removes all values from [set]. *)

val delete : value:'a -> 'a t -> bool
(** [delete ~value set] removes [value] from [set]; returns whether the value was present. *)

val forEach : f:('a -> unit) -> 'a t -> unit
(** [forEach ~f set] calls [f value] for each value in insertion order. *)

val has : value:'a -> 'a t -> bool
(** [has ~value set] returns whether [value] is present in [set]. *)

val values : 'a t -> 'a Js_iterator.t
(** [values set] returns an iterator over the values in insertion order. *)

val entries : 'a t -> ('a * 'a) Js_iterator.t
(** [entries set] returns an iterator over [(value, value)] pairs in insertion order, like JS [Set.prototype.entries].
*)

(** Provides bindings for ES6 Map

    Mutable, insertion-ordered map matching JS Map semantics: iteration order is insertion order, re-setting an existing
    key keeps its position, and deleting then re-adding a key moves it to the end.

    Divergences from JavaScript:

    - Key equality is OCaml structural equality ([=]) instead of SameValueZero. Consequently [nan] keys compare unequal
      to themselves ([has ~key:nan] is [false] after [set ~key:nan], whereas JS Maps treat [NaN] as a single key), and
      two structurally equal but physically distinct mutable keys (e.g. two arrays [[|1|]]) are the same key here while
      JS would keep them separate.
    - [keys]/[values]/[entries] return a snapshot iterator: mutations made after the iterator is created are not
      observed, whereas JS Map iterators are live. *)

type ('k, 'v) t
(** The Map type *)

val make : unit -> ('k, 'v) t
(** [make ()] creates a new empty map. *)

val fromArray : ('k * 'v) array -> ('k, 'v) t
(** [fromArray entries] creates a map from an array of [(key, value)] pairs. Like JS [new Map(entries)], a duplicated
    key keeps the position of its first occurrence but the value of its last one. *)

val toArray : ('k, 'v) t -> ('k * 'v) array
(** [toArray map] returns the [(key, value)] pairs in insertion order, like JS [Array.from(map)]. *)

val size : ('k, 'v) t -> int
(** [size map] returns the number of entries in [map]. *)

val has : key:'k -> ('k, 'v) t -> bool
(** [has ~key map] returns whether [key] is present in [map]. *)

val get : key:'k -> ('k, 'v) t -> 'v option
(** [get ~key map] returns [Some value] if [key] is present, [None] otherwise. *)

val set : key:'k -> value:'v -> ('k, 'v) t -> ('k, 'v) t
(** [set ~key ~value map] sets [key] to [value] in [map] (mutating it) and returns [map] for chaining. *)

val clear : ('k, 'v) t -> unit
(** [clear map] removes all entries from [map]. *)

val delete : key:'k -> ('k, 'v) t -> bool
(** [delete ~key map] removes [key] from [map]; returns whether the key was present. *)

val forEach : f:('v -> 'k -> ('k, 'v) t -> unit) -> ('k, 'v) t -> unit
(** [forEach ~f map] calls [f value key map] for each entry in insertion order, like JS [Map.prototype.forEach]. *)

val keys : ('k, 'v) t -> 'k Js_iterator.t
(** [keys map] returns an iterator over the keys in insertion order. *)

val values : ('k, 'v) t -> 'v Js_iterator.t
(** [values map] returns an iterator over the values in insertion order. *)

val entries : ('k, 'v) t -> ('k * 'v) Js_iterator.t
(** [entries map] returns an iterator over the [(key, value)] pairs in insertion order. *)

(** JavaScript Array API *)

type 'a t = 'a array
type 'a array_like

val from : 'a array_like -> 'a t [@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val fromMap : 'a array_like -> f:('a -> 'b) -> 'b t
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val isArray : 'a array -> bool
val length : 'a array -> int

val copyWithin : to_:int -> ?start:int -> ?end_:int -> 'a t -> 'a t
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val fill : value:'a -> ?start:int -> ?end_:int -> 'a t -> 'a t
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val pop : 'a t -> 'a Js_internal.nullable
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val push : value:'a -> 'a t -> int [@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val pushMany : values:'a t -> 'a t -> int
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val reverseInPlace : 'a t -> 'a t [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val shift : 'a t -> 'a option [@@alert not_implemented "is not implemented in native under server-reason-react.js"]
val sortInPlace : 'a t -> 'a t [@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val sortInPlaceWith : f:('a -> 'a -> int) -> 'a t -> 'a t
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val spliceInPlace : start:int -> remove:int -> add:'a t -> 'a t -> 'a t
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val removeFromInPlace : start:int -> 'a t -> 'a t
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val removeCountInPlace : start:int -> count:int -> 'a t -> 'a t
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val unshift : value:'a -> 'a t -> int
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val unshiftMany : values:'a t -> 'a t -> int
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val concat : other:'a t -> 'a t -> 'a t
val concatMany : arrays:'a t t -> 'a t -> 'a t
val includes : value:'a -> 'a t -> bool
val indexOf : value:'a -> ?start:int -> 'a t -> int
val join : ?sep:string -> string t -> string
val lastIndexOf : value:'a -> 'a t -> int
val lastIndexOfFrom : value:'a -> start:int -> 'a t -> int
val slice : ?start:int -> ?end_:int -> 'a t -> 'a t
val copy : 'a array -> 'a array
val toString : 'a t -> string [@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val toLocaleString : 'a t -> string
[@@alert not_implemented "is not implemented in native under server-reason-react.js"]

val everyi : f:('a -> int -> bool) -> 'a t -> bool
val every : f:('a -> bool) -> 'a t -> bool
val filter : f:('a -> bool) -> 'a t -> 'a t
val filteri : f:('a -> int -> bool) -> 'a t -> 'a t
val findi : f:('a -> int -> bool) -> 'a t -> 'a Js_internal.nullable
val find : f:('a -> bool) -> 'a t -> 'a Js_internal.nullable
val findIndexi : f:('a -> int -> bool) -> 'a t -> int
val findIndex : f:('a -> bool) -> 'a t -> int
val forEach : f:('a -> unit) -> 'a t -> unit
val forEachi : f:('a -> int -> unit) -> 'a t -> unit
val map : f:('a -> 'b) -> 'a t -> 'b t
val mapi : f:('a -> int -> 'b) -> 'a t -> 'b t
val reduce : f:('b -> 'a -> 'b) -> init:'b -> 'a t -> 'b
val reducei : f:('b -> 'a -> int -> 'b) -> init:'b -> 'a t -> 'b
val reduceRight : f:('b -> 'a -> 'b) -> init:'b -> 'a t -> 'b
val reduceRighti : f:('b -> 'a -> int -> 'b) -> init:'b -> 'a t -> 'b
val some : f:('a -> bool) -> 'a t -> bool
val somei : f:('a -> int -> bool) -> 'a t -> bool
val unsafe_get : 'a array -> int -> 'a
val unsafe_set : 'a array -> int -> 'a -> unit

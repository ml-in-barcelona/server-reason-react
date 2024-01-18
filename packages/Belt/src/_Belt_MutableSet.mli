module Int = Belt_MutableSetInt
module String = Belt_MutableSetString
module N = Belt_internalAVLset
module A = Belt_Array
module Sort = Belt_SortArray

type ('k, 'id) id = ('k, 'id) Belt_Id.comparable
type ('key, 'id) cmp = ('key, 'id) Belt_Id.cmp

module S : sig
  type ('value, 'id) t

  val t : cmp:('value, 'id) cmp -> data:'value N.t -> ('value, 'id) t
  val cmp : ('value, 'id) t -> ('value, 'id) cmp
  val dataSet : ('value, 'id) t -> 'value N.t -> unit
  val data : ('value, 'id) t -> 'value N.t
end

type ('k, 'id) t = ('k, 'id) S.t

val remove0 : 'a N.node -> 'b -> cmp:('b -> 'a -> int) -> 'a N.t
val remove : ('a, 'b) S.t -> 'a -> unit

val removeMany0 :
  'a N.node ->
  'weak237 A.t ->
  int ->
  int ->
  cmp:('weak237 -> 'a -> int) ->
  'a N.node option

val removeMany : ('a, 'b) S.t -> 'a A.t -> unit

val removeCheck0 :
  'a N.node -> 'a -> bool ref -> cmp:('a -> 'a -> int) -> 'a N.t

val removeCheck : ('a, 'b) S.t -> 'a -> bool
val addCheck0 : 'a N.t -> 'a -> bool ref -> cmp:('a -> 'a -> int) -> 'a N.t
val addCheck : ('a, 'b) S.t -> 'a -> bool
val add : ('a, 'b) S.t -> 'a -> unit
val addArrayMutate : 'a N.t -> 'a A.t -> cmp:('a -> 'a -> int) -> 'a N.t
val mergeMany : ('a, 'b) S.t -> 'a A.t -> unit
val make : id:('value, 'identity) id -> ('value, 'a) S.t
val isEmpty : ('a, 'b) S.t -> bool
val minimum : ('a, 'b) S.t -> 'a option
val minUndefined : ('a, 'b) S.t -> 'a option
val maximum : ('a, 'b) S.t -> 'a option
val maxUndefined : ('a, 'b) S.t -> 'a option
val forEachU : ('a, 'b) S.t -> ('a -> unit) -> unit
val forEach : ('a, 'b) S.t -> ('a -> unit) -> unit
val reduceU : ('a, 'b) S.t -> 'c -> ('c -> 'a -> 'c) -> 'c
val reduce : ('a, 'b) S.t -> 'c -> ('c -> 'a -> 'c) -> 'c
val everyU : ('a, 'b) S.t -> ('a -> bool) -> bool
val every : ('a, 'b) S.t -> ('a -> bool) -> bool
val someU : ('a, 'b) S.t -> ('a -> bool) -> bool
val some : ('a, 'b) S.t -> ('a -> bool) -> bool
val size : ('a, 'b) S.t -> int
val toList : ('a, 'b) S.t -> 'a list
val toArray : ('a, 'b) S.t -> 'a array

val fromSortedArrayUnsafe :
  'value A.t -> id:('value, 'identity) id -> ('value, 'a) t

val checkInvariantInternal : ('a, 'b) S.t -> unit
val fromArray : 'value array -> id:('value, 'identity) id -> ('value, 'a) S.t
val cmp : ('a, 'b) S.t -> ('a, 'c) S.t -> int
val eq : ('a, 'b) S.t -> ('a, 'c) S.t -> bool
val get : ('a, 'b) S.t -> 'a -> 'a option
val getUndefined : ('a, 'b) S.t -> 'a -> 'a option
val getExn : ('a, 'b) S.t -> 'a -> 'a
val split : ('a, 'b) S.t -> 'a -> (('a, 'c) S.t * ('a, 'd) S.t) * bool
val keepU : ('a, 'b) S.t -> ('a -> bool) -> ('a, 'c) S.t
val keep : ('a, 'b) S.t -> ('a -> bool) -> ('a, 'c) S.t
val partitionU : ('a, 'b) S.t -> ('a -> bool) -> ('a, 'c) S.t * ('a, 'd) S.t
val partition : ('a, 'b) S.t -> ('a -> bool) -> ('a, 'c) S.t * ('a, 'd) S.t
val subset : ('a, 'b) S.t -> ('a, 'c) S.t -> bool
val intersect : ('a, 'b) S.t -> ('a, 'c) S.t -> ('a, 'd) t
val diff : ('a, 'b) S.t -> ('a, 'c) S.t -> ('a, 'd) t
val union : ('a, 'b) S.t -> ('a, 'c) S.t -> ('a, 'd) S.t
val has : ('a, 'b) S.t -> 'a -> bool
val copy : ('a, 'b) S.t -> ('a, 'c) S.t

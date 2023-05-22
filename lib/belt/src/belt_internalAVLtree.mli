type ('k, 'v) node = {
  mutable key : 'k;
  mutable value : 'v;
  mutable height : int;
  mutable left : ('k, 'v) t;
  mutable right : ('k, 'v) t;
}

and ('key, 'a) t = ('key, 'a) node option

val node :
  key:'k ->
  value:'v ->
  height:int ->
  left:('k, 'v) t ->
  right:('k, 'v) t ->
  ('k, 'v) node

val keySet : ('k, 'v) node -> 'k -> unit
val key : ('k, 'v) node -> 'k
val valueSet : ('k, 'v) node -> 'v -> unit
val value : ('k, 'v) node -> 'v
val heightSet : ('k, 'v) node -> int -> unit
val height : ('k, 'v) node -> int
val leftSet : ('k, 'v) node -> ('k, 'v) t -> unit
val left : ('k, 'v) node -> ('k, 'v) t
val rightSet : ('k, 'v) node -> ('k, 'v) t -> unit
val right : ('k, 'v) node -> ('k, 'v) t

type ('k, 'id) cmp = ('k, 'id) Belt_Id.cmp

module A = Belt_Array
module S = Belt_SortArray

val toOpt : 'a option -> 'a option
val return : 'a -> 'a option
val empty : 'a option
val unsafeCoerce : 'a option -> 'a
val treeHeight : ('a, 'b) t -> int
val copy : ('a, 'b) node option -> ('a, 'b) node option
val create : ('a, 'b) t -> 'a -> 'b -> ('a, 'b) t -> ('a, 'b) node option
val singleton : 'a -> 'b -> ('a, 'b) node option
val heightGe : ('a, 'b) node option -> ('c, 'd) node option -> bool
val updateValue : ('a, 'b) node -> 'b -> ('a, 'b) node

val bal :
  ('a, 'b) node option ->
  'a ->
  'b ->
  ('a, 'b) node option ->
  ('a, 'b) node option

val minKey0Aux : ('a, 'b) node -> 'a
val minKey : ('a, 'b) node option -> 'a option
val minKeyUndefined : ('a, 'b) node option -> 'a option
val maxKey0Aux : ('a, 'b) node -> 'a
val maxKey : ('a, 'b) node option -> 'a option
val maxKeyUndefined : ('a, 'b) node option -> 'a option
val minKV0Aux : ('a, 'b) node -> 'a * 'b
val minimum : ('a, 'b) node option -> ('a * 'b) option
val minUndefined : ('a, 'b) node option -> ('a * 'b) option
val maxKV0Aux : ('a, 'b) node -> 'a * 'b
val maximum : ('a, 'b) node option -> ('a * 'b) option
val maxUndefined : ('a, 'b) node option -> ('a * 'b) option
val removeMinAuxWithRef : ('a, 'b) node -> 'a ref -> 'b ref -> ('a, 'b) t
val isEmpty : 'a option -> bool

val stackAllLeft :
  ('a, 'b) node option -> ('a, 'b) node list -> ('a, 'b) node list

val forEachU : ('a, 'b) node option -> ('a -> 'b -> unit) -> unit
val forEach : ('a, 'b) node option -> ('a -> 'b -> unit) -> unit
val mapU : ('a, 'b) node option -> ('b -> 'c) -> ('a, 'c) node option
val map : ('a, 'b) node option -> ('b -> 'c) -> ('a, 'c) node option

val mapWithKeyU :
  ('a, 'b) node option -> ('a -> 'b -> 'c) -> ('a, 'c) node option

val mapWithKey :
  ('a, 'b) node option -> ('a -> 'b -> 'c) -> ('a, 'c) node option

val reduceU : ('a, 'b) node option -> 'c -> ('c -> 'a -> 'b -> 'c) -> 'c
val reduce : ('a, 'b) node option -> 'c -> ('c -> 'a -> 'b -> 'c) -> 'c
val everyU : ('a, 'b) node option -> ('a -> 'b -> bool) -> bool
val every : ('a, 'b) node option -> ('a -> 'b -> bool) -> bool
val someU : ('a, 'b) node option -> ('a -> 'b -> bool) -> bool
val some : ('a, 'b) node option -> ('a -> 'b -> bool) -> bool
val addMinElement : ('a, 'b) node option -> 'a -> 'b -> ('a, 'b) node option
val addMaxElement : ('a, 'b) node option -> 'a -> 'b -> ('a, 'b) node option

val join :
  ('a, 'b) node option ->
  'a ->
  'b ->
  ('a, 'b) node option ->
  ('a, 'b) node option

val concat :
  ('a, 'b) node option -> ('a, 'b) node option -> ('a, 'b) node option

val concatOrJoin :
  ('a, 'b) node option ->
  'a ->
  'b option ->
  ('a, 'b) node option ->
  ('a, 'b) node option

val keepSharedU :
  ('a, 'b) node option -> ('a -> 'b -> bool) -> ('a, 'b) node option

val keepShared :
  ('a, 'b) node option -> ('a -> 'b -> bool) -> ('a, 'b) node option

val keepMapU :
  ('a, 'b) node option -> ('a -> 'b -> 'c option) -> ('a, 'c) node option

val keepMap :
  ('a, 'b) node option -> ('a -> 'b -> 'c option) -> ('a, 'c) node option

val partitionSharedU :
  ('a, 'b) node option ->
  ('a -> 'b -> bool) ->
  ('a, 'b) node option * ('a, 'b) node option

val partitionShared :
  ('a, 'b) node option ->
  ('a -> 'b -> bool) ->
  ('a, 'b) node option * ('a, 'b) node option

val lengthNode : ('a, 'b) node -> int
val size : ('a, 'b) node option -> int
val toListAux : ('a, 'b) node option -> ('a * 'b) list -> ('a * 'b) list
val toList : ('a, 'b) node option -> ('a * 'b) list
val checkInvariantInternal : ('a, 'b) t -> unit
val fillArrayKey : ('a, 'b) node -> int -> 'a A.t -> int
val fillArrayValue : ('a, 'b) node -> int -> 'b A.t -> int
val fillArray : ('weak55, 'a) node -> int -> ('weak55 * 'a) A.t -> int

type cursor

val cursor : forward:int -> backward:int -> cursor
val forwardSet : cursor -> int -> unit
val forward : cursor -> int
val backwardSet : cursor -> int -> unit
val backward : cursor -> int

val fillArrayWithPartition :
  ('a, 'b) node -> cursor -> ('a * 'b) A.t -> ('a -> bool) -> unit

val fillArrayWithFilter :
  ('a, 'b) node -> int -> ('a * 'b) A.t -> ('a -> bool) -> int

val toArray : ('a, 'b) node option -> ('a * 'b) array
val keysToArray : ('a, 'b) node option -> 'a array
val valuesToArray : ('a, 'b) node option -> 'b array
val fromSortedArrayRevAux : ('a * 'b) A.t -> int -> int -> ('a, 'b) node option
val fromSortedArrayAux : ('a * 'b) A.t -> int -> int -> ('a, 'b) node option
val fromSortedArrayUnsafe : ('a * 'b) A.t -> ('a, 'b) node option

val compareAux :
  ('a, 'b) node list ->
  ('a, 'c) node list ->
  kcmp:('a -> 'a -> int) ->
  vcmp:('b -> 'c -> int) ->
  int

val eqAux :
  ('a, 'b) node list ->
  ('a, 'c) node list ->
  kcmp:('a -> 'a -> int) ->
  veq:('b -> 'c -> bool) ->
  bool

val cmpU :
  ('a, 'b) node option ->
  ('a, 'c) node option ->
  kcmp:('a -> 'a -> int) ->
  vcmp:('b -> 'c -> int) ->
  int

val cmp :
  ('a, 'b) node option ->
  ('a, 'c) node option ->
  kcmp:('a -> 'a -> int) ->
  vcmp:('b -> 'c -> int) ->
  int

val eqU :
  ('a, 'b) node option ->
  ('a, 'c) node option ->
  kcmp:('a -> 'a -> int) ->
  veq:('b -> 'c -> bool) ->
  bool

val eq :
  ('a, 'b) node option ->
  ('a, 'c) node option ->
  kcmp:('a -> 'a -> int) ->
  veq:('b -> 'c -> bool) ->
  bool

val get : ('a, 'b) node option -> 'a -> cmp:('a -> 'a -> int) -> 'b option

val getUndefined :
  ('a, 'b) node option -> 'a -> cmp:('a -> 'a -> int) -> 'b option

val getExn : ('a, 'b) node option -> 'a -> cmp:('a -> 'a -> int) -> 'b

val getWithDefault :
  ('a, 'weak59) node option -> 'a -> 'weak59 -> cmp:('a -> 'a -> int) -> 'weak59

val has : ('a, 'b) node option -> 'a -> cmp:('a -> 'a -> int) -> bool
val rotateWithLeftChild : ('a, 'b) node -> ('a, 'b) node
val rotateWithRightChild : ('a, 'b) node -> ('a, 'b) node
val doubleWithLeftChild : ('a, 'b) node -> ('a, 'b) node
val doubleWithRightChild : ('a, 'b) node -> ('a, 'b) node
val heightUpdateMutate : ('a, 'b) node -> ('a, 'b) node
val balMutate : ('a, 'b) node -> ('a, 'b) node

val updateMutate :
  ('a, 'b) t -> 'a -> 'b -> cmp:('a -> 'a -> int) -> ('a, 'b) node option

val fromArray : ('a * 'b) array -> cmp:('a -> 'a -> int) -> ('a, 'b) node option
val removeMinAuxWithRootMutate : ('a, 'b) node -> ('a, 'c) node -> ('a, 'c) t
val findFirstByU : ('a, 'b) t -> (('a -> 'b -> bool)[@bs]) -> ('a * 'b) option
val findFirstBy : ('a, 'b) t -> ('a -> 'b -> bool) -> ('a * 'b) option

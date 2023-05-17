type 'value node = {
  mutable value : 'value;
  mutable height : int;
  mutable left : 'value t;
  mutable right : 'value t;
}

and 'value t = 'value node option

val node :
  value:'value -> height:int -> left:'value t -> right:'value t -> 'value node

val valueSet : 'value node -> 'value -> unit
val value : 'value node -> 'value
val heightSet : 'value node -> int -> unit
val height : 'value node -> int
val leftSet : 'value node -> 'value t -> unit
val left : 'value node -> 'value t
val rightSet : 'value node -> 'value t -> unit
val right : 'value node -> 'value t

module A = Belt_Array
module S = Belt_SortArray

val toOpt : 'a option -> 'a option
val return : 'a -> 'a option
val empty : 'a option
val unsafeCoerce : 'a option -> 'a

type ('a, 'b) cmp = ('a, 'b) Belt_Id.cmp

val treeHeight : 'a t -> int
val copy : 'a node option -> 'a node option
val create : 'a t -> 'a -> 'a t -> 'a node option
val singleton : 'a -> 'a node option
val heightGe : 'a node option -> 'b node option -> bool
val bal : 'a node option -> 'a -> 'a node option -> 'a node option
val min0Aux : 'a node -> 'a
val minimum : 'a node option -> 'a option
val minUndefined : 'a node option -> 'a option
val max0Aux : 'a node -> 'a
val maximum : 'a node option -> 'a option
val maxUndefined : 'a node option -> 'a option
val removeMinAuxWithRef : 'a node -> 'a ref -> 'a t
val isEmpty : 'a option -> bool
val stackAllLeft : 'a node option -> 'a node list -> 'a node list
val forEachU : 'a node option -> ('a -> unit) -> unit
val forEach : 'a node option -> ('a -> unit) -> unit
val reduceU : 'a node option -> 'b -> ('b -> 'a -> 'b) -> 'b
val reduce : 'a node option -> 'b -> ('b -> 'a -> 'b) -> 'b
val everyU : 'a node option -> ('a -> bool) -> bool
val every : 'a node option -> ('a -> bool) -> bool
val someU : 'a node option -> ('a -> bool) -> bool
val some : 'a node option -> ('a -> bool) -> bool
val addMinElement : 'a node option -> 'a -> 'a node option
val addMaxElement : 'a node option -> 'a -> 'a node option
val joinShared : 'a node option -> 'a -> 'a node option -> 'a node option
val concatShared : 'a node option -> 'a node option -> 'a node option

val partitionSharedU :
  'a node option -> ('a -> bool) -> 'a node option * 'a node option

val partitionShared :
  'a node option -> ('a -> bool) -> 'a node option * 'a node option

val lengthNode : 'a node -> int
val size : 'a node option -> int
val toListAux : 'a node option -> 'a list -> 'a list
val toList : 'a node option -> 'a list
val checkInvariantInternal : 'a t -> unit
val fillArray : 'a node -> int -> 'a A.t -> int

type cursor

val cursor : forward:int -> backward:int -> cursor
val forwardSet : cursor -> int -> unit
val forward : cursor -> int
val backwardSet : cursor -> int -> unit
val backward : cursor -> int
val fillArrayWithPartition : 'a node -> cursor -> 'a A.t -> ('a -> bool) -> unit
val fillArrayWithFilter : 'a node -> int -> 'a A.t -> ('a -> bool) -> int
val toArray : 'a node option -> 'a array
val fromSortedArrayRevAux : 'a A.t -> int -> int -> 'a node option
val fromSortedArrayAux : 'a A.t -> int -> int -> 'a node option
val fromSortedArrayUnsafe : 'a A.t -> 'a node option
val keepSharedU : 'a node option -> ('a -> bool) -> 'a t
val keepShared : 'a node option -> ('a -> bool) -> 'a t
val keepCopyU : 'a node option -> ('a -> bool) -> 'a t
val keepCopy : 'a node option -> ('a -> bool) -> 'a t

val partitionCopyU :
  'a node option -> ('a -> bool) -> 'a node option * 'a node option

val partitionCopy :
  'a node option -> ('a -> bool) -> 'a node option * 'a node option

val has : 'a t -> 'a -> cmp:('a -> 'a -> int) -> bool
val compareAux : 'a node list -> 'a node list -> cmp:('a -> 'a -> int) -> int
val cmp : 'a node option -> 'a node option -> cmp:('a -> 'a -> int) -> int
val eq : 'a node option -> 'a node option -> cmp:('a -> 'a -> int) -> bool
val subset : 'a t -> 'a t -> cmp:('a -> 'a -> int) -> bool
val get : 'a t -> 'a -> cmp:('a -> 'a -> int) -> 'a option
val getUndefined : 'a t -> 'a -> cmp:('a -> 'a -> int) -> 'a option
val getExn : 'a t -> 'a -> cmp:('a -> 'a -> int) -> 'a
val rotateWithLeftChild : 'a node -> 'a node
val rotateWithRightChild : 'a node -> 'a node
val doubleWithLeftChild : 'a node -> 'a node
val doubleWithRightChild : 'a node -> 'a node
val heightUpdateMutate : 'a node -> 'a node
val balMutate : 'a node -> 'a node
val addMutate : cmp:('a -> 'a -> int) -> 'a t -> 'a -> 'a node option
val fromArray : 'a array -> cmp:('a -> 'a -> int) -> 'a node option
val removeMinAuxWithRootMutate : 'a node -> 'a node -> 'a t

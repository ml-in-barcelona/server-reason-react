module C = Belt_internalBucketsType

type 'a bucket
and ('hash, 'eq, 'a) t = ('hash, 'eq, 'a bucket) C.container

val bucket : key:'a -> next:'a bucket C.opt -> 'a bucket
val keySet : 'a bucket -> 'a -> unit
val key : 'a bucket -> 'a
val nextSet : 'a bucket -> 'a bucket C.opt -> unit
val next : 'a bucket -> 'a bucket C.opt

module A = Belt_Array

val copy : ('a, 'b, 'c) t -> ('a, 'b, 'c) t
val copyBuckets : 'a bucket C.opt array -> 'a bucket C.opt array
val copyBucket : 'a bucket C.opt -> 'a bucket C.opt
val copyAuxCont : 'a bucket C.opt -> 'a bucket -> unit
val bucketLength : int -> 'a bucket C.opt -> int
val doBucketIter : f:('a -> unit) -> 'a bucket C.opt -> unit
val forEachU : ('a, 'b, 'c bucket) C.container -> ('c -> unit) -> unit
val forEach : ('a, 'b, 'c bucket) C.container -> ('c -> unit) -> unit
val fillArray : int -> 'a A.t -> 'a bucket -> int
val toArray : ('a, 'b, 'c bucket) C.container -> 'c A.t
val doBucketFold : f:('a -> 'b -> 'a) -> 'b bucket C.opt -> 'a -> 'a
val reduceU : ('a, 'b, 'c bucket) C.container -> 'd -> ('d -> 'c -> 'd) -> 'd
val reduce : ('a, 'b, 'c bucket) C.container -> 'd -> ('d -> 'c -> 'd) -> 'd
val getMaxBucketLength : ('a, 'b, 'c bucket) C.container -> int
val getBucketHistogram : ('a, 'b, 'c bucket) C.container -> int A.t
val logStats : ('a, 'b, 'c bucket) C.container -> unit

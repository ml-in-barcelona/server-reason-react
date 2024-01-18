module C = Belt_internalBucketsType

type ('a, 'b) bucket = {
  mutable key : 'a;
  mutable value : 'b;
  mutable next : ('a, 'b) bucket option;
}

and ('hash, 'eq, 'a, 'b) t = ('hash, 'eq, ('a, 'b) bucket) C.container

val bucket : key:'a -> value:'b -> next:('a, 'b) bucket C.opt -> ('a, 'b) bucket
val keySet : ('a, 'b) bucket -> 'a -> unit
val key : ('a, 'b) bucket -> 'a
val valueSet : ('a, 'b) bucket -> 'b -> unit
val value : ('a, 'b) bucket -> 'b
val nextSet : ('a, 'b) bucket -> ('a, 'b) bucket C.opt -> unit
val next : ('a, 'b) bucket -> ('a, 'b) bucket C.opt

module A = Belt_Array

val copy : ('a, 'b, 'c, 'd) t -> ('a, 'b, 'c, 'd) t
val copyBuckets : ('a, 'b) bucket C.opt array -> ('a, 'b) bucket C.opt array
val copyBucket : ('a, 'b) bucket C.opt -> ('a, 'b) bucket C.opt
val copyAuxCont : ('a, 'b) bucket C.opt -> ('a, 'b) bucket -> unit
val bucketLength : int -> ('a, 'b) bucket C.opt -> int
val do_bucket_iter : f:('a -> 'b -> unit) -> ('a, 'b) bucket C.opt -> unit

val forEachU :
  ('a, 'b, ('c, 'd) bucket) C.container -> ('c -> 'd -> unit) -> unit

val forEach :
  ('a, 'b, ('c, 'd) bucket) C.container -> ('c -> 'd -> unit) -> unit

val do_bucket_fold :
  f:('a -> 'b -> 'c -> 'a) -> ('b, 'c) bucket C.opt -> 'a -> 'a

val reduceU :
  ('a, 'b, ('c, 'd) bucket) C.container -> 'e -> ('e -> 'c -> 'd -> 'e) -> 'e

val reduce :
  ('a, 'b, ('c, 'd) bucket) C.container -> 'e -> ('e -> 'c -> 'd -> 'e) -> 'e

val getMaxBucketLength : ('a, 'b, ('c, 'd) bucket) C.container -> int
val getBucketHistogram : ('a, 'b, ('c, 'd) bucket) C.container -> int A.t
val logStats : ('a, 'b, ('c, 'd) bucket) C.container -> unit

val filterMapInplaceBucket :
  ('a -> 'b -> 'b option) ->
  ('c, 'd, ('a, 'b) bucket) C.container ->
  int ->
  ('a, 'b) bucket C.opt ->
  ('a, 'b) bucket ->
  unit

val keepMapInPlaceU :
  ('a, 'b, ('c, 'd) bucket) C.container -> ('c -> 'd -> 'd option) -> unit

val keepMapInPlace :
  ('a, 'b, ('c, 'd) bucket) C.container -> ('c -> 'd -> 'd option) -> unit

val fillArray : int -> ('a * 'b) A.t -> ('a, 'b) bucket -> int
val toArray : ('a, 'b, ('c, 'd) bucket) C.container -> ('c * 'd) A.t

val fillArrayMap :
  int -> 'a A.t -> ('b, 'c) bucket -> (('b, 'c) bucket -> 'a) -> int

val linear :
  ('a, 'b, ('c, 'd) bucket) C.container -> (('c, 'd) bucket -> 'e) -> 'e A.t

val keysToArray : ('a, 'b, ('c, 'd) bucket) C.container -> 'c A.t
val valuesToArray : ('a, 'b, ('c, 'd) bucket) C.container -> 'd A.t
val toArray : ('a, 'b, ('c, 'd) bucket) C.container -> ('c * 'd) A.t

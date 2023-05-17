type 'a opt = 'a option
type ('hash, 'eq, 'c) container

val container :
  size:int ->
  buckets:'c opt array ->
  hash:'hash ->
  eq:'eq ->
  ('hash, 'eq, 'c) container

val sizeSet : ('hash, 'eq, 'c) container -> int -> unit
val size : ('hash, 'eq, 'c) container -> int
val bucketsSet : ('hash, 'eq, 'c) container -> 'c opt array -> unit
val buckets : ('hash, 'eq, 'c) container -> 'c opt array
val hash : ('hash, 'eq, 'c) container -> 'hash
val eq : ('hash, 'eq, 'c) container -> 'eq

module A = Belt_Array

val toOpt : 'a option -> 'a option
val return : 'a -> 'a option
val emptyOpt : 'a option
val power_2_above : int -> int -> int
val make : hash:'a -> eq:'b -> hintSize:int -> ('a, 'b, 'c) container
val clear : ('a, 'b, 'c) container -> unit
val isEmpty : ('a, 'b, 'c) container -> bool

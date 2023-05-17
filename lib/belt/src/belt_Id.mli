type ('a, 'id) hash = 'a -> int
type ('a, 'id) eq = 'a -> 'a -> bool
type ('a, 'id) cmp = 'a -> 'a -> int

val getHashInternal : ('a, 'id) hash -> 'a -> int
val getEqInternal : ('a, 'id) eq -> 'a -> 'a -> bool
val getCmpInternal : ('a, 'id) cmp -> 'a -> 'a -> int

module type Comparable = sig
  type identity
  type t

  val cmp : (t, identity) cmp
end

type ('key, 'id) comparable =
  (module Comparable with type identity = 'id and type t = 'key)

module MakeComparableU : functor
  (M : sig
     type t

     val cmp : t -> t -> int
   end)
  -> sig
  type identity
  type t = M.t

  val cmp : M.t -> M.t -> int
end

module MakeComparable : functor
  (M : sig
     type t

     val cmp : t -> t -> int
   end)
  -> sig
  type identity
  type t = M.t

  val cmp : M.t -> M.t -> int
end

val comparableU :
  cmp:('key -> 'key -> int) -> (module Comparable with type t = 'key)

val comparable :
  cmp:('key -> 'key -> int) -> (module Comparable with type t = 'key)

module type Hashable = sig
  type identity
  type t

  val hash : (t, identity) hash
  val eq : (t, identity) eq
end

type ('key, 'id) hashable =
  (module Hashable with type identity = 'id and type t = 'key)

module MakeHashableU : functor
  (M : sig
     type t

     val hash : t -> int
     val eq : t -> t -> bool
   end)
  -> sig
  type identity
  type t = M.t

  val hash : M.t -> int
  val eq : M.t -> M.t -> bool
end

module MakeHashable : functor
  (M : sig
     type t

     val hash : t -> int
     val eq : t -> t -> bool
   end)
  -> sig
  type identity
  type t = M.t

  val hash : M.t -> int
  val eq : M.t -> M.t -> bool
end

val hashableU :
  hash:('key -> int) ->
  eq:('key -> 'key -> bool) ->
  (module Hashable with type t = 'key)

val hashable :
  hash:('key -> int) ->
  eq:('key -> 'key -> bool) ->
  (module Hashable with type t = 'key)

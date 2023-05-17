module Int = Belt_MapInt
(** specalized when key type is [int], more efficient
    than the generic type
*)

module String = Belt_MapString
(** specalized when key type is [string], more efficient
    than the generic type *)

module Dict = Belt_MapDict
(** seprate function from data, a more verboe but slightly
    more efficient
*)

type ('key, 'id) id = ('key, 'id) Belt_Id.comparable
type ('key, 'id) cmp = ('key, 'id) Belt_Id.cmp
type ('k, 'v, 'id) t = { cmp : ('k, 'id) cmp; data : ('k, 'v, 'id) Dict.t }

module S = struct
  include (
    struct
      let t : cmp:('k, 'id) cmp -> data:('k, 'v, 'id) Dict.t -> ('k, 'v, 'id) t
          =
       fun ~cmp ~data -> { cmp; data }

      let cmp : ('k, 'v, 'id) t -> ('k, 'id) cmp = fun o -> o.cmp
      let data : ('k, 'v, 'id) t -> ('k, 'v, 'id) Dict.t = fun o -> o.data
    end :
      sig
        val t :
          cmp:('k, 'id) cmp -> data:('k, 'v, 'id) Dict.t -> ('k, 'v, 'id) t

        val cmp : ('k, 'v, 'id) t -> ('k, 'id) cmp
        val data : ('k, 'v, 'id) t -> ('k, 'v, 'id) Dict.t
      end)
end

let fromArray (type k idx) data ~(id : (k, idx) id) =
  let module M = (val id) in
  let cmp = M.cmp in
  S.t ~cmp ~data:(Dict.fromArray ~cmp data)

let remove m x =
  let cmp, odata =
    let open S in
    (cmp m, data m)
  in
  let newData = Dict.remove odata x ~cmp in
  if newData == odata then m else S.t ~cmp ~data:newData

let removeMany m x =
  let cmp, odata = (S.cmp m, S.data m) in
  let newData = Dict.removeMany odata x ~cmp in
  S.t ~cmp ~data:newData

let set m key d =
  let cmp = S.cmp m in
  S.t ~cmp ~data:(Dict.set ~cmp (S.data m) key d)

let mergeMany m e =
  let cmp = S.cmp m in
  S.t ~cmp ~data:(Dict.mergeMany ~cmp (S.data m) e)

let updateU m key f =
  let cmp = S.cmp m in
  S.t ~cmp ~data:(Dict.updateU ~cmp (S.data m) key f)

let update m key f = updateU m key (fun a -> f a)

let split m x =
  let cmp = S.cmp m in
  let (l, r), b = Dict.split ~cmp (S.data m) x in
  ((S.t ~cmp ~data:l, S.t ~cmp ~data:r), b)

let mergeU s1 s2 f =
  let cmp = S.cmp s1 in
  S.t ~cmp ~data:(Dict.mergeU ~cmp (S.data s1) (S.data s2) f)

let merge s1 s2 f = mergeU s1 s2 (fun a b c -> f a b c)

let make (type key idx) ~(id : (key, idx) id) =
  let module M = (val id) in
  S.t ~cmp:M.cmp ~data:Dict.empty

let isEmpty map = Dict.isEmpty (S.data map)
let forEachU m f = Dict.forEachU (S.data m) f
let forEach m f = forEachU m (fun a b -> f a b)
let reduceU m acc f = Dict.reduceU (S.data m) acc f
let reduce m acc f = reduceU m acc (fun a b c -> f a b c)
let everyU m f = Dict.everyU (S.data m) f
let every m f = everyU m (fun a b -> f a b)
let someU m f = Dict.someU (S.data m) f
let some m f = someU m (fun a b -> f a b)
let keepU m f = S.t ~cmp:(S.cmp m) ~data:(Dict.keepU (S.data m) f)
let keep m f = keepU m (fun a b -> f a b)

let partitionU m p =
  let cmp = S.cmp m in
  let l, r = Dict.partitionU (S.data m) p in
  (S.t ~cmp ~data:l, S.t ~cmp ~data:r)

let partition m p = partitionU m (fun a b -> p a b)
let mapU m f = S.t ~cmp:(S.cmp m) ~data:(Dict.mapU (S.data m) f)
let map m f = mapU m (fun a -> f a)
let mapWithKeyU m f = S.t ~cmp:(S.cmp m) ~data:(Dict.mapWithKeyU (S.data m) f)
let mapWithKey m f = mapWithKeyU m (fun a b -> f a b)
let size map = Dict.size (S.data map)
let toList map = Dict.toList (S.data map)
let toArray m = Dict.toArray (S.data m)
let keysToArray m = Dict.keysToArray (S.data m)
let valuesToArray m = Dict.valuesToArray (S.data m)
let minKey m = Dict.minKey (S.data m)
let minKeyUndefined m = Dict.minKeyUndefined (S.data m)
let maxKey m = Dict.maxKey (S.data m)
let maxKeyUndefined m = Dict.maxKeyUndefined (S.data m)
let minimum m = Dict.minimum (S.data m)
let minUndefined m = Dict.minUndefined (S.data m)
let maximum m = Dict.maximum (S.data m)
let maxUndefined m = Dict.maxUndefined (S.data m)
let get map x = Dict.get ~cmp:(S.cmp map) (S.data map) x
let getUndefined map x = Dict.getUndefined ~cmp:(S.cmp map) (S.data map) x

let getWithDefault map x def =
  Dict.getWithDefault ~cmp:(S.cmp map) (S.data map) x def

let getExn map x = Dict.getExn ~cmp:(S.cmp map) (S.data map) x
let has map x = Dict.has ~cmp:(S.cmp map) (S.data map) x
let checkInvariantInternal m = Dict.checkInvariantInternal (S.data m)
let eqU m1 m2 veq = Dict.eqU ~kcmp:(S.cmp m1) ~veq (S.data m1) (S.data m2)
let eq m1 m2 veq = eqU m1 m2 (fun a b -> veq a b)
let cmpU m1 m2 vcmp = Dict.cmpU ~kcmp:(S.cmp m1) ~vcmp (S.data m1) (S.data m2)
let cmp m1 m2 vcmp = cmpU m1 m2 (fun a b -> vcmp a b)
let getData = S.data

let getId (type key identity) (m : (key, _, identity) t) : (key, identity) id =
  let module T = struct
    type nonrec identity = identity
    type nonrec t = key

    let cmp = S.cmp m
  end in
  (module T)

let packIdData (type key idx) ~(id : (key, idx) id) ~data =
  let module M = (val id) in
  S.t ~cmp:M.cmp ~data

let findFirstByU m f = Dict.findFirstByU m.data f
let findFirstBy m f = findFirstByU m (fun a b -> f a b)

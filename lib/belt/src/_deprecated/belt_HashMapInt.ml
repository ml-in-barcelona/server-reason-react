[@@@ocaml.text
"  Adapted by Authors of BuckleScript 2017                           "]

type key = int
type seed = int

let caml_hash_mix_int = Caml_hash.caml_hash_mix_int
let final_mix = Caml_hash.caml_hash_final_mix

let hash (s : key) =
  Nativeint.to_int
    (final_mix (caml_hash_mix_int Nativeint.zero (Nativeint.of_int s)))

module N = Belt_internalBuckets
module C = Belt_internalBucketsType
module A = Belt_Array

type 'b t = (unit, unit, key, 'b) N.t

let rec copyBucketReHash ~h_buckets ~ndata_tail old_bucket =
  match C.toOpt old_bucket with
  | None -> ()
  | Some cell ->
      let nidx = hash (N.key cell) land (A.length h_buckets - 1) in
      let v = C.return cell in
      (match C.toOpt (A.getUnsafe ndata_tail nidx) with
      | None -> A.setUnsafe h_buckets nidx v
      | Some tail -> N.nextSet tail v);
      A.setUnsafe ndata_tail nidx v;
      copyBucketReHash ~h_buckets ~ndata_tail (N.next cell)

let resize h =
  let odata = C.buckets h in
  let osize = A.length odata in
  let nsize = osize * 2 in
  if nsize >= osize then (
    let h_buckets = A.makeUninitialized nsize in
    let ndata_tail = A.makeUninitialized nsize in
    C.bucketsSet h h_buckets;
    for i = 0 to osize - 1 do
      copyBucketReHash ~h_buckets ~ndata_tail (A.getUnsafe odata i)
    done;
    for i = 0 to nsize - 1 do
      match C.toOpt (A.getUnsafe ndata_tail i) with
      | None -> ()
      | Some tail -> N.nextSet tail C.emptyOpt
    done)

let rec replaceInBucket (key : key) info cell =
  if N.key cell = key then (
    N.valueSet cell info;
    false)
  else
    match C.toOpt (N.next cell) with
    | None -> true
    | Some cell -> replaceInBucket key info cell

let set h (key : key) value =
  let h_buckets = C.buckets h in
  let buckets_len = A.length h_buckets in
  let i = hash key land (buckets_len - 1) in
  let l = A.getUnsafe h_buckets i in
  (match C.toOpt l with
  | None ->
      A.setUnsafe h_buckets i (C.return (N.bucket ~key ~value ~next:C.emptyOpt));
      C.sizeSet h (C.size h + 1)
  | Some bucket ->
      if replaceInBucket key value bucket then (
        A.setUnsafe h_buckets i (C.return (N.bucket ~key ~value ~next:l));
        C.sizeSet h (C.size h + 1)));
  if C.size h > buckets_len lsl 1 then resize h

let rec removeInBucket h h_buckets i (key : key) prec buckets =
  match C.toOpt buckets with
  | None -> ()
  | Some cell ->
      let cell_next = N.next cell in
      if N.key cell = key then (
        N.nextSet prec cell_next;
        C.sizeSet h (C.size h - 1))
      else removeInBucket h h_buckets i key cell cell_next

let remove h key =
  let h_buckets = C.buckets h in
  let i = hash key land (A.length h_buckets - 1) in
  let bucket = A.getUnsafe h_buckets i in
  match C.toOpt bucket with
  | None -> ()
  | Some cell ->
      if N.key cell = key then (
        A.setUnsafe h_buckets i (N.next cell);
        C.sizeSet h (C.size h - 1))
      else removeInBucket h h_buckets i key cell (N.next cell)

let rec getAux (key : key) buckets =
  match C.toOpt buckets with
  | None -> None
  | Some cell ->
      if key = N.key cell then Some (N.value cell) else getAux key (N.next cell)

let get h (key : key) =
  let h_buckets = C.buckets h in
  let nid = hash key land (A.length h_buckets - 1) in
  match C.toOpt @@ A.getUnsafe h_buckets nid with
  | None -> None
  | Some cell1 -> (
      if key = N.key cell1 then Some (N.value cell1)
      else
        match C.toOpt (N.next cell1) with
        | None -> None
        | Some cell2 -> (
            if key = N.key cell2 then Some (N.value cell2)
            else
              match C.toOpt (N.next cell2) with
              | None -> None
              | Some cell3 ->
                  if key = N.key cell3 then Some (N.value cell3)
                  else getAux key (N.next cell3)))

let rec memInBucket (key : key) cell =
  N.key cell = key
  ||
  match C.toOpt (N.next cell) with
  | None -> false
  | Some nextCell -> memInBucket key nextCell

let has h key =
  let h_buckets = C.buckets h in
  let nid = hash key land (A.length h_buckets - 1) in
  let bucket = A.getUnsafe h_buckets nid in
  match C.toOpt bucket with
  | None -> false
  | Some bucket -> memInBucket key bucket

let make ~hintSize = C.make ~hintSize ~hash:() ~eq:()
let clear = C.clear
let size = C.size
let forEachU = N.forEachU
let forEach = N.forEach
let reduceU = N.reduceU
let reduce = N.reduce
let logStats = N.logStats
let keepMapInPlaceU = N.keepMapInPlaceU
let keepMapInPlace = N.keepMapInPlace
let toArray = N.toArray
let copy = N.copy
let keysToArray = N.keysToArray
let valuesToArray = N.valuesToArray
let getBucketHistogram = N.getBucketHistogram
let isEmpty = C.isEmpty

let fromArray arr =
  let len = A.length arr in
  let v = make len in
  for i = 0 to len - 1 do
    let k, value = A.getUnsafe arr i in
    set v k value
  done;
  v

let mergeMany h arr =
  let len = A.length arr in
  for i = 0 to len - 1 do
    let k, v = A.getUnsafe arr i in
    set h k v
  done

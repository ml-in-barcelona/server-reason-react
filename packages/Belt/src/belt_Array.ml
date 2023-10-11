type 'a t = 'a array

external length : 'a array -> int = "%array_length"
external size : 'a array -> int = "%array_length"
external getUnsafe : 'a array -> int -> 'a = "%array_unsafe_get"
external setUnsafe : 'a array -> int -> 'a -> unit = "%array_unsafe_set"

let getUndefined arr i =
  try Js.fromOpt (Some arr.(i)) with Invalid_argument _ -> Js.fromOpt None

external get : 'a array -> int -> 'a = "%array_safe_get"

let get arr i =
  if i >= 0 && i < length arr then Some (getUnsafe arr i) else None

let getExn arr i =
  (if Stdlib.not (i >= 0 && i < length arr) then
     let error = Printf.sprintf "File %s, line %d" __FILE__ __LINE__ in
     Js.Exn.raiseError error);
  getUnsafe arr i

let set arr i v =
  if i >= 0 && i < length arr then (
    setUnsafe arr i v;
    true)
  else false

let setExn arr i v =
  if Stdlib.not (i >= 0 && i < length arr) then (
    let error = Printf.sprintf "File %s, line %d" __FILE__ __LINE__ in
    Js.Exn.raiseError error;
    setUnsafe arr i v)

let makeUninitialized len = Array.make len Js.undefined
let makeUninitializedUnsafe len defaultVal = Array.make len defaultVal
let truncateToLengthUnsafe arr len = Stdlib.Array.sub arr 0 len

let copy a =
  let l = length a in
  let v = if l > 0 then Array.make l (getUnsafe a 0) else [||] in
  for i = 0 to l - 1 do
    setUnsafe v i (getUnsafe a i)
  done;
  v

let swapUnsafe xs i j =
  let tmp = getUnsafe xs i in
  setUnsafe xs i (getUnsafe xs j);
  setUnsafe xs j tmp

let random_int min max = Random.int (max - min) + min

let shuffleInPlace xs =
  let len = length xs in
  for i = 0 to len - 1 do
    swapUnsafe xs i (random_int i len)
  done

let shuffle xs =
  let result = copy xs in
  shuffleInPlace result;
  result

let reverseAux xs ofs len =
  for i = 0 to (len / 2) - 1 do
    swapUnsafe xs (ofs + i) (ofs + len - i - 1)
  done

let reverseInPlace xs =
  let len = length xs in
  reverseAux xs 0 len

let make l f =
  if l <= 0 then [||]
  else
    let res = Array.make l f in
    res

let reverse xs =
  let len = length xs in
  let result =
    if len > 0 then makeUninitializedUnsafe len (getUnsafe xs 0) else [||]
  in
  for i = 0 to len - 1 do
    setUnsafe result i (getUnsafe xs (len - 1 - i))
  done;
  result

let makeByU l f =
  if l <= 0 then [||]
  else
    let res = if l > 0 then makeUninitializedUnsafe l (f 0) else [||] in
    for i = 0 to l - 1 do
      setUnsafe res i (f i)
    done;
    res

let makeBy l f = makeByU l (fun a -> f a)

let makeByAndShuffleU l f =
  let u = makeByU l f in
  shuffleInPlace u;
  u

let makeByAndShuffle l f = makeByAndShuffleU l (fun a -> f a)

let range start finish =
  let cut = finish - start in
  if cut < 0 then [||]
  else
    let arr = makeUninitializedUnsafe (cut + 1) 0 in
    for i = 0 to cut do
      setUnsafe arr i (start + i)
    done;
    arr

let rangeBy start finish ~step =
  let cut = finish - start in
  if cut < 0 || step <= 0 then [||]
  else
    let nb = (cut / step) + 1 in
    let arr = makeUninitializedUnsafe nb 0 in
    let cur = ref start in
    for i = 0 to nb - 1 do
      setUnsafe arr i !cur;
      cur := !cur + step
    done;
    arr

let zip xs ys =
  let lenx, leny = (length xs, length ys) in
  let len = Stdlib.min lenx leny in
  let s =
    if len > 0 then makeUninitializedUnsafe len (getUnsafe xs 0, getUnsafe ys 0)
    else [||]
  in
  for i = 0 to len - 1 do
    setUnsafe s i (getUnsafe xs i, getUnsafe ys i)
  done;
  s

let zipByU xs ys f =
  let lenx, leny = (length xs, length ys) in
  let len = Stdlib.min lenx leny in
  let s =
    if len > 0 then
      makeUninitializedUnsafe len (f (getUnsafe xs 0) (getUnsafe ys 0))
    else [||]
  in
  for i = 0 to len - 1 do
    setUnsafe s i (f (getUnsafe xs i) (getUnsafe ys i))
  done;
  s

let zipBy xs ys f = zipByU xs ys (fun a b -> f a b)

let concat a1 a2 =
  let l1 = length a1 in
  let l2 = length a2 in
  let a1a2 =
    if l1 > 0 then makeUninitializedUnsafe (l1 + l2) (getUnsafe a1 0) else [||]
  in
  for i = 0 to l1 - 1 do
    setUnsafe a1a2 i (getUnsafe a1 i)
  done;
  for i = 0 to l2 - 1 do
    setUnsafe a1a2 (l1 + i) (getUnsafe a2 i)
  done;
  a1a2

let concatMany arrs =
  let lenArrs = length arrs in
  let totalLen = ref 0 in
  let firstArrWithLengthMoreThanZero = ref None in
  for i = 0 to lenArrs - 1 do
    let len = length (getUnsafe arrs i) in
    totalLen := !totalLen + len;
    if len > 0 && !firstArrWithLengthMoreThanZero = None then
      firstArrWithLengthMoreThanZero := Some (getUnsafe arrs i)
  done;
  match !firstArrWithLengthMoreThanZero with
  | None -> [||]
  | Some firstArr ->
      let result = makeUninitializedUnsafe !totalLen (getUnsafe firstArr 0) in
      totalLen := 0;
      for j = 0 to lenArrs - 1 do
        let cur = getUnsafe arrs j in
        for k = 0 to length cur - 1 do
          setUnsafe result !totalLen (getUnsafe cur k);
          incr totalLen
        done
      done;
      result

let slice a ~offset ~len =
  if len <= 0 then [||]
  else
    let lena = length a in
    let ofs = if offset < 0 then max (lena + offset) 0 else offset in
    let hasLen = lena - ofs in
    let copyLength = min hasLen len in
    if copyLength <= 0 then [||]
    else
      let result =
        if lena > 0 then makeUninitializedUnsafe copyLength (getUnsafe a 0)
        else [||]
      in
      for i = 0 to copyLength - 1 do
        setUnsafe result i (getUnsafe a (ofs + i))
      done;
      result

let fill a ~offset ~len v =
  if len > 0 then
    let lena = length a in
    let ofs = if offset < 0 then max (lena + offset) 0 else offset in
    let hasLen = lena - ofs in
    let fillLength = min hasLen len in
    if fillLength > 0 then
      for i = ofs to ofs + fillLength - 1 do
        setUnsafe a i v
      done

let blitUnsafe ~src:a1 ~srcOffset:srcofs1 ~dst:a2 ~dstOffset:srcofs2
    ~len:blitLength =
  if srcofs2 <= srcofs1 then
    for j = 0 to blitLength - 1 do
      setUnsafe a2 (j + srcofs2) (getUnsafe a1 (j + srcofs1))
    done
  else
    for j = blitLength - 1 downto 0 do
      setUnsafe a2 (j + srcofs2) (getUnsafe a1 (j + srcofs1))
    done

let blit ~src:a1 ~srcOffset:ofs1 ~dst:a2 ~dstOffset:ofs2 ~len =
  let lena1 = length a1 in
  let lena2 = length a2 in
  let srcofs1 = if ofs1 < 0 then max (lena1 + ofs1) 0 else ofs1 in
  let srcofs2 = if ofs2 < 0 then max (lena2 + ofs2) 0 else ofs2 in
  let blitLength = min len (min (lena1 - srcofs1) (lena2 - srcofs2)) in
  if srcofs2 <= srcofs1 then
    for j = 0 to blitLength - 1 do
      setUnsafe a2 (j + srcofs2) (getUnsafe a1 (j + srcofs1))
    done
  else
    for j = blitLength - 1 downto 0 do
      setUnsafe a2 (j + srcofs2) (getUnsafe a1 (j + srcofs1))
    done

let forEachU a f =
  for i = 0 to length a - 1 do
    f (getUnsafe a i)
  done

let forEach a f = forEachU a (fun a -> f a)

let mapU a f =
  let l = length a in
  let r =
    if l > 0 then makeUninitializedUnsafe l (f (getUnsafe a 0)) else [||]
  in
  for i = 0 to l - 1 do
    setUnsafe r i (f (getUnsafe a i))
  done;
  r

let map a f = mapU a (fun a -> f a)

let keepU a f =
  let l = length a in
  let r = if l > 0 then makeUninitializedUnsafe l (getUnsafe a 0) else [||] in
  let j = ref 0 in
  for i = 0 to l - 1 do
    let v = getUnsafe a i in
    if f v then (
      setUnsafe r !j v;
      incr j)
  done;
  truncateToLengthUnsafe r !j

let keep a f = keepU a (fun a -> f a)

let keepWithIndexU a f =
  let l = length a in
  let r = if l > 0 then makeUninitializedUnsafe l (getUnsafe a 0) else [||] in
  let j = ref 0 in
  for i = 0 to l - 1 do
    let v = getUnsafe a i in
    if f v i then (
      setUnsafe r !j v;
      incr j)
  done;
  truncateToLengthUnsafe r !j

let keepWithIndex a f = keepWithIndexU a (fun a -> f a)

let keepMapU a f =
  let l = length a in
  let r = ref None in
  let j = ref 0 in
  for i = 0 to l - 1 do
    let v = getUnsafe a i in
    match f v with
    | None -> ()
    | Some v ->
        let r =
          match !r with
          | None ->
              let newr = makeUninitializedUnsafe l v in
              r := Some newr;
              newr
          | Some r -> r
        in
        setUnsafe r !j v;
        incr j
  done;
  match !r with None -> [||] | Some r -> truncateToLengthUnsafe r !j

let keepMap a f = keepMapU a (fun a -> f a)

let forEachWithIndexU a f =
  for i = 0 to length a - 1 do
    f i (getUnsafe a i)
  done

let forEachWithIndex a f = forEachWithIndexU a (fun a b -> f a b)

let mapWithIndexU a f =
  let l = length a in
  let r =
    if l > 0 then makeUninitializedUnsafe l (f 0 (getUnsafe a 0)) else [||]
  in
  for i = 0 to l - 1 do
    setUnsafe r i (f i (getUnsafe a i))
  done;
  r

let mapWithIndex a f = mapWithIndexU a (fun a b -> f a b)

let reduceU a x f =
  let r = ref x in
  for i = 0 to length a - 1 do
    r := f !r (getUnsafe a i)
  done;
  !r

let reduce a x f = reduceU a x (fun a b -> f a b)

let reduceReverseU a x f =
  let r = ref x in
  for i = length a - 1 downto 0 do
    r := f !r (getUnsafe a i)
  done;
  !r

let reduceReverse a x f = reduceReverseU a x (fun a b -> f a b)

let reduceReverse2U a b x f =
  let r = ref x in
  let len = min (length a) (length b) in
  for i = len - 1 downto 0 do
    r := f !r (getUnsafe a i) (getUnsafe b i)
  done;
  !r

let reduceReverse2 a b x f = reduceReverse2U a b x (fun a b c -> f a b c)

let rec everyAux arr i b len =
  if i = len then true
  else if b (getUnsafe arr i) then everyAux arr (i + 1) b len
  else false

let rec someAux arr i b len =
  if i = len then false
  else if b (getUnsafe arr i) then true
  else someAux arr (i + 1) b len

let everyU arr b =
  let len = length arr in
  everyAux arr 0 b len

let every arr f = everyU arr (fun b -> f b)

let someU arr b =
  let len = length arr in
  someAux arr 0 b len

let some arr f = someU arr (fun b -> f b)

let rec everyAux2 arr1 arr2 i b len =
  if i = len then true
  else if b (getUnsafe arr1 i) (getUnsafe arr2 i) then
    everyAux2 arr1 arr2 (i + 1) b len
  else false

let rec someAux2 arr1 arr2 i b len =
  if i = len then false
  else if b (getUnsafe arr1 i) (getUnsafe arr2 i) then true
  else someAux2 arr1 arr2 (i + 1) b len

let every2U a b p = everyAux2 a b 0 p (min (length a) (length b))
let every2 a b p = every2U a b (fun a b -> p a b)
let some2U a b p = someAux2 a b 0 p (min (length a) (length b))
let some2 a b p = some2U a b (fun a b -> p a b)

let eqU a b p =
  let lena = length a in
  let lenb = length b in
  if lena = lenb then everyAux2 a b 0 p lena else false

let eq a b p = eqU a b (fun a b -> p a b)

let rec everyCmpAux2 arr1 arr2 i b len =
  if i = len then 0
  else
    let c = b (getUnsafe arr1 i) (getUnsafe arr2 i) in
    if c = 0 then everyCmpAux2 arr1 arr2 (i + 1) b len else c

let cmpU a b p =
  let lena = length a in
  let lenb = length b in
  if lena > lenb then 1
  else if lena < lenb then -1
  else everyCmpAux2 a b 0 p lena

let cmp a b p = cmpU a b (fun a b -> p a b)

let partitionU a f =
  let l = length a in
  let i = ref 0 in
  let j = ref 0 in
  let a1 = if l > 0 then makeUninitializedUnsafe l (getUnsafe a 0) else [||] in
  let a2 = if l > 0 then makeUninitializedUnsafe l (getUnsafe a 0) else [||] in
  for ii = 0 to l - 1 do
    let v = getUnsafe a ii in
    if f v then (
      setUnsafe a1 !i v;
      incr i)
    else (
      setUnsafe a2 !j v;
      incr j)
  done;
  (truncateToLengthUnsafe a1 !i, truncateToLengthUnsafe a2 !j)

let partition a f = partitionU a (fun x -> f x)

let unzip a =
  let l = length a in
  let a1, a2 =
    if l > 0 then
      let v1, v2 = getUnsafe a 0 in
      (makeUninitializedUnsafe l v1, makeUninitializedUnsafe l v2)
    else ([||], [||])
  in
  for i = 0 to l - 1 do
    let v1, v2 = getUnsafe a i in
    setUnsafe a1 i v1;
    setUnsafe a2 i v2
  done;
  (a1, a2)

let sliceToEnd a offset =
  let lena = length a in
  let ofs = if offset < 0 then Stdlib.max (lena + offset) 0 else offset in
  let len = if lena > ofs then lena - ofs else 0 in
  Stdlib.Array.init len (fun i -> getUnsafe a (ofs + i))

let flatMapU a f = concatMany (mapU a f)
let flatMap a f = flatMapU a (fun a -> f a)

let getByU a p =
  let l = length a in
  let i = ref 0 in
  let r = ref None in
  while r.contents = None && i.contents < l do
    let v = getUnsafe a i.contents in
    if p v then r.contents <- Some v;
    i.contents <- i.contents + 1
  done;
  r.contents

let getBy a p = getByU a (fun [@bs] a -> p a)

let getIndexByU a p =
  let l = length a in
  let i = ref 0 in
  let r = ref None in
  while r.contents = None && i.contents < l do
    let v = getUnsafe a i.contents in
    if p v then r.contents <- Some i.contents;
    i.contents <- i.contents + 1
  done;
  r.contents

let getIndexBy a p = getIndexByU a (fun a -> p a)

let reduceWithIndexU a x f =
  let r = ref x in
  for i = 0 to length a - 1 do
    r.contents <- f r.contents (getUnsafe a i) i
  done;
  r.contents

let reduceWithIndex a x f = reduceWithIndexU a x (fun a b c -> f a b c)

let joinWithU a sep toString =
  match length a with
  | 0 -> ""
  | l ->
      let lastIndex = l - 1 in
      let rec aux i res =
        let v = getUnsafe a i in
        if i = lastIndex then res ^ toString v
        else aux (i + 1) (res ^ toString v ^ sep)
      in
      aux 0 ""

let joinWith a sep toString = joinWithU a sep (fun x -> toString x)
let initU n f = Stdlib.Array.init n f
let init n f = initU n (fun i -> f i)

let push arr i =
  let len = length arr in
  setUnsafe arr (len + 1) i
[@@deprecated
  "You should use `concat` instead. Since in JavaScript `Array.prototype.push` \
   mutates the array reference, and it is not possible in native OCaml."]

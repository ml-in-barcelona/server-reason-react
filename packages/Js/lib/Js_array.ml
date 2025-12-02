(** JavaScript Array API *)

type 'a t = 'a array
type 'a array_like

let from _ = Js_internal.notImplemented "Js.Array" "from"
let fromMap _ ~f:_ = Js_internal.notImplemented "Js.Array" "fromMap"

(* This doesn't behave the same as melange-js, since it's a runtime check so lists are represented as arrays in the runtime: isArray([1, 2]) == true *)
let isArray (_arr : 'a) = true
let length arr = Stdlib.Array.length arr

(* Mutator functions *)
let copyWithin ~to_:_ ?start:_ ?end_:_ _ = Js_internal.notImplemented "Js.Array" "copyWithin"
let fill ~value:_ ?start:_ ?end_:_ _ = Js_internal.notImplemented "Js.Array" "fill"
let pop _ = Js_internal.notImplemented "Js.Array" "pop"
let push ~value:_ _ = Js_internal.notImplemented "Js.Array" "push"
let pushMany ~values:_ _ = Js_internal.notImplemented "Js.Array" "pushMany"
let reverseInPlace _ = Js_internal.notImplemented "Js.Array" "reverseInPlace"
let sortInPlace _ = Js_internal.notImplemented "Js.Array" "sortInPlace"
let sortInPlaceWith ~f:_ _ = Js_internal.notImplemented "Js.Array" "sortInPlaceWith"
let spliceInPlace ~start:_ ~remove:_ ~add:_ _ = Js_internal.notImplemented "Js.Array" "spliceInPlace"
let removeFromInPlace ~start:_ _ = Js_internal.notImplemented "Js.Array" "removeFromInPlace"
let removeCountInPlace ~start:_ ~count:_ _ = Js_internal.notImplemented "Js.Array" "removeCountInPlace"
let shift _ = Js_internal.notImplemented "Js.Array" "shift"
let unshift ~value:_ _ = Js_internal.notImplemented "Js.Array" "unshift"
let unshiftMany ~values:_ _ = Js_internal.notImplemented "Js.Array" "unshiftMany"

(* Accessor functions *)
let concat ~other:second first = Stdlib.Array.append first second
let concatMany ~arrays arr = Stdlib.Array.concat (arr :: Stdlib.Array.to_list arrays)
let includes ~value arr = Stdlib.Array.exists (fun x -> x = value) arr

let indexOf ~value ?start arr =
  let rec aux idx = if idx >= Stdlib.Array.length arr then -1 else if arr.(idx) = value then idx else aux (idx + 1) in
  match start with None -> aux 0 | Some from -> if from < 0 || from >= Stdlib.Array.length arr then -1 else aux from

let join ?sep arr =
  (* js bindings can really take in `'a array`, while native is constrained to `string array` *)
  match sep with
  | None -> Stdlib.Array.to_list arr |> String.concat ","
  | Some sep -> Stdlib.Array.to_list arr |> String.concat sep

let lastIndexOf ~value arr =
  let rec aux idx = if idx < 0 then -1 else if arr.(idx) = value then idx else aux (idx - 1) in
  aux (Stdlib.Array.length arr - 1)

let lastIndexOfFrom ~value ~start arr =
  let rec aux idx = if idx < 0 then -1 else if arr.(idx) = value then idx else aux (idx - 1) in
  if start < 0 || start >= Stdlib.Array.length arr then -1 else aux start

let slice ?start ?end_ arr =
  let len = Stdlib.Array.length arr in
  let start = match start with None -> 0 | Some s -> s in
  let end_ = match end_ with None -> Stdlib.Array.length arr | Some e -> e in
  let s = max 0 (if start < 0 then len + start else start) in
  let e = min len (if end_ < 0 then len + end_ else end_) in
  if s >= e then [||] else Stdlib.Array.sub arr s (e - s)

let copy = Stdlib.Array.copy
let toString _ = Js_internal.notImplemented "Js.Array" "toString"
let toLocaleString _ = Js_internal.notImplemented "Js.Array" "toLocaleString"

(* Iteration functions *)
let everyi ~f arr =
  let len = Stdlib.Array.length arr in
  let rec aux idx = if idx >= len then true else if f arr.(idx) idx then aux (idx + 1) else false in
  aux 0

let every ~f arr =
  let len = Stdlib.Array.length arr in
  let rec aux idx = if idx >= len then true else if f arr.(idx) then aux (idx + 1) else false in
  aux 0

let filter ~f arr = arr |> Stdlib.Array.to_list |> List.filter f |> Stdlib.Array.of_list
let filteri ~f arr = arr |> Stdlib.Array.to_list |> List.filteri (fun i a -> f a i) |> Stdlib.Array.of_list

let findi ~f arr =
  let len = Stdlib.Array.length arr in
  let rec aux idx = if idx >= len then None else if f arr.(idx) idx then Some arr.(idx) else aux (idx + 1) in
  aux 0

let find ~f arr =
  let len = Stdlib.Array.length arr in
  let rec aux idx = if idx >= len then None else if f arr.(idx) then Some arr.(idx) else aux (idx + 1) in
  aux 0

let findIndexi ~f arr =
  let len = Stdlib.Array.length arr in
  let rec aux idx = if idx >= len then -1 else if f arr.(idx) idx then idx else aux (idx + 1) in
  aux 0

let findIndex ~f arr =
  let len = Stdlib.Array.length arr in
  let rec aux idx = if idx >= len then -1 else if f arr.(idx) then idx else aux (idx + 1) in
  aux 0

let forEach ~f arr = Stdlib.Array.iter f arr
let forEachi ~f arr = Stdlib.Array.iteri (fun i a -> f a i) arr
let map ~f arr = Stdlib.Array.map f arr
let mapi ~f arr = Stdlib.Array.mapi (fun i a -> f a i) arr

let reduce ~f ~init arr =
  let r = ref init in
  for i = 0 to length arr - 1 do
    r := f !r (Stdlib.Array.unsafe_get arr i)
  done;
  !r

let reducei ~f ~init arr =
  let r = ref init in
  for i = 0 to length arr - 1 do
    r := f !r (Stdlib.Array.unsafe_get arr i) i
  done;
  !r

let reduceRight ~f ~init arr =
  let r = ref init in
  for i = length arr - 1 downto 0 do
    r := f !r (Stdlib.Array.unsafe_get arr i)
  done;
  !r

let reduceRighti ~f ~init arr =
  let r = ref init in
  for i = length arr - 1 downto 0 do
    r := f !r (Stdlib.Array.unsafe_get arr i) i
  done;
  !r

let some ~f arr =
  let n = Stdlib.Array.length arr in
  let rec loop i = if i = n then false else if f (Stdlib.Array.unsafe_get arr i) then true else loop (succ i) in
  loop 0

let somei ~f arr =
  let n = Stdlib.Array.length arr in
  let rec loop i = if i = n then false else if f (Stdlib.Array.unsafe_get arr i) i then true else loop (succ i) in
  loop 0

let unsafe_get arr idx = Stdlib.Array.unsafe_get arr idx
let unsafe_set arr idx item = Stdlib.Array.unsafe_set arr idx item

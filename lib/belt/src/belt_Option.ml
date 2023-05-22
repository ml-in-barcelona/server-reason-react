let getExn = function
  | Some x -> x
  | None ->
      let error = Printf.sprintf "File %s, line %d" __FILE__ __LINE__ in
      Js.Exn.raiseError error

let mapWithDefaultU opt default f =
  match opt with Some x -> f x | None -> default

let mapWithDefault opt default f = mapWithDefaultU opt default (fun x -> f x)
let mapU opt f = match opt with Some x -> Some (f x) | None -> None
let map opt f = mapU opt (fun x -> f x)
let flatMapU opt f = match opt with Some x -> f x | None -> None
let flatMap opt f = flatMapU opt (fun x -> f x)
let getWithDefault opt default = match opt with Some x -> x | None -> default
let isSome = function Some _ -> true | None -> false
let isNone = function Some _ -> false | None -> true

let eqU a b f =
  match (a, b) with
  | Some a, Some b -> f a b
  | None, Some _ | Some _, None -> false
  | None, None -> true

let eq a b f = eqU a b (fun x y -> f x y)

let cmpU a b f =
  match (a, b) with
  | Some a, Some b -> f a b
  | None, Some _ -> -1
  | Some _, None -> 1
  | None, None -> 0

let cmp a b f = cmpU a b (fun x y -> f x y)

let keepU opt f =
  match opt with Some x when f x -> opt | Some _ | None -> None

let keep opt f = keepU opt (fun x -> f x)
let forEachU opt f = match opt with Some x -> f x | None -> ()
let forEach opt f = forEachU opt (fun x -> f x)

external getUnsafe : 'a option -> 'a = "%identity"

(** Provides bindings for ES6 Map

    Backed by a Hashtbl plus an insertion-order log so that iteration (toArray/forEach/keys/values/entries) follows JS
    Map iteration order: first insertion wins the position, re-setting an existing key keeps it, deleting and re-adding
    moves it to the end. *)

type ('k, 'v) t = { table : ('k, 'v) Hashtbl.t; mutable order : 'k list (* reversed insertion order *) }

let make () : ('k, 'v) t = { table = Hashtbl.create 10; order = [] }

let set ~(key : 'k) ~(value : 'v) (map : ('k, 'v) t) : ('k, 'v) t =
  if not (Hashtbl.mem map.table key) then map.order <- key :: map.order;
  Hashtbl.replace map.table key value;
  map

let fromArray (entries : ('k * 'v) array) : ('k, 'v) t =
  let map = make () in
  Stdlib.Array.iter (fun (key, value) -> ignore (set ~key ~value map)) entries;
  map

let ordered_keys (map : ('k, 'v) t) : 'k list = Stdlib.List.rev map.order

let toArray (map : ('k, 'v) t) : ('k * 'v) array =
  ordered_keys map |> Stdlib.List.map (fun k -> (k, Hashtbl.find map.table k)) |> Stdlib.Array.of_list

let size (map : ('k, 'v) t) : int = Hashtbl.length map.table
let has ~(key : 'k) (map : ('k, 'v) t) : bool = Hashtbl.mem map.table key
let get ~(key : 'k) (map : ('k, 'v) t) : 'v option = Hashtbl.find_opt map.table key

let clear (map : ('k, 'v) t) : unit =
  Hashtbl.reset map.table;
  map.order <- []

let delete ~(key : 'k) (map : ('k, 'v) t) : bool =
  if Hashtbl.mem map.table key then begin
    Hashtbl.remove map.table key;
    map.order <- Stdlib.List.filter (fun k -> k <> key) map.order;
    true
  end
  else false

let forEach ~(f : 'v -> 'k -> ('k, 'v) t -> unit) (map : ('k, 'v) t) : unit =
  Stdlib.List.iter (fun k -> f (Hashtbl.find map.table k) k map) (ordered_keys map)

let keys (map : ('k, 'v) t) : 'k Js_iterator.t = Js_iterator.make (Stdlib.List.to_seq (ordered_keys map))

let values (map : ('k, 'v) t) : 'v Js_iterator.t =
  Js_iterator.make (ordered_keys map |> Stdlib.List.map (fun k -> Hashtbl.find map.table k) |> Stdlib.List.to_seq)

let entries (map : ('k, 'v) t) : ('k * 'v) Js_iterator.t =
  Js_iterator.make (ordered_keys map |> Stdlib.List.map (fun k -> (k, Hashtbl.find map.table k)) |> Stdlib.List.to_seq)

(** Provide utilities for JS dictionary object.

    Backed by a Hashtbl plus an insertion-order log so that iteration (entries/keys/values) follows JS object key order:
    first insertion wins the position, re-setting an existing key keeps it, deleting and re-adding moves it to the end.
*)

type key = string
type 'a t = { table : (key, 'a) Hashtbl.t; mutable order : key list (* reversed insertion order *) }

let empty () : 'a t = { table = Hashtbl.create 10; order = [] }
let get (dict : 'a t) (k : key) : 'a option = Hashtbl.find_opt dict.table k

let set (dict : 'a t) (k : key) (x : 'a) : unit =
  if not (Hashtbl.mem dict.table k) then dict.order <- k :: dict.order;
  Hashtbl.replace dict.table k x

let ordered_keys (dict : 'a t) : key list = Stdlib.List.rev dict.order
let keys (dict : 'a t) = Stdlib.Array.of_list (ordered_keys dict)

let entries (dict : 'a t) : (key * 'a) array =
  ordered_keys dict |> Stdlib.List.map (fun k -> (k, Hashtbl.find dict.table k)) |> Stdlib.Array.of_list

let values (dict : 'a t) =
  ordered_keys dict |> Stdlib.List.map (fun k -> Hashtbl.find dict.table k) |> Stdlib.Array.of_list

let map ~(f : 'a -> 'b) (dict : 'a t) : 'b t =
  let result = empty () in
  Stdlib.List.iter (fun k -> set result k (f (Hashtbl.find dict.table k))) (ordered_keys dict);
  result

let fromList (lst : (key * 'a) list) : 'a t =
  let dict = empty () in
  Stdlib.List.iter (fun (k, v) -> set dict k v) lst;
  dict

let fromArray (arr : (key * 'a) array) : 'a t =
  let dict = empty () in
  Stdlib.Array.iter (fun (k, v) -> set dict k v) arr;
  dict

let unsafeGet (dict : 'a t) (k : key) : 'a = Hashtbl.find dict.table k

let unsafeDeleteKey (dict : 'a t) (key : key) =
  if Hashtbl.mem dict.table key then begin
    Hashtbl.remove dict.table key;
    dict.order <- Stdlib.List.filter (fun k -> k <> key) dict.order
  end

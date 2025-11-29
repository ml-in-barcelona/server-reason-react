(** Provide utilities for JS dictionary object *)

type key = string
type 'a t = (key, 'a) Hashtbl.t

let empty () : 'a t = Hashtbl.create 10

let entries (dict : 'a t) : (string * 'a) array =
  Hashtbl.fold (fun k v acc -> (k, v) :: acc) dict [] |> Stdlib.Array.of_list

let get (dict : 'a t) (k : key) : 'a option = try Some (Hashtbl.find dict k) with Not_found -> None

let map ~(f : 'a -> 'b) (dict : 'a t) =
  Hashtbl.fold
    (fun k v acc ->
      Hashtbl.add acc k (f v);
      acc)
    dict (empty ())

let set (dict : 'a t) (k : key) (x : 'a) : unit = Hashtbl.replace dict k x

let fromList (lst : (key * 'a) list) : 'a t =
  let length = Stdlib.List.length lst in
  let dict = Hashtbl.create length in
  Stdlib.List.iter (fun (k, v) -> Hashtbl.add dict k v) lst;
  dict

let fromArray (arr : (key * 'a) array) : 'a t =
  let length = Stdlib.Array.length arr in
  let dict = Hashtbl.create length in
  Stdlib.Array.iter (fun (k, v) -> Hashtbl.add dict k v) arr;
  dict

let keys (dict : 'a t) = Hashtbl.fold (fun k _ acc -> k :: acc) dict [] |> Stdlib.Array.of_list
let values (dict : 'a t) = Hashtbl.fold (fun _k value acc -> value :: acc) dict [] |> Stdlib.Array.of_list
let unsafeGet (dict : 'a t) (k : key) : 'a = Hashtbl.find dict k
let unsafeDeleteKey (dict : 'a t) (key : key) = Hashtbl.remove dict key

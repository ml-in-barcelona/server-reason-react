(** Provides bindings for ES6 Set

    Backed by a Hashtbl plus an insertion-order log so that iteration (toArray/forEach/values/entries) follows JS Set
    iteration order: first insertion wins the position, re-adding an existing value keeps it, deleting and re-adding
    moves it to the end. *)

type 'a t = { table : ('a, unit) Hashtbl.t; mutable order : 'a list (* reversed insertion order *) }

let make () : 'a t = { table = Hashtbl.create 10; order = [] }

let add ~(value : 'a) (set : 'a t) : 'a t =
  if not (Hashtbl.mem set.table value) then begin
    Hashtbl.replace set.table value ();
    set.order <- value :: set.order
  end;
  set

let fromArray (values : 'a array) : 'a t =
  let set = make () in
  Stdlib.Array.iter (fun value -> ignore (add ~value set)) values;
  set

let ordered_values (set : 'a t) : 'a list = Stdlib.List.rev set.order
let toArray (set : 'a t) : 'a array = Stdlib.Array.of_list (ordered_values set)
let size (set : 'a t) : int = Hashtbl.length set.table

let clear (set : 'a t) : unit =
  Hashtbl.reset set.table;
  set.order <- []

let delete ~(value : 'a) (set : 'a t) : bool =
  if Hashtbl.mem set.table value then begin
    Hashtbl.remove set.table value;
    set.order <- Stdlib.List.filter (fun v -> v <> value) set.order;
    true
  end
  else false

let forEach ~(f : 'a -> unit) (set : 'a t) : unit = Stdlib.List.iter f (ordered_values set)
let has ~(value : 'a) (set : 'a t) : bool = Hashtbl.mem set.table value
let values (set : 'a t) : 'a Js_iterator.t = Js_iterator.make (Stdlib.List.to_seq (ordered_values set))

let entries (set : 'a t) : ('a * 'a) Js_iterator.t =
  Js_iterator.make (ordered_values set |> Stdlib.List.map (fun v -> (v, v)) |> Stdlib.List.to_seq)

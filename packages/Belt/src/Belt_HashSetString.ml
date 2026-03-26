type key = string
type t = (key, unit) Hashtbl.t

let make ~hintSize = Hashtbl.create hintSize
let clear = Hashtbl.clear
let isEmpty h = Hashtbl.length h = 0
let add h key = Hashtbl.replace h key ()
let copy = Hashtbl.copy
let has = Hashtbl.mem
let remove = Hashtbl.remove
let forEachU h f = Hashtbl.iter (fun key () -> f key) h
let forEach h f = forEachU h (fun key -> f key)

let reduceU h init f =
  let acc = ref init in
  Hashtbl.iter (fun key () -> acc := f !acc key) h;
  !acc

let reduce h init f = reduceU h init (fun acc key -> f acc key)
let size = Hashtbl.length

let logStats h =
  let stats = Hashtbl.stats h in
  Printf.printf "{\n\tbindings: %d,\n\tbuckets: %d\n\thistogram: %s\n}" stats.num_bindings stats.num_buckets
    (Belt_Array.reduceU stats.bucket_histogram "" (fun acc x -> acc ^ string_of_int x))

let toArray h = Hashtbl.fold (fun key () acc -> key :: acc) h [] |> Array.of_list

let fromArray arr =
  let h = make ~hintSize:(Belt_Array.length arr) in
  Belt_Array.forEachU arr (fun key -> add h key);
  h

let mergeMany h arr = Belt_Array.forEachU arr (fun key -> add h key)
let getBucketHistogram h = (Hashtbl.stats h).bucket_histogram

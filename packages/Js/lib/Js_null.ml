type 'a t = 'a Js_internal.nullable

external toOption : 'a t -> 'a option = "%identity"
external fromOpt : 'a option -> 'a t = "%identity"

let empty = None
let return a = Some a
let getUnsafe a = match toOption a with None -> assert false | Some a -> a

(* Melange raises a JS Error with this exact message. *)
let getExn f = match toOption f with None -> Js_exn.raiseError "Js.Null.getExn" | Some x -> x
let map ~f x = match toOption x with None -> empty | Some x -> return (f x)
let bind ~f x = match toOption x with None -> empty | Some x -> f x
let iter ~f x = match toOption x with None -> () | Some x -> f x
let fromOption = fromOpt
let from_opt = fromOpt

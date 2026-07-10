type 'a t = 'a Js_internal.undefined

let return a = Some a
let empty = None

external toOption : 'a t -> 'a option = "%identity"
external fromOpt : 'a option -> 'a t = "%identity"

(* Melange raises a JS Error with this exact message. *)
let getExn f = match toOption f with None -> Js_exn.raiseError "Js.Undefined.getExn" | Some x -> x
let getUnsafe a = match toOption a with None -> assert false | Some a -> a
let map ~f x = match toOption x with None -> empty | Some x -> return (f x)
let bind ~f x = match toOption x with None -> empty | Some x -> f x
let iter ~f x = match toOption x with None -> () | Some x -> f x
let testAny _ = Js_internal.notImplemented "Js.Undefined" "testAny"
let fromOption = fromOpt
let from_opt = fromOpt

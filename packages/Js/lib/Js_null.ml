type 'a t = 'a Js_internal.nullable

external toOption : 'a t -> 'a option = "%identity"
external fromOpt : 'a option -> 'a t = "%identity"

let empty = None
let return a = Some a
let getUnsafe a = match toOption a with None -> assert false | Some a -> a
let test = function None -> true | Some _ -> false
let getExn _ = Js_internal.notImplemented "Js.Null" "getExn"
let bind _ _ = Js_internal.notImplemented "Js.Null" "bind"
let iter _ _ = Js_internal.notImplemented "Js.Null" "iter"
let fromOption = fromOpt
let from_opt = fromOpt

type 'a t = 'a Js_internal.undefined

external return : 'a -> 'a t = "%identity"

let empty = None

external toOption : 'a t -> 'a option = "%identity"
external fromOpt : 'a option -> 'a t = "%identity"

let getExn _ = Js_internal.notImplemented "Js.Undefined" "getExn"
let getUnsafe a = match toOption a with None -> assert false | Some a -> a
let bind _ _ = Js_internal.notImplemented "Js.Undefined" "bind"
let iter _ _ = Js_internal.notImplemented "Js.Undefined" "iter"
let testAny _ = Js_internal.notImplemented "Js.Undefined" "testAny"
let test _ = Js_internal.notImplemented "Js.Undefined" "test"
let fromOption = fromOpt
let from_opt = fromOpt

type 'a t = 'a Js_internal.nullable

external toOption : 'a t -> 'a Js_internal.nullable = "%identity"
external to_opt : 'a t -> 'a Js_internal.nullable = "%identity"

let return : 'a -> 'a t = fun x -> Some x
let isNullable : 'a t -> bool = function None -> true | Some _ -> false
let null : 'a t = None
let undefined : 'a t = None
let map ~f x = match to_opt x with None -> (None : 'b t) | Some x -> return (f x)
let bind ~f x = match to_opt x with None -> (None : 'b t) | Some x -> f x
let iter ~f x = match to_opt x with None -> () | Some x -> f x
let fromOption : 'a Js_internal.nullable -> 'a t = function None -> undefined | Some x -> return x
let from_opt = fromOption

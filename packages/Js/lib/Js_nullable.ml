type 'a t = 'a option

external toOption : 'a t -> 'a option = "%identity"
external to_opt : 'a t -> 'a option = "%identity"

let return : 'a -> 'a t = fun x -> Some x
let isNullable : 'a t -> bool = function Some _ -> false | None -> true
let null : 'a t = None
let undefined : 'a t = None
let bind x f = match to_opt x with None -> ((x : 'a t) : 'b t) | Some x -> return (f x)
let iter x f = match to_opt x with None -> () | Some x -> f x
let fromOption x = match x with None -> undefined | Some x -> return x
let from_opt = fromOption

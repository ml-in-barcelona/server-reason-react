(** Provides functionality for dealing with the ['a Js.undefined] type *)

type +'a t = 'a Types.undefined

external to_opt : 'a t -> 'a option = "#undefined_to_opt"
external toOption : 'a t -> 'a option = "#undefined_to_opt"
external return : 'a -> 'a t = "%identity"
(* external empty : 'a t = "#undefined" *)
(* let empty = Option.get [%bs.external null] *)

(* let test : 'a t -> bool = fun x -> x = empty *)
(* let testAny : 'a -> bool = fun x -> Obj.magic x = empty *)

external getUnsafe : 'a t -> 'a = "%identity"

let getExn f =
  match toOption f with
  | None -> Js_exn.raiseError "Js.Undefined.getExn"
  | Some x -> x

(* let bind x f =
   match to_opt x with None -> empty | Some x -> return (f x [@bs]) *)

let iter x f = match to_opt x with None -> () | Some x -> f x [@bs]
(* let fromOption x = match x with None -> empty | Some x -> return x
   let from_opt = fromOption
*)

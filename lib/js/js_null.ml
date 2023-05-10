(** Provides functionality for dealing with the ['a Js.null] type *)

type +'a t = 'a Types.null

external to_opt : 'a t -> 'a option = "#null_to_opt"
external toOption : 'a t -> 'a option = "#null_to_opt"
external return : 'a -> 'a t = "%identity"

(* null as value *)
(* let test : 'a t -> bool = fun x -> x = Types.null *)

(* external empty : 'a t = "#null" *)
external getUnsafe : 'a t -> 'a = "%identity"

let getExn f =
  match toOption f with
  | None -> Js_exn.raiseError "Js.Null.getExn"
  | Some x -> x

(* let bind x f =
   match toOption x with None -> empty | Some x -> return (f x [@bs]) *)

let iter x f = match toOption x with None -> () | Some x -> f x [@bs]

(* let fromOption x = match x with None -> empty | Some x -> return x *)
(* let from_opt = fromOption *)

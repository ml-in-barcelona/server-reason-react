(** Provide bindings to Js regex expression *)

(* The RegExp object *)
type t = Quickjs.RegExp.t

(* The result of a executing a RegExp on a string. *)
type result = Quickjs.RegExp.result

(* Maps with nullable since Melange does too: https://melange.re/v3.0.0/api/re/melange/Js/Re/index.html#val-captures *)
let captures : result -> string Js_internal.nullable array =
 fun result -> Quickjs.RegExp.captures result |> Stdlib.Array.map (fun x -> Some x)

let index : result -> int = Quickjs.RegExp.index
let input : result -> string = Quickjs.RegExp.input
let source : t -> string = Quickjs.RegExp.source

let fromString : string -> t =
 fun str ->
  match Quickjs.RegExp.compile str ~flags:"" with Ok regex -> regex | Error (_, msg) -> raise (Invalid_argument msg)

let fromStringWithFlags : string -> flags:string -> t =
 fun str ~flags ->
  match Quickjs.RegExp.compile str ~flags with Ok regex -> regex | Error (_, msg) -> raise (Invalid_argument msg)

let flags : t -> string = fun regexp -> Quickjs.RegExp.flags regexp
let global : t -> bool = fun regexp -> Quickjs.RegExp.global regexp
let ignoreCase : t -> bool = fun regexp -> Quickjs.RegExp.ignorecase regexp
let multiline : t -> bool = fun regexp -> Quickjs.RegExp.multiline regexp
let sticky : t -> bool = fun regexp -> Quickjs.RegExp.sticky regexp
let unicode : t -> bool = fun regexp -> Quickjs.RegExp.unicode regexp
let lastIndex : t -> int = fun regex -> Quickjs.RegExp.lastIndex regex
let setLastIndex : t -> int -> unit = fun regex index -> Quickjs.RegExp.setLastIndex regex index

let exec : str:string -> t -> result option =
 fun ~str rex -> match Quickjs.RegExp.exec rex str with result -> Some result | exception _ -> None

let test_ : t -> string -> bool = fun regexp str -> Quickjs.RegExp.test regexp str
let test : str:string -> t -> bool = fun ~str regex -> test_ regex str

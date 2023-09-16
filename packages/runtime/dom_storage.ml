type t = Dom_storage2.t

(* external getItem : string -> string option = "getItem"
   [@@mel.send.pipe: t] [@@mel.return null_to_opt] *)
let getItem _k = None

(* external setItem : string -> string -> unit = "setItem" [@@mel.send.pipe: t] *)
let setItem _k _v = ()

(* external removeItem : string -> unit = "removeItem" [@@mel.send.pipe: t] *)
let removeItem _k = ()

(* external clear : unit -> unit = "clear" [@@mel.send.pipe: t] *)
let clear _ = ()

(* external key : int -> string option = "key"
   [@@mel.send.pipe: t] [@@mel.return null_to_opt] *)
let key _ = None

(* external length : t -> int = "length" [@@mel.get] *)
let length _ = 0

(* external localStorage : t = "localStorage" *)
let localStorage = assert false

(* external sessionStorage : t = "sessionStorage" *)
let sessionStorage = assert false

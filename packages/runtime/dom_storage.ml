type t = Dom_storage2.t

(* external getItem : string -> string option = "getItem"
   [@@bs.send.pipe: t] [@@bs.return null_to_opt] *)
let getItem _k = None

(* external setItem : string -> string -> unit = "setItem" [@@bs.send.pipe: t] *)
let setItem _k _v = ()

(* external removeItem : string -> unit = "removeItem" [@@bs.send.pipe: t] *)
let removeItem _k = ()

(* external clear : unit -> unit = "clear" [@@bs.send.pipe: t] *)
let clear _ = ()

(* external key : int -> string option = "key"
   [@@bs.send.pipe: t] [@@bs.return null_to_opt] *)
let key _ = None

(* external length : t -> int = "length" [@@bs.get] *)
let length _ = 0

(* external localStorage : t = "localStorage" [@@bs.val] *)
let localStorage = assert false

(* external sessionStorage : t = "sessionStorage" [@@bs.val] *)
let sessionStorage = assert false

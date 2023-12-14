type t

external getItem : t -> string -> string option = "getItem"
[@@mel.send.pipe: t] [@@mel.return null_to_opt]

external setItem : string -> string -> unit = "setItem" [@@mel.send.pipe: t]
external removeItem : string -> unit = "removeItem" [@@mel.send.pipe: t]
external clear : unit -> unit = "clear" [@@mel.send.pipe: t]

external key : int -> string option = "key"
[@@mel.send.pipe: t] [@@mel.return null_to_opt]

external length : t -> int = "length" [@@mel.get]
external localStorage : t = "localStorage"
external sessionStorage : t = "sessionStorage"

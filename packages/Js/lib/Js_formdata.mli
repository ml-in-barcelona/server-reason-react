(* TODO: This is a bad implementation for FormData, and not compatible with the Js.FormData from melange.js *)
type entryValue = [ `String of string ]
type t = (string, entryValue) Hashtbl.t

val make : unit -> t
val append : t -> string -> entryValue -> unit
val get : t -> string -> entryValue
val entries : t -> (string * entryValue) list

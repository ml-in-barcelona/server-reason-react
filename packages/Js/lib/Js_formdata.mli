type entryValue = [ `String of string ]
type t = (string, entryValue) Hashtbl.t

val make : unit -> t
val append : t -> string -> entryValue -> unit
val get : t -> string -> entryValue
val entries : t -> (string * entryValue) list

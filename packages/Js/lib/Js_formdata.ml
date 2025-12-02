(* TODO: This is a bad implementation for FormData, and not compatible with the Js.FormData from melange.js *)
type entryValue = [ `String of string ]
type t = (string, entryValue) Hashtbl.t

let make = (fun () -> Hashtbl.create 10 : unit -> t)
let append = (fun formData key value -> Hashtbl.add formData key value : t -> string -> entryValue -> unit)
let get = (fun formData key -> Hashtbl.find formData key : t -> string -> entryValue)

let entries : t -> (string * entryValue) list =
 fun formData -> Hashtbl.fold (fun key value acc -> (key, value) :: acc) formData []

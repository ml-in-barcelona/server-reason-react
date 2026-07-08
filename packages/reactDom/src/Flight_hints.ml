type t = { dedup_key : string; code : string; payload : Yojson.Basic.t }

let sink : (t -> unit) Lwt.key = Lwt.new_key ()
let with_sink emit fn = Lwt.with_value sink (Some emit) fn
let emit hint = match Lwt.get sink with Some emit -> emit hint | None -> ()

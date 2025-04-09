val render_html :
  ?bootstrapScriptContent:string ->
  ?bootstrapScripts:string list ->
  ?bootstrapModules:string list ->
  React.element ->
  (string * ((string -> unit Lwt.t) -> unit Lwt.t)) Lwt.t

val render_model : ?subscribe:(string -> unit Lwt.t) -> React.element -> string Lwt_stream.t Lwt.t
val act : ?subscribe:(string -> unit Lwt.t) -> React.client_value -> string Lwt_stream.t Lwt.t

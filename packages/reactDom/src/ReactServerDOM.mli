val render_html :
  ?debug:bool ->
  ?bootstrapScriptContent:string ->
  ?bootstrapScripts:string list ->
  ?bootstrapModules:string list ->
  React.element ->
  (string * ((string -> unit Lwt.t) -> unit Lwt.t)) Lwt.t

val render_model : ?debug:bool -> ?subscribe:(string -> unit Lwt.t) -> React.element -> unit Lwt.t
val create_action_response : ?debug:bool -> ?subscribe:(string -> unit Lwt.t) -> React.client_value -> unit Lwt.t

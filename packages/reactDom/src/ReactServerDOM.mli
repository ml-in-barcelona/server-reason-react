module Env : sig
  type t = DEV | PROD
end

val render_html :
  ?env:Env.t ->
  ?debug:bool ->
  ?bootstrapScriptContent:string ->
  ?bootstrapScripts:string list ->
  ?bootstrapModules:string list ->
  React.element ->
  (string * ((string -> unit Lwt.t) -> unit Lwt.t)) Lwt.t

val render_model : ?env:Env.t -> ?debug:bool -> ?subscribe:(string -> unit Lwt.t) -> React.element -> unit Lwt.t

val create_action_response :
  ?env:Env.t -> ?debug:bool -> ?subscribe:(string -> unit Lwt.t) -> React.client_value Lwt.t -> unit Lwt.t

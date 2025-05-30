val render_html :
  ?env:[ `Dev | `Prod ] ->
  ?debug:bool ->
  ?bootstrapScriptContent:string ->
  ?bootstrapScripts:string list ->
  ?bootstrapModules:string list ->
  React.element ->
  (string * ((string -> unit Lwt.t) -> unit Lwt.t)) Lwt.t

val render_model :
  ?env:[ `Dev | `Prod ] -> ?debug:bool -> ?subscribe:(string -> unit Lwt.t) -> React.element -> unit Lwt.t

val create_action_response :
  ?env:[ `Dev | `Prod ] -> ?debug:bool -> ?subscribe:(string -> unit Lwt.t) -> React.client_value Lwt.t -> unit Lwt.t

type server_function =
  | FormData of (Js.FormData.t -> React.client_value Lwt.t)
  | Body of (Yojson.Basic.t list -> React.client_value Lwt.t)

val decodeReply : string -> Yojson.Basic.t list

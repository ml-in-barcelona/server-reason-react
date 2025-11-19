val render_html :
  ?skipRoot:bool ->
  ?env:[ `Dev | `Prod ] ->
  ?debug:bool ->
  ?bootstrapScriptContent:string ->
  ?bootstrapScripts:string list ->
  ?bootstrapModules:string list ->
  React.element ->
  (string * ((string -> unit Lwt.t) -> unit Lwt.t)) Lwt.t

val render_model_value :
  ?env:[ `Dev | `Prod ] -> ?debug:bool -> ?subscribe:(string -> unit Lwt.t) -> React.model_value -> unit Lwt.t

val render_model :
  ?env:[ `Dev | `Prod ] -> ?debug:bool -> ?subscribe:(string -> unit Lwt.t) -> React.element -> unit Lwt.t

val create_action_response :
  ?env:[ `Dev | `Prod ] -> ?debug:bool -> ?subscribe:(string -> unit Lwt.t) -> React.model_value Lwt.t -> unit Lwt.t

type server_function =
  | FormData of (Yojson.Basic.t array -> Js.FormData.t -> React.model_value Lwt.t)
  | Body of (Yojson.Basic.t array -> React.model_value Lwt.t)

val decodeReply : string -> Yojson.Basic.t array
val decodeFormDataReply : Js.FormData.t -> Yojson.Basic.t array * Js.FormData.t

module type FunctionReferences = sig
  type t

  val registry : t
  val register : string -> server_function -> unit
  val get : string -> server_function option
end

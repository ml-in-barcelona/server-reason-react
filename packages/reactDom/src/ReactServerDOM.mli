val render_html :
  ?skipRoot:bool ->
  ?env:[ `Dev | `Prod ] ->
  ?debug:bool ->
  ?timeout:float ->
  ?progressive_chunk_size:int ->
  ?bootstrapScriptContent:string ->
  ?bootstrapScripts:string list ->
  ?bootstrapModules:string list ->
  ?identifier_prefix:string ->
  React.element ->
  (string * ((string -> unit Lwt.t) -> unit Lwt.t)) Lwt.t

val render_model :
  ?env:[ `Dev | `Prod ] ->
  ?debug:bool ->
  ?filter_stack_frame:(string -> string -> bool) ->
  ?subscribe:(string -> unit Lwt.t) ->
  React.element ->
  unit Lwt.t

val render_model_value :
  ?env:[ `Dev | `Prod ] ->
  ?debug:bool ->
  ?filter_stack_frame:(string -> string -> bool) ->
  ?subscribe:(string -> unit Lwt.t) ->
  React.model_value ->
  unit Lwt.t

val create_action_response :
  ?env:[ `Dev | `Prod ] ->
  ?debug:bool ->
  ?filter_stack_frame:(string -> string -> bool) ->
  ?subscribe:(string -> unit Lwt.t) ->
  React.model_value Lwt.t ->
  unit Lwt.t

type server_function =
  | FormData of (Yojson.Basic.t array -> Js.FormData.t -> React.model_value Lwt.t)
  | Body of (Yojson.Basic.t array -> React.model_value Lwt.t)

val decodeReply :
  ?temporaryReferences:(string -> Yojson.Basic.t option) -> string -> (Yojson.Basic.t array, string) result

val decodeFormDataReply :
  ?temporaryReferences:(string -> Yojson.Basic.t option) ->
  Js.FormData.t ->
  (Yojson.Basic.t array * Js.FormData.t, string) result

val decodeAction : Js.FormData.t -> (string * Js.FormData.t) option

module type FunctionReferences = sig
  type t

  val registry : t
  val register : string -> server_function -> unit
  val get : string -> server_function option
end

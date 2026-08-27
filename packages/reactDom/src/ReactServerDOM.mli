(** [timeout] (seconds) and [abort] stop a render that is still streaming: every pending row settles as a Flight error
    row (dev carries the reason, prod only the digest), pending Suspense boundaries additionally get a $RX client-render
    instruction in [render_html], the stream closes, and the pending Lwt work is canceled (best-effort: promises without
    cancellation support keep running, but their late output is dropped). [abort] is a host-supplied promise, typically
    resolved on client disconnect; a rejected or canceled signal also aborts. [render_html]'s deadline starts when the
    returned subscribe function is called, not during shell rendering. *)

val render_html :
  ?skipRoot:bool ->
  ?env:[ `Dev | `Prod ] ->
  ?debug:bool ->
  ?filter_stack_frame:(string -> string -> bool) ->
  ?timeout:float ->
  ?abort:unit Lwt.t ->
  ?progressive_chunk_size:int ->
  ?bootstrapScriptContent:string ->
  ?bootstrapScripts:string list ->
  ?bootstrapModules:string list ->
  ?nonce:string ->
  ?identifier_prefix:string ->
  React.element ->
  (string * ((string -> unit Lwt.t) -> unit Lwt.t)) Lwt.t

val render_model :
  ?env:[ `Dev | `Prod ] ->
  ?debug:bool ->
  ?filter_stack_frame:(string -> string -> bool) ->
  ?subscribe:(string -> unit Lwt.t) ->
  ?timeout:float ->
  ?abort:unit Lwt.t ->
  React.element ->
  unit Lwt.t

val render_model_value :
  ?env:[ `Dev | `Prod ] ->
  ?debug:bool ->
  ?filter_stack_frame:(string -> string -> bool) ->
  ?subscribe:(string -> unit Lwt.t) ->
  ?timeout:float ->
  ?abort:unit Lwt.t ->
  React.model_value ->
  unit Lwt.t

val create_action_response :
  ?env:[ `Dev | `Prod ] ->
  ?debug:bool ->
  ?filter_stack_frame:(string -> string -> bool) ->
  ?subscribe:(string -> unit Lwt.t) ->
  ?timeout:float ->
  ?abort:unit Lwt.t ->
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

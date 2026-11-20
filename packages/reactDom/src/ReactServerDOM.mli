(** [timeout] (seconds) and [abort] stop a render that is still streaming: every pending row settles as a Flight error
    row (dev carries the reason, prod only the digest), pending Suspense boundaries additionally get a $RX client-render
    instruction in [render_html], the stream closes, and the pending Lwt work is canceled (best-effort: promises without
    cancellation support keep running, but their late output is dropped). [abort] is a host-supplied promise, typically
    resolved on client disconnect; a rejected or canceled signal also aborts. [render_html]'s deadline starts when the
    returned subscribe function is called, not during shell rendering.

    With [~env:`Dev], all render functions emit element key-validation metadata. Static child positions have state [1],
    unkeyed dynamic members have state [2], and other unvalidated elements have state [0]. The default [env] is [`Prod]:
    React's four-field element tuples without this metadata, and redacted error messages and stacks. *)

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

(** Decode the arguments of a server function call from an untrusted request.

    [max_bytes] (default 1048576) limits the byte length of each JSON text that is parsed: the body for [decodeReply];
    the root entry and each outlined entry for [decodeFormDataReply]. Blob ([$B]) entries are not parsed and are not
    limited. A text with a ['/'] outside a string, such as a comment, is rejected.

    [max_depth] (default 512) limits nesting. The root argument array is level 1, and each array, object and reference
    to an outlined entry adds one level. Byte size and nesting inside one text are checked before the text is parsed.

    The decoded arguments may hold at most [max_bytes] JSON values in total. An outlined entry that is referenced more
    than once counts once for each reference, so a small payload cannot expand to a huge value.

    A payload over a limit returns [Error], with a message that starts with ["decodeReply:"], like every other decode
    error. To accept larger payloads, pass a larger [~max_bytes] (and [~max_depth] if needed), and limit the HTTP body
    size in the server as well. *)

val decodeReply :
  ?temporaryReferences:(string -> Yojson.Basic.t option) ->
  ?max_depth:int ->
  ?max_bytes:int ->
  string ->
  (Yojson.Basic.t array, string) result

val decodeFormDataReply :
  ?temporaryReferences:(string -> Yojson.Basic.t option) ->
  ?max_depth:int ->
  ?max_bytes:int ->
  Js.FormData.t ->
  (Yojson.Basic.t array * Js.FormData.t, string) result

val decodeAction : Js.FormData.t -> (string * Js.FormData.t) option

module type FunctionReferences = sig
  type t

  val registry : t
  val register : string -> server_function -> unit
  val get : string -> server_function option
end

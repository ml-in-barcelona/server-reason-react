(** [timeout] (seconds) and [abort] stop a render that is still streaming: every pending row settles as a Flight error
    row (dev carries the reason, prod only the digest), pending Suspense boundaries additionally get a $RX client-render
    instruction in [render_html], the stream closes, and the pending Lwt work is canceled (best-effort: promises without
    cancellation support keep running, but their late output is dropped). [abort] is a host-supplied promise, typically
    resolved on client disconnect; a rejected or canceled signal also aborts. [render_html]'s deadline starts when the
    returned subscribe function is called, not during shell rendering.

    With [~env:`Dev], all render functions emit element key-validation metadata. Static child positions have state [1],
    unkeyed dynamic members have state [2], and other unvalidated elements have state [0]. The default [env] is [`Prod]:
    React's four-field element tuples without this metadata, and redacted error messages and stacks.

    [onError] is called once for each error that the render turns into an error row: an exception from a component, a
    rejected promise, or a failed server function in [create_action_response]. [Some digest] sets the digest of that
    error, which is sent in [`Prod] too and lets the host find its log entry. With [None], no [onError], or an [onError]
    that raises, the digest is empty, except in [create_action_response], where the rejection of the server function
    gets a random digest. Out_of_memory, Stack_overflow and Sys.Break raised by [onError] are re-raised. A timeout or an
    abort does not call [onError]. *)

val render_html :
  ?skipRoot:bool ->
  ?env:[ `Dev | `Prod ] ->
  ?debug:bool ->
  ?filter_stack_frame:(string -> string -> bool) ->
  ?timeout:float ->
  ?abort:unit Lwt.t ->
  ?onError:(exn -> string option) ->
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
  ?onError:(exn -> string option) ->
  React.element ->
  unit Lwt.t

val render_model_value :
  ?env:[ `Dev | `Prod ] ->
  ?debug:bool ->
  ?filter_stack_frame:(string -> string -> bool) ->
  ?subscribe:(string -> unit Lwt.t) ->
  ?timeout:float ->
  ?abort:unit Lwt.t ->
  ?onError:(exn -> string option) ->
  React.model_value ->
  unit Lwt.t

val create_action_response :
  ?env:[ `Dev | `Prod ] ->
  ?debug:bool ->
  ?filter_stack_frame:(string -> string -> bool) ->
  ?subscribe:(string -> unit Lwt.t) ->
  ?timeout:float ->
  ?abort:unit Lwt.t ->
  ?onError:(exn -> string option) ->
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

type 'meta server_function_entry = {
  id : string;  (** The wire id that the client sends. *)
  name : string;  (** The path id [<path>[.Modules]#<name>] of the function in the source. *)
  meta : 'meta;  (** The payload of [[@react.server.function <meta>]], or the default meta. *)
  handler : server_function;
}

(** The module that the application names [FunctionReferences]. The ppx calls
    [FunctionReferences.register ~id ~name ~meta handler] for each [[@react.server.function]], and passes
    [FunctionReferences.default_meta] as [meta] when the attribute has no payload. A payload must have the type [meta].

    Registration happens when the module that defines the server function is initialised. The linker drops a module of a
    library that nothing references, and then its ids are not registered. Link the libraries that define server
    functions with [(link_flags (-linkall))] in the executable, or reference each such module from the executable.

    The host gets the entry of a call with [get] and can check its [meta] (for example, permissions) before it calls
    [handler]. Every registered function can be called over HTTP unless the host rejects it. *)
module type FunctionReferences = sig
  type meta

  val default_meta : meta

  val register : id:string -> name:string -> meta:meta -> server_function -> unit
  (** Raises [Invalid_argument] when [id] is already registered. The message names both functions. *)

  val get : string -> meta server_function_entry option
end

module FunctionReferences : sig
  (** A registry for server functions. An application defines its module [FunctionReferences] as
      [include ReactServerDOM.FunctionReferences.Make (Meta)]. *)
  module Make (Meta : sig
    type t

    val default : t
  end) : FunctionReferences with type meta = Meta.t
end

(* The server router turns an HTTP location into a renderable response in stages.

    {!Path} and {!Search} first validate the untrusted URL. {!Registry} and
    {!Match} select a route, then {!Decode} gives the generated endpoint typed
    inputs. The endpoint describes both its reusable layout {!Branch} and its
    deferred loader {!Execution}. Finally, {!Plan} assembles the view, metadata,
    and headers while {!ServerEngine} decides whether the client needs a full
    response, a branch patch, a redirect, or a reload. *)

(** Validation and decomposition of URL pathnames.

    Segments are decoded only after splitting, so an encoded slash cannot alter the route shape. Dot segments are
    rejected rather than normalized because matching must use the same pathname the application received. *)
module Path : sig
  type error = MalformedEscape of string | EncodedSlash of string | InvalidPath of string

  val decodePathname : string -> (string list, error) result
  val stripBasePath : basePath:string -> string -> string option
  val splitLocation : string -> string * string
end

module Route : sig
  type t

  val make : id:string -> path:string -> t
  val id : t -> string
  val path : t -> string
end

module Registry : sig
  type t

  type error =
    | DuplicateId of string
    | DuplicatePath of string
    | AmbiguousPattern of string * string
    | InvalidPattern of string

  val make : Route.t list -> (t, error) result
  (** Builds a registry after rejecting duplicate identities and patterns that could match the same pathname with equal
      specificity. *)

  val makeExn : Route.t list -> t
  val routes : t -> Route.t list
end

module Match : sig
  type t = { route : Route.t; parameters : (string * string) list }
  type error = MalformedEscape of string | EncodedSlash of string | InvalidPath of string

  val find : Registry.t -> pathname:string -> (t option, error) result
  (** Validates [pathname], selects the route with the most static segments, and decodes its parameters. Registry
      validation makes that choice unique. *)
end

(** Parsed query parameters. Repeated values and first-seen key order are preserved so generated decoders can
    distinguish one, optional, and many parameters without reparsing the URL. *)
module Search : sig
  type t
  type error = MalformedEscape of string | QueryTooLong

  val parse : string -> (t, error) result
  val values : t -> string -> string list
  val unknown : t -> owned:string list -> (string * string list) list
end

module Input : sig
  type t

  val forSearch : Search.t -> t
end

module Decode : sig
  val path :
    input:Input.t ->
    name:string ->
    parse:(string -> ('value, string) result) ->
    ('value, 'error RouterRuntime.Error.t) result

  val searchRequired :
    input:Input.t ->
    name:string ->
    parse:(string -> ('value, string) result) ->
    ('value, 'error RouterRuntime.Error.t) result

  val searchOptional :
    input:Input.t ->
    name:string ->
    parse:(string -> ('value, string) result) ->
    ('value option, 'error RouterRuntime.Error.t) result

  val searchDefault :
    input:Input.t ->
    name:string ->
    parse:(string -> ('value, string) result) ->
    fallback:'value ->
    ('value, 'error RouterRuntime.Error.t) result

  val searchMany :
    input:Input.t ->
    name:string ->
    parse:(string -> ('value, string) result) ->
    ('value list, 'error RouterRuntime.Error.t) result
end

(** A deferred, sequential description of route loaders.

    Generated routes build this value while walking from the outermost layout to the page. Running it later keeps
    decoding and branch comparison free of loader side effects, which is important when deciding whether a navigation
    can be sent as a patch. *)
module Execution : sig
  type ('result, 'error) t

  val done_ : 'result -> ('result, 'error) t

  val load :
    (unit -> ('data, 'error) RouterRuntime.Loader.result Lwt.t) -> ('data -> ('result, 'error) t) -> ('result, 'error) t
  (** Adds a loader whose non-data result leaves the execution immediately. *)

  val loadWithBoundary :
    run:(unit -> ('data, 'error) RouterRuntime.Loader.result Lwt.t) ->
    failure:('error RouterRuntime.Error.t -> 'result) ->
    next:('data -> ('result, 'error) t) ->
    ('result, 'error) t
  (** Adds a loader with the nearest error boundary. Application errors, not found results, and non-fatal exceptions
      become [failure] values; redirects and fatal exceptions still escape the boundary. *)

  val run : ?diagnosticId:(exn -> string) -> ('result, 'error) t -> ('result, 'error) RouterRuntime.Loader.result Lwt.t
end

module Branch : sig
  (** The identity of one layout instance in a matched route branch. *)
  module Scope : sig
    type t

    val make : id:string -> parameters:(string * string) list -> reusable:bool -> t
    (** [parameters] are framed into [instanceKey], avoiding ambiguous keys when names or values have shared prefixes.
    *)

    val id : t -> string
    val instanceKey : t -> string
    val reusable : t -> bool
  end

  type t = Scope.t list

  val sharedPrefix : t -> t -> int
  (** Returns the number of leading layout instances that can survive a navigation. Comparison stops as soon as either
      scope is not reusable. *)

  val layouts : t -> RouterRuntime.Navigation.layout list
end

(** The render plan produced after all route loaders have completed.

    A plan keeps rendering separate from loader execution: scopes contribute layouts and response values, while success
    or failure supplies the leaf to place inside those layouts. *)
module Plan : sig
  module Scope : sig
    type 'view t

    val make :
      ?layout:('view -> 'view) ->
      ?metadata:(unit -> RouterRuntime.Metadata.t Lwt.t) ->
      ?headers:(unit -> RouterRuntime.Headers.t Lwt.t) ->
      unit ->
      'view t
  end

  type ('view, 'error) t

  type ('view, 'error) resolved = {
    element : 'view option;
    error : 'error RouterRuntime.Error.t option;
    status : RouterRuntime.Status.t;
    metadata : RouterRuntime.Metadata.t;
    headers : RouterRuntime.Headers.t;
  }

  val success : scopes:'view Scope.t list -> page:'view -> ('view, 'error) t

  val failure :
    scopes:'view Scope.t list ->
    error:'error RouterRuntime.Error.t ->
    ?notFound:('error RouterRuntime.Error.t -> 'view) ->
    ?errorBoundary:('error RouterRuntime.Error.t -> 'view) ->
    unit ->
    ('view, 'error) t

  type render = Full | Suffix of { omitted_scopes : int }

  val resolve :
    ?render:render ->
    ('view, 'error) t ->
    applicationStatus:('error -> RouterRuntime.Status.t) ->
    ('view, 'error) resolved Lwt.t
  (** Resolves metadata and headers from every scope, then renders either the whole layout chain or only its changed
      suffix. Omitting layouts for a patch does not omit their response metadata or headers. *)
end

(** A generated route endpoint.

    Decoding produces one [prepared] value containing both the branch identity and the deferred execution. Keeping them
    together ensures patch planning and loader execution use the same decoded parameters. *)
module Endpoint : sig
  type ('result, 'error) t
  type ('result, 'error) prepared

  val make :
    id:string ->
    path:string ->
    activeRoutes:(string * string list) list ->
    fingerprint:string ->
    decode:(Input.t -> (('result, 'error) prepared, 'error RouterRuntime.Error.t) result) ->
    ('result, 'error) t

  val prepared : branch:Branch.t -> execution:(unit -> ('result, 'error) Execution.t) -> ('result, 'error) prepared
  (** [execution] is a thunk so inspecting a candidate branch never starts its loaders. *)

  val branch : ('result, 'error) prepared -> Branch.t
  val execution : ('result, 'error) prepared -> ('result, 'error) Execution.t
  val route : ('result, 'error) t -> Route.t
end

module EndpointRegistry : sig
  type ('result, 'error) t
  type ('result, 'error) matched

  val make : ('result, 'error) Endpoint.t list -> (('result, 'error) t, Registry.error) result
  val makeExn : ('result, 'error) Endpoint.t list -> ('result, 'error) t
  val find : ('result, 'error) t -> pathname:string -> (('result, 'error) matched option, Match.error) result

  val decode :
    ('result, 'error) matched ->
    search:Search.t ->
    (('result, 'error) Endpoint.prepared, 'error RouterRuntime.Error.t) result

  val route : ('result, 'error) matched -> Route.t
  val parameters : ('result, 'error) matched -> (string * string) list
  val matches : ('result, 'error) matched -> RouterRuntime.Navigation.matched list

  val fingerprint : ('result, 'error) t -> string
  (** A stable digest of generated endpoint fingerprints, used to detect a client whose route definitions no longer
      agree with the server. *)
end

(** The request-level state machine.

    Document requests always produce complete render data. RSC navigations may instead reuse the common prefix of the
    previous and target branches. A registry mismatch requests a reload before any route loaders run. *)
module ServerEngine : sig
  type requestKind = Document | Rsc
  type navigationFacts = { from : string option; registry : string option; base_revision : string option }

  type request = {
    pathname : string;
    search : string;
    hash : string;
    kind : requestKind;
    navigation : navigationFacts option;
  }

  type ('view, 'error) full = {
    kind : requestKind;
    canonical_url : string;
    revision : string;
    registry_fingerprint : string;
    protocol_version : int;
    matches : RouterRuntime.Navigation.matched list;
    layouts : RouterRuntime.Navigation.layout list;
    resolved : ('view, 'error) Plan.resolved;
  }

  type ('view, 'error) patch = {
    kind : requestKind;
    canonical_url : string;
    base_revision : string;
    revision : string;
    registry_fingerprint : string;
    protocol_version : int;
    matches : RouterRuntime.Navigation.matched list;
    layouts : RouterRuntime.Navigation.layout list;
    replace_from : string;
    resolved : ('view, 'error) Plan.resolved;
  }

  type ('view, 'error) outcome =
    | Full of ('view, 'error) full
    | Patch of ('view, 'error) patch
    | ReloadRequired
    | Redirect of RouterRuntime.destination

  val run :
    registry:(('view, 'error) Plan.t, 'error) EndpointRegistry.t ->
    basePath:string ->
    fallback:(search:Search.t -> error:'error RouterRuntime.Error.t -> ('view, 'error) Plan.t) ->
    applicationStatus:('error -> RouterRuntime.Status.t) ->
    diagnosticId:(exn -> string) ->
    revision:(unit -> string) ->
    protocolVersion:int ->
    request ->
    ('view, 'error) outcome Lwt.t
  (** Validates and matches the request, executes its loaders, resolves the resulting plan, and chooses the smallest
      safe outcome. Unexpected exceptions are offered to the root fallback before a blank internal-error response is
      used as a last resort. *)
end

(** Configured facade shared by the HTTP adapter and the generated client root. *)
module Server : sig
  type ('view, 'error) t

  val make :
    basePath:string ->
    registry:(('view, 'error) Plan.t, 'error) EndpointRegistry.t ->
    fallback:(search:Search.t -> error:'error RouterRuntime.Error.t -> ('view, 'error) Plan.t) ->
    applicationStatus:('error -> RouterRuntime.Status.t) ->
    ?protocolVersion:int ->
    unit ->
    ('view, 'error) t

  val basePath : ('view, 'error) t -> string
  val protocolVersion : ('view, 'error) t -> int
  val fingerprint : ('view, 'error) t -> string

  val clientRoot :
    (React.element, 'error) t ->
    initial:RouterRuntime.Navigation.committed ->
    metadata:React.element ->
    children:React.element ->
    React.element

  val run :
    ('view, 'error) t ->
    diagnosticId:(exn -> string) ->
    revision:(unit -> string) ->
    ServerEngine.request ->
    ('view, 'error) ServerEngine.outcome Lwt.t
end

val statusOfError :
  application:('error -> RouterRuntime.Status.t) -> 'error RouterRuntime.Error.t -> RouterRuntime.Status.t

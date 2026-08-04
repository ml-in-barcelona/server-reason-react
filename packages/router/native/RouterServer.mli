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
  val makeExn : Route.t list -> t
  val routes : t -> Route.t list
end

module Match : sig
  type t = { route : Route.t; parameters : (string * string) list }
  type error = MalformedEscape of string | EncodedSlash of string | InvalidPath of string

  val find : Registry.t -> pathname:string -> (t option, error) result
end

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

module Execution : sig
  type ('result, 'error) t

  val done_ : 'result -> ('result, 'error) t

  val load :
    (unit -> ('data, 'error) RouterRuntime.Loader.result Lwt.t) -> ('data -> ('result, 'error) t) -> ('result, 'error) t

  val loadWithBoundary :
    run:(unit -> ('data, 'error) RouterRuntime.Loader.result Lwt.t) ->
    failure:('error RouterRuntime.Error.t -> 'result) ->
    next:('data -> ('result, 'error) t) ->
    ('result, 'error) t

  val run : ('result, 'error) t -> ('result, 'error) RouterRuntime.Loader.result Lwt.t
end

module Branch : sig
  module Scope : sig
    type t

    val make : id:string -> parameters:(string * string) list -> reusable:bool -> t
    val id : t -> string
    val instanceKey : t -> string
    val reusable : t -> bool
  end

  type t = Scope.t list

  val sharedPrefix : t -> t -> int
  val layouts : t -> RouterRuntime.Navigation.layout list
end

module Plan : sig
  module Scope : sig
    type 'view t

    val make :
      id:string ->
      instanceKey:string ->
      reusable:bool ->
      ?layout:('view -> 'view) ->
      ?loading:(unit -> 'view) ->
      ?metadata:(unit -> RouterRuntime.Metadata.t Lwt.t) ->
      ?headers:(unit -> RouterRuntime.Headers.t Lwt.t) ->
      unit ->
      'view t

    val id : 'view t -> string
    val instanceKey : 'view t -> string
    val reusable : 'view t -> bool
    val loading : 'view t -> (unit -> 'view) option
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
end

module Endpoint : sig
  type ('result, 'error) t

  val make :
    id:string ->
    path:string ->
    activeRoutes:(string * string list) list ->
    fingerprintParts:string list ->
    project:(Input.t -> (Branch.t, 'error RouterRuntime.Error.t) result) ->
    prepare:(Input.t -> (('result, 'error) Execution.t, 'error RouterRuntime.Error.t) result) ->
    ('result, 'error) t

  val route : ('result, 'error) t -> Route.t
end

module EndpointRegistry : sig
  type ('result, 'error) t
  type ('result, 'error) matched

  val make : ('result, 'error) Endpoint.t list -> (('result, 'error) t, Registry.error) result
  val makeExn : ('result, 'error) Endpoint.t list -> ('result, 'error) t
  val find : ('result, 'error) t -> pathname:string -> (('result, 'error) matched option, Match.error) result

  val prepare :
    ('result, 'error) matched -> search:Search.t -> (('result, 'error) Execution.t, 'error RouterRuntime.Error.t) result

  val project : ('result, 'error) matched -> search:Search.t -> (Branch.t, 'error RouterRuntime.Error.t) result
  val route : ('result, 'error) matched -> Route.t
  val parameters : ('result, 'error) matched -> (string * string) list
  val matches : ('result, 'error) matched -> RouterRuntime.Navigation.matched list
  val fingerprint : ('result, 'error) t -> string
end

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
end

val statusOfError :
  application:('error -> RouterRuntime.Status.t) -> 'error RouterRuntime.Error.t -> RouterRuntime.Status.t

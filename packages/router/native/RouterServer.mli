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
  (** Returns the part of [pathname] below [basePath], or [None] when [pathname] is outside it. Segments are compared
      after decoding, as route segments are, so [/app] matches [/app] and [/app/x] but not [/apple], and escapes match
      in either letter case. *)

  val splitLocation : string -> string * string

  val stripTrailingSlashes : string -> string option
  (** Returns the canonical pathname when [pathname] ends with one or more slashes, or [None] when it is already
      canonical. The root pathname ["/"] is canonical. *)
end

(** Policy for request pathnames that end with a slash. Generated hrefs never end with a slash, so the canonical form of
    every route is slash-free. [Redirect] answers with a permanent redirect to the canonical pathname; [Reject] treats
    the request as not found. *)
module TrailingSlash : sig
  type t = Redirect | Reject
end

module Route : sig
  type t

  val make : id:string -> path:string -> t
  val id : t -> string
  val path : t -> string
end

module Registry : sig
  type t
  type error = DuplicateId of string | DuplicatePath of string | AmbiguousPattern of string * string

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

(** A deferred, sequential description of route work.

    Generated routes build this value while walking from the outermost layout to the page. Running it later keeps
    decoding and branch comparison free of loader side effects, which is important when deciding whether a navigation
    can be sent as a patch. *)
module Execution : sig
  type ('result, 'error) t

  val done_ : 'result -> ('result, 'error) t

  val redirect : RouterRuntime.destination -> ('result, 'error) t
  (** Ends execution with a temporary redirect without running a loader. *)

  val permanentRedirect : RouterRuntime.destination -> ('result, 'error) t
  (** Ends execution with a permanent redirect without running a loader. *)

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
        [reusable] marks a scope that owns an outlet and can therefore receive a navigation patch. *)

    val id : t -> string
    val instanceKey : t -> string
    val reusable : t -> bool
  end

  type t = Scope.t list

  val sharedPrefix : t -> t -> int
  (** Returns the number of leading layout instances that can survive a navigation. Comparison stops as soon as either
      scope is not reusable. The result is an upper bound: {!Plan.scopeCount} bounds it further once loaders have run.
  *)

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

  val withFailure : ('view, 'error) t -> ('error RouterRuntime.Error.t -> ('view, 'error) t) -> ('view, 'error) t
  (** Gives a successful plan the plan to render when the page itself fails after its loaders ran, for example when a
      form's server function fails. Generated routes pass a failure plan with the route's nearest boundaries. A plan
      without one renders the failure in its layouts with the built-in text. *)

  val failure :
    scopes:'view Scope.t list ->
    error:'error RouterRuntime.Error.t ->
    ?notFound:('error RouterRuntime.Error.t -> 'view) ->
    ?errorBoundary:('error RouterRuntime.Error.t -> 'view) ->
    unit ->
    ('view, 'error) t

  val scopeCount : ('view, 'error) t -> int
  (** The number of layout scopes the plan renders. A loader failure drops the failing scope and everything below it, so
      this can be shorter than the matched {!Branch.t} and bounds how deep a patch may graft. *)

  type render = Full | Suffix of { omitted_scopes : int }

  val resolve :
    ?render:render ->
    ('view, 'error) t ->
    applicationStatus:('error -> RouterRuntime.Status.t) ->
    ('view, 'error) resolved Lwt.t
  (** Resolves metadata and headers from every scope, then renders either the whole layout chain or only its changed
      suffix. Every scope starts at once; the results merge from the root down, whatever order they resolve in. Omitting
      layouts for a patch does not omit their response metadata or headers. *)

  val resolvedElement : (React.element, 'error) resolved -> React.element
  (** The element to render: [resolved.element], or a built-in plain paragraph when the app declares no boundary for the
      failure ("Not found", "Bad request" or "Something went wrong"). It never includes error details. *)
end

(** A generated route endpoint.

    Decoding produces one [prepared] value containing the branch identity, publishable active routes, and deferred
    execution. Keeping them together ensures response state, patch planning, and loader execution use the same decoded
    parameters. *)
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

  val recovered :
    branch:Branch.t ->
    activeRoutes:string list ->
    execution:(unit -> ('result, 'error) Execution.t) ->
    ('result, 'error) prepared
  (** Builds a decode-failure preparation whose response exposes only the listed successfully decoded active routes. *)

  val withPrefetch : ('result, 'error) t -> RouterRuntime.PrefetchLevel.t -> ('result, 'error) t
  (** Sets the route's prefetch level. {!make} gives [Intent]. *)

  val prefetch : ('result, 'error) t -> RouterRuntime.PrefetchLevel.t
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
  val prefetch : ('result, 'error) matched -> RouterRuntime.PrefetchLevel.t

  val matches :
    ('result, 'error) matched -> ('result, 'error) Endpoint.prepared -> RouterRuntime.Navigation.matched list

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
        (** A navigation redirect requested by a route loader. Document adapters answer with a see-other redirect (303).
        *)
    | PermanentRedirect of RouterRuntime.destination
        (** A permanent redirect: pathname canonicalization, a loader that returns [Loader.PermanentRedirect], or a
            [Router.redirect ~permanent:true]. Adapters answer documents with status 308 so the request method survives
            the redirect. *)
    | PrefetchRefused of RouterRuntime.PrefetchLevel.t
        (** A prefetch asked for a level more eager than the matched route's level, which it carries. No decoder or
            loader ran. *)

  val run :
    registry:(('view, 'error) Plan.t, 'error) EndpointRegistry.t ->
    basePath:string ->
    trailingSlash:TrailingSlash.t ->
    fallback:(search:Search.t -> error:'error RouterRuntime.Error.t -> ('view, 'error) Plan.t) ->
    applicationStatus:('error -> RouterRuntime.Status.t) ->
    diagnosticId:(exn -> string) ->
    revision:(unit -> string) ->
    protocolVersion:int ->
    ?prefetch:RouterRuntime.PrefetchLevel.t ->
    ?actionError:'error RouterRuntime.Error.t ->
    request ->
    ('view, 'error) outcome Lwt.t
  (** Validates and matches the request, executes its loaders, resolves the resulting plan, and chooses the smallest
      safe outcome. Unexpected exceptions are offered to the root fallback before a blank internal-error response is
      used as a last resort.

      [prefetch] marks the request as a prefetch at that level. When it is more eager than the matched route's level,
      the outcome is [PrefetchRefused] and no decoder or loader runs. Otherwise, including when no route matches, the
      outcome is the same as without [prefetch], and its headers add [Router-Prefetch] to [Vary].

      [actionError] renders the page as failed with that error after its loaders ran (see {!Plan.withFailure}). A
      loader's own redirect or failure still wins. *)
end

(** Configured facade shared by the HTTP adapter and the generated client root. *)
module Server : sig
  type ('view, 'error) t

  val make :
    basePath:string ->
    registry:(('view, 'error) Plan.t, 'error) EndpointRegistry.t ->
    ?trailingSlash:TrailingSlash.t ->
    fallback:(search:Search.t -> error:'error RouterRuntime.Error.t -> ('view, 'error) Plan.t) ->
    applicationStatus:('error -> RouterRuntime.Status.t) ->
    ?protocolVersion:int ->
    ?interceptLinks:bool ->
    ?viewTransitions:bool ->
    unit ->
    ('view, 'error) t
  (** [trailingSlash] defaults to {!TrailingSlash.Redirect}. [interceptLinks] (default [true]) and [viewTransitions]
      (default [false]) are passed to the client [Provider] by {!clientRoot} and {!clientRootWithCache}. *)

  val basePath : ('view, 'error) t -> string
  val protocolVersion : ('view, 'error) t -> int
  val fingerprint : ('view, 'error) t -> string

  val routes : ('view, 'error) t -> string array
  (** Every concrete route path, optional segments expanded, without the base path, in registry order. The client parses
      each with [RouterPattern.parse] and matches links with [RouterPattern.matchesPath ~basePath], so a base path that
      is not valid route syntax, such as [/a%20b], still works. *)

  val clientRoot :
    (React.element, 'error) t ->
    initial:RouterRuntime.Navigation.committed ->
    metadata:React.element ->
    children:React.element ->
    React.element
  (** The client root with the client's default page cache (30 pages). *)

  val clientRootWithCache :
    (React.element, 'error) t ->
    pageCacheCapacity:int ->
    initial:RouterRuntime.Navigation.committed ->
    metadata:React.element ->
    children:React.element ->
    React.element

  val clientRootWith :
    (React.element, 'error) t ->
    make:
      (initial:RouterRuntime.Navigation.committed ->
      protocolVersion:int ->
      registryFingerprint:string ->
      basePath:string ->
      routes:string array ->
      metadata:React.element ->
      children:React.element ->
      React.element) ->
    initial:RouterRuntime.Navigation.committed ->
    metadata:React.element ->
    children:React.element ->
    React.element

  val run :
    ('view, 'error) t ->
    diagnosticId:(exn -> string) ->
    revision:(unit -> string) ->
    ?prefetch:RouterRuntime.PrefetchLevel.t ->
    ?actionError:'error RouterRuntime.Error.t ->
    ServerEngine.request ->
    ('view, 'error) ServerEngine.outcome Lwt.t
end

(** Server functions run from a page form without JavaScript. *)
module Action : sig
  exception Redirect of RouterRuntime.destination

  val redirect : RouterRuntime.destination -> 'a
  (** Ends a server function with a redirect. After a form post without JavaScript, the adapter answers 303 to
      [destination] instead of to the page. *)
end

(** Server-agnostic pieces of an HTTP adapter. An adapter parses its request into a {!ServerEngine.request}, calls
    {!Server.run}, passes the outcome to {!reply}, and writes the {!reply} with its own server. Nothing here depends on
    an HTTP server. *)
module Adapter : sig
  val metadata_element : RouterRuntime.Metadata.t -> React.element
  (** Renders resolved metadata as head elements: [<title>], [<meta name="description">], then each entry as a [<meta>]
      or [<link>] in order. Every element has the stable React key ["router:" ^ key]. For a [Link], attributes named
      [rel] or [href] (any case) in [attrs] are ignored: the [rel] and [href] fields win. The result goes in [<head>]
      and is also sent to the client in navigation responses. *)

  val document_element :
    (React.element, 'error) Server.t ->
    ?pageCacheCapacity:int ->
    document:(head:React.element -> React.element -> React.element) ->
    (React.element, 'error) ServerEngine.full ->
    React.element
  (** Builds the HTML document for a full response. [document ~head children] builds [<html>]. [head] is the metadata
      element, to be placed inside [<head>]. [children] holds the routed root and a marker that tells the client
      bootstrap whether the server rendered the markup, and goes in [<body>]. Without [pageCacheCapacity] the client's
      default page cache (30 pages) applies; [0] turns it off. *)

  val full_model : (React.element, 'error) ServerEngine.full -> React.model_value
  val patch_model : (React.element, 'error) ServerEngine.patch -> React.model_value

  val redirect_model :
    protocolVersion:int -> registryFingerprint:string -> RouterRuntime.destination -> React.model_value

  type body =
    | Empty
    | Html of React.element  (** An HTML document. Render it with the server's bootstrap modules. *)
    | Model of { location : string; model : React.model_value }
        (** A navigation response. [location] is the value for the [X-Location] header. *)

  type reply = { status : int; headers : (string * string) list; body : body }
  (** [headers] holds every protocol header for the outcome, including [Content-Type] for [Html] and [Model] and
      [Location] for redirects. The adapter adds nothing but transport details. *)

  val methodReply : allow:string list -> string -> reply option
  (** Decides an HTTP method before {!Server.run}. [allow] lists the methods the adapter serves at the router's paths.
      [OPTIONS] answers 204 and a method outside [allow] answers 405, both with an [Allow] header. [None] means the
      adapter handles the method: [GET] and [HEAD] run the router, and a [HEAD] reply is sent without its body. Methods
      are case-sensitive. *)

  type formAction =
    | Completed
    | Redirected of RouterRuntime.destination  (** The server function called {!Action.redirect}. *)
    | Failed of exn

  val runFormAction :
    lookup:(string -> 'meta ReactServerDOM.server_function_entry option) -> Js.FormData.t -> formAction option Lwt.t
  (** Runs the server function named by the [$ACTION_ID_<id>] field of a form posted without JavaScript, with the rest
      of the form. [None] when the form names no registered server function. Fatal exceptions are re-raised. The server
      function's result is not used: a page without JavaScript cannot show it. *)

  val redirectLocation : RouterRuntime.destination -> string option
  (** The [Location] for a redirect to [destination]: its href when it is a path that starts with a single ["/"] (not
      ["//"] or a slash followed by a backslash) or an absolute [http:] or [https:] URL, without control characters.
      [None] otherwise, for example [javascript:] or [//host]. Every redirect the router sends goes through it: {!reply}
      answers an unsafe redirect outcome with 500, {!ServerEngine.run} turns an unsafe loader or route redirect into an
      internal error, and an unsafe {!Action.redirect} fails the server function. *)

  val actionRedirectHeader : RouterRuntime.destination -> (string * string) option
  (** [Some ("Router-Redirect", location)] for a safe destination (see {!redirectLocation}). A server function called
      from JavaScript that ends with {!Action.redirect} gets a normal action response with a [null] result and this
      header; the client then navigates to the location with a push. The adapter must wait for the function before it
      sends the headers, and must treat [None] as a failed function. *)

  val formActionReply :
    (React.element, 'error) Server.t ->
    diagnosticId:(exn -> string) ->
    revision:(unit -> string) ->
    target:string ->
    ?pageCacheCapacity:int ->
    document:(head:React.element -> React.element -> React.element) ->
    ServerEngine.request ->
    formAction ->
    reply Lwt.t
  (** The reply to a page form posted without JavaScript, so a reload does not post again:
      - [Completed]: 303 to [target], the posted URL.
      - [Redirected destination]: 303 to [destination].
      - [Failed]: the page at [request], rendered as a document with its nearest error boundary and the status of an
        internal error, through [Server.run ~actionError]. When the page itself redirects, for example a URL with a
        trailing slash, the reply is a 303 to that location: a reply to a [POST] is never 307 or 308, so the browser
        never posts the form again. An unsafe location (see {!redirectLocation}) gives 500 instead of a redirect. *)

  val reply :
    (React.element, 'error) Server.t ->
    target:string ->
    ?pageCacheCapacity:int ->
    document:(head:React.element -> React.element -> React.element) ->
    kind:ServerEngine.requestKind ->
    (React.element, 'error) ServerEngine.outcome ->
    reply
  (** Maps an outcome to status, headers and body. [target] is the request target, used for [X-Location] on RSC
      redirects. [kind] is the request kind given to {!Server.run}.
      - Full and patch: the resolved status and headers.
      - Document redirect: 303 ([Redirect]) or 308 ([PermanentRedirect]) with [Location].
      - RSC redirect: 200 with [Router-Response: redirect], [Router-Registry] and [Cache-Control: private, no-store].
      - [PrefetchRefused]: 204 with [Router-Prefetch-Refused] set to the route's level, [Vary: Accept, Router-Prefetch]
        and [Cache-Control: private, no-store].
      - [ReloadRequired]: 409 with [Router-Response: reload-required] and [Cache-Control: private, no-store]. Every RSC
        reply carries [Vary: Accept, Router-Prefetch]; document replies carry [Vary: Accept]. *)
end

val statusOfError :
  application:('error -> RouterRuntime.Status.t) -> 'error RouterRuntime.Error.t -> RouterRuntime.Status.t

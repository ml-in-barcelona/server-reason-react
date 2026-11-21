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
  type error = QueryTooLong

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

(** Not-found and redirect signals from render code, such as a page or a server component, for a result that only
    rendering can decide.

    A signal takes effect when {!Adapter.serve} or {!Adapter.serveWithContext} renders the response, if it is raised
    before the response starts: while the HTML shell renders (including the synchronous part of a [Suspense] boundary),
    or before the first chunk of a navigation payload. [notFound] then answers like a loader [NotFound]: the route runs
    again with the error [NotFound { reason = RenderNotFound }], so the nearest [~notFound] (or [~error]) boundary
    renders with status 404, and its loaders run a second time. [redirect] answers like a loader redirect. A signal
    raised later, in content that streams after the response started, cannot change the status: it is an error in that
    content, and the nearest [~error] boundary shows in the browser. *)
module Render : sig
  type signal = NotFound | Redirect of RouterRuntime.destination | PermanentRedirect of RouterRuntime.destination

  exception Signal of signal

  val notFound : unit -> 'a
  (** Raises [Signal NotFound]. *)

  val redirect : ?permanent:bool -> RouterRuntime.destination -> 'a
  (** Raises [Signal (Redirect destination)], or [Signal (PermanentRedirect destination)] when [permanent] is true. *)
end

(** A deferred description of route work.

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

  type ('data, 'error) started
  (** A loader that already runs. *)

  val start :
    run:(unit -> ('data, 'error) RouterRuntime.Loader.result Lwt.t) ->
    next:(('data, 'error) started -> ('result, 'error) t) ->
    ('result, 'error) t
  (** Calls [run] when the execution reaches this step and goes on with [next] without waiting for the result. An
      exception from [run] is kept in the result. Pass {!await} as the [run] of a later {!loadWithBoundary} to read the
      result in its place, so ancestors still decide first. A result that is never awaited is dropped. *)

  val await : ('data, 'error) started -> unit -> ('data, 'error) RouterRuntime.Loader.result Lwt.t
  (** The result of a started loader. *)

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
  type ('result, 'error, 'context) t
  type ('result, 'error, 'context) prepared

  val make :
    id:string ->
    path:string ->
    activeRoutes:(string * string list) list ->
    fingerprint:string ->
    decode:(Input.t -> (('result, 'error, 'context) prepared, 'error RouterRuntime.Error.t) result) ->
    ('result, 'error, 'context) t

  val prepared :
    branch:Branch.t -> execution:('context -> ('result, 'error) Execution.t) -> ('result, 'error, 'context) prepared
  (** [execution] is a function so inspecting a candidate branch never starts its loaders. It receives the request
      context given to {!ServerEngine.runWithContext}, or [()]. *)

  val recovered :
    branch:Branch.t ->
    activeRoutes:string list ->
    execution:('context -> ('result, 'error) Execution.t) ->
    ('result, 'error, 'context) prepared
  (** Builds a decode-failure preparation whose response exposes only the listed successfully decoded active routes. *)

  val withPrefetch : ('result, 'error, 'context) t -> RouterRuntime.PrefetchLevel.t -> ('result, 'error, 'context) t
  (** Sets the route's prefetch level. {!make} gives [Intent]. *)

  val prefetch : ('result, 'error, 'context) t -> RouterRuntime.PrefetchLevel.t
  val branch : ('result, 'error, 'context) prepared -> Branch.t
  val execution : ('result, 'error, unit) prepared -> ('result, 'error) Execution.t
  val executionWithContext : ('result, 'error, 'context) prepared -> context:'context -> ('result, 'error) Execution.t
  val route : ('result, 'error, 'context) t -> Route.t
end

module EndpointRegistry : sig
  type ('result, 'error, 'context) t
  type ('result, 'error, 'context) matched

  val make : ('result, 'error, 'context) Endpoint.t list -> (('result, 'error, 'context) t, Registry.error) result
  val makeExn : ('result, 'error, 'context) Endpoint.t list -> ('result, 'error, 'context) t

  val find :
    ('result, 'error, 'context) t -> pathname:string -> (('result, 'error, 'context) matched option, Match.error) result

  val decode :
    ('result, 'error, 'context) matched ->
    search:Search.t ->
    (('result, 'error, 'context) Endpoint.prepared, 'error RouterRuntime.Error.t) result

  val route : ('result, 'error, 'context) matched -> Route.t
  val parameters : ('result, 'error, 'context) matched -> (string * string) list
  val prefetch : ('result, 'error, 'context) matched -> RouterRuntime.PrefetchLevel.t

  val matches :
    ('result, 'error, 'context) matched ->
    ('result, 'error, 'context) Endpoint.prepared ->
    RouterRuntime.Navigation.matched list

  val fingerprint : ('result, 'error, 'context) t -> string
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
    registry:(('view, 'error) Plan.t, 'error, unit) EndpointRegistry.t ->
    basePath:string ->
    trailingSlash:TrailingSlash.t ->
    fallback:(search:Search.t -> error:'error RouterRuntime.Error.t -> ('view, 'error) Plan.t) ->
    applicationStatus:('error -> RouterRuntime.Status.t) ->
    diagnosticId:(exn -> string) ->
    ?revision:(unit -> string) ->
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
      loader's own redirect or failure still wins.

      [revision] names the deployed build in full and patch responses. The client commits it and sends it back as the
      base revision of its next navigation; a patch whose base revision is not the committed one is a full load. The
      default is the constant [""], for an application that does not track deploys. *)

  val runWithContext :
    registry:(('view, 'error) Plan.t, 'error, 'context) EndpointRegistry.t ->
    basePath:string ->
    trailingSlash:TrailingSlash.t ->
    fallback:(context:'context -> search:Search.t -> error:'error RouterRuntime.Error.t -> ('view, 'error) Plan.t) ->
    applicationStatus:('error -> RouterRuntime.Status.t) ->
    diagnosticId:(exn -> string) ->
    ?revision:(unit -> string) ->
    protocolVersion:int ->
    ?prefetch:RouterRuntime.PrefetchLevel.t ->
    ?actionError:'error RouterRuntime.Error.t ->
    context:'context ->
    request ->
    ('view, 'error) outcome Lwt.t
  (** {!run} for a registry with a request context, for example the signed-in session. Every route execution and
      [fallback] receive [context], and generated routes pass it to loaders, [~metadata] and [~headers] as [~context].
  *)
end

(** Configured facade shared by the HTTP adapter and the generated client root. *)
module Server : sig
  type ('view, 'error, 'context) t

  val make :
    basePath:string ->
    registry:(('view, 'error) Plan.t, 'error, unit) EndpointRegistry.t ->
    ?trailingSlash:TrailingSlash.t ->
    fallback:(search:Search.t -> error:'error RouterRuntime.Error.t -> ('view, 'error) Plan.t) ->
    applicationStatus:('error -> RouterRuntime.Status.t) ->
    ?protocolVersion:int ->
    ?interceptLinks:bool ->
    ?viewTransitions:bool ->
    ?pageCacheMaxAge:float ->
    unit ->
    ('view, 'error, unit) t
  (** [trailingSlash] defaults to {!TrailingSlash.Redirect}. [interceptLinks] (default [true]), [viewTransitions]
      (default [false]) and [pageCacheMaxAge] (seconds, the client's default [0.0] when absent) are passed to the client
      [Provider] by {!clientRoot}, {!clientRootWithCache} and the [make] given to {!clientRootWith}. *)

  val makeWithContext :
    basePath:string ->
    registry:(('view, 'error) Plan.t, 'error, 'context) EndpointRegistry.t ->
    ?trailingSlash:TrailingSlash.t ->
    fallback:(context:'context -> search:Search.t -> error:'error RouterRuntime.Error.t -> ('view, 'error) Plan.t) ->
    applicationStatus:('error -> RouterRuntime.Status.t) ->
    ?protocolVersion:int ->
    ?interceptLinks:bool ->
    ?viewTransitions:bool ->
    ?pageCacheMaxAge:float ->
    unit ->
    ('view, 'error, 'context) t
  (** {!make} for a registry with a request context. Run it with {!runWithContext}. *)

  val basePath : ('view, 'error, 'context) t -> string
  val protocolVersion : ('view, 'error, 'context) t -> int
  val fingerprint : ('view, 'error, 'context) t -> string

  val routes : ('view, 'error, 'context) t -> string array
  (** Every concrete route path, optional segments expanded, without the base path, in registry order. The client parses
      each with [RouterPattern.parse] and matches links with [RouterPattern.matchesPath ~basePath], so a base path that
      is not valid route syntax, such as [/a%20b], still works. *)

  val clientRoot :
    (React.element, 'error, 'context) t ->
    initial:RouterRuntime.Navigation.committed ->
    metadata:React.element ->
    children:React.element ->
    React.element
  (** The client root with the client's default page cache (30 pages). *)

  val clientRootWithCache :
    (React.element, 'error, 'context) t ->
    pageCacheCapacity:int ->
    initial:RouterRuntime.Navigation.committed ->
    metadata:React.element ->
    children:React.element ->
    React.element

  val clientRootWith :
    ?pageCacheCapacity:int ->
    (React.element, 'error, 'context) t ->
    make:
      (initial:RouterRuntime.Navigation.committed ->
      protocolVersion:int ->
      registryFingerprint:string ->
      basePath:string ->
      routes:string array ->
      interceptLinks:bool ->
      viewTransitions:bool ->
      pageCacheCapacity:int option ->
      pageCacheMaxAge:float option ->
      metadata:React.element ->
      children:React.element ->
      React.element) ->
    initial:RouterRuntime.Navigation.committed ->
    metadata:React.element ->
    children:React.element ->
    React.element
  (** Builds the client root with a custom [make], for example a client component that renders [RouterReact.Provider]
      with [~onNavigationError]. [make] receives every setting the default client root passes to the [Provider]:
      [interceptLinks] and [viewTransitions] from {!make}, [pageCacheCapacity] as given here, and [pageCacheMaxAge] from
      {!make}. [None] means the [Provider]'s default; pass the option on with [?pageCacheCapacity]. *)
end

(** Server functions run from a page form without JavaScript. *)
module Action : sig
  exception Redirect of RouterRuntime.destination

  val redirect : RouterRuntime.destination -> 'a
  (** Ends a server function with a redirect. After a form post without JavaScript, the adapter answers 303 to
      [destination] instead of to the page. *)
end

(** Request-scoped memoisation, like React's [cache]. *)
module Request : sig
  type 'a key
  (** Names one memoised function. Create it once, at the top level. *)

  val key : unit -> 'a key

  val memo : 'a key -> string -> (unit -> 'a Lwt.t) -> 'a Lwt.t
  (** [memo key argument run] runs [run] once per request for each [key] and [argument], and gives every later call in
      the same request the same promise, also when it failed. [argument] must hold every input of [run], encoded so that
      two different inputs never give the same string. Outside {!scope} it runs [run] each time. *)

  val scope : (unit -> 'a Lwt.t) -> 'a Lwt.t
  (** Runs one request with a new, empty cache. {!memo} calls in [run] and in every [Lwt] callback registered while it
      runs share it. It never joins an enclosing scope, so a scope opened around anything longer than one request does
      not leak entries between requests: every adapter entry point opens its own. {!Adapter.serve},
      {!Adapter.serveWithContext}, {!Adapter.serveFormAction} and {!Adapter.serveFormActionWithContext} keep the cache
      of the request for the whole streamed body, so loaders, [~metadata], [~headers] and server components share it.
      {!Adapter.handle}, {!Adapter.handleWithContext} and the [formActionReply] functions open one for loaders,
      [~metadata] and [~headers] only: server components that {!Adapter.response} streams later do not see it. *)
end

(** Server-agnostic pieces of an HTTP adapter. An adapter parses its request into a {!ServerEngine.request}, calls
    {!run}, passes the outcome to {!reply}, and writes the {!reply} with its own server. Nothing here depends on an HTTP
    server. *)
module Adapter : sig
  val metadata_element : RouterRuntime.Metadata.t -> React.element
  (** Renders resolved metadata as head elements: [<title>], [<meta name="description">], then each entry as a [<meta>]
      or [<link>] in order. Every element has the stable React key ["router:" ^ key]. For a [Link], attributes named
      [rel] or [href] (any case) in [attrs] are ignored: the [rel] and [href] fields win. The result goes in [<head>]
      and is also sent to the client in navigation responses. *)

  val document_element :
    (React.element, 'error, 'context) Server.t ->
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
  (** Decides an HTTP method before {!run}. [allow] lists the methods the adapter serves at the router's paths.
      [OPTIONS] answers 204 and a method outside [allow] answers 405, both with an [Allow] header. [None] means the
      adapter handles the method: [GET] and [HEAD] run the router, and a [HEAD] reply is sent without its body. Methods
      are case-sensitive. *)

  type formAction =
    | Completed
    | Redirected of RouterRuntime.destination  (** The server function called {!Action.redirect}. *)
    | Failed of exn

  val runFormAction :
    lookup:(string -> ReactServerDOM.server_function option) -> Js.FormData.t -> formAction option Lwt.t
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
    (React.element, 'error, unit) Server.t ->
    diagnosticId:(exn -> string) ->
    ?revision:(unit -> string) ->
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
        internal error, through [run ~actionError]. When the page itself redirects, for example a URL with a trailing
        slash, the reply is a 303 to that location: a reply to a [POST] is never 307 or 308, so the browser never posts
        the form again. An unsafe location (see {!redirectLocation}) gives 500 instead of a redirect. *)

  val formActionReplyWithContext :
    (React.element, 'error, 'context) Server.t ->
    diagnosticId:(exn -> string) ->
    ?revision:(unit -> string) ->
    target:string ->
    ?pageCacheCapacity:int ->
    document:(head:React.element -> React.element -> React.element) ->
    context:'context ->
    ServerEngine.request ->
    formAction ->
    reply Lwt.t
  (** {!formActionReply} for a server with a request context. A failed function renders the page through
      {!runWithContext}. *)

  val reply :
    (React.element, 'error, 'context) Server.t ->
    target:string ->
    ?pageCacheCapacity:int ->
    document:(head:React.element -> React.element -> React.element) ->
    kind:ServerEngine.requestKind ->
    (React.element, 'error) ServerEngine.outcome ->
    reply
  (** Maps an outcome to status, headers and body. [target] is the request target, used for [X-Location] on RSC
      redirects. [kind] is the request kind given to {!run}.
      - Full and patch: the resolved status and headers.
      - Document redirect: 303 ([Redirect]) or 308 ([PermanentRedirect]) with [Location].
      - RSC redirect: 200 with [Router-Response: redirect], [Router-Registry] and [Cache-Control: private, no-store].
      - [PrefetchRefused]: 204 with [Router-Prefetch-Refused] set to the route's level, [Vary: Accept, Router-Prefetch]
        and [Cache-Control: private, no-store].
      - [ReloadRequired]: 409 with [Router-Response: reload-required] and [Cache-Control: private, no-store]. Every RSC
        reply carries [Vary: Accept, Router-Prefetch]; document replies carry [Vary: Accept]. *)

  type request = { engine : ServerEngine.request; prefetch : RouterRuntime.PrefetchLevel.t option }

  val parseRequest : target:string -> headers:(string * string) list -> request
  (** Reads an HTTP request. [target] is the request target, path and query, as sent. A fragment is dropped, and an
      empty query (a lone [?]) is no search. The path is not normalised: the engine decodes each segment when it
      matches. Header names match in any letter case. With [Accept: application/react.component] the request is a
      navigation ([Rsc]): its navigation facts come from [Router-Navigation-From], [Router-Registry] and
      [Router-Base-Revision], and [prefetch] from [Router-Prefetch] ([None] for a value that is not a level). Any other
      [Accept] gives a [Document] request without navigation facts or [prefetch]. *)

  val handle :
    (React.element, 'error, unit) Server.t ->
    diagnosticId:(exn -> string) ->
    ?revision:(unit -> string) ->
    ?pageCacheCapacity:int ->
    document:(head:React.element -> React.element -> React.element) ->
    ?allow:string list ->
    method_:string ->
    target:string ->
    headers:(string * string) list ->
    unit ->
    reply Lwt.t
  (** Answers one router request: {!methodReply} with [allow] (default [GET], [HEAD], [OPTIONS]), then {!parseRequest},
      {!run} and {!reply}. A [HEAD] reply has no body. An adapter that serves [POST] at the router's paths, for server
      functions, adds ["POST"] to [allow] and does not send [POST]s here. *)

  val handleWithContext :
    (React.element, 'error, 'context) Server.t ->
    diagnosticId:(exn -> string) ->
    ?revision:(unit -> string) ->
    ?pageCacheCapacity:int ->
    document:(head:React.element -> React.element -> React.element) ->
    ?allow:string list ->
    context:(unit -> 'context) ->
    method_:string ->
    target:string ->
    headers:(string * string) list ->
    unit ->
    reply Lwt.t
  (** {!handle} for a server with a request context. [context] runs once, only when the router runs, so a method that
      {!methodReply} answers builds no context. *)

  type response = {
    status : int;
    headers : (string * string) list;
    body : ((string -> unit Lwt.t) -> unit Lwt.t) option;
  }
  (** A reply ready to write. [body] is [None] for an empty body. Otherwise call it with a function that writes one
      chunk; it resolves after the last chunk. *)

  val response :
    ?env:[ `Dev | `Prod ] ->
    ?timeout:float ->
    ?skipRoot:bool ->
    ?bootstrapModules:string list ->
    ?nonce:string ->
    reply ->
    response
  (** Adds the transport headers and the renderer to a {!reply}. [Html] streams through {!ReactServerDOM.render_html}
      with [skipRoot] (default [false]), [bootstrapModules] and [nonce], with [Content-Type: text/html; charset=utf-8].
      [Model] streams through {!ReactServerDOM.render_model_value} with [Content-Type: application/react.component],
      [X-Content-Type-Options: nosniff] and [X-Location] set to its [location]. [env] and [timeout] go to the renderer.
      These headers replace a header of the same name in the reply. *)

  val serve :
    (React.element, 'error, unit) Server.t ->
    diagnosticId:(exn -> string) ->
    ?revision:(unit -> string) ->
    ?pageCacheCapacity:int ->
    document:(head:React.element -> React.element -> React.element) ->
    ?allow:string list ->
    ?env:[ `Dev | `Prod ] ->
    ?timeout:float ->
    ?skipRoot:bool ->
    ?bootstrapModules:string list ->
    ?nonce:string ->
    method_:string ->
    target:string ->
    headers:(string * string) list ->
    unit ->
    response Lwt.t
  (** {!handle} and {!response} in one step, with {!Render} signals. It renders the HTML shell, or the first chunk of a
      navigation payload, before it returns, so a signal raised by then changes the response: [Render.notFound] runs the
      route again with its not-found boundary and status 404, and [Render.redirect] answers as a loader redirect. A
      signal while the not-found boundary renders answers 500. [HEAD] runs the router without rendering. Another
      exception while the HTML shell renders runs the route again with [Internal { diagnosticId }], so its nearest
      [~error] boundary renders with status 500; an exception there propagates. *)

  val serveWithContext :
    (React.element, 'error, 'context) Server.t ->
    diagnosticId:(exn -> string) ->
    ?revision:(unit -> string) ->
    ?pageCacheCapacity:int ->
    document:(head:React.element -> React.element -> React.element) ->
    ?allow:string list ->
    ?env:[ `Dev | `Prod ] ->
    ?timeout:float ->
    ?skipRoot:bool ->
    ?bootstrapModules:string list ->
    ?nonce:string ->
    context:(unit -> 'context) ->
    method_:string ->
    target:string ->
    headers:(string * string) list ->
    unit ->
    response Lwt.t
  (** {!serve} for a server with a request context. [context] runs once per request that runs the router. *)

  val serveFormAction :
    (React.element, 'error, unit) Server.t ->
    diagnosticId:(exn -> string) ->
    ?revision:(unit -> string) ->
    target:string ->
    ?pageCacheCapacity:int ->
    document:(head:React.element -> React.element -> React.element) ->
    ?env:[ `Dev | `Prod ] ->
    ?timeout:float ->
    ?skipRoot:bool ->
    ?bootstrapModules:string list ->
    ?nonce:string ->
    ServerEngine.request ->
    formAction ->
    response Lwt.t
  (** {!formActionReply} and {!response} in one step, with {!Render} signals as in {!serve}. When the page that renders
      after a failed function signals not found, it renders with its not-found boundary and status 404; a redirect
      signal answers 303, never 307 or 308. *)

  val serveFormActionWithContext :
    (React.element, 'error, 'context) Server.t ->
    diagnosticId:(exn -> string) ->
    ?revision:(unit -> string) ->
    target:string ->
    ?pageCacheCapacity:int ->
    document:(head:React.element -> React.element -> React.element) ->
    ?env:[ `Dev | `Prod ] ->
    ?timeout:float ->
    ?skipRoot:bool ->
    ?bootstrapModules:string list ->
    ?nonce:string ->
    context:'context ->
    ServerEngine.request ->
    formAction ->
    response Lwt.t
  (** {!serveFormAction} for a server with a request context. *)
end

val run :
  ('view, 'error, unit) Server.t ->
  diagnosticId:(exn -> string) ->
  ?revision:(unit -> string) ->
  ?prefetch:RouterRuntime.PrefetchLevel.t ->
  ?actionError:'error RouterRuntime.Error.t ->
  ServerEngine.request ->
  ('view, 'error) ServerEngine.outcome Lwt.t
(** Runs {!ServerEngine.run} with the configuration of [server]. [revision] defaults to the constant [""] (see
    {!ServerEngine.run}). *)

val runWithContext :
  ('view, 'error, 'context) Server.t ->
  diagnosticId:(exn -> string) ->
  ?revision:(unit -> string) ->
  ?prefetch:RouterRuntime.PrefetchLevel.t ->
  ?actionError:'error RouterRuntime.Error.t ->
  context:'context ->
  ServerEngine.request ->
  ('view, 'error) ServerEngine.outcome Lwt.t
(** {!run} for a server made from a manifest that declares [~context]: loaders, [~metadata] and [~headers] receive
    [context]. *)

val statusOfError :
  application:('error -> RouterRuntime.Status.t) -> 'error RouterRuntime.Error.t -> RouterRuntime.Status.t

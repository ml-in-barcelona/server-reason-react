(** The server side of the router: signals for render code and server functions, request-scoped memoisation, and the
    pieces of an HTTP adapter. [DreamRouter] is built on them; an adapter for another HTTP server parses its request
    with {!parseRequest}, answers it with {!serve}, and writes the {!response}.

    Every entry point takes [~context], the request context that loaders, [~metadata] and [~headers] receive: a value
    for {!run}, {!formActionReply} and {!serveFormAction}, and a function for {!handle} and {!serve}, which build it
    inside the request's {!requestScope}. Pass [~context:()] or [~context:(fun () -> ())] for a manifest without
    [~context]. *)

type ('view, 'error, 'context) t = ('view, 'error, 'context) RouterEngine.Server.t
(** A router server, made by the generated [RouterRegistry.server]. *)

(** {1 Render code and server functions} *)

type signal = NotFound | Redirect of RouterRuntime.destination | PermanentRedirect of RouterRuntime.destination

exception Signal of signal

val notFound : unit -> 'a
(** Raises [Signal NotFound] from a page or a server component, for a result that only rendering can decide.

    The signal takes effect when {!serve} renders the response, if it is raised before the response starts: while the
    HTML shell renders (including the synchronous part of a [Suspense] boundary), or before the first chunk of a
    navigation payload. The route then runs again with the error [NotFound { reason = RenderNotFound }], so the nearest
    [~notFound] (or [~error]) boundary renders with status 404, and its loaders run a second time. A signal raised
    later, in content that streams after the response started, cannot change the status: it is an error in that content,
    and the nearest [~error] boundary shows in the browser. *)

val redirect : ?permanent:bool -> RouterRuntime.destination -> 'a
(** Raises [Signal (Redirect destination)], or [Signal (PermanentRedirect destination)] when [permanent] is true.

    In render code it answers like a loader redirect, with the same timing as {!notFound}. In a server function it ends
    the function: after a form post without JavaScript the adapter answers 303 to [destination] instead of to the page,
    and a call from JavaScript answers with a [null] result and the {!actionRedirectHeader}. A server function's code
    called directly from a server component during {!serve} is render code, so its redirect redirects the page. *)

(** {1 Request-scoped memoisation} *)

type 'a memoKey
(** Names one memoised function. Create it once, at the top level. *)

val memoKey : unit -> 'a memoKey

val memo : 'a memoKey -> string -> (unit -> 'a Lwt.t) -> 'a Lwt.t
(** [memo key argument run] runs [run] once per request for each [key] and [argument], like React's [cache], and gives
    every later call in the same request the same promise, also when it failed. [argument] must hold every input of
    [run], encoded so that two different inputs never give the same string. Outside {!requestScope} it runs [run] each
    time. *)

val requestScope : (unit -> 'a Lwt.t) -> 'a Lwt.t
(** Runs one request with a new, empty {!memo} cache, shared by [run] and every [Lwt] callback registered while it runs.
    It never joins an enclosing scope, so a scope opened around anything longer than one request does not leak entries
    between requests: every entry point below opens its own. {!serve} and {!serveFormAction} keep the cache of the
    request for the whole streamed body, so loaders, [~metadata], [~headers] and server components share it. {!handle}
    and {!formActionReply} open one for loaders, [~metadata] and [~headers] only: server components that {!response}
    streams later do not see it. *)

(** {1 Requests} *)

type request = { engine : RouterEngine.ServerEngine.request; prefetch : RouterRuntime.PrefetchLevel.t option }

val parseRequest : target:string -> headers:(string * string) list -> request
(** Reads an HTTP request. [target] is the request target, path and query, as sent. A fragment is dropped, and an empty
    query (a lone [?]) is no search. The path is not normalised: the engine decodes each segment when it matches. Header
    names match in any letter case. With [Accept: application/react.component] the request is a navigation: its
    navigation facts come from [Router-Navigation-From], [Router-Registry] and [Router-Base-Revision], and [prefetch]
    from [Router-Prefetch] ([None] for a value that is not a level). Any other [Accept] gives a document request without
    navigation facts or [prefetch]. *)

type ('view, 'error) outcome = ('view, 'error) RouterEngine.ServerEngine.outcome

val run :
  ('view, 'error, 'context) t ->
  diagnosticId:(exn -> string) ->
  ?revision:(unit -> string) ->
  ?actionError:'error RouterRuntime.Error.t ->
  context:'context ->
  request ->
  ('view, 'error) outcome Lwt.t
(** Matches the request, runs its loaders and resolves the outcome. A prefetch more eager than the matched route's level
    is refused before any loader runs. [actionError] renders the page as failed with that error after its loaders ran.
    [revision] names the deployed build; the default is the constant [""], for an application that does not track
    deploys. *)

(** {1 Replies} *)

type body =
  | Empty
  | Html of React.element  (** An HTML document. Render it with the server's bootstrap modules. *)
  | Model of { location : string; model : React.model_value }
      (** A navigation response. [location] is the value for the [X-Location] header. *)

type reply = { status : int; headers : (string * string) list; body : body }
(** [headers] holds every protocol header for the outcome, including [Content-Type] for [Html] and [Model] and
    [Location] for redirects. The adapter adds nothing but transport details. *)

type makeClientRoot =
  initial:RouterRuntime.Navigation.committed ->
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
  React.element
(** Makes a custom client root, for {!clientRootWith} and the [clientRoot] argument of {!reply}, {!handle}, {!serve},
    {!formActionReply} and {!serveFormAction}. It receives every setting the default client root passes to
    [RouterReact.Provider]; [None] means the [Provider]'s default, so pass the option on with [?pageCacheCapacity]. In a
    document from {!reply}, [children] is the routed page inside its location scope and root error boundary, as the
    default root gets it. *)

val reply :
  (React.element, 'error, 'context) t ->
  target:string ->
  ?pageCacheCapacity:int ->
  ?clientRoot:makeClientRoot ->
  document:(head:React.element -> React.element -> React.element) ->
  kind:RouterEngine.ServerEngine.requestKind ->
  (React.element, 'error) outcome ->
  reply
(** Maps an outcome to status, headers and body. [target] is the request target, used for [X-Location] on navigation
    redirects. [kind] is the kind of the request given to {!run}. A document is [document] around the client root: the
    default one ({!clientRoot}), or the one [clientRoot] makes (see {!clientRootWith}), for an application whose client
    bundle registers its own root component.
    - Full and patch: the resolved status and headers.
    - Document redirect: 303 ([Redirect]) or 308 ([PermanentRedirect]) with [Location].
    - Navigation redirect: 200 with [Router-Response: redirect], [Router-Registry] and
      [Cache-Control: private, no-store].
    - Refused prefetch: 204 with [Router-Prefetch-Refused] set to the route's level, [Vary: Accept, Router-Prefetch] and
      [Cache-Control: private, no-store].
    - Reload required: 409 with [Router-Response: reload-required] and [Cache-Control: private, no-store]. Every
      navigation reply carries [Vary: Accept, Router-Prefetch]; document replies carry [Vary: Accept]. *)

val methodReply : allow:string list -> string -> reply option
(** Decides an HTTP method before {!run}. [allow] lists the methods the adapter serves at the router's paths. [OPTIONS]
    answers 204 and a method outside [allow] answers 405, both with an [Allow] header. [None] means the adapter handles
    the method: [GET] and [HEAD] run the router, and a [HEAD] reply is sent without its body. Methods are
    case-sensitive. *)

val handle :
  (React.element, 'error, 'context) t ->
  diagnosticId:(exn -> string) ->
  ?revision:(unit -> string) ->
  ?pageCacheCapacity:int ->
  ?clientRoot:makeClientRoot ->
  document:(head:React.element -> React.element -> React.element) ->
  ?allow:string list ->
  context:(unit -> 'context) ->
  method_:string ->
  target:string ->
  headers:(string * string) list ->
  unit ->
  reply Lwt.t
(** Answers one router request: {!methodReply} with [allow] (default [GET], [HEAD], [OPTIONS]), then {!parseRequest},
    {!run} and {!reply}. A [HEAD] reply has no body. An adapter that serves [POST] at the router's paths, for server
    functions, adds ["POST"] to [allow] and does not send [POST]s here. [context] runs once, inside the request's
    {!requestScope} and only when the router runs, so a method that {!methodReply} answers builds no context and {!memo}
    calls in [context] share the request's cache; pass [fun () -> ()] for a manifest without [~context]. *)

type response = { status : int; headers : (string * string) list; body : ((string -> unit Lwt.t) -> unit Lwt.t) option }
(** A reply ready to write. [body] is [None] for an empty body. Otherwise call it with a function that writes one chunk;
    it resolves after the last chunk. *)

val response :
  ?env:[ `Dev | `Prod ] ->
  ?timeout:float ->
  ?skipRoot:bool ->
  ?bootstrapModules:string list ->
  ?nonce:string ->
  reply ->
  response
(** Adds the transport headers and the renderer to a {!reply}. [Html] streams through {!ReactServerDOM.render_html} with
    [skipRoot] (default [false]), [bootstrapModules] and [nonce], with [Content-Type: text/html; charset=utf-8]. [Model]
    streams through {!ReactServerDOM.render_model_value} with [Content-Type: application/react.component],
    [X-Content-Type-Options: nosniff] and [X-Location] set to its [location]. [env] and [timeout] go to the renderer.
    These headers replace a header of the same name in the reply. *)

val serve :
  (React.element, 'error, 'context) t ->
  diagnosticId:(exn -> string) ->
  ?revision:(unit -> string) ->
  ?pageCacheCapacity:int ->
  ?clientRoot:makeClientRoot ->
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
(** {!handle} and {!response} in one step, with {!notFound} and {!redirect} signals. [context] is built as in {!handle}.
    It renders the HTML shell, or the first chunk of a navigation payload, before it returns, so a signal raised by then
    changes the response. A signal while the not-found boundary renders answers 500. [HEAD] runs the router without
    rendering. Another exception while the HTML shell renders runs the route again with [Internal { diagnosticId }], so
    its nearest [~error] boundary renders with status 500; an exception there propagates. *)

(** {1 Forms posted without JavaScript} *)

type formAction =
  | Completed
  | Redirected of RouterRuntime.destination  (** The server function called {!redirect}. *)
  | Failed of exn

val runFormAction : lookup:(string -> ReactServerDOM.server_function option) -> Js.FormData.t -> formAction option Lwt.t
(** Runs the server function named by the [$ACTION_ID_<id>] field of a form posted without JavaScript, with the rest of
    the form. [None] when the form names no registered server function. Fatal exceptions are re-raised. The server
    function's result is not used: a page without JavaScript cannot show it. *)

val formActionReply :
  (React.element, 'error, 'context) t ->
  diagnosticId:(exn -> string) ->
  ?revision:(unit -> string) ->
  target:string ->
  ?pageCacheCapacity:int ->
  ?clientRoot:makeClientRoot ->
  document:(head:React.element -> React.element -> React.element) ->
  context:'context ->
  request ->
  formAction ->
  reply Lwt.t
(** The reply to a page form posted without JavaScript, so a reload does not post again:
    - [Completed]: 303 to [target], the posted URL.
    - [Redirected destination]: 303 to [destination].
    - [Failed]: the page at [request], rendered as a document with its nearest error boundary and the status of an
      internal error, through [run ~actionError]. When the page itself redirects, for example a URL with a trailing
      slash, the reply is a 303 to that location: a reply to a [POST] is never 307 or 308, so the browser never posts
      the form again. An unsafe location (see {!redirectLocation}) gives 500 instead of a redirect. *)

val serveFormAction :
  (React.element, 'error, 'context) t ->
  diagnosticId:(exn -> string) ->
  ?revision:(unit -> string) ->
  target:string ->
  ?pageCacheCapacity:int ->
  ?clientRoot:makeClientRoot ->
  document:(head:React.element -> React.element -> React.element) ->
  ?env:[ `Dev | `Prod ] ->
  ?timeout:float ->
  ?skipRoot:bool ->
  ?bootstrapModules:string list ->
  ?nonce:string ->
  context:'context ->
  request ->
  formAction ->
  response Lwt.t
(** {!formActionReply} and {!response} in one step, with signals as in {!serve}. When the page that renders after a
    failed function signals not found, it renders with its not-found boundary and status 404; a redirect signal answers
    303, never 307 or 308. *)

val redirectLocation : RouterRuntime.destination -> string option
(** The [Location] for a redirect to [destination]: its href when it is a path that starts with a single ["/"] (not
    ["//"] or a slash followed by a backslash) or an absolute [http:] or [https:] URL, without control characters.
    [None] otherwise, for example [javascript:] or [//host]. Every redirect the router sends goes through it: {!reply}
    answers an unsafe redirect outcome with 500, the engine turns an unsafe loader or route redirect into an internal
    error, and an unsafe {!redirect} from a server function fails it. *)

val actionRedirectHeader : RouterRuntime.destination -> (string * string) option
(** [Some ("Router-Redirect", location)] for a safe destination (see {!redirectLocation}). A server function called from
    JavaScript that ends with {!redirect} gets a normal action response with a [null] result and this header; the client
    then navigates to the location with a push. The adapter must wait for the function before it sends the headers, and
    must treat [None] as a failed function. *)

(** {1 Server settings} *)

val basePath : ('view, 'error, 'context) t -> string

val clientRoot :
  ?pageCacheCapacity:int ->
  (React.element, 'error, 'context) t ->
  initial:RouterRuntime.Navigation.committed ->
  metadata:React.element ->
  children:React.element ->
  React.element
(** The default client root. Without [pageCacheCapacity] the client's default page cache (30 pages) applies; [0] turns
    it off. *)

val clientRootWith :
  ?pageCacheCapacity:int ->
  (React.element, 'error, 'context) t ->
  make:makeClientRoot ->
  initial:RouterRuntime.Navigation.committed ->
  metadata:React.element ->
  children:React.element ->
  React.element
(** Builds the client root with a custom [make] (see {!makeClientRoot}), for example a client component that renders
    [RouterReact.Provider] with [~onNavigationError]. *)

val metadataElement : RouterRuntime.Metadata.t -> React.element
(** Renders resolved metadata as head elements: [<title>], [<meta name="description">], then each entry as a [<meta>] or
    [<link>] in order. Every element has the stable React key ["router:" ^ key]. For a [Link], attributes named [rel] or
    [href] (any case) in [attrs] are ignored. *)

val statusOfError :
  application:('error -> RouterRuntime.Status.t) -> 'error RouterRuntime.Error.t -> RouterRuntime.Status.t
(** The HTTP status of a route error: 404 for not found, 400 for an invalid path or search parameter, 500 for an
    internal error, and [application] for an application error. *)

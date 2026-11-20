(** Dream integration for React Server Components.

    Provides request context (cookies, headers) accessible from server components and server functions via ambient
    {!Lwt.key} storage, plus streaming helpers for RSC rendering and action dispatch. *)

(** {1 Request data} *)

val request : unit -> Dream.request option
(** The request being handled. [routes], [createFromRequest] and [streamFunctionResponse] hold it for the whole
    response, including streaming, so route loaders, [~metadata], [~headers], server components and server functions
    read their own request after any [Lwt] wait, also when requests run concurrently. [None] outside a request. *)

val get_header : string -> string option
(** Read a request header from the ambient request.

    Available in server components and server functions. Raises outside a request context.

    @param name case-insensitive header name *)

val get_cookie : ?decrypt:bool -> string -> string option
(** Read a cookie from the ambient request.

    Available in server components and server functions. Raises outside a request context.

    @param decrypt whether to decrypt the cookie value (default: false)
    @param name cookie name *)

val set_cookie :
  ?expires:float ->
  ?max_age:float ->
  ?domain:string ->
  ?path:string ->
  ?secure:bool ->
  ?http_only:bool ->
  ?same_site:[ `Strict | `Lax | `None ] ->
  string ->
  string ->
  unit
(** Queue a [Set-Cookie] header on the server-function response.

    Raises during render or outside an action context.

    @param expires absolute expiration time in Unix seconds
    @param max_age lifetime in seconds
    @param domain cookie domain
    @param path request path on which the cookie is available
    @param secure whether the cookie requires HTTPS
    @param http_only whether browser scripts are denied access
    @param same_site cross-site request policy
    @param name cookie name
    @param value cookie value *)

(** {1 Streaming} *)

val createFromRequest :
  ?debug:bool ->
  ?disableSSR:bool ->
  ?layout:(React.element -> React.element) ->
  ?bootstrapModules:string list ->
  ?bootstrapScripts:string list ->
  ?bootstrapScriptContent:string ->
  React.element ->
  Dream.request ->
  Dream.response Lwt.t
(** Render a React element as a full HTML page or RSC model stream, depending on the request's [Accept] header.

    Installs a render-phase request context: [get_header] and [get_cookie] are available, while [set_cookie] raises.

    @param debug enable RSC and HTML stream logging (default: false)
    @param disableSSR stream only the document shell before client rendering (default: false)
    @param layout wrap the supplied element in a document or application shell
    @param bootstrapModules JavaScript modules loaded by the HTML response
    @param bootstrapScripts classic JavaScript files loaded by the HTML response
    @param bootstrapScriptContent inline bootstrap JavaScript
    @param element React tree to render
    @param request current Dream request *)

val streamFunctionResponse :
  ?debug:bool ->
  ?timeout:float ->
  lookup:(string -> ReactServerDOM.server_function option) ->
  Dream.request ->
  Dream.response Lwt.t
(** Handle a server function POST request.

    Installs an action-phase request context in which [get_header], [get_cookie], and [set_cookie] are available.
    Pending cookies are serialized as [Set-Cookie] response headers. If the action raises, pending cookies are
    discarded. If it calls {!RouterServer.Action.redirect}, the response keeps its cookies, carries
    [Router-Redirect: <href>] and the result [null].

    @param debug enable action-response logging (default: false)
    @param timeout maximum action execution and response streaming time in seconds (default: 30)
    @param lookup maps an action ID to a registered {!ReactServerDOM.server_function}
    @param request current Dream request *)

val routes :
  server:(React.element, 'error, unit) RouterServer.Server.t ->
  actionHandler:(Dream.request -> Dream.response Lwt.t) ->
  ?lookup:(string -> ReactServerDOM.server_function option) ->
  ?diagnosticId:(exn -> string) ->
  ?revision:(unit -> string) ->
  ?ssr:(Dream.request -> bool) ->
  ?bootstrapModules:string list ->
  ?pageCacheCapacity:int ->
  document:(head:React.element -> React.element -> React.element) ->
  unit ->
  Dream.route list
(** Register document, RSC, and server-function routes for a generated router.

    [GET] and [HEAD] run the router; a [HEAD] response has the same status and headers and no body. [POST] goes to
    [actionHandler] behind {!Dream.origin_referrer_check}: a [POST] whose [Origin] (or [Referer]) does not match [Host]
    answers 400. An RSC request with [Router-Prefetch: <level>] is a prefetch at that level (see
    {!RouterServer.ServerEngine.run}); a value that is not a level is ignored. [OPTIONS] answers 204 and any other
    method answers 405, both with [Allow: GET, HEAD, OPTIONS, POST].

    @param server generated router server
    @param actionHandler server-function POST handler
    @param lookup
      maps an action ID to a registered {!ReactServerDOM.server_function}. With it, a page form posted without
      JavaScript (multipart, no [ACTION_ID] header) runs its server function here and answers 303 to the page, 303 to
      the destination given to {!RouterServer.Action.redirect}, or the page rendered with its nearest error boundary
      when the function fails (see {!RouterServer.Adapter.formActionReply}). Cookies set by a failed function are
      dropped. Other [POST]s go to [actionHandler]. Without it, every [POST] goes to [actionHandler]
    @param diagnosticId
      produce a safe identifier for an internal exception (default: 12 random bytes from {!Dream.random}, base64url)
    @param revision produce the revision attached to a successful response (default: as [diagnosticId])
    @param ssr
      decide whether to include the routed root markup in each document response (default: always true). An empty hidden
      [div#ssr-query-param] marker renders next to the root markup, so the bootstrap module can check the DOM for it:
      present means mount with [ReactDOM.Client.hydrateRoot], absent means [ReactDOM.Client.createRoot]
    @param bootstrapModules JavaScript modules loaded by document responses
    @param pageCacheCapacity
      maximum visited pages cached by the client router (default: the client's 30; 0 turns it off)
    @param document build the HTML document. [~head] is the resolved metadata, to place inside [<head>]. *)

val routesWithContext :
  server:(React.element, 'error, 'context) RouterServer.Server.t ->
  context:(Dream.request -> 'context) ->
  actionHandler:(Dream.request -> Dream.response Lwt.t) ->
  ?lookup:(string -> ReactServerDOM.server_function option) ->
  ?diagnosticId:(exn -> string) ->
  ?revision:(unit -> string) ->
  ?ssr:(Dream.request -> bool) ->
  ?bootstrapModules:string list ->
  ?pageCacheCapacity:int ->
  document:(head:React.element -> React.element -> React.element) ->
  unit ->
  Dream.route list
(** {!routes} for a router whose manifest declares [~context]. [context] builds the request context once per routed
    request, inside the request context of {!request}. Loaders, [~metadata] and [~headers] receive it as [~context]. *)

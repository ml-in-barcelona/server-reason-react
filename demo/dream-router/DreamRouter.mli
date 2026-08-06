(** Dream integration for React Server Components.

    Provides request context (cookies, headers) accessible from server components and server functions via ambient
    {!Lwt.key} storage, plus streaming helpers for RSC rendering and action dispatch. *)

(** {1 Request data} *)

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
  ?debug:bool -> lookup:(string -> ReactServerDOM.server_function option) -> Dream.request -> Dream.response Lwt.t
(** Handle a server function POST request.

    Installs an action-phase request context in which [get_header], [get_cookie], and [set_cookie] are available.
    Pending cookies are serialized as [Set-Cookie] response headers. If the action raises, pending cookies are
    discarded.

    @param debug enable action-response logging (default: false)
    @param lookup maps an action ID to a registered {!ReactServerDOM.server_function}
    @param request current Dream request *)

val handler :
  registry:((React.element, 'error) RouterServer.Plan.t, 'error) RouterServer.EndpointRegistry.t ->
  basePath:string ->
  fallback:
    (search:RouterServer.Search.t -> error:'error RouterRuntime.Error.t -> (React.element, 'error) RouterServer.Plan.t) ->
  applicationStatus:('error -> RouterRuntime.Status.t) ->
  diagnosticId:(exn -> string) ->
  revision:(unit -> string) ->
  protocolVersion:int ->
  ?bootstrapModules:string list ->
  document:(React.element -> React.element) ->
  Dream.request ->
  Dream.response Lwt.t
(** Handle document and RSC requests for a generated router registry.

    @param registry generated endpoint registry
    @param basePath URL path under which the router is mounted
    @param fallback build the plan used for unmatched routes and decode errors
    @param applicationStatus map application errors to HTTP statuses
    @param diagnosticId produce a safe identifier for an internal exception
    @param revision produce the revision attached to a successful response
    @param protocolVersion router wire-protocol version
    @param bootstrapModules JavaScript modules loaded by document responses
    @param document wrap the routed client root in the HTML document tree
    @param request current Dream request *)

val routes :
  basePath:string ->
  actionHandler:(Dream.request -> Dream.response Lwt.t) ->
  (Dream.request -> Dream.response Lwt.t) ->
  Dream.route list
(** Register GET and server-function POST routes for a router mount.

    @param basePath URL path under which the router is mounted
    @param actionHandler server-function POST handler
    @param handler document and RSC request handler *)

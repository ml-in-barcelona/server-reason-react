/** Dream integration for React Server Components.

    Provides request context (cookies, headers) accessible from server
    components and server functions via ambient [Lwt.key] storage,
    plus streaming helpers for RSC rendering and action dispatch. */;

module RequestContext: {
  /** {2 Reading request data}

      These functions are available in both server components (render phase)
      and server functions (action phase). They raise if called outside
      a request context. */;

  /** Returns the current [Dream.request]. Raises if no request context. */
  let get_request: unit => Dream.request;

  /** Read a request header by name. */
  let get_header: string => option(string);

  /** Read a cookie from the request.
      @param decrypt whether to decrypt the cookie value (default: false) */
  let get_cookie: (~decrypt: bool=?, string) => option(string);

  /** {2 Writing cookies}

      Only available during the action phase (server functions).
      Raises during render or outside a request context. */;

  /** Queue a [Set-Cookie] header on the action response.

      Raises during render (matching Next.js [ReadonlyRequestCookiesError]). */
  let set_cookie:
    (
      ~expires: float=?,
      ~max_age: float=?,
      ~domain: string=?,
      ~path: string=?,
      ~secure: bool=?,
      ~http_only: bool=?,
      ~same_site:
        [
          | `Strict
          | `Lax
          | `None
        ]
          =?,
      string,
      string
    ) =>
    unit;
};

/** {1 Streaming} */;

/** Render a React element as a full HTML page or RSC model stream,
    depending on the request's [Accept] header.

    Installs a render-phase request context: [RequestContext.get_*] is
    available, [RequestContext.set_cookie] raises. */
let createFromRequest:
  (
    ~debug: bool=?,
    ~disableSSR: bool=?,
    ~layout: React.element => React.element=?,
    ~bootstrapModules: list(string)=?,
    ~bootstrapScripts: list(string)=?,
    ~bootstrapScriptContent: string=?,
    React.element,
    Dream.request
  ) =>
  Lwt.t(Dream.response);

/** Handle a server function POST request.

    Installs an action-phase request context: both [RequestContext.get_*]
    and [RequestContext.set_cookie] are available. Pending cookies are
    serialized as [Set-Cookie] response headers. If the action raises,
    pending cookies are discarded.

    @param lookup maps an action ID to a registered [ReactServerDOM.server_function]
    @param debug  enable debug logging (default: false) */
let streamFunctionResponse:
  (
    ~debug: bool=?,
    ~lookup: string => option(ReactServerDOM.server_function),
    Dream.request
  ) =>
  Lwt.t(Dream.response);

/** Stream a [React.model_value] as an RSC model response. */
let stream_model_value:
  (~debug: bool=?, ~location: string, React.model_value) =>
  Lwt.t(Dream.response);

/** Stream a [React.element] as an RSC model response. */
let stream_model:
  (~debug: bool=?, ~location: string, React.element) => Lwt.t(Dream.response);

/** Stream a [React.element] as an HTML response with optional
    bootstrap scripts for client hydration. */
let stream_html:
  (
    ~debug: bool=?,
    ~skipRoot: bool=?,
    ~bootstrapScriptContent: string=?,
    ~bootstrapScripts: list(string)=?,
    ~bootstrapModules: list(string)=?,
    React.element
  ) =>
  Lwt.t(Dream.response);

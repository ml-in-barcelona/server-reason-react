module type MAIN_LAYOUT = {
  [@react.component]
  let make: (~children: React.element, unit) => React.element;
};

module type MAIN_PAGE = {
  [@react.component]
  let make: (~query: URL.SearchParams.t, unit) => React.element;
};

module type LAYOUT = {
  [@react.component]
  let make:
    (~children: React.element, ~params: PathParams.t, unit) => React.element;
};

module type PAGE = {
  [@react.component]
  let make:
    (~params: PathParams.t, ~query: URL.SearchParams.t, unit) => React.element;
};

module type NOT_FOUND = {
  [@react.component]
  let make: (~path: string, unit) => React.element;
};

module type LOADING = {
  [@react.component]
  let make: unit => React.element;
};

type routeConfig;
type t;

let route:
  (
    ~path: string,
    ~layout: (module LAYOUT)=?,
    ~page: (module PAGE)=?,
    ~loading: (module LOADING)=?,
    list(routeConfig),
    unit
  ) =>
  routeConfig;

let make:
  (
    ~layout: (module MAIN_LAYOUT)=?,
    ~page: (module MAIN_PAGE),
    ~notFound: (module NOT_FOUND)=?,
    ~loading: (module LOADING)=?,
    list(routeConfig)
  ) =>
  t;

let getRoute:
  (
    ~initialPathParams: PathParams.t=?,
    ~globalLoading: option(module LOADING)=?,
    ~definition: string,
    ~request: Dream.request,
    list(routeConfig)
  ) =>
  option(React.element);

let getSubRoute:
  (
    ~request: Dream.request,
    ~parentDefinition: string,
    ~subRouteDefinition: string,
    ~globalLoading: option(module LOADING)=?,
    list(routeConfig)
  ) =>
  option(React.element);

let generated_routes_paths: (~routes: list(routeConfig)) => list(string);

/** Deterministic identity of the route registry, echoed by clients in the
    SRR-Registry header. A mismatch yields a reload-required response. */
let registryFingerprint:
  (~basePath: string, ~routes: list(routeConfig)) => string;

/** Match a concrete path (relative to the mount) against route definitions.
    First match in generation order wins. */
let matchDefinition: (~definitions: list(string), string) => option(string);

/** Split the target branch at the last level shared with the committed
    branch. Shared requires definition and concrete segment equality.
    Returns (parentRouteDefinition, subRouteDefinition), or None when the
    caller should answer with a full model. */
let sharedPrefixSplit:
  (
    ~fromDefinition: string,
    ~fromPath: string,
    ~targetDefinition: string,
    ~targetPath: string
  ) =>
  option((string, string));

let buildUrlFromRequest: Dream.request => URL.t;

let routeDefinitionsHandlers:
  (
    ~bootstrapModules: list(string),
    ~document: (~children: React.element) => React.element,
    ~routeDefinitions: t,
    string,
    (string, Dream.handler) => Dream.route
  ) =>
  list(Dream.route);

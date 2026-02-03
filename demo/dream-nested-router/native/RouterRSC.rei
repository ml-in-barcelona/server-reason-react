module type MAIN_LAYOUT = {
  let make: (~key: string=?, ~children: React.element, unit) => React.element;
};

module type MAIN_PAGE = {
  let make:
    (~key: string=?, ~query: URL.SearchParams.t, unit) => React.element;
};

module type LAYOUT = {
  let make:
    (
      ~key: string=?,
      ~children: React.element,
      ~params: DynamicParams.t,
      unit
    ) =>
    React.element;
};

module type PAGE = {
  let make:
    (
      ~key: string=?,
      ~params: DynamicParams.t,
      ~query: URL.SearchParams.t,
      unit
    ) =>
    React.element;
};

module type NOT_FOUND = {
  let make: (~key: string=?, ~path: string, unit) => React.element;
};

module type LOADING = {
  let make: (~key: string=?, unit) => React.element;
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
    ~initialDynamicParams: DynamicParams.t=?,
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

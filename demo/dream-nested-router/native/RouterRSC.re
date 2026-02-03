/**
* RouterRSC is a module that provides the helpers to build the route and the layout component from the route definitions.
*/
module type MAIN_LAYOUT = {
  let make: (~key: string=?, ~children: React.element, unit) => React.element;
};

module type MAIN_PAGE = {
  let make:
    (~key: string=?, ~query: URL.SearchParams.t, unit) => React.element;
};

/**
 * A layout is the UI that is shared between multiple pages.
 * On navigation, layouts preserve state, remain interactive, and do not rerender.
 * Why there is no queryParams in the layout?
 * As it does not rerender on navigation, it cannot access search params which would otherwise become stale.
 */
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

/**
 * A page is the UI that is rendered on a specific route.
 */
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

type routeConfig = {
  path: string,
  layout: option(module LAYOUT),
  page: option(module PAGE),
  loading: option(module LOADING),
  /**
   * children is a list of routes that are nested within the current route.
   * It is used to render a specific UI within a parent route layout.
   * A sub-route "takes" the parent page place in the layout.
   */
  children: list(routeConfig),
};

type t = {
  layout: option(module MAIN_LAYOUT),
  page: (module MAIN_PAGE),
  notFound: option(module NOT_FOUND),
  loading: option(module LOADING),
  routes: list(routeConfig),
};

let route = (~path, ~layout=?, ~page=?, ~loading=?, children, ()) => {
  path,
  layout,
  page,
  loading,
  children,
};

let make = (~layout=?, ~page, ~notFound=?, ~loading=?, routes) => {
  layout,
  page,
  notFound,
  loading,
  routes,
};

let extractDynamicParam = (request, segment) => {
  String.starts_with(segment, ~prefix=":")
    ? {
      let key = segment->String.sub(1, String.length(segment) - 1);
      Some((key, Dream.param(request, key)));
    }
    : None;
};

let renderPage = (~pageOpt, ~loadingOpt, ~globalLoading, ~params, ~query) => {
  switch (pageOpt) {
  | None => React.null
  | Some(page) =>
    module Page = (val page: PAGE);
    let pageElement = Page.make(~params, ~query, ());
    let loading =
      switch (loadingOpt, globalLoading) {
      | (Some(_), _) => loadingOpt
      | (None, Some(_)) => globalLoading
      | _ => None
      };
    switch (loading) {
    | None => pageElement
    | Some(loading) =>
      module Loading = (val loading: LOADING);
      <React.Suspense fallback={Loading.make()}> pageElement </React.Suspense>;
    };
  };
};

let renderMainPage = (~page, ~globalLoading, ~query) => {
  module Page = (val page: MAIN_PAGE);
  let pageElement = Page.make(~query, ());
  switch (globalLoading) {
  | None => pageElement
  | Some(loading) =>
    module Loading = (val loading: LOADING);
    <React.Suspense fallback={Loading.make()}> pageElement </React.Suspense>;
  };
};

module DefaultMainLayout = {
  let make = (~key=?, ~children, ()) => children;
};

let renderMainLayout = (~layoutOpt, ~children) => {
  module Layout = (
    val layoutOpt
        |> Option.value(
             ~default=(module DefaultMainLayout): (module MAIN_LAYOUT),
           )
  );
  Layout.make(~children, ());
};

let renderNotFound = (~notFound, ~path) => {
  switch (notFound) {
  | None => React.null
  | Some(notFound) =>
    module NotFound = (val notFound: NOT_FOUND);
    NotFound.make(~path, ());
  };
};

/**
  * Returns the React.element for the given path definition from the routes tree.
  * Example:
  * - definition: /students/:id
  * - React.element returned:
  *   <Route
  *     path="/students"
  *     layout={<StudentsLayout />}
  *     pageconsumer={
  *       <Route
  *         path="/students/:id"
  *         layout={<StudentLayout />}
  *         pageconsumer={<StudentPage />}
  *       />
  *     }
  *   />
  */
let getRoute =
    (
      ~initialDynamicParams=DynamicParams.create(),
      ~globalLoading=None,
      ~definition: string,
      ~request: Dream.request,
      routes: list(routeConfig),
    ) => {
  let pathSegments =
    String.split_on_char('/', definition)
    |> List.filter(segment => segment != "");
  let query =
    Dream.all_queries(request)
    |> Array.of_list
    |> URL.SearchParams.makeWithArray;

  // Goes through the route definitions to find the correct route from the definition
  let rec aux =
          (
            routes: list(routeConfig),
            pathSegments,
            parentPath,
            currentDynamicParams,
          )
          : option(React.element) => {
    switch (routes, pathSegments) {
    | ([route, ...restRoutes], [segment, ...restSegments]) =>
      let currentRoutePath = parentPath ++ route.path;

      /**
        * The page and layout have only access to
        * the dynamic params of the current route and the parent route.
        * So we append the current dynamic params to the parent dynamic params.
        * Example:
        * - Path: /classroom/:classroom_id
        * - Parent dynamic params: [("classroom_id", "1")]
        * - Path: /student/:student_id
        * - Request: /classroom/1/student/1
        * - Dynamic params: [("student_id", "1"), ("classroom_id", "1")]
        */
      let dynamicParams =
        extractDynamicParam(request, segment)
        |> Option.map(((key, value)) =>
             DynamicParams.add(currentDynamicParams, key, value)
           )
        |> Option.value(~default=currentDynamicParams);

      let renderLayout =
        switch (route.layout) {
        | Some(layout) =>
          module Layout = (val layout: LAYOUT);
          Layout.make(
            ~children=<Route.PageConsumer />,
            ~params=dynamicParams,
            (),
          );
        | None =>
          renderPage(
            ~pageOpt=route.page,
            ~loadingOpt=route.loading,
            ~globalLoading,
            ~params=dynamicParams,
            ~query,
          )
        };

      if (route.path == "/" ++ segment) {
        let pageconsumer =
          switch (route.children) {
          | [] => None
          | children =>
            Some(
              aux(children, restSegments, currentRoutePath, dynamicParams)
              |> Option.value(
                   ~default=
                     renderPage(
                       ~pageOpt=route.page,
                       ~loadingOpt=route.loading,
                       ~globalLoading,
                       ~params=dynamicParams,
                       ~query,
                     ),
                 ),
            )
          };

        Some(
          <Route path=currentRoutePath pageconsumer layout=renderLayout />,
        );
      } else {
        aux(restRoutes, pathSegments, parentPath, dynamicParams);
      };

    // No match
    | _ => None
    };
  };

  aux(routes, pathSegments, "", initialDynamicParams);
};

/**
  * Returns the React.element for a specific sub route for the given path definitions
  * using the parents segments to find the correct component
  * Example:
  * - parentPath: /students
  * - subRoutePath: /:id
  * - React.element returned:
  *   <Route
  *     path="/students/:id"
  *     layout={<StudentLayout />}
  *     pageconsumer={<StudentPage />}
  *   />
  */
let getSubRoute =
    (
      ~request: Dream.request,
      ~parentDefinition: string,
      ~subRouteDefinition: string,
      ~globalLoading=None,
      routes: list(routeConfig),
    ) => {
  let query =
    Dream.all_queries(request)
    |> Array.of_list
    |> URL.SearchParams.makeWithArray;
  let parentPathSegments =
    String.split_on_char('/', parentDefinition)
    |> List.filter(segment => segment != "");

  // Goes through the parent route definitions to find the correct route from the subRoutePath to render
  let rec aux = (routes, parentSegments, currentDynamicParams) => {
    switch (routes, parentSegments) {
    // When the parent segments are empty, we start rendering the route for the given subRoutePath
    | (routes, []) =>
      getRoute(
        ~initialDynamicParams=currentDynamicParams,
        ~definition=subRouteDefinition,
        ~request,
        ~globalLoading,
        routes,
      )
    | (
        [routeDefinition, ...restRouteDefinitions],
        [parentRouteDefinitionSegment, ...restParentRouteDefinitionSegments],
      ) =>
      let dynamicParams =
        /**
          * The page and layout have only access to
          * the dynamic params of the current route and the parent route.
          * So we append the current dynamic params to the parent dynamic params.
          * Example:
          * - Path: /classroom/:classroom_id
          * - Parent dynamic params: [("classroom_id", "1")]
          * - Path: /student/:student_id
          * - Request: /classroom/1/student/1
          * - Dynamic params: [("student_id", "1"), ("classroom_id", "1")]
          */
        extractDynamicParam(request, parentRouteDefinitionSegment)
        |> Option.map(((key, value)) =>
             DynamicParams.add(currentDynamicParams, key, value)
           )
        |> Option.value(~default=currentDynamicParams);

      if (routeDefinition.path == "/" ++ parentRouteDefinitionSegment) {
        switch (routeDefinition.children) {
        | [] =>
          switch (routeDefinition.page) {
          | None => None
          | Some(_) =>
            Some(
              renderPage(
                ~pageOpt=routeDefinition.page,
                ~loadingOpt=routeDefinition.loading,
                ~globalLoading,
                ~params=dynamicParams,
                ~query,
              ),
            )
          }
        | children =>
          aux(children, restParentRouteDefinitionSegments, dynamicParams)
        };
      } else {
        aux(restRouteDefinitions, parentSegments, dynamicParams);
      };

    | _ => None
    };
  };

  aux(routes, parentPathSegments, DynamicParams.create());
};

/**
  Generate all possible routes paths from a given list of routes
  Example:
  - Routes: [
    { path: "/student", children: [{ path: "/student/:student_id", children: [] }] },
    { path: "/classroom", children: [{ path: "/classroom/:classroom_id", children: [] }] },
  ]
  - Routes paths: ["/student", "/student/:student_id", "/classroom", "/classroom/:classroom_id"]
 */
let generated_routes_paths = (~routes: list(routeConfig)) => {
  let rec aux =
          (routes: list(routeConfig), parentPath: string): list(string) => {
    switch (routes) {
    | [] => []
    | [route, ...remainingRoutes] =>
      let fullPath = parentPath ++ route.path;

      let childRoutes =
        switch (route.children) {
        | [] => []
        | children => aux(children, fullPath)
        };

      [fullPath] @ childRoutes @ aux(remainingRoutes, parentPath);
    };
  };

  aux(routes, "");
};

let buildUrlFromRequest = request => {
  let protocol = Dream.tls(request) ? "https" : "http";
  let host = Dream.header(request, "Host") |> Option.value(~default="");
  let target = Dream.target(request);
  Printf.sprintf("%s://%s%s", protocol, host, target) |> URL.makeExn;
};

let renderSubRouteModel =
    (
      ~request,
      ~parentRouteDefinition /* students */,
      ~subRouteDefinition /* :id */,
      ~dynamicParams,
      ~globalLoading,
      ~notFound,
      routes,
    ) => {
  /* DreamRSC.stream_element( */
  DreamRSC.stream_model_value(
    ~location=Dream.target(request),
    /**
    The list of models is:
    - The parent route path (So the client can know which route to render)
    - The dynamic params
    - The sub route element
     */
    React.Model.List([
      React.Model.Json(
        `String(parentRouteDefinition == "" ? "/" : parentRouteDefinition),
      ),
      React.Model.Json(dynamicParams |> DynamicParams.to_json),
      React.Model.Element(
        routes
        |> getSubRoute(
             ~request,
             ~parentDefinition=
               parentRouteDefinition == "" ? "/" : parentRouteDefinition,
             ~subRouteDefinition,
             ~globalLoading,
           )
        |> Option.value(
             ~default=renderNotFound(~notFound, ~path=Dream.target(request)),
           ),
      ),
    ]),
  );
};

/**
 * Renders the route model for the given route definition from route definitions
  */
let renderRouteModel =
    (~request, ~routeDefinition, ~dynamicParams, routeDefinitions) => {
  let globalLoading = routeDefinitions.loading;
  DreamRSC.stream_model_value(
    ~location=Dream.target(request),
    React.Model.List([
      React.Model.Json(`String(routeDefinition)),
      /**
        * As the client don't have access to the dynamic params (/:)
        * we need to extract them from the path and send them to the client.
        * Example:
        * - Route definition: /classroom/:classroom_id/student/:student_id
        * - Route path: /classroom/1/student/1
        * - Dynamic params: [("student_id", "1"), ("classroom_id", "1")]
        */
      React.Model.Json(dynamicParams |> DynamicParams.to_json),
      React.Model.Element(
        <Route
          path="/"
          layout={renderMainLayout(
            ~layoutOpt=routeDefinitions.layout,
            ~children=<Route.PageConsumer />,
          )}
          pageconsumer={
                         let isRoot = routeDefinition ++ "/" == "/";
                         Some(
                           if (isRoot) {
                             renderMainPage(
                               ~page=routeDefinitions.page,
                               ~globalLoading,
                               ~query=
                                 Dream.all_queries(request)
                                 |> Array.of_list
                                 |> URL.SearchParams.makeWithArray,
                             );
                           } else {
                             routeDefinitions.routes
                             |> getRoute(
                                  ~request,
                                  ~definition=routeDefinition,
                                  ~globalLoading,
                                )
                             |> Option.value(
                                  ~default=
                                    renderNotFound(
                                      ~notFound=routeDefinitions.notFound,
                                      ~path=Dream.target(request),
                                    ),
                                );
                           },
                         );
                       }
        />,
      ),
    ]),
  );
};

// Render full route HTML (for initial page load)
let renderRouteHtml =
    (
      ~request,
      ~routeDefinition,
      ~dynamicParams,
      ~bootstrapModules,
      ~document,
      routeDefinitions,
    ) => {
  let globalLoading = routeDefinitions.loading;
  let url = buildUrlFromRequest(request);
  DreamRSC.stream_html(
    ~bootstrapModules,
    document(
      ~children=
        <Router serverUrl=url initialDynamicParams=dynamicParams>
          <Route
            /* MAIN ROUTE */
            path="/"
            layout={renderMainLayout(
              ~layoutOpt=routeDefinitions.layout,
              ~children=<Route.PageConsumer />,
            )}
            pageconsumer={
                           let isRoot = routeDefinition ++ "/" == "/";
                           Some(
                             if (isRoot) {
                               renderMainPage(
                                 ~page=routeDefinitions.page,
                                 ~globalLoading,
                                 ~query=
                                   Dream.all_queries(request)
                                   |> Array.of_list
                                   |> URL.SearchParams.makeWithArray,
                               );
                             } else {
                               routeDefinitions.routes
                               |> getRoute(
                                    ~request,
                                    ~definition=routeDefinition,
                                    ~globalLoading,
                                  )
                               |> Option.value(
                                    ~default=
                                      renderNotFound(
                                        ~notFound=routeDefinitions.notFound,
                                        ~path=Dream.target(request),
                                      ),
                                  );
                             },
                           );
                         }
          />
        </Router>,
    ),
  );
};

let routeDefinitionsHandlers =
    (~bootstrapModules, ~document, ~routeDefinitions, basePath, handler) => {
  let routesPaths = [
    "/",
    ...generated_routes_paths(~routes=routeDefinitions.routes),
  ];

  routesPaths
  |> List.map(path => {
       let normalizedPath = path == "/" ? "" : path;

       [
         handler(
           basePath ++ normalizedPath ++ "/",
           request => {
             Dream.log("Redirecting to /demo%s", normalizedPath);
             let query = Dream.target(request) |> Dream.split_target |> snd;
             Dream.redirect(
               request,
               basePath ++ normalizedPath ++ "?" ++ query,
             );
           },
         ),
         handler(
           basePath ++ normalizedPath,
           request => {
             let dynamicParams: DynamicParams.t =
               /**
                 * Route definition: /students/:id/grades/:grade_id
                 * Current path: /students/123/grades/456
                 * Dynamic params: [("id", "123"), ("grade_id", "456")]
                 */
               normalizedPath
               |> String.split_on_char('/')
               |> List.filter_map(extractDynamicParam(request))
               |> Array.of_list;

             switch (Dream.query(request, "toSubRoute")) {
             | Some(subRoutePath) =>
               /**
                   * When the user navigates to a sub-route path (Example: /grades/456) from a parent route path (Example: /students/123), we need to find this sub-route definition (grades/:grade_id)
                   * and the parent route definition (students/:id) so we can match it on the renderSubRouteModel function.
                   * To find the sub-route definition, we need to find the index of the sub-route path in the current route definition from the subRoutePath.
                   * Then split the current route definition into the sub-route definition and the parent route definition.
                   * Request: https://localhost:3000/students/123/grades/456?toSubRoute=/grades/456
                   * The toSubRoute means that from the current path, the user wants to navigate from /students/123 to /grades/456.
                   * Route definition that matches the current path: /students/:id/grades/:grade_id (server-side only)
                   * Sub-route target: ["grades", "456"] (?toSubRoute=/grades/456) -> Length: 2
                   * Split ["students", ":id", "grades", ":grade_id"] into:
                   * - ["students", ":id"] (parent route definition)
                   * - ["grades", ":grade_id"] (sub-route definition)
                   */
               let subRoutePathnamesIndex =
                 (normalizedPath |> String.split_on_char('/') |> List.length)
                 - (subRoutePath |> String.split_on_char('/') |> List.length);

               // Split the route definition into the parent route definition and the sub route definition
               let (parentRouteDefinition, subRouteDefinition) =
                 normalizedPath
                 |> String.split_on_char('/')
                 |> List.fold_left(
                      ((parent, sub, remaining), segment) =>
                        if (remaining > 0) {
                          ([segment, ...parent], sub, remaining - 1);
                        } else {
                          (parent, [segment, ...sub], remaining);
                        },
                      ([], [], subRoutePathnamesIndex),
                    )
                 |> (
                   ((parent, sub, _)) => (
                     List.rev(parent) |> String.concat("/"),
                     List.rev(sub) |> String.concat("/"),
                   )
                 );

               renderSubRouteModel(
                 ~request,
                 ~parentRouteDefinition,
                 ~subRouteDefinition,
                 ~dynamicParams,
                 ~globalLoading=routeDefinitions.loading,
                 ~notFound=routeDefinitions.notFound,
                 routeDefinitions.routes,
               );

             | None =>
               /* If the request has the header application/react.component, we render the full route as model */
               let isModelRequest =
                 Dream.header(request, "Accept")
                 == Some("application/react.component");

               if (isModelRequest) {
                 routeDefinitions
                 |> renderRouteModel(
                      ~request,
                      ~routeDefinition=normalizedPath,
                      ~dynamicParams,
                    );
               } else {
                 renderRouteHtml(
                   ~bootstrapModules,
                   ~request,
                   ~routeDefinition=normalizedPath,
                   ~dynamicParams,
                   ~document,
                   routeDefinitions,
                 );
               };
             };
           },
         ),
       ];
     })
  |> List.flatten;
};

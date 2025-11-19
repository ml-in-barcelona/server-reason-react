/**
* RouterRSC is a module that provides the helpers to build the route and the layout component from the route definitions.
*/
type route = {
  path: string,
  layout:
    option(
      (~children: React.element, ~dynamicParams: Router.DynamicParams.t) =>
      React.element,
    ),
  page:
    option(
      (
        ~dynamicParams: Router.DynamicParams.t,
        ~queryParams: URL.SearchParams.t
      ) =>
      React.element,
    ),
  subRoutes: option(list(route)),
};

type routeDefinitions = {
  rootLayout: (~children: React.element) => React.element,
  rootPage: (~queryParams: URL.SearchParams.t) => React.element,
  routes: list(route),
};

let extractDynamicParam = (request, segment) => {
  String.starts_with(segment, ~prefix=":")
    ? {
      let key = segment->String.sub(1, String.length(segment) - 1);
      Some((key, Dream.param(request, key)));
    }
    : None;
};

// Returns the React.element for the given path definition
let getRoute =
    (
      ~initialDynamicParams=Router.DynamicParams.create(),
      ~definition: string,
      ~request: Dream.request,
      routes: list(route),
    ) => {
  let pathSegments =
    String.split_on_char('/', definition)
    |> List.filter(segment => segment != "");
  let queryParams =
    Dream.all_queries(request)
    |> Array.of_list
    |> URL.SearchParams.makeWithArray;

  let rec aux =
          (
            routes: list(route),
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
             Router.DynamicParams.add(currentDynamicParams, key, value)
           )
        |> Option.value(~default=currentDynamicParams);

      let renderPage = (pageOpt, ~dynamicParams) =>
        pageOpt
        |> Option.map(page => page(~dynamicParams, ~queryParams))
        |> Option.value(~default=React.null);
      let renderLayout =
        switch (route.layout) {
        | Some(layout) => layout(~children=<Route.Outlet />, ~dynamicParams)
        | None => renderPage(route.page, ~dynamicParams)
        };

      if (route.path == "/" ++ segment) {
        let outlet =
          switch (route.subRoutes) {
          | Some(children) =>
            Some(
              aux(children, restSegments, currentRoutePath, dynamicParams)
              |> Option.value(
                   ~default=renderPage(route.page, ~dynamicParams),
                 ),
            )
          | None => None
          };

        Some(<Route path=currentRoutePath outlet layout=renderLayout />);
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
  Returns the React.element for a specific sub route for the given path definitions
  using the parents segments to find the correct component
  */
let getSubRoute =
    (
      ~request: Dream.request,
      ~parentPath: string,
      ~subRoutePath: string,
      routes: list(route),
    ) => {
  let queryParams =
    Dream.all_queries(request)
    |> Array.of_list
    |> URL.SearchParams.makeWithArray;
  let parentPathSegments =
    String.split_on_char('/', parentPath)
    |> List.filter(segment => segment != "");

  let renderPage = (pageOpt, ~dynamicParams) =>
    pageOpt |> Option.map(page => page(~dynamicParams, ~queryParams));

  // Goes through the parent route definitions to find the correct route from the subRoutePath to render
  let rec aux = (routes, parentSegments, currentDynamicParams) => {
    switch (routes, parentSegments) {
    // When the parent segments are empty, we start rendering the route for the given subRoutePath
    | (routes, []) =>
      getRoute(
        ~initialDynamicParams=currentDynamicParams,
        ~definition=subRoutePath,
        ~request,
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
             Router.DynamicParams.add(currentDynamicParams, key, value)
           )
        |> Option.value(~default=currentDynamicParams);

      if (routeDefinition.path == "/" ++ parentRouteDefinitionSegment) {
        switch (routeDefinition.subRoutes) {
        | Some(children) =>
          aux(children, restParentRouteDefinitionSegments, dynamicParams)
        | None => renderPage(routeDefinition.page, ~dynamicParams)
        };
      } else {
        aux(restRouteDefinitions, parentSegments, dynamicParams);
      };

    | _ => None
    };
  };

  aux(routes, parentPathSegments, Router.DynamicParams.create());
};

/**
  Generate all possible routes paths from a given list of routes
  Example:
  - Routes: [
    { path: "/student", subRoutes: Some([{ path: "/student/:student_id", subRoutes: None }]) },
    { path: "/classroom", subRoutes: Some([{ path: "/classroom/:classroom_id", subRoutes: None }]) },
  ]
  - Routes paths: ["/student", "/student/:student_id", "/classroom", "/classroom/:classroom_id"]
 */
let generated_routes_paths = (~routes: list(route)) => {
  let rec aux = (routes: list(route), parentPath: string): list(string) => {
    switch (routes) {
    | [] => []
    | [route, ...remainingRoutes] =>
      let fullPath = parentPath ++ route.path;

      let childRoutes =
        switch (route.subRoutes) {
        | Some(children) => aux(children, fullPath)
        | None => []
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
  Printf.sprintf("%s://%s%s", protocol, host, target);
};

let renderSubRouteModel =
    (
      ~request,
      ~parentRouteDefinition /* students */,
      ~subRouteDefinition /* :id */,
      ~dynamicParams,
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
      React.Model.Json(dynamicParams |> Router.DynamicParams.to_json),
      React.Model.Element(
        routes
        |> getSubRoute(
             ~request,
             ~parentPath=
               parentRouteDefinition == "" ? "/" : parentRouteDefinition,
             ~subRoutePath=subRouteDefinition,
           )
        |> Option.value(~default=React.null),
      ),
    ]),
  );
};

// Render full route model (when revalidating the route)
let renderRevalidatedRouteModel =
    (~request, ~routeDefinition, ~dynamicParams, routeDefinitions) => {
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
      React.Model.Json(dynamicParams |> Router.DynamicParams.to_json),
      React.Model.Element(
        <Route
          path="/"
          layout={routeDefinitions.rootLayout(~children=<Route.Outlet />)}
          outlet={
                   let isRoot = routeDefinition ++ "/" == "/";
                   Some(
                     if (isRoot) {
                       routeDefinitions.rootPage(
                         ~queryParams=
                           Dream.all_queries(request)
                           |> Array.of_list
                           |> URL.SearchParams.makeWithArray,
                       );
                     } else {
                       routeDefinitions.routes
                       |> getRoute(~request, ~definition=routeDefinition)
                       // TODO: Handle 404 case here
                       |> Option.value(~default=React.null);
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
  let url = buildUrlFromRequest(request);
  DreamRSC.stream_html(
    ~bootstrapModules,
    document(
      ~children=
        <Router dynamicParams url={URL.makeExn(url)}>
          <Route
            /* MAIN ROUTE */
            path="/"
            layout={routeDefinitions.rootLayout(~children=<Route.Outlet />)}
            outlet={
                     let isRoot = routeDefinition ++ "/" == "/";
                     Some(
                       if (isRoot) {
                         routeDefinitions.rootPage(
                           ~queryParams=
                             Dream.all_queries(request)
                             |> Array.of_list
                             |> URL.SearchParams.makeWithArray,
                         );
                       } else {
                         routeDefinitions.routes
                         |> getRoute(~request, ~definition=routeDefinition)
                         // TODO: Handle 404 case here
                         |> Option.value(~default=React.null);
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
             let dynamicParams: Router.DynamicParams.t =
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
             | Some(subRoutePath /* 123 */) =>
               /**
                * When the user navigates to a sub-route, we need to find the sub-route definition and the parent route definition.
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
               let subRoutePathnamesLength =
                 subRoutePath |> String.split_on_char('/') |> List.length;

               let (parentRouteDefinition, subRouteDefinition) =
                 normalizedPath
                 |> String.split_on_char('/')
                 |> List.fold_left(
                      ((parent, sub, remaining), segment) =>
                        if (remaining > 0) {
                          (parent, [segment, ...sub], remaining - 1);
                        } else {
                          ([segment, ...parent], sub, remaining);
                        },
                      ([], [], subRoutePathnamesLength),
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
                 routeDefinitions.routes,
               );

             | None =>
               let isModelRequest =
                 Dream.header(request, "Accept")
                 == Some("application/react.component");

               if (isModelRequest) {
                 routeDefinitions
                 |> renderRevalidatedRouteModel(
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

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

/**
  Returns the route for the given path
  */
let renderRoute =
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
  Render a specific sub route for the given path definitions
  using the parents segments to find the correct component
  */
let renderSubRoute =
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

  /* TODO: This should live rent free into another place, hopefully in a RoutesDefinitions module */
  let rec aux = (routes, parentSegments, currentDynamicParams) => {
    switch (routes, parentSegments) {
    // When the parent segments are empty, we render the route for the given subRoutePath
    | (routes, []) =>
      renderRoute(
        ~initialDynamicParams=currentDynamicParams,
        ~definition=subRoutePath,
        ~request,
        routes,
      )
    | ([route, ...restRoutes], [segment, ...restSegments]) =>
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

      if (route.path == "/" ++ segment) {
        switch (route.subRoutes) {
        | Some(children) => aux(children, restSegments, dynamicParams)
        | None => renderPage(route.page, ~dynamicParams)
        };
      } else {
        aux(restRoutes, parentSegments, dynamicParams);
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
  DreamRSC.stream_value(
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
        |> renderSubRoute(
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
  DreamRSC.stream_model(
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
                       |> renderRoute(~request, ~definition=routeDefinition)
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
                         |> renderRoute(
                              ~request,
                              ~definition=routeDefinition,
                            )
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
               /* [("student_id", "123")] */
               normalizedPath
               |> String.split_on_char('/')
               |> List.filter_map(extractDynamicParam(request))
               |> Array.of_list;

             /* TODO: instead of using rsc to describe where te user is going to navigate to, we could send the previous route path. */
             /* OR: a complete solution that doesn't use the word rsc */
             switch (Dream.query(request, "rsc")) {
             | Some(subRoutePath /* 123 */) =>
               /* where you are:      currentPath/parent/referrer */
               /* where you wanna go: nextPath   */

               /*
                   ___ /
                  |         |
                 students   about
                123    456
                */

               /* user students/ */
               /* navigate to students/123 */
               /* pathnames: ["students", "123"] */
               /* routeDefinition: students/:id */

               let subRouteIndex =
                 subRoutePath |> String.split_on_char('/') |> List.length;

               let currentRouteDefinition =
                 /* ["students", ":id"] */
                 normalizedPath |> String.split_on_char('/');

               /* TODO: Consider if routes definitions should be a tree, not a list. */
               let subRouteDefinition =
                 currentRouteDefinition
                 |> List.filteri((index, _) => index >= subRouteIndex)
                 |> String.concat("/");

               let parentRouteDefinition =
                 currentRouteDefinition
                 |> List.filteri((index, _) => index < subRouteIndex)
                 |> String.concat("/");

               /* let component = RoutesDefinitions.getSubComponent(asdjnasdkjfnasdkjnfksajdnfkjsndfkjasnfkjsndafkjsd); */
               /* renderModel(component); */
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

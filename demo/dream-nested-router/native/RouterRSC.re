/**
* RouterRSC is a module that provides the helpers to build the route and the layout component from the route definitions.
*/
module type MAIN_LAYOUT = {
  [@react.component]
  let make: (~children: React.element, unit) => React.element;
};

module type MAIN_PAGE = {
  [@react.component]
  let make: (~query: URL.SearchParams.t, unit) => React.element;
};

/**
 * A layout is the UI that is shared between multiple pages.
 * On navigation, layouts preserve state, remain interactive, and do not rerender.
 * Why there is no queryParams in the layout?
 * As it does not rerender on navigation, it cannot access search params which would otherwise become stale.
 */
module type LAYOUT = {
  [@react.component]
  let make:
    (~children: React.element, ~params: PathParams.t, unit) => React.element;
};

/**
 * A page is the UI that is rendered on a specific route.
 */
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

let extractPathParam = (request, segment) => {
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
    let pageElement = <Page params query />;
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
      <React.Suspense fallback={<Loading />}> pageElement </React.Suspense>;
    };
  };
};

let renderMainPage = (~page, ~globalLoading, ~query) => {
  module Page = (val page: MAIN_PAGE);
  let pageElement = <Page query />;
  switch (globalLoading) {
  | None => pageElement
  | Some(loading) =>
    module Loading = (val loading: LOADING);
    <React.Suspense fallback={<Loading />}> pageElement </React.Suspense>;
  };
};

module DefaultMainLayout = {
  [@react.component]
  let make = (~children) => children;
};

let renderMainLayout = (~layoutOpt, ~children) => {
  module Layout = (
    val layoutOpt
        |> Option.value(
             ~default=(module DefaultMainLayout): (module MAIN_LAYOUT),
           )
  );
  <Layout> children </Layout>;
};

let renderNotFound = (~notFound, ~path) => {
  switch (notFound) {
  | None => React.null
  | Some(notFound) =>
    module NotFound = (val notFound: NOT_FOUND);
    <NotFound path />;
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
      ~initialPathParams=PathParams.create(),
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
            currentPathParams,
          )
          : option(React.element) => {
    switch (routes, pathSegments) {
    | ([route, ...restRoutes], [segment, ...restSegments]) =>
      let currentRoutePath = parentPath ++ route.path;

      /**
        * The page and layout have only access to
        * the path params of the current route and the parent route.
        * So we append the current path params to the parent path params.
        * Example:
        * - Path: /classroom/:classroom_id
        * - Parent path params: [("classroom_id", "1")]
        * - Path: /student/:student_id
        * - Request: /classroom/1/student/1
        * - Path params: [("student_id", "1"), ("classroom_id", "1")]
        */
      let pathParams =
        extractPathParam(request, segment)
        |> Option.map(((key, value)) =>
             PathParams.add(currentPathParams, key, value)
           )
        |> Option.value(~default=currentPathParams);

      let renderLayout =
        switch (route.layout) {
        | Some(layout) =>
          module Layout = (val layout: LAYOUT);
          <Layout params=pathParams> <Route.PageConsumer /> </Layout>;
        | None =>
          renderPage(
            ~pageOpt=route.page,
            ~loadingOpt=route.loading,
            ~globalLoading,
            ~params=pathParams,
            ~query,
          )
        };

      if (route.path == "/" ++ segment) {
        let pageconsumer =
          switch (route.children) {
          | [] => None
          | children =>
            Some(
              aux(children, restSegments, currentRoutePath, pathParams)
              |> Option.value(
                   ~default=
                     renderPage(
                       ~pageOpt=route.page,
                       ~loadingOpt=route.loading,
                       ~globalLoading,
                       ~params=pathParams,
                       ~query,
                     ),
                 ),
            )
          };

        Some(
          <Route path=currentRoutePath pageconsumer layout=renderLayout />,
        );
      } else {
        aux(restRoutes, pathSegments, parentPath, pathParams);
      };

    // No match
    | _ => None
    };
  };

  aux(routes, pathSegments, "", initialPathParams);
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
  let rec aux = (routes, parentSegments, currentPathParams) => {
    switch (routes, parentSegments) {
    // When the parent segments are empty, we start rendering the route for the given subRoutePath
    | (routes, []) =>
      getRoute(
        ~initialPathParams=currentPathParams,
        ~definition=subRouteDefinition,
        ~request,
        ~globalLoading,
        routes,
      )
    | (
        [routeDefinition, ...restRouteDefinitions],
        [parentRouteDefinitionSegment, ...restParentRouteDefinitionSegments],
      ) =>
      let pathParams =
        /**
          * The page and layout have only access to
          * the path params of the current route and the parent route.
          * So we append the current path params to the parent path params.
          * Example:
          * - Path: /classroom/:classroom_id
          * - Parent path params: [("classroom_id", "1")]
          * - Path: /student/:student_id
          * - Request: /classroom/1/student/1
          * - Path params: [("student_id", "1"), ("classroom_id", "1")]
          */
        extractPathParam(request, parentRouteDefinitionSegment)
        |> Option.map(((key, value)) =>
             PathParams.add(currentPathParams, key, value)
           )
        |> Option.value(~default=currentPathParams);

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
                ~params=pathParams,
                ~query,
              ),
            )
          }
        | children =>
          aux(children, restParentRouteDefinitionSegments, pathParams)
        };
      } else {
        aux(restRouteDefinitions, parentSegments, pathParams);
      };

    | _ => None
    };
  };

  aux(routes, parentPathSegments, PathParams.create());
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

let protocolVersion = 1;

/**
  * Deterministic identity of this route registry. Clients echo it in the
  * SRR-Registry header; a mismatch means the hydrated client belongs to an
  * incompatible deployment and must reload instead of applying payloads.
  */
let registryFingerprint = (~basePath, ~routes) => {
  let identity =
    String.concat("|", [basePath, ...generated_routes_paths(~routes)]);
  Printf.sprintf(
    "%d.%s",
    protocolVersion,
    Digest.to_hex(Digest.string(identity)),
  );
};

let segments = path =>
  String.split_on_char('/', path) |> List.filter(segment => segment != "");

let segmentMatches = (definitionSegment, concreteSegment) =>
  String.starts_with(definitionSegment, ~prefix=":")
  || definitionSegment == concreteSegment;

/**
  * Match a concrete path (from SRR-Navigation-From, relative to the mount)
  * against the generated route definitions. First match in generation order
  * wins, mirroring Dream's registration order.
  */
let matchDefinition = (~definitions, concretePath) => {
  let concrete = segments(concretePath);
  definitions
  |> List.find_opt(definition => {
       let definitionSegments = segments(definition);
       List.length(definitionSegments) == List.length(concrete)
       && List.for_all2(segmentMatches, definitionSegments, concrete);
     });
};

/**
  * Compute where the target branch stops being shared with the committed
  * branch. A level is shared only when its definition segment AND its
  * concrete segment are both equal: /note/1 and /note/2 share nothing below
  * their common static ancestor, so a stale :id layout can never be reused.
  *
  * Returns (parentRouteDefinition, subRouteDefinition), where the parent is
  * the shared prefix ("" means the root layout) and the sub is the branch to
  * rerender. Returns None when the whole target is shared (same location):
  * the caller should answer with a full model.
  */
let sharedPrefixSplit =
    (~fromDefinition, ~fromPath, ~targetDefinition, ~targetPath) => {
  let rec walk = (defF, concF, defT, concT, shared) =>
    switch (defF, concF, defT, concT) {
    | ([df, ...defF], [cf, ...concF], [dt, ...defT], [ct, ...concT])
        when df == dt && cf == ct =>
      walk(defF, concF, defT, concT, [dt, ...shared])
    | (_, _, remaining, _) => (List.rev(shared), remaining)
    };

  let (shared, sub) =
    walk(
      segments(fromDefinition),
      segments(fromPath),
      segments(targetDefinition),
      segments(targetPath),
      [],
    );

  /* When the target is fully shared (same location or an ancestor of the
     committed branch), rerender its deepest level instead of nothing. */
  let (shared, sub) =
    switch (sub, List.rev(shared)) {
    | ([], [last, ...restReversed]) => (List.rev(restReversed), [last])
    | (sub, _) => (shared, sub)
    };

  switch (sub) {
  | [] => None
  | sub =>
    let parent =
      switch (shared) {
      | [] => ""
      | shared => "/" ++ String.concat("/", shared)
      };
    Some((parent, "/" ++ String.concat("/", sub)));
  };
};

let maxNavigationFromLength = 2048;

/**
  * Interpret the SRR-Navigation-From header: same mount, sane length, and
  * matching a known route definition. Anything else degrades to a full
  * response — a stripped or foreign header must never produce a wrong patch.
  */
let navigationFrom = (~basePath, ~definitions, request) => {
  switch (Dream.header(request, "SRR-Navigation-From")) {
  | Some(from)
      when
        String.length(from) <= maxNavigationFromLength
        && String.starts_with(from, ~prefix=basePath) =>
    let fromPath =
      switch (String.index_opt(from, '?')) {
      | Some(queryStart) => String.sub(from, 0, queryStart)
      | None => from
      };
    let relativePath =
      String.sub(
        fromPath,
        String.length(basePath),
        String.length(fromPath) - String.length(basePath),
      );
    matchDefinition(~definitions, relativePath)
    |> Option.map(definition => (definition, relativePath));
  | Some(_)
  | None => None
  };
};

let renderSubRouteModel =
    (
      ~request,
      ~parentRouteDefinition /* students */,
      ~subRouteDefinition /* :id */,
      ~pathParams,
      ~globalLoading,
      ~notFound,
      routes,
    ) => {
  let parentRoute = parentRouteDefinition == "" ? "/" : parentRouteDefinition;
  let element =
    routes
    |> getSubRoute(
         ~request,
         ~parentDefinition=parentRoute,
         ~subRouteDefinition,
         ~globalLoading,
       )
    |> Option.value(
         ~default=renderNotFound(~notFound, ~path=Dream.target(request)),
       );

  let%lwt response =
    DreamRSC.stream_model_value(
      ~location=Dream.target(request),
      React.Model.Element(
        <Navigation parentRoute pathParams kind="patch"> element </Navigation>,
      ),
    );
  Dream.set_header(response, "SRR-Response", "patch");
  Dream.set_header(response, "Vary", "Accept");
  /* Patches depend on SRR-Navigation-From; relying on Vary for that key is
     unreliable across CDNs and its cardinality makes caching worthless. */
  Dream.set_header(response, "Cache-Control", "private, no-store");
  Lwt.return(response);
};

let renderRouteModel =
    (~request, ~routeDefinition, ~pathParams, routeDefinitions) => {
  let globalLoading = routeDefinitions.loading;
  let parentRoute = routeDefinition == "" ? "/" : routeDefinition;
  let pageconsumer = {
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
        |> getRoute(~request, ~definition=routeDefinition, ~globalLoading)
        |> Option.value(
             ~default=
               renderNotFound(
                 ~notFound=routeDefinitions.notFound,
                 ~path=Dream.target(request),
               ),
           );
      },
    );
  };
  let%lwt response =
    DreamRSC.stream_model_value(
      ~location=Dream.target(request),
      React.Model.Element(
        <Navigation parentRoute pathParams kind="full">
          <Route
            path="/"
            layout={renderMainLayout(
              ~layoutOpt=routeDefinitions.layout,
              ~children=<Route.PageConsumer />,
            )}
            pageconsumer
          />
        </Navigation>,
      ),
    );
  Dream.set_header(response, "SRR-Response", "full");
  Dream.set_header(response, "Vary", "Accept");
  Lwt.return(response);
};

// Render full route HTML (for initial page load)
let renderRouteHtml =
    (
      ~request,
      ~routeDefinition,
      ~pathParams,
      ~registryFingerprint,
      ~bootstrapModules,
      ~document,
      routeDefinitions,
    ) => {
  let globalLoading = routeDefinitions.loading;
  let url = buildUrlFromRequest(request);
  let%lwt response =
    DreamRSC.stream_html(
      ~bootstrapModules,
      document(
        ~children=
          <Router
            serverUrl=url initialPathParams=pathParams registryFingerprint>
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
  /* The same URL serves HTML and flight payloads, negotiated by Accept. */
  Dream.set_header(response, "Vary", "Accept");
  Lwt.return(response);
};

let routeDefinitionsHandlers =
    (~bootstrapModules, ~document, ~routeDefinitions, basePath, handler) => {
  let routesPaths = [
    "/",
    ...generated_routes_paths(~routes=routeDefinitions.routes),
  ];
  let registry =
    registryFingerprint(~basePath, ~routes=routeDefinitions.routes);

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
             let pathParams: PathParams.t =
               /**
                 * Route definition: /students/:id/grades/:grade_id
                 * Current path: /students/123/grades/456
                 * Path params: [("id", "123"), ("grade_id", "456")]
                 */
               normalizedPath
               |> String.split_on_char('/')
               |> List.filter_map(extractPathParam(request))
               |> Array.of_list;

             let isModelRequest =
               Dream.header(request, "Accept")
               == Some("application/react.component");

             if (!isModelRequest) {
               renderRouteHtml(
                 ~bootstrapModules,
                 ~request,
                 ~routeDefinition=normalizedPath,
                 ~pathParams,
                 ~registryFingerprint=registry,
                 ~document,
                 routeDefinitions,
               );
             } else {
               switch (Dream.header(request, "SRR-Registry")) {
               | Some(clientRegistry) when clientRegistry != registry =>
                 /* The hydrated client belongs to another deployment: it must
                    reload rather than apply an incompatible payload. */
                 Dream.respond(
                   ~headers=[
                     ("SRR-Response", "reload-required"),
                     ("Vary", "Accept"),
                     ("Cache-Control", "private, no-store"),
                   ],
                   "",
                 )
               | Some(_)
               | None =>
                 let renderFull = () =>
                   routeDefinitions
                   |> renderRouteModel(
                        ~request,
                        ~routeDefinition=normalizedPath,
                        ~pathParams,
                      );

                 let targetPath = {
                   let (target, _query) =
                     Dream.target(request) |> Dream.split_target;
                   String.sub(
                     target,
                     String.length(basePath),
                     String.length(target) - String.length(basePath),
                   );
                 };

                 switch (
                   navigationFrom(
                     ~basePath,
                     ~definitions=routesPaths,
                     request,
                   )
                 ) {
                 | None => renderFull()
                 | Some((fromDefinition, fromPath)) =>
                   switch (
                     sharedPrefixSplit(
                       ~fromDefinition,
                       ~fromPath,
                       ~targetDefinition=normalizedPath,
                       ~targetPath,
                     )
                   ) {
                   | None => renderFull()
                   | Some((parentRouteDefinition, subRouteDefinition)) =>
                     renderSubRouteModel(
                       ~request,
                       ~parentRouteDefinition,
                       ~subRouteDefinition,
                       ~pathParams,
                       ~globalLoading=routeDefinitions.loading,
                       ~notFound=routeDefinitions.notFound,
                       routeDefinitions.routes,
                     )
                   }
                 };
               };
             };
           },
         ),
       ];
     })
  |> List.flatten;
};

// Allow GET and POST from the same handler enables progressive enhancement.
// When JS is disabled, the browser will make a POST request into the same page (instead of a GET). The server should handle the form action and return the page.
// When JS is enabled, the page will make a POST request to the server with the action ID and the server will return the action response.
let getAndPost = (path, handler) =>
  Dream.scope(
    "/",
    [],
    [
      Dream.get(path, handler),
      Dream.post(path, DreamRSC.streamFunctionResponse),
    ],
  );

let rscRouting = (basePath, handler) => {
  RouteDefinitions.generated_routes_paths
  |> List.map(path => {
       let path = path == "/" ? "" : path;

       [
         getAndPost(
           basePath ++ path ++ "/",
           request => {
             // Redirect when the route is accessed with a trailing slash
             Dream.log("Redirecting to /demo%s", path);
             Dream.redirect(request, basePath ++ path);
           },
         ),
         getAndPost(
           basePath ++ path,
           request => {
             let routeSegments = String.split_on_char('/', path);
             let rscParam = Dream.query(request, "rsc");
             let element =
               switch (rscParam) {
               | Some(rscPath) =>
                 let rscRouteSegments = rscPath |> String.split_on_char('/');
                 RouteDefinitions.(
                   routes |> renderComponent(routeSegments, rscRouteSegments)
                 );
               | None =>
                 RouteDefinitions.(routes |> renderByPath(routeSegments))
               };

             handler(~element, request);
           },
         ),
       ];
     })
  |> List.flatten;
};

let server =
  Dream.logger(
    Dream.router([
      getAndPost("/", Pages.Home.handler),
      Dream.get("/demo", req => Dream.redirect(req, "/")),
      Dream.get(
        "/output.css",
        Dream.from_filesystem("./_build/default/demo", "output.css"),
      ),
      Dream.get(
        "/static/**",
        Dream.static("./_build/default/demo/client/app"),
      ),
      getAndPost(Routes.renderToString, _request =>
        Dream.html(
          ReactDOM.renderToString(
            <Document script="/static/demo/RenderRoot.re.js">
              <App />
            </Document>,
          ),
        )
      ),
      getAndPost(Routes.renderToStaticMarkup, _request =>
        Dream.html(
          ReactDOM.renderToStaticMarkup(
            <Document script="/static/demo/HydrateRoot.re.js">
              <App />
            </Document>,
          ),
        )
      ),
      getAndPost(Routes.renderToStream, Pages.Comments.handler),
      getAndPost(Routes.singlePageRSC, Pages.SinglePageRSC.handler),
      getAndPost(Routes.dummyRouterRSC, Pages.DummyRouterRSC.handler),
      getAndPost(Routes.serverOnlyRSC, Pages.ServerOnlyRSC.handler),
      ...rscRouting(Routes.router, Pages.Router.handler),
    ]),
  );

let interface = {
  switch (Sys.getenv_opt("SERVER_INTERFACE")) {
  | Some(env) => env
  | None => "localhost"
  };
};

Dream.run(~port=8080, ~interface, server);

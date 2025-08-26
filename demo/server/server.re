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
let getSupersonicRoutes = () => {
  Supersonic.RouteRegistry.clear();

  RouteDefinitions.routes
  |> List.iter((route: RouteDefinitions.t) => {
       Supersonic.RouteRegistry.register(
         ~path=route.path,
         ~element=route.component,
         (),
       )
     });

  Supersonic.RouteRegistry.getAllRoutes()
  |> List.map(({path, element, _}: Supersonic.RouteRegistry.route) => {
       getAndPost(path, Pages.Router.handler(~element))
     });
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
      ...getSupersonicRoutes(),
    ]),
  );

let error_handler =
  Dream.error_template((error, _request, response) => {
    let status = Dream.status(response);
    let status_code = Dream.status_to_int(status);
    let status_text = Dream.status_to_string(status);

    Dream.html(
      ReactDOM.renderToStaticMarkup(
        <Pages.Error status status_code status_text error />,
      ),
    );
  });

let interface = {
  switch (Sys.getenv_opt("SERVER_INTERFACE")) {
  | Some(env) => env
  | None => "localhost"
  };
};

Dream.run(~port=8080, ~interface, ~error_handler, server);

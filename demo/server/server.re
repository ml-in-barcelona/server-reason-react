let debug = Sys.getenv_opt("DEMO_ENV") == Some("development");

let serverFunctionHandler =
  DreamRouter.streamFunctionResponse(~debug, ~lookup=FunctionReferences.get);

let getAndPost = (path, handler) =>
  Dream.scope(
    "/",
    [],
    [Dream.get(path, handler), Dream.post(path, serverFunctionHandler)],
  );

let routerHandler =
  DreamRouter.handler(
    ~registry=RouterRegistry.registry,
    ~basePath=RouterRegistry.basePath,
    ~fallback=RouterRegistry.fallback,
    ~applicationStatus=RouterRegistry.applicationStatus,
    ~diagnosticId=_ => string_of_int(Random.bits()),
    ~revision=() => string_of_int(Random.bits()),
    ~protocolVersion=1,
    ~bootstrapModules=["/static/demo/RouterDemo.re.js"],
    ~document=
      children =>
        RouterPages.Document.make(
          RouterPages.Document.makeProps(~children, ()),
        ),
  );

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
      getAndPost(Routes.serverOnlyRSC, Pages.ServerOnlyRSC.handler),
      ...DreamRouter.routes(
           ~basePath=RouterRegistry.basePath,
           ~actionHandler=serverFunctionHandler,
           routerHandler,
         ),
    ]),
  );

let interface = {
  switch (Sys.getenv_opt("SERVER_INTERFACE")) {
  | Some(env) => env
  | None => "localhost"
  };
};

let port = {
  switch (Sys.getenv_opt("PORT")) {
  | Some(env) =>
    switch (int_of_string_opt(env)) {
    | Some(port) => port
    | None => failwith("PORT must be a number, got: " ++ env)
    }
  | None => 8080
  };
};

Dream.run(~port, ~interface, server);

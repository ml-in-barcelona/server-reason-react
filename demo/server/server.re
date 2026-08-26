let debug = Sys.getenv_opt("DEMO_ENV") == Some("development");

let serverFunctionHandler =
  DreamRouter.streamFunctionResponse(~debug, ~lookup=FunctionReferences.get);

let getAndPost = (path, handler) =>
  Dream.scope(
    "/",
    [],
    [Dream.get(path, handler), Dream.post(path, serverFunctionHandler)],
  );

let shouldSSR = request =>
  switch (Dream.query(request, "ssr")) {
  | Some("false") => false
  | Some("true")
  | Some(_)
  | None => true
  };

let server =
  Dream.logger(
    Dream.router([
      getAndPost("/", Examples.Home.handler),
      Dream.get("/demo", req => Dream.redirect(req, "/")),
      Dream.get(
        "/output.css",
        Dream.from_filesystem("./_build/default/demo", "output.css"),
      ),
      Dream.get(
        "/static/**",
        Dream.static("./_build/default/demo/client/dist"),
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
      getAndPost(Routes.renderToStream, Examples.Comments.handler),
      getAndPost(Routes.singlePageRSC, Examples.SinglePageRSC.handler),
      getAndPost(Routes.serverOnlyRSC, Examples.ServerOnlyRSC.handler),
      ...List.concat([
           DreamRouter.routes(
             ~router=RouterRegistry.server,
             ~actionHandler=serverFunctionHandler,
             ~ssr=shouldSSR,
             ~bootstrapModules=["/static/demo/RouterDemo.re.js"],
             ~document=children => <Pages.Document> children </Pages.Document>,
             (),
           ),
           DreamRouter.routes(
             ~router=Demo_hacker_news_router_native.RouterRegistry.server,
             ~actionHandler=serverFunctionHandler,
             ~ssr=_ => true,
             ~bootstrapModules=[],
             ~document=
               children =>
                 <Demo_hacker_news_router_native.Pages.Document>
                   children
                 </Demo_hacker_news_router_native.Pages.Document>,
             (),
           ),
         ]),
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

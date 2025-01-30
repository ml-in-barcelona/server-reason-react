let server =
  Dream.logger(
    Dream.router([
      Dream.get("/", Pages.Home.handler),
      Dream.get(
        "/static/**",
        Dream.static("./_build/default/demo/client/app"),
      ),
      Dream.get(Router.demoRenderToString, _request =>
        Dream.html(
          ReactDOM.renderToString(
            <Document script="/static/demo/client/hydrate-static-html.js">
              <App />
            </Document>,
          ),
        )
      ),
      Dream.get(Router.demoRenderToStaticMarkup, _request =>
        Dream.html(
          ReactDOM.renderToStaticMarkup(
            <Document script="/static/demo/client/hydrate-static-html.js">
              <App />
            </Document>,
          ),
        )
      ),
      Dream.get(Router.demoRenderToStream, Pages.Comments.handler),
      Dream.get(Router.demoCreateFromFetch, Pages.ServerOnlyRSC.handler),
      Dream.get(
        Router.demoCreateFromReadableStream,
        Pages.SinglePageRSC.handler,
      ),
      Dream.get(Router.demoRouter, Pages.RouterRSC.handler),
    ]),
  );

let interface = {
  switch (Sys.getenv_opt("SERVER_INTERFACE")) {
  | Some(env) => env
  | None => "localhost"
  };
};

Dream.run(~port=8080, ~interface, server);

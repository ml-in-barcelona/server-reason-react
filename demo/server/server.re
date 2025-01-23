let server =
  Dream.logger(
    Dream.router([
      Dream.get("/", Home.handler),
      Dream.get(
        "/static/**",
        Dream.static("./_build/default/demo/client/app"),
      ),
      Dream.get(Router.demoRenderToString, _request =>
        Dream.html(
          ReactDOM.renderToString(
            <Document script="/static/demo/client/index.js">
              <App />
            </Document>,
          ),
        )
      ),
      Dream.get(Router.demoRenderToStaticMarkup, _request =>
        Dream.html(
          ReactDOM.renderToStaticMarkup(
            <Document script="/static/demo/client/index.js">
              <App />
            </Document>,
          ),
        )
      ),
      Dream.get(Router.demoRenderToStream, Comments.handler),
      Dream.get(Router.demoCreateFromFetch, ServerOnlyRSC.handler),
      Dream.get(Router.demoCreateFromReadableStream, SinglePageRSC.handler),
      Dream.get(Router.demoRouter, RouterRSC.handler),
    ]),
  );

let interface = {
  switch (Sys.getenv_opt("SERVER_INTERFACE")) {
  | Some(env) => env
  | None => "localhost"
  };
};

Dream.run(~port=8080, ~interface, ~error_handler=Error.handler, server);

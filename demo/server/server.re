// Allow GET and POST from the same handler enables progressive enhancement.
// When JS is disabled, the browser will make a POST request into the same page (instead of a GET). The server should handle the form action and return the page.
// When JS is enabled, the page will make a POST request to the server with the action ID and the server will return the action response.
let getAndPost = (path, handler) =>
  Dream.scope(
    "/",
    [],
    [Dream.get(path, handler), Dream.post(path, Actions.handleRequest)],
  );

let server =
  Dream.logger(
    Dream.router([
      getAndPost("/", Pages.Home.handler),
      Dream.get(
        "/output.css",
        Dream.from_filesystem("./_build/default/demo", "output.css"),
      ),
      Dream.get(
        "/static/**",
        Dream.static("./_build/default/demo/client/app"),
      ),
      getAndPost(Router.demoRenderToString, _request =>
        Dream.html(
          ReactDOM.renderToString(
            <Document script="/static/demo/Hydrate.re.js"> <App /> </Document>,
          ),
        )
      ),
      getAndPost(Router.demoRenderToStaticMarkup, _request =>
        Dream.html(
          ReactDOM.renderToStaticMarkup(
            <Document script="/static/demo/Hydrate.re.js"> <App /> </Document>,
          ),
        )
      ),
      getAndPost(Router.demoRenderToStream, Pages.Comments.handler),
      getAndPost(Router.demoSinglePageRSC, Pages.SinglePageRSC.handler),
      getAndPost(Router.demoRouterRSC, Pages.RouterRSC.handler),
      getAndPost(Router.demoServerOnlyRSC, Pages.ServerOnlyRSC.handler),
    ]),
  );

let interface = {
  switch (Sys.getenv_opt("SERVER_INTERFACE")) {
  | Some(env) => env
  | None => "localhost"
  };
};

Dream.run(~port=8080, ~interface, server);

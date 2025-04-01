// This make possible to handle progressive enhancment on pages.
// If there is no JS or hydration the page will make a POST request to the server
// handling the action on the server and returning the page.
let getAndPost = (path, handler) =>
  Dream.scope(
    "/",
    [],
    [
      Dream.get(path, handler),
      Dream.post(
        path,
        request => {
          let actionId = Dream.header(request, "ACTION_ID");
          let contentType = Dream.header(request, "Content-Type");
          switch (contentType) {
          | Some(contentType) =>
            let response =
              Server_actions.Route.actionsHandler(contentType, actionId);
            switch (response) {
            | `FormData(handler') =>
              switch%lwt (Dream.multipart(request, ~csrf=false)) {
              | `Ok(formData) =>
                let%lwt response = handler'(formData);
                ActionsRSC.createFromRequest(request, response);
              | _ => failwith("Missing body")
              }
            | `Body(handler') =>
              let%lwt body = Dream.body(request);
              // QUESTION: Should we handle the response somewhere?
              let%lwt _ = handler'(body);
              handler(request);
            | `Error(error) => Dream.html(error)
            };
          | None => failwith("Missing Content-Type")
          };
        },
      ),
    ],
  );

let server =
  Dream.logger(
    Dream.router([
      getAndPost("/", Pages.Home.handler),
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
      getAndPost(
        Router.demoCreateFromReadableStream,
        Pages.SinglePageRSC.handler,
      ),
      getAndPost(Router.demoRouter, Pages.RouterRSC.handler),
      getAndPost(Router.demoCreateFromFetch, Pages.ServerOnlyRSC.handler),
    ]),
  );

let interface = {
  switch (Sys.getenv_opt("SERVER_INTERFACE")) {
  | Some(env) => env
  | None => "localhost"
  };
};

Dream.run(~port=8080, ~interface, server);

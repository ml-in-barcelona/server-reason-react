// Allow GET and POST from the same handler enables progressive enhancement.
// When JS is disabled, the browser will make a POST request into the same page (instead of a GET). The server should handle the form action and return the page.
// When JS is enabled, the page will make a POST request to the server with the action ID and the server will return the action response.
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
          let action_response =
            switch (contentType) {
            | Some(contentType)
                when
                  contentType
                  |> String.starts_with(~prefix="multipart/form-data") =>
              switch%lwt (Dream.multipart(request, ~csrf=false)) {
              | `Ok(formData) =>
                let%lwt response =
                  Server_actions.Route.actionsHandler(
                    FormData(formData),
                    actionId,
                  );
                DreamRSC.createActionFromRequest(
                  request,
                  React.Json(response),
                );
              | _ => failwith("Something went wrong")
              }
            | _ =>
              let%lwt body = Dream.body(request);
              let%lwt response =
                Server_actions.Route.actionsHandler(Body(body), actionId);
              DreamRSC.createActionFromRequest(
                request,
                React.Json(response),
              );
            };

          switch (actionId) {
          | Some(_) =>
            // If there is no action ID means that the page does not hydrate or has no JS.
            // Then we can execute the action and return the page.
            action_response
          | None =>
            // If there is no action ID means that the page does not hydrate or has no JS.
            // Then we can execute the action and return the page.
            // QUESTION: Should we handle the response here?
            handler(request)
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

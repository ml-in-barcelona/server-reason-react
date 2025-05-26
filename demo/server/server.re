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

          switch (contentType) {
          | Some(contentType)
              when
                String.starts_with(contentType, ~prefix="multipart/form-data") =>
            switch%lwt (Dream.multipart(request, ~csrf=false)) {
            | `Ok(formData) =>
              // For now we're using hashtbl for FormData as we still cannot support the Js.FormData.t.
              let formData =
                formData
                |> List.fold_left(
                     (acc, (name, value)) => {
                       // For now we're only supporting strings.
                       let (_filename, value) = value |> List.hd;
                       FormData.append(acc, name, `String(value));
                       acc;
                     },
                     FormData.make(),
                   );
              let response =
                ServerReference.formDataHandler(formData, actionId);
              DreamRSC.streamResponse(response);
            | _ =>
              failwith(
                "Missing form data, this request was not created by server-reason-react",
              )
            }
          | _ =>
            let%lwt body = Dream.body(request);
            let actionId =
              switch (actionId) {
              | Some(actionId) => actionId
              | None =>
                failwith(
                  "Missing action ID, this request was not created by server-reason-react",
                )
              };
            let response = ServerReference.bodyHandler(body, actionId);
            DreamRSC.streamResponse(response);
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

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

let splitListAt = (n, list) => {
  let rec aux = (i, acc, remaining_list) =>
    if (i == 0) {
      (List.rev(acc), remaining_list == [] ? [""] : remaining_list);
    } else {
      switch (remaining_list) {
      | [] => (List.rev(acc), [])
      | [h, ...t] => aux(i - 1, [h, ...acc], t)
      };
    };
  aux(n, [], list);
};

let rscRoutes = (basePath, handler) => {
  RouteDefinitions.generated_routes_paths
  |> List.map(path => {
       let path = path == "/" ? "" : path;

       [
         getAndPost(
           basePath ++ path ++ "/",
           request => {
             // Redirect when the route is accessed with a trailing slash
             Dream.log("Redirecting to /demo%s", path);
             let query = Dream.target(request) |> Dream.split_target |> snd;
             Dream.redirect(request, basePath ++ path ++ "?" ++ query);
           },
         ),
         getAndPost(
           basePath ++ path,
           request => {
             let url = {
               let protocol = Dream.tls(request) ? "https" : "http";
               let host =
                 switch (Dream.header(request, "Host")) {
                 | Some(h) => h
                 | None => ""
                 };
               let target = Dream.target(request);
               Printf.sprintf("%s://%s%s", protocol, host, target);
             };

             let routeSegments = String.split_on_char('/', path);
             let params = {
               let params = Supersonic.Params.create();
               routeSegments
               |> List.iter(segment =>
                    if (String.starts_with(segment, ~prefix=":")) {
                      let key =
                        segment->String.sub(1, String.length(segment) - 1);
                      Supersonic.Params.add(
                        params,
                        key,
                        Dream.param(request, key),
                      );
                    } else {
                      ();
                    }
                  );

               params;
             };

             /**
              * If the rsc query param is present, we need to render the specific route
              * based on the rsc path.
              */
             let rscParam = Dream.query(request, "rsc");

             let element =
               switch (rscParam) {
               | Some(rscPath) =>
                 let rscSegmentLevel =
                   (routeSegments |> List.length)
                   - (rscPath |> String.split_on_char('/') |> List.length);

                 /**
                  * To get the dynamic segments (/:id) we cannot get them from the rsc path
                  * but from the route path segments.
                  * We then split the route path into 2 lists:
                  * - the first list is the parent segments that aren't required but used to find the correct component
                  * - the second list is the rsc segments
                  * The list is split based on the number of segments in the rsc query param
                  */
                 let (parentSegments, rscSegments) =
                   splitListAt(rscSegmentLevel, routeSegments);

                 RouteDefinitions.(
                   routes
                   |> renderComponent(
                        request,
                        parentSegments,
                        rscSegments,
                        basePath,
                      )
                 )
                 |> Option.value(~default=React.null);
               | None =>
                 let routeData: Supersonic.RouterContext.routeData = {
                   params,
                   url: URL.makeExn(url),
                 };
                 <Supersonic.RouterContext.Provider routeData>
                   {switch (
                      RouteDefinitions.(
                        routes
                        |> renderByPath(request, routeSegments, ~basePath)
                      )
                    ) {
                    | Some(element) => element
                    | None => React.null
                    }}
                 </Supersonic.RouterContext.Provider>;
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
      ...rscRoutes(Routes.router, Pages.Router.handler),
    ]),
  );

let interface = {
  switch (Sys.getenv_opt("SERVER_INTERFACE")) {
  | Some(env) => env
  | None => "localhost"
  };
};

Dream.run(~port=8080, ~interface, server);

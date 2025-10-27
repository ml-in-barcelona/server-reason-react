type t = {
  path: string,
  layout:
    option(
      (
        ~children: React.element,
        ~params: Supersonic.Params.t,
        ~queryParams: Supersonic.Params.t
      ) =>
      React.element,
    ),
  page:
    option(
      (~params: Supersonic.Params.t, ~queryParams: Supersonic.Params.t) =>
      React.element,
    ),
  children: option(list(t)),
};

type app = {
  layout: (~children: React.element) => React.element,
  page: unit => React.element,
};

[@platform native]
module App = {
  [@react.async.component]
  let make =
      (~params: Hashtbl.t(string, string), ~queryParams: Supersonic.Params.t) => {
    // let%lwt _ = Lwt_unix.sleep(2.);
    Lwt.return(
      <>
        <div className="text-white text-6xl">
          {React.string("App Home")}
        </div>
      </>,
    );
  };
};

[@platform native]
let document = (~children, ~params, ~queryParams) =>
  <html>
    <head>
      <meta charSet="utf-8" />
      <link rel="stylesheet" href="/output.css" />
    </head>
    <body> children </body>
  </html>;

[@platform native]
let routes = [
  {
    path: "/",
    layout:
      Some(
        (~children, ~params, ~queryParams) => {
          <DemoLayout>
            <Supersonic.Navigation />
            <div className="text-white text-6xl"> children </div>
          </DemoLayout>
        },
      ),
    page: Some(App.make()),
    children:
      Some([
        {
          path: "/about",
          page: None,
          layout: Some((~children, ~params, ~queryParams) => children),
          children:
            Some([
              {
                path: "/work",
                layout:
                  Some(
                    (~children, ~params as _, ~queryParams as _) =>
                      <div className="text-white text-6xl">
                        <span> {React.string("\"/work\" Page")} </span>
                        children
                      </div>,
                  ),
                page: None,
                children: None,
              },
              {
                path: "/me",
                page:
                  Some(
                    (~params as _, ~queryParams as _) =>
                      <div className="text-white text-6xl">
                        <span> {React.string("\"/me\" Page")} </span>
                      </div>,
                  ),
                layout: None,
                children: None,
              },
            ]),
        },
        {
          path: "/dashboard",
          page:
            Some(
              (~params as _, ~queryParams as _) =>
                <div className="text-white text-6xl">
                  {React.string("\"/dashboard\" Page")}
                </div>,
            ),
          layout: None,
          children: None,
        },
        {
          path: "/profile",
          layout:
            Some(
              (~children, ~params as _, ~queryParams as _) =>
                <div className="text-white text-6xl"> children </div>,
            ),
          page:
            Some(
              (~params as _, ~queryParams as _) =>
                <div className="text-white text-6xl">
                  {React.string("\"/profile\" Page")}
                </div>,
            ),
          children:
            Some([
              {
                path: "/:id",
                page:
                  Some(
                    (~params, ~queryParams as _) => {
                      let id = Hashtbl.find(params, "id");
                      <div className="text-white text-6xl">
                        {React.string("\"/profile/:id\" Page")}
                        <br />
                        {React.string("id: " ++ id)}
                      </div>;
                    },
                  ),
                layout:
                  Some(
                    (~children, ~params as _, ~queryParams as _) => children,
                  ),
                children:
                  Some([
                    {
                      path: "/:name",
                      page:
                        Some(
                          (~params, ~queryParams as _) => {
                            let name = Hashtbl.find(params, "name");
                            let id = Hashtbl.find(params, "id");
                            <div className="text-white text-6xl">
                              {React.string("\"/profile/:id/:name\" Page")}
                              <br />
                              {React.string("id: " ++ id)}
                              <br />
                              {React.string("name: " ++ name)}
                            </div>;
                          },
                        ),
                      layout: None,
                      children: None,
                    },
                  ]),
              },
            ]),
        },
      ]),
  },
];

/**x
  Returns the component for the given path segments
  */
[@platform native]
let renderByPath =
    (
      ~basePath: string="",
      ~params: Supersonic.Params.t,
      ~queryParams: Supersonic.Params.t,
      request: Dream.request,
      pathSegments: list(string),
      routes: list(t),
    ) => {
  let rec aux =
          (routes: list(t), pathSegments: list(string), parentPath)
          : option(React.element) => {
    switch (routes, pathSegments) {
    | ([route, ...routes], []) => aux(routes, [], parentPath)
    | ([route, ...routes], [pathSegment, ...remainingSegments]) =>
      if (route.path == "/" ++ pathSegment) {
        let component =
          switch (route.children) {
          | Some(children) =>
            let path = parentPath ++ (route.path == "/" ? "" : route.path);
            <Supersonic.Route
              path
              outlet={
                Some(
                  {
                    switch (aux(children, remainingSegments, path)) {
                    | Some(component) => component
                    | None =>
                      route.page
                      |> Option.map(page => page(~params, ~queryParams))
                      |> Option.value(~default=React.null)
                    };
                  },
                )
              }>
              {switch (route.layout) {
               | Some(layout) =>
                 layout(
                   ~children=<Supersonic.Outlet />,
                   ~params,
                   ~queryParams,
                 )
               | None =>
                 (
                   route.page
                   |> Option.value(~default=(~params as _, ~queryParams as _) =>
                        React.null
                      )
                 )(
                   ~params,
                   ~queryParams,
                 )
               }}
            </Supersonic.Route>;
          | None =>
            <Supersonic.Route
              path={parentPath ++ (route.path == "/" ? "" : route.path)}
              outlet=None>
              {switch (route.layout) {
               | Some(layout) =>
                 layout(~children=React.null, ~params, ~queryParams)
               | None =>
                 (
                   route.page
                   |> Option.value(~default=(~params as _, ~queryParams as _) =>
                        React.null
                      )
                 )(
                   ~params,
                   ~queryParams,
                 )
               }}
            </Supersonic.Route>
          };
        Some(component);
      } else {
        aux(routes, pathSegments, parentPath);
      }
    | _ => None
    };
  };

  aux(routes, pathSegments, basePath);
};

/**
  Generate all possible routes paths
 */
[@platform native]
let generated_routes_paths = {
  let rec aux = (routes: list(t), parentPath: string): list(string) => {
    switch (routes) {
    | [] => []
    | [route, ...remainingRoutes] =>
      let fullPath =
        if (parentPath == "/") {
          route.path;
        } else {
          parentPath ++ route.path;
        };

      let childRoutes =
        switch (route.children) {
        | Some(children) => aux(children, fullPath)
        | None => []
        };

      [fullPath] @ childRoutes @ aux(remainingRoutes, parentPath);
    };
  };

  aux(routes, "");
};

/**
  Render only the component for the given path segments
  Using the parents segments to find the correct component
  */
[@platform native]
let renderComponent =
    (
      ~params,
      ~queryParams,
      request: Dream.request,
      parentSegments: list(string),
      pathSegments: list(string),
      basePath: string,
      routes: list(t),
    ) => {
  let rec aux =
          (routes: list(t), parentSegments: list(string))
          : option(React.element) => {
    switch (routes, parentSegments) {
    | (routes, []) =>
      renderByPath(
        ~basePath,
        ~params,
        ~queryParams,
        request,
        pathSegments,
        routes,
      )
    | ([route, ...routes], [parentSegment, ...remainingSegments]) =>
      if (route.path == "/" ++ parentSegment) {
        switch (route.children) {
        | Some(children) => aux(children, remainingSegments)
        | _ => route.page |> Option.map(page => page(~params, ~queryParams))
        };
      } else {
        aux(routes, parentSegments);
      }
    | _ => None
    };
  };

  switch (parentSegments, pathSegments) {
  // Root page
  | ([], [""]) =>
    Js.log("Root page");
    routes
    |> List.hd
    |> (
      route => route.page |> Option.map(page => page(~params, ~queryParams))
    );
  | _ => aux(routes, parentSegments)
  };
};

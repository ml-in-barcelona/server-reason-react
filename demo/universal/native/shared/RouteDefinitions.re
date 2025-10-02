type t = {
  path: string,
  layout: option((~children: React.element) => React.element),
  page: option((~params: Hashtbl.t(string, string)) => React.element),
  children: option(list(t)),
};

type app = {
  layout: (~children: React.element) => React.element,
  page: unit => React.element,
};

[@platform native]
let routes = [
  {
    path: "/",
    layout:
      Some(
        (~children) =>
          <>
            <Supersonic.Navigation />
            <div className="text-white text-6xl"> children </div>
          </>,
      ),
    page:
      Some(
        (~params as _) =>
          <span className="text-white text-6xl">
            <span> {React.string("\"home\" Page")} </span>
          </span>,
      ),
    children:
      Some([
        {
          path: "/about",
          page: None,
          layout: Some((~children) => children),
          children:
            Some([
              {
                path: "/work",
                layout:
                  Some(
                    (~children) =>
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
                    (~params as _) =>
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
              (~params as _) =>
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
              (~children) =>
                <div className="text-white text-6xl"> children </div>,
            ),
          page:
            Some(
              (~params as _) =>
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
                    (~params) => {
                      let id = Hashtbl.find(params, "id");
                      <div className="text-white text-6xl">
                        {React.string("\"/profile/:id\" Page")}
                        <br />
                        {React.string("id: " ++ id)}
                      </div>;
                    },
                  ),
                layout: Some((~children) => children),
                children:
                  Some([
                    {
                      path: "/:name",
                      page:
                        Some(
                          (~params) => {
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

/**
  Returns the component for the given path segments
  */
[@platform native]
let renderByPath =
    (
      ~basePath: string="",
      ~params: Hashtbl.t(string, string)=Hashtbl.create(5),
      request: Dream.request,
      pathSegments: list(string),
      routes: list(t),
    ) => {
  let rec aux =
          (routes: list(t), pathSegments: list(string), params, parentPath)
          : option(React.element) => {
    switch (routes, pathSegments) {
    | ([route, ...routes], []) => aux(routes, [], params, parentPath)
    | ([route, ...routes], [pathSegment, ...remainingSegments]) =>
      if (String.starts_with(pathSegment, ~prefix=":")) {
        // Add param to the Hashtbl
        let key = pathSegment->String.sub(1, String.length(pathSegment) - 1);
        Hashtbl.add(params, key, Dream.param(request, key));
      };

      if (route.path == "/" ++ pathSegment) {
        let component =
          switch (route.children) {
          | Some(children) =>
            let path = parentPath ++ (route.path == "/" ? "" : route.path);
            <Supersonic.Route
              path
              outlet={
                switch (aux(children, remainingSegments, params, path)) {
                | Some(component) => Some(component)
                | None => route.page |> Option.map(page => page(~params))
                }
              }>
              {switch (route.layout) {
               | Some(layout) => layout(~children=<Supersonic.Outlet />)
               | None =>
                 (
                   route.page
                   |> Option.value(~default=(~params as _) => React.null)
                 )(
                   ~params,
                 )
               }}
            </Supersonic.Route>;
          | None =>
            <Supersonic.Route
              path={parentPath ++ (route.path == "/" ? "" : route.path)}
              outlet=None>
              {switch (route.layout) {
               | Some(layout) => layout(~children=React.null)
               | None =>
                 (
                   route.page
                   |> Option.value(~default=(~params as _) => React.null)
                 )(
                   ~params,
                 )
               }}
            </Supersonic.Route>
          };
        Some(component);
      } else {
        aux(routes, pathSegments, params, parentPath);
      };
    | _ => None
    };
  };

  aux(routes, pathSegments, params, basePath);
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
      request: Dream.request,
      parentSegments: list(string),
      pathSegments: list(string),
      basePath: string,
      routes: list(t),
    ) => {
  let rec aux =
          (
            routes: list(t),
            parentSegments: list(string),
            params: Hashtbl.t(string, string),
          )
          : option(React.element) => {
    switch (routes, parentSegments) {
    | (routes, []) => renderByPath(~basePath, request, pathSegments, routes)
    | ([route, ...routes], [parentSegment, ...remainingSegments]) =>
      let _ =
        String.starts_with(parentSegment, ~prefix=":")
          ? {
            let key =
              parentSegment->String.sub(1, String.length(parentSegment) - 1);
            Hashtbl.add(params, key, Dream.param(request, key));
          }
          : ();

      if (route.path == "/" ++ parentSegment) {
        switch (route.children) {
        | Some(children) => aux(children, remainingSegments, params)
        | _ =>
          route.page |> Option.map(page => page(~params=Hashtbl.create(10)))
        };
      } else {
        aux(routes, parentSegments, params);
      };
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
      route =>
        route.page |> Option.map(page => page(~params=Hashtbl.create(0)))
    );
  | _ => aux(routes, parentSegments, Hashtbl.create(5))
  };
};

type t = {
  path: string,
  layout: option((~children: React.element) => React.element),
  page: option(unit => React.element),
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
        () =>
          <span className="text-white text-6xl">
            <span> {React.string("\"Home\" Page")} </span>
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
                        <span> {React.string("\"/Work\" Page")} </span>
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
                    () =>
                      <div className="text-white text-6xl">
                        <span> {React.string("\"/Me\" Page")} </span>
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
              () =>
                <div className="text-white text-6xl">
                  {React.string("\"/Dashboard\" Page")}
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
          page: None,
          children:
            Some([
              {
                path: "/123",
                page:
                  Some(
                    () =>
                      <div className="text-white text-6xl">
                        {React.string("\"/Profile/123\" Page")}
                      </div>,
                  ),
                layout: None,
                children: None,
              },
              {
                path: "/:id",
                page:
                  Some(
                    () =>
                      <div className="text-white text-6xl">
                        {React.string("\"/Profile/:id\" Page")}
                      </div>,
                  ),
                layout: None,
                children: None,
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
    (~level: int=0, pathSegments: list(string), routes: list(t)) => {
  let rec aux =
          (routes: list(t), pathSegments: list(string), level: int)
          : option(React.element) => {
    switch (routes, pathSegments) {
    | ([route, ...routes], []) => aux(routes, [], level)
    | ([route, ...routes], [pathSegment, ...remainingSegments]) =>
      Dream.log("pathSegment %s", pathSegment);
      let pathSegment = pathSegment == "/" ? "" : pathSegment;
      if (route.path == "/" ++ pathSegment) {
        let component =
          switch (route.children) {
          | Some(children) =>
            <Supersonic.Route
              level
              path={route.path}
              outlet={
                switch (aux(children, remainingSegments, level + 1)) {
                | Some(component) => Some(component)
                | None => route.page |> Option.map(page => page())
                }
              }>
              {switch (route.layout) {
               | Some(layout) => layout(~children=<Supersonic.Outlet />)
               | None =>
                 (route.page |> Option.value(~default=() => React.null))()
               }}
            </Supersonic.Route>
          | None =>
            <Supersonic.Route level path={route.path} outlet=None>
              {switch (route.layout) {
               | Some(layout) => layout(~children=React.null)
               | None =>
                 (route.page |> Option.value(~default=() => React.null))()
               }}
            </Supersonic.Route>
          };
        Some(component);
      } else {
        aux(routes, pathSegments, level);
      };
    | _ => None
    };
  };

  aux(routes, pathSegments, level);
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
      parentSegments: list(string),
      pathSegments: list(string),
      routes: list(t),
    ) => {
  let rec aux =
          (routes: list(t), parentSegments: list(string), level: int)
          : option(React.element) => {
    switch (routes, parentSegments) {
    | (routes, []) => renderByPath(~level, pathSegments, routes)
    | ([route, ...routes], [parentSegment, ...remainingSegments]) =>
      let pathSegment = parentSegment == "" ? "/" : "/" ++ parentSegment;

      if (route.path == pathSegment) {
        switch (route.children) {
        | Some(children) => aux(children, remainingSegments, level + 1)
        | _ => route.page |> Option.map(page => page())
        };
      } else {
        aux(routes, parentSegments, level);
      };

    | _ => None
    };
  };

  switch (parentSegments, pathSegments) {
  // Root page
  | ([""], [""]) =>
    routes
    |> List.find(route => route.path == "/")
    |> (route => route.page |> Option.map(page => page()))
  | _ => aux(routes, parentSegments, 0)
  };
};

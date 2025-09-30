type t = {
  path: string,
  component: React.element,
  children: option(list(t)),
};

[@platform native]
let routes = [
  {
    path: "/router",
    component:
      <>
        <Supersonic.Navigation />
        <div className="text-white text-6xl"> <Supersonic.Outlet /> </div>
      </>,
    children:
      Some([
        {
          path: "/",
          component:
            <span className="text-white text-6xl">
              <span> {React.string("\"Home\" Page")} </span>
            </span>,
          children: None,
        },
        {
          path: "/about",
          component:
            <div className="text-white text-6xl">
              <span> {React.string("\"About\" Page")} </span>
              <Supersonic.Outlet />
            </div>,
          children:
            Some([
              {
                path: "/me",
                component:
                  <div className="text-white text-6xl">
                    <span> {React.string("\"/Me\" Page")} </span>
                    <Supersonic.Outlet />
                  </div>,
                children: None,
              },
            ]),
        },
        {
          path: "/dashboard",
          component:
            <div className="text-white text-6xl">
              {React.string("\"/Dashboard\" Page")}
            </div>,
          children: None,
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
          (
            routes: list(t),
            pathSegments: list(string),
            parentPath: string,
            level: int,
          ) => {
    switch (routes, pathSegments) {
    | ([route, ...routes], []) =>
      if (route.path == "/") {
        aux([route], [""], parentPath, level);
      } else {
        aux(routes, [], parentPath, level);
      }
    | ([route, ...routes], [pathSegment, ...remainingSegments]) =>
      if (route.path == "/" ++ pathSegment) {
        let component =
          switch (route.children) {
          | Some(children) =>
            <Supersonic.Route
              level
              path={route.path}
              outlet={aux(
                children,
                remainingSegments,
                if (parentPath == "/") {
                  route.path;
                } else {
                  parentPath ++ route.path;
                },
                level + 1,
              )}>
              {route.component}
            </Supersonic.Route>
          | None =>
            <Supersonic.Route level path={route.path} outlet=React.null>
              {route.component}
            </Supersonic.Route>
          };
        component;
      } else {
        aux(routes, pathSegments, parentPath, level);
      }
    | _ => React.null
    };
  };
  aux(routes, pathSegments, "/", level);
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
  let rec aux = (routes: list(t), parentSegments: list(string), level: int) => {
    switch (routes, parentSegments) {
    | (routes, []) => renderByPath(~level, pathSegments, routes)
    | ([route, ...routes], [pathSegment, ...remainingSegments]) =>
      if (route.path == "/" ++ pathSegment) {
        switch (route.children) {
        | Some(children) => aux(children, remainingSegments, level + 1)
        | None => route.component
        };
      } else {
        aux(routes, parentSegments, level);
      }

    | _ => React.null
    };
  };
  aux(routes, parentSegments, 0);
};

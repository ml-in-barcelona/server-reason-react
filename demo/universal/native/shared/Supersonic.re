module RouterContext = {
  type t = {
    navigate: (~replace: bool, string) => unit,
    currentPath: string,
  };

  let context: React.Context.t(t) =
    React.createContext({
      navigate: (~replace as _, _) => (),
      currentPath: "/",
    });

  [@platform js]
  module Provider = {
    let provider = React.Context.provider(context);

    [@react.component]
    let make = (~value, ~children) => {
      React.createElement(
        provider,
        {
          "value": value,
          "children": children,
        },
      );
    };
  };

  [@platform native]
  module Provider = {
    [@react.component]
    let make = (~value as _, ~children) => {
      children;
    };
  };
};

let useNavigate = () => {
  let { RouterContext.navigate, _ } =
    React.useContext(RouterContext.context);
  navigate;
};

let useLocation = () => {
  let { RouterContext.currentPath, _ } =
    React.useContext(RouterContext.context);
  currentPath;
};

module RouteRegistry = {
  type route = {
    path: string,
    element: React.element,
    loader: option(unit => Js.Promise.t(React.element)),
  };

  let routes = ref([]);

  let register = (~path, ~element, ~loader=?, ()) => {
    let filteredRoutes = List.filter(route => route.path != path, routes^);

    routes :=
      [
        {
          path,
          element,
          loader,
        },
        ...filteredRoutes,
      ];
  };

  let find = (path: string) => {
    List.find_opt(route => route.path == path, routes^);
  };

  let clear = () => {
    routes := [];
  };

  let getAllRoutes = () => {
    routes^;
  };
};

[@platform js]
module Router = {
  module DOM = Webapi.Dom;
  module Location = DOM.Location;
  module History = DOM.History;

  [@react.client.component]
  let make = (~children: React.element) => {
    let location = DOM.window->DOM.Window.location;
    let initialPath = Location.pathname(location);

    let (currentPath, setCurrentPath) = React.useState(() => initialPath);
    let (currentElement, setCurrentElement) =
      React.useState(() => React.null);
    let (isLoading, setIsLoading) = React.useState(() => false);

    let rscNavigation = (~replace as _, path: string) => {
      setIsLoading(_ => true);

      let headers =
        Fetch.HeadersInit.make({ "Accept": "application/react.component" });
      Fetch.fetchWithInit(
        path,
        Fetch.RequestInit.make(~method_=Fetch.Get, ~headers, ()),
      )
      |> Js.Promise.then_(response => {
           let body = Fetch.Response.body(response);
           ReactServerDOMEsbuild.createFromReadableStream(body);
         })
      |> Js.Promise.then_(element => {
           React.startTransition(() => {
             setCurrentElement(_ => element);
             setIsLoading(_ => false);
           });
           Js.Promise.resolve();
         })
      |> Js.Promise.catch(error => {
           Js.log2("Navigation error:", error);
           setIsLoading(_ => false);
           Js.Promise.resolve();
         })
      |> ignore;
    };

    /* let navigate = (~replace, path: string) => {
            let currentLocation = DOM.window->DOM.Window.location;
            let currentPath = Location.pathname(currentLocation);
            Js.log("NAVIGATE!");
            Js.log2("currentPath", currentPath);
            Js.log2("path", path);

            if (currentPath != path) {
              if (replace) {
                History.replaceState(
                  History.state(DOM.history),
                  "",
                  path,
                  DOM.history,
                );
              } else {
                History.pushState(
                  History.state(DOM.history),
                  "",
                  path,
                  DOM.history,
                );
              };

              setCurrentPath(_ => path);

              switch (RouteRegistry.find(path)) {
              | Some({loader: Some(loaderFn), _}) =>
                setIsLoading(_ => true);
                loaderFn()
                |> Js.Promise.then_(element => {
                     React.startTransition(() => {
                       setCurrentElement(_ => element);
                       setIsLoading(_ => false);
                     });
                     Js.Promise.resolve();
                   })
                |> ignore;
              | Some({element, _}) => setCurrentElement(_ => element)
              | None => rscNavigation(path)
              };
            };
          };
       */
    let popStateHandler = () => {
      let handlePopState = _ => {
        let newPath = Location.pathname(DOM.window->DOM.Window.location);
        setCurrentPath(_ => newPath);

        switch (RouteRegistry.find(newPath)) {
        | Some({ element, _ }) => setCurrentElement(_ => element)
        | None => rscNavigation(~replace=false, newPath)
        };
      };

      DOM.window |> DOM.Window.addEventListener("popstate", handlePopState);

      Some(
        () => {
          DOM.window
          |> DOM.Window.removeEventListener("popstate", handlePopState)
        },
      );
    };

    React.useEffect0(popStateHandler);

    let initialRouteResolution = () => {
      switch (RouteRegistry.find(currentPath)) {
      | Some({ element, loader, _ }) =>
        switch (loader) {
        | Some(loaderFn) =>
          loaderFn()
          |> Js.Promise.then_(element => {
               setCurrentElement(_ => element);
               Js.Promise.resolve();
             })
          |> ignore
        | None => setCurrentElement(_ => element)
        }
      | None =>
        /* Try loading from RSC */
        rscNavigation(~replace=false, currentPath)
      };
      None;
    };

    React.useEffect1(initialRouteResolution, [|currentPath|]);

    let contextValue: RouterContext.t = {
      navigate: rscNavigation,
      currentPath,
    };

    <RouterContext.Provider value=contextValue>
      children
      {isLoading ? <div> {React.string("Loading...")} </div> : currentElement}
    </RouterContext.Provider>;
  };
};

[@platform native]
module Router = {
  [@react.component]
  let make = (~children) => {
    children;
  };
};

module Route = {
  [@react.component]
  let make = (~path: string, ~component: option(React.element)=?) => {
    /* ~loader: option(unit => Js.Promise.t(React.element))=?, */

    /* let loader = () => {
         switch%platform (Runtime.platform) {
         | Server => ()
         | Client =>
           let headers =
             Fetch.HeadersInit.make({"Accept": "application/react.component"});

             Fetch.fetchWithInit(
               path,
               Fetch.RequestInit.make(~method_=Fetch.Get, ~headers, ()),
             )
             |> Js.Promise.then_(response => {
                  let body = Fetch.Response.body(response);
                  ReactServerDOMEsbuild.createFromReadableStream(body);
                });
         };
       }; */

    RouteRegistry.register(
      ~path,
      ~element=
        switch (component) {
        | Some(el) => el
        | None => React.null
        },
      (),
    );

    React.null;
  };
};

module Link = {
  [@react.component]
  let make = (~to_: string, ~children, ~replace=false, ~className=?) => {
    let navigate = useNavigate();
    let currentPath = useLocation();

    let handleClick = (e: React.Event.Mouse.t) => {
      React.Event.Mouse.preventDefault(e);
      Js.log("to_ " ++ to_);
      navigate(~replace, to_);
    };

    let className =
      switch (className) {
      | Some(cls) => cls ++ (currentPath == to_ ? "font-bold" : "")
      | None => currentPath == to_ ? "font-bold" : ""
      };

    <button onClick=handleClick className> children </button>;
  };
};

module Navigation = {
  [@react.component]
  let make = () => {
    <nav className="flex space-x-4">
      <Link to_="/demo/router" className="text-white">
        {React.string("Home")}
      </Link>
      <Link to_="/demo/router/about" className="text-white">
        {React.string("About")}
      </Link>
      <Link to_="/demo/router/dashboard" className="text-white">
        {React.string("Dashboard")}
      </Link>
    </nav>;
  };
};

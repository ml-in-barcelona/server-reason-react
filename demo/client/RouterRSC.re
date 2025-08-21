module DOM = Webapi.Dom;
module Location = DOM.Location;
module History = DOM.History;
module ReadableStream = Webapi.ReadableStream;

[@mel.module "react"]
external startTransition: (unit => unit) => unit = "startTransition";
external readable_stream: ReadableStream.t =
  "window.srr_stream.readable_stream";

let fetchApp = url => {
  let headers =
    Fetch.HeadersInit.make({"Accept": "application/react.component"});
  Fetch.fetchWithInit(
    url,
    Fetch.RequestInit.make(~method_=Fetch.Get, ~headers, ()),
  );
};

/* Router Context for sharing navigation state */
module RouterContext = {
  type t = {
    navigate: string => unit,
    currentPath: string,
  };

  let context =
    React.createContext({
      navigate: _ => (),
      currentPath: "/",
    });

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
};

/* Hook to access navigation */
let useNavigate = () => {
  let {RouterContext.navigate, _} = React.useContext(RouterContext.context);
  navigate;
};

/* Hook to access current path */
let useLocation = () => {
  let {RouterContext.currentPath, _} =
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
    routes :=
      [
        {
          path,
          element,
          loader,
        },
        ...routes^,
      ];
  };

  let find = (path: string) => {
    List.find_opt(route => route.path == path, routes^);
  };

  let clear = () => {
    routes := [];
  };
};

/* Main Router Component */
module Router = {
  [@react.component]
  let make = (~children) => {
    let location = DOM.window->DOM.Window.location;
    let initialPath = Location.pathname(location);

    let (currentPath, setCurrentPath) = React.useState(() => initialPath);
    let (currentElement, setCurrentElement) =
      React.useState(() => React.null);
    let (isLoading, setIsLoading) = React.useState(() => false);

    let navigateWithRSC = (path: string) => {
      setIsLoading(_ => true);

      let headers =
        Fetch.HeadersInit.make({"Accept": "application/react.component"});
      Fetch.fetchWithInit(
        path,
        Fetch.RequestInit.make(~method_=Fetch.Get, ~headers, ()),
      )
      |> Js.Promise.then_(response => {
           let body = Fetch.Response.body(response);
           ReactServerDOMEsbuild.createFromReadableStream(body);
         })
      |> Js.Promise.then_(element => {
           startTransition(() => {
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

    let navigate = (path: string) => {
      let currentLocation = DOM.window->DOM.Window.location;
      let currentPath = Location.pathname(currentLocation);

      if (currentPath != path) {
        History.pushState(History.state(DOM.history), "", path, DOM.history);

        setCurrentPath(_ => path);

        switch (RouteRegistry.find(path)) {
        | Some({loader: Some(loaderFn), _}) =>
          setIsLoading(_ => true);
          loaderFn()
          |> Js.Promise.then_(element => {
               startTransition(() => {
                 setCurrentElement(_ => element);
                 setIsLoading(_ => false);
               });
               Js.Promise.resolve();
             })
          |> ignore;
        | Some({element, _}) => setCurrentElement(_ => element)
        | None => navigateWithRSC(path)
        };
      };
    };

    /* Handle browser back/forward */
    React.useEffect0(() => {
      let handlePopState = _ => {
        let newPath = Location.pathname(DOM.window->DOM.Window.location);
        setCurrentPath(_ => newPath);

        switch (RouteRegistry.find(newPath)) {
        | Some({element, _}) => setCurrentElement(_ => element)
        | None => navigateWithRSC(newPath)
        };
      };

      DOM.window |> DOM.Window.addEventListener("popstate", handlePopState);

      Some(
        () => {
          DOM.window
          |> DOM.Window.removeEventListener("popstate", handlePopState)
        },
      );
    });

    /* Initial route resolution */
    React.useEffect1(
      () => {
        switch (RouteRegistry.find(currentPath)) {
        | Some({element, loader, _}) =>
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
          navigateWithRSC(currentPath)
        };
        None;
      },
      [|currentPath|],
    );

    let contextValue = {
      RouterContext.navigate,
      currentPath,
    };

    <RouterContext.Provider value=contextValue>
      children
      {isLoading ? <div> {React.string("Loading...")} </div> : currentElement}
    </RouterContext.Provider>;
  };
};

module Route = {
  [@react.component]
  let make =
      (
        ~path: string,
        ~element: option(React.element)=?,
        ~loader: option(unit => Js.Promise.t(React.element))=?,
        ~children: option(React.element)=?,
      ) => {
    React.useEffect0(() => {
      let routeElement =
        switch (element, children) {
        | (Some(el), _) => el
        | (None, Some(ch)) => ch
        | (None, None) => React.null
        };

      RouteRegistry.register(~path, ~element=routeElement, ~loader?, ());

      Some(() => {()});
    });

    React.null;
  };
};

module Link = {
  [@react.component]
  let make = (~to_: string, ~children, ~className=?) => {
    let navigate = useNavigate();

    let handleClick = (e: React.Event.Mouse.t) => {
      React.Event.Mouse.preventDefault(e);
      navigate(to_);
    };

    <a href=to_ onClick=handleClick ?className> children </a>;
  };
};

module RSCRoute = {
  [@react.component]
  let make = (~path: string) => {
    let loader = () => {
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

    <Route path loader />;
  };
};

module SinglePageApp = {
  [@react.component]
  let make = () => {
    <Router>
      <Route path="/" element={<div> {React.string("Home")} </div>} />
      <Route path="/about"> <div> {React.string("About")} </div> </Route>
      <RSCRoute path="/dashboard" />
      <RSCRoute path="/profile" />
      <Route
        path="/app"
        loader={() => {
          fetchApp("/app")
          |> Js.Promise.then_(response => {
               let body = Fetch.Response.body(response);
               ReactServerDOMEsbuild.createFromReadableStream(body);
             })
        }}
      />
    </Router>;
  };
};

/* Navigation Example Component */
module Navigation = {
  [@react.component]
  let make = () => {
    let currentPath = useLocation();

    <nav>
      <Link to_="/" className={currentPath == "/" ? "active" : ""}>
        {React.string("Home")}
      </Link>
      <Link to_="/about" className={currentPath == "/about" ? "active" : ""}>
        {React.string("About")}
      </Link>
      <Link
        to_="/dashboard"
        className={currentPath == "/dashboard" ? "active" : ""}>
        {React.string("Dashboard")}
      </Link>
    </nav>;
  };
};

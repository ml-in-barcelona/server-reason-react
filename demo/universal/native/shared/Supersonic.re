let findPathDifference = (path1: list(string), path2: list(string)) => {
  let rec findCommonPrefix = (p1, p2, acc) => {
    switch (p1, p2) {
    | ([h1, ...t1], [h2, ...t2]) when h1 == h2 =>
      findCommonPrefix(t1, t2, [h1, ...acc])
    | (_, remaining2) => (List.rev(acc), remaining2)
    };
  };

  findCommonPrefix(path1, path2, []);
};

module RouteRegistry = {
  type route = {
    level: int,
    path: string,
    loader: option((string, string) => unit),
  };

  let routes = ref([]);

  let register = (~path, ~level, ~loader=?, ()) => {
    let filteredRoutes = List.filter(route => route.path != path, routes^);

    routes :=
      filteredRoutes
      @ [
        {
          path,
          level,
          loader,
        },
      ];
  };

  let find = (level: int) => {
    List.find_opt(route => route.level == level, routes^);
  };

  let clear = () => {
    routes := [];
  };

  let clearAboveLevel = (level: int) => {
    routes := List.filter(route => route.level < level, routes^);
  };

  let getAllRoutes = () => {
    routes^;
  };
};

module RouterContext = {
  type route = {
    level: int,
    path: string,
    loader: (string, string) => unit,
  };

  type t = {navigate: (~replace: bool, string) => unit};

  let context: React.Context.t(t) =
    React.createContext({navigate: (~replace as _, _) => ()});

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

[@mel.scope "window"] [@mel.set]
external setNavigate:
  (Webapi.Dom.Window.t, (~replace: bool, string) => unit) => unit =
  "__navigate";

[@platform js]
external navigate: (~replace: bool, string) => unit = "window.__navigate";

module DOM = Webapi.Dom;
module Location = DOM.Location;
module History = DOM.History;

module Router = {
  [@react.client.component]
  let make = (~children: React.element) =>
    switch%platform (Runtime.platform) {
    | Server => children
    | Client =>
      let rscNavigation = (~replace as _, path: string) => {
        let location = DOM.window->DOM.Window.location;
        let curPath =
          Location.pathname(location)
          ->String.sub(5, String.length(Location.pathname(location)) - 5)
          |> String.split_on_char('/');
        let pathSegments =
          path->String.sub(5, String.length(path) - 5)
          |> String.split_on_char('/');
        let (commonPrefix, remainingDifference) =
          findPathDifference(curPath, pathSegments);

        let route: option(RouteRegistry.route) =
          RouteRegistry.find((commonPrefix |> List.length) - 2);

        switch (route) {
        | Some(route) =>
          switch (route.loader) {
          | Some(loader) =>
            loader(
              commonPrefix |> String.concat("/"),
              remainingDifference |> String.concat("/"),
            )
          | None => ()
          }
        | None => ()
        };
        Js.log(RouteRegistry.getAllRoutes());
        RouteRegistry.clearAboveLevel((commonPrefix |> List.length) - 1);
        Js.log(RouteRegistry.getAllRoutes());
        let origin = Location.origin(location);

        let finalURL =
          URL.makeExn(
            origin
            ++ "/demo"
            ++ (commonPrefix |> String.concat("/"))
            ++ "/"
            ++ (remainingDifference |> String.concat("/")),
          );
        History.pushState(
          History.state(DOM.history),
          "",
          URL.toString(finalURL),
          DOM.history,
        )
        |> ignore;
      };

      // let popStateHandler = () => {
      //   let handlePopState = _ => {
      //     let newPath = Location.pathname(DOM.window->DOM.Window.location);
      //     setCurrentPath(_ => newPath);

      //     switch (RouteRegistry.find(newPath)) {
      //     | Some({element, _}) => setCurrentElement(_ => element)
      //     | None => rscNavigation(~replace=false, newPath)
      //     };
      //   };

      //   DOM.window |> DOM.Window.addEventListener("popstate", handlePopState);

      //   Some(
      //     () => {
      //       DOM.window
      //       |> DOM.Window.removeEventListener("popstate", handlePopState)
      //     },
      //   );
      // };

      setNavigate(Webapi.Dom.window, rscNavigation);

      // React.useEffect0(popStateHandler);

      children;
    };
};

module RouteContext = {
  type t = React.element;

  let context = React.createContext(React.null);
};

module RouteContextProvider = {
  let provider = React.Context.provider(RouteContext.context);
  [@react.client.component]
  let make = (~value: React.element, ~children: React.element) => {
    switch%platform (Runtime.platform) {
    | Client =>
      React.createElement(
        provider,
        {
          "value": value,
          "children": children,
        },
      )
    | Server => provider(~value, ~children, ())
    };
  };
};

module Route = {
  open Melange_json.Primitives;

  [@react.client.component]
  let make =
      (
        ~path: string,
        ~children: React.element,
        ~outlet: React.element,
        ~level: int,
      ) => {
    let (outlet, setOutlet) = React.useState(() => outlet);

    let%browser_only loader = (commonPrefix, remainingDifference) => {
      let headers =
        Fetch.HeadersInit.make({"Accept": "application/react.component"});
      Fetch.fetchWithInit(
        "/demo" ++ commonPrefix ++ "?rsc=" ++ remainingDifference,
        Fetch.RequestInit.make(~method_=Fetch.Get, ~headers, ()),
      )
      |> ReactServerDOMEsbuild.createFromFetch
      |> Js.Promise.then_(element => {
           setOutlet(_ =>
             <React.Fragment
               key={commonPrefix ++ "?rsc=" ++ remainingDifference}>
               element
             </React.Fragment>
           );
           Js.Promise.resolve();
         })
      |> ignore;
    };

    React.useEffect0(() => {
      RouteRegistry.register(~level, ~loader, ~path, ());
      None;
    });

    <RouteContextProvider key=path value=outlet>
      children
    </RouteContextProvider>;
  };
};

module Outlet = {
  [@react.client.component]
  let make = () => {
    let value = React.useContext(RouteContext.context);

    value;
  };
};

module Link = {
  open Melange_json.Primitives;

  [@react.client.component]
  let make =
      (
        ~to_: string,
        ~children: React.element,
        ~replace: bool=false,
        ~className: option(string)=?,
      ) => {
    let handleClick = (e: React.Event.Mouse.t) => {
      React.Event.Mouse.preventDefault(e);
      navigate(~replace, to_);
    };

    <button onClick=handleClick ?className> children </button>;
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
      <Link to_="/demo/router/about/me" className="text-white">
        {React.string("About 1")}
      </Link>
      <Link to_="/demo/router/dashboard" className="text-white">
        {React.string("Dashboard")}
      </Link>
    </nav>;
  };
};

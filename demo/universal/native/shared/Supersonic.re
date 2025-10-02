exception NoProvider(string);
module DOM = Webapi.Dom;
module Location = DOM.Location;
module History = DOM.History;

module URL = {
  include URL;

  let to_json = t => {
    t |> toString |> Melange_json.To_json.string;
  };

  let of_json = json => {
    json |> Melange_json.Of_json.string |> makeExn;
  };
};

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

[@mel.send]
external dispatchEvent: (Dom.window, Dom.event) => unit = "dispatchEvent";

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
  type t = {
    url: URL.t,
    navigate: (~replace: bool, string) => unit,
  };

  [@mel.new] external makeEventIE11Compatible: string => Dom.event = "Event";

  [@mel.scope "document"]
  external createEventNonIEBrowsers: string => Dom.event = "createEvent";

  [@mel.send]
  external initEventNonIEBrowsers: (Dom.event, string, bool, bool) => unit =
    "initEvent";

  [@platform js]
  let safeMakeEvent = eventName =>
    if (Js.typeof(DOM.Event.make) == "function") {
      makeEventIE11Compatible(eventName);
    } else {
      let event = createEventNonIEBrowsers("Event");
      initEventNonIEBrowsers(event, eventName, true, true);
      event;
    };

  [@platform js]
  let push = path => {
    History.pushState(History.state(DOM.history), "", path, DOM.history);
    DOM.EventTarget.dispatchEvent(
      safeMakeEvent("popstate"),
      DOM.Window.asEventTarget(DOM.window),
    );
  };

  [@platform js]
  let replace = path => {
    History.replaceState(History.state(DOM.history), "", path, DOM.history);
    DOM.EventTarget.dispatchEvent(
      safeMakeEvent("popstate"),
      DOM.Window.asEventTarget(DOM.window),
    );
  };

  [@platform js]
  let watchUrl = callback => {
    let watcherID = _ =>
      callback(URL.makeExn(Location.href(DOM.window->DOM.Window.location)));
    DOM.EventTarget.addEventListener(
      "popstate",
      watcherID,
      DOM.Window.asEventTarget(DOM.window),
    );
    watcherID;
  };

  [@platform js]
  let unwatchUrl = watcherID => {
    DOM.EventTarget.removeEventListener(
      "popstate",
      watcherID,
      DOM.Window.asEventTarget(DOM.window),
    );
  };

  let context: React.Context.t(option(t)) = React.createContext(None);

  module Provider = {
    let provider = React.Context.provider(context);

    [@react.client.component]
    let make = (~url: URL.t, ~children: React.element) => {
      switch%platform (Runtime.platform) {
      | Client =>
        let (url, setUrl) = React.useState(() => url);

        React.useEffect0(() => {
          let watcherId = watchUrl(url => setUrl(_ => url));

          /**
            * check for updates that may have occured between
            * the initial state and the subscribe above
            */
          let newUrl =
            URL.makeExn(Location.href(DOM.window->DOM.Window.location));
          if (newUrl == url) {
            setUrl(_ => newUrl);
          };

          Some(() => unwatchUrl(watcherId));
        });
        let navigate = (~replace as _, path: string) => {
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
          RouteRegistry.clearAboveLevel((commonPrefix |> List.length) - 1);

          push(path) |> ignore;
        };

        React.createElement(
          provider,
          {
            "value":
              Some({
                url,
                navigate,
              }),
            "children": children,
          },
        );
      | Server =>
        provider(
          ~value=
            Some({
              url,
              navigate: (~replace as _, _) =>
                failwith("navigate in'tnot supported on server"),
            }),
          ~children,
          (),
        )
      };
    };
  };

  let use = () => {
    switch (React.useContext(context)) {
    | Some(context) => context
    | None => raise(NoProvider("RouterContext requires a provider"))
    };
  };
};

[@mel.scope "window"] [@mel.set]
external setNavigate:
  (Webapi.Dom.Window.t, (~replace: bool, string) => unit) => unit =
  "__navigate";

[@platform js]
external navigate: (~replace: bool, string) => unit = "window.__navigate";

module Router = {
  [@react.client.component]
  let make = (~children: React.element) =>
    switch%platform (Runtime.platform) {
    | Server => children
    | Client =>
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

      // React.useEffect0(popStateHandler);

      children
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
        ~outlet: option(React.element),
        ~level: int,
      ) => {
    Js.log("Route: " ++ path);
    let (outlet, setOutlet) =
      React.useState(() =>
        switch (outlet) {
        | Some(outlet) => outlet
        | None => React.null
        }
      );
    let (cachedNodeKey, setCachedNodeKey) = React.useState(() => path);

    let%browser_only loader = (commonPrefix, remainingDifference) => {
      let headers =
        Fetch.HeadersInit.make({"Accept": "application/react.component"});
      Fetch.fetchWithInit(
        "/demo" ++ commonPrefix ++ "?rsc=" ++ remainingDifference,
        Fetch.RequestInit.make(~method_=Fetch.Get, ~headers, ()),
      )
      |> ReactServerDOMEsbuild.createFromFetch
      |> Js.Promise.then_(element => {
           setOutlet(_ => element);
           setCachedNodeKey(_ =>
             commonPrefix ++ "?rsc=" ++ remainingDifference
           );
           Js.Promise.resolve();
         })
      |> ignore;
    };

    React.useEffect0(() => {
      RouteRegistry.register(~level, ~loader, ~path, ());
      None;
    });

    <RouteContextProvider key=cachedNodeKey value=outlet>
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
    let {RouterContext.url, navigate} = RouterContext.use();
    let path = URL.pathname(url);
    let isActive = path == to_;
    let handleClick = (e: React.Event.Mouse.t) => {
      React.Event.Mouse.preventDefault(e);
      navigate(~replace, to_);
    };

    let className =
      switch (className) {
      | Some(className) => className ++ (isActive ? " font-bold" : "")
      | None => ""
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
      <Link to_="/demo/router/about/me" className="text-white">
        {React.string("About me")}
      </Link>
      <Link to_="/demo/router/about/work" className="text-white">
        {React.string("About work")}
      </Link>
      <Link to_="/demo/router/about" className="text-white">
        {React.string("About (404)")}
      </Link>
      <Link to_="/demo/router/dashboard" className="text-white">
        {React.string("Dashboard")}
      </Link>
      <Link to_="/demo/router/profile/123" className="text-white">
        {React.string("Profile")}
      </Link>
    </nav>;
  };
};

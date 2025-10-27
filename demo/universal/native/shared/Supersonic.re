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

module Params = {
  type t = Hashtbl.t(string, string);

  let create = () => {
    Hashtbl.create(10);
  };

  let add = (t, key, value) => {
    Hashtbl.add(t, key, value);
  };

  let find = (t, key) => {
    Hashtbl.find_opt(t, key);
  };

  let to_json = t => {
    t
    |> Hashtbl.to_seq
    |> List.of_seq
    |> Melange_json.To_json.list(((key, value)) =>
         Melange_json.To_json.list(Melange_json.To_json.string, [key, value])
       );
  };

  let of_json = json => {
    let hashtbl = Hashtbl.create(10);

    let _ =
      json
      |> Melange_json.Of_json.list(pair =>
           pair |> Melange_json.Of_json.list(Melange_json.Of_json.string)
         );

    hashtbl;
  };
};

[@mel.send]
external dispatchEvent: (Dom.window, Dom.event) => unit = "dispatchEvent";

module RouteRegistry = {
  type route = {
    path: string,
    loader: option((string, string) => unit),
  };

  let routes = ref([]);

  let register = (~path, ~loader=?, ()) => {
    let filteredRoutes = List.filter(route => route.path != path, routes^);

    routes :=
      filteredRoutes
      @ [
        {
          path,
          loader,
        },
      ];
  };

  let find = (path: string) => {
    List.find_opt(route => route.path == path, routes^);
  };

  let clear = () => {
    routes := [];
  };

  let clearBellow = path => {
    routes :=
      List.filter(
        route => route.path |> String.length <= (path |> String.length),
        routes^,
      );
  };

  let getAllRoutes = () => {
    routes^;
  };
};

type page = {
  params: Params.t,
  element: React.element,
};

module RouterContext = {
  [@deriving json]
  type routeData = {
    params: Params.t,
    url: URL.t,
  };

  type t = {
    routeData,
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
    let make = (~routeData: routeData, ~children: React.element) => {
      switch%platform (Runtime.platform) {
      | Client =>
        let (url, setUrl) = React.useState(() => routeData.url);

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

        let findPathDifference = (path1, path2): (string, string) => {
          let curPath = path1 |> String.split_on_char('/') |> List.tl;
          let pathSegments = path2 |> String.split_on_char('/') |> List.tl;
          let rec findCommonPrefix = (p1, p2, acc) => {
            switch (p1, p2) {
            | ([h1, ...t1], [h2, ...t2]) when h1 == h2 =>
              findCommonPrefix(t1, t2, acc ++ "/" ++ h1)
            | (_, remaining2) => (acc, remaining2 |> String.concat("/"))
            };
          };

          findCommonPrefix(curPath, pathSegments, "");
        };

        let navigate = (~replace as _, path: string) => {
          let location = DOM.window->DOM.Window.location;
          let curPath = Location.pathname(location);
          let (commonPrefix, remainingDifference) =
            findPathDifference(curPath, path);

          let route: option(RouteRegistry.route) =
            RouteRegistry.find(commonPrefix);

          switch (route) {
          | Some(route) =>
            switch (route.loader) {
            | Some(loader) => loader(path, remainingDifference)
            | None => ()
            };
            RouteRegistry.clearBellow(route.path);

          | None => ()
          };

          push(path) |> ignore;
        };

        React.createElement(
          provider,
          {
            "value":
              Some({
                routeData,
                navigate,
              }),
            "children": children,
          },
        );
      | Server =>
        provider(
          ~value=
            Some({
              routeData,
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
      ) => {
    let (outlet, setOutlet) =
      React.useState(() =>
        switch (outlet) {
        | Some(outlet) => outlet
        | None => React.null
        }
      );
    let isFirstRender = React.useRef(true);
    let (cachedNodeKey, setCachedNodeKey) = React.useState(() => path);

    let%browser_only loader = (path, rscPath) => {
      let headers =
        Fetch.HeadersInit.make({"Accept": "application/react.component"});
      Fetch.fetchWithInit(
        path ++ "?rsc=" ++ rscPath,
        Fetch.RequestInit.make(~method_=Fetch.Get, ~headers, ()),
      )
      |> ReactServerDOMEsbuild.createFromFetch
      |> Js.Promise.then_((page: page) => {
           setOutlet(_ => page.element);
           setCachedNodeKey(_ => path ++ "?rsc=" ++ rscPath);
           Js.Promise.resolve(page);
         })
      |> ignore;
    };

    if (isFirstRender.current) {
      isFirstRender.current = false;
      RouteRegistry.register(~path, ~loader, ());
      let _ =
        switch%platform (Runtime.platform) {
        | Client => Js.log(RouteRegistry.getAllRoutes())
        | Server => ()
        };
      ();
    };

    <RouteContextProvider key=cachedNodeKey value=outlet>
      <React.Fragment key=path> children </React.Fragment>
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
    let {RouterContext.routeData, navigate} = RouterContext.use();
    let path = URL.pathname(routeData.url);
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
      <Link to_="/demo/router/profile" className="text-white">
        {React.string("Profile")}
      </Link>
      <Link to_="/demo/router/profile/123" className="text-white">
        {React.string("Profile with dynamic id")}
      </Link>
      <Link to_="/demo/router/profile/12345/pedro" className="text-white">
        {React.string("Profile with dynamic id and dynamic name")}
      </Link>
    </nav>;
  };
};

/**
* Router is a component that provides the router context to the application.
* It provides the dynamic params, url and navigation function to the application.
* On navigation, it fetches the route component and updates the dynamic params.
* Depending on the mode (revalidate or not), it either updates the whole page or the specific route component.
*/
exception No_provider(string);
module DOM = Webapi.Dom;
module Location = DOM.Location;
module History = DOM.History;

type url = URL.t;
let url_to_json = url => url |> URL.toString |> Melange_json.To_json.string;
let url_of_json = (json: Melange_json.t) =>
  URL.makeExn(json |> Melange_json.Of_json.string);

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

[@platform js]
module HistoryCache = {
  module HistoryCacheConfig = {
    type key = {
      .
      "path": string,
      "dynamicParams": DynamicParams.t,
      "parentRoute": string,
    };
  };

  module HistoryCache = HistoryCache.Make(HistoryCacheConfig);
  let cache = HistoryCache.create();
  let set = (~key, ~page) => {
    HistoryCache.set(cache, ~key, ~page);
  };
  let get = (~key) => {
    HistoryCache.get(cache, ~key);
  };
};

/**
  * Compares two paths and returns the sub-route path between them.
  * Example:
  * - path1: /students/123
  * - path2: /students/123/grades/456
  * - Returns: /grades/456
  */
[@platform js]
let findSubRoutePath = (path1, path2) => {
  let splitPath = path => path |> String.split_on_char('/') |> List.tl;

  let rec findSubRoutePath = (p1, p2, acc) => {
    switch (p1, p2) {
    | ([h1, ...t1], [h2, ...t2]) when h1 == h2 =>
      findSubRoutePath(t1, t2, acc)
    | (_, remaining) => remaining |> String.concat("/")
    };
  };

  findSubRoutePath(splitPath(path1), splitPath(path2), "");
};

let%browser_only splitPathAndQuery = to_ => {
  switch (to_ |> String.split_on_char('?')) {
  | [path, queryParams, ..._] => (path, Some(queryParams))
  | _ => (to_, None)
  };
};

let%browser_only buildQueryString = (~prefix, queryParamsOpt) => {
  queryParamsOpt |> Option.map(q => prefix ++ q) |> Option.value(~default="");
};

let%browser_only fetchComponent = endpoint => {
  let headers =
    Fetch.HeadersInit.make({ "Accept": "application/react.component" });

  Fetch.fetchWithInit(
    endpoint,
    Fetch.RequestInit.make(~method_=Fetch.Get, ~headers, ()),
  )
  |> Js.Promise.then_(response => {
       let body = Fetch.Response.body(response);
       ReactServerDOMEsbuild.createFromReadableStream(body);
     });
};

[@platform js]
type pendingNavigation = {
  revalidate: bool,
  path: string,
  shouldReplace: bool,
};

type t =
  (~replace: bool=?, ~revalidate: bool=?, ~shallow: bool=?, string) => unit;

type router = {
  navigate: t,
  params: DynamicParams.t,
  url: URL.t,
  pathname: string,
  searchParams: URL.SearchParams.t,
  isNavigating: bool,
};

let context: React.Context.t(option(router)) = React.createContext(None);
let provider = React.Context.provider(context);

let use = () => {
  switch (React.useContext(context)) {
  | Some(context) => context.navigate
  | None => raise(No_provider("Router.use() requires the Router component"))
  };
};

let useRouter = () => {
  switch (React.useContext(context)) {
  | Some(context) => context
  | None =>
    raise(No_provider("Router.useRouter() requires the Router component"))
  };
};

[@react.client.component]
let make =
    (
      ~serverUrl: url,
      ~initialDynamicParams: DynamicParams.t,
      ~children: React.element,
    ) => {
  let (element, setElement) = React.useState(() => children);
  let (url, setUrl) = React.useState(() => serverUrl);
  let (dynamicParams, setDynamicParams) =
    React.useState(() => initialDynamicParams);
  let setDynamicParams = params => setDynamicParams(_ => params);
  let pathname = URL.pathname(url);
  let searchParams = URL.searchParams(url);

  React.useEffect0(() => {
    let watcherId = watchUrl(url => setUrl(_ => url));
    Some(() => unwatchUrl(watcherId));
  });
  let (cachedNodeKey, setCachedNodeKey) = React.useState(() => "");
  let (isNavigating, setIsNavigating) = React.useState(() => false);
  let pendingNavigationRef = React.useRef(None);

  let%browser_only renderFullPage = element => {
    /**
      * This is a hack to force a re-render of the route by changing the key
      * react-router do something similar
      * Is there a better way to do this?
      */
    setCachedNodeKey(_ => Js.Date.now() |> string_of_float);
    setElement(_ => element);
    VirtualHistory.cleanup();
  };

  let%browser_only renderSubRoute = (~parentRoute, element) => {
    let virtualHistoryRoute =
      VirtualHistory.find(parentRoute)
      |> Option.value(~default=VirtualHistory.state^ |> List.hd);

    VirtualHistory.cleanPathState(virtualHistoryRoute.path);
    virtualHistoryRoute.renderPage(element);
  };

  let%browser_only handleNavigationResponse =
                   (~parentRoute, ~dynamicParams, ~element) => {
    switch (pendingNavigationRef.current) {
    | Some({ revalidate, path, shouldReplace }) =>
      setDynamicParams(dynamicParams);

      let historyState = {
        "dynamicParams": dynamicParams,
        "parentRoute": parentRoute,
        "path": path,
      };

      let _ =
        shouldReplace
          ? HistoryState.replace(HistoryState.fromJs(historyState), path)
          : HistoryState.push(HistoryState.fromJs(historyState), path);

      let _ =
        if (revalidate) {
          HistoryCache.set(~key=historyState, ~page=FullPage(element));
          renderFullPage(element);
        } else {
          HistoryCache.set(~key=historyState, ~page=SubRoute(element));
          renderSubRoute(~parentRoute, element);
        };

      pendingNavigationRef.current = None;
      setIsNavigating(_ => false);
    | None => ()
    };
  };

  let%browser_only navigate =
                   (
                     ~replace as shouldReplace=false,
                     ~revalidate=false,
                     ~shallow=false,
                     to_,
                   ) => {
    let curPath = Location.pathname(DOM.window->DOM.Window.location);
    let (toPath, queryParamsOpt) = splitPathAndQuery(to_);
    /**
     * Identify the sub-route path from the current path to the target path
     * Example:
     * 1.
     *  - Current path: /students/123
     *  - Target path: /students/123/grades/456
     *  - Sub-route path: /grades/456
     *  - Endpoint: /students/123/grades/456?toSubRoute=/grades/456
     *  - We only receive the /grades/456 component to render in the /students/123 route
     * 2.
     *  - Current path: /students/123/grades/456
     *  - Target path: /about/contact
     *  - Sub-route path: "" (No sub-route)
     *  - Endpoint: /about/contact?toSubRoute=
     *  - We receive the /about/contact component to render in the /.
     */
    let subRoutePath = findSubRoutePath(curPath, toPath);

    let endpoint =
      if (revalidate) {
        toPath ++ buildQueryString(~prefix="?", queryParamsOpt);
      } else {
        toPath
        ++ "?toSubRoute="
        ++ subRoutePath
        ++ buildQueryString(~prefix="&", queryParamsOpt);
      };

    if (shallow) {
      ();
    } else {
      setIsNavigating(_ => true);
      pendingNavigationRef.current =
        Some({
          revalidate,
          path: to_,
          shouldReplace,
        });

      let _ =
        fetchComponent(endpoint)
        |> Js.Promise.then_((navigationResponse: React.element) => {
             setElement(_ => navigationResponse);
             Js.Promise.resolve();
           })
        |> Js.Promise.catch(error => {
             pendingNavigationRef.current = None;
             setIsNavigating(_ => false);
             Js.Promise.reject(Obj.magic(error));
           });
      ();
    };

    ();
  };

  // Initialize cache and history state after hydration
  React.useEffect0(() => {
    let curPath = Location.pathname(DOM.window->DOM.Window.location);
    let historyState = {
      "dynamicParams": dynamicParams,
      "path": curPath,
      "parentRoute": curPath,
    };
    HistoryCache.set(~key=historyState, ~page=FullPage(element));

    /**
       * Replace the history state set by the browser to our own implementation.
       */
    HistoryState.replace(HistoryState.fromJs(historyState), curPath);

    None;
  });

  // Listen to the popstate event and handle the history navigation.
  React.useEffect0(() => {
    let watcherId = event =>
      /**
        * Event is trusted when it was generated by the user agent, not by EventTarget.dispatchEvent.
        * https://developer.mozilla.org/en-US/docs/Web/API/Event/isTrusted
        */
      (
        if (DOM.Event.isTrusted(event)) {
          let historyState: {
            .
            "dynamicParams": DynamicParams.t,
            "path": string,
            "parentRoute": string,
          } =
            event->HistoryState.fromEvent->HistoryState.toJs;

          let dynamicParams = historyState##dynamicParams;
          let parentRoute = historyState##parentRoute;
          setDynamicParams(dynamicParams);

          switch (HistoryCache.get(~key=historyState)) {
          | Some(FullPage(page)) => renderFullPage(page)
          | Some(SubRoute(page)) => renderSubRoute(~parentRoute, page)
          | None =>
            /**
              * If we don't find the cached page, we navigate to the path and replace the history state.
              * That may happen when the user refreshes the page, as the cache is in-memory or when the cache was cleared from the cache history due to the max cache size.
              */
            navigate(~replace=true, historyState##path)
          };
        }
      );

    DOM.EventTarget.addEventListener(
      "popstate",
      watcherId,
      DOM.Window.asEventTarget(DOM.window),
    );

    Some(
      () =>
        DOM.EventTarget.removeEventListener(
          "popstate",
          watcherId,
          DOM.Window.asEventTarget(DOM.window),
        ),
    );
  });

  let routerValue =
    Some({
      navigate,
      params: dynamicParams,
      url,
      pathname,
      searchParams,
      isNavigating,
    });

  <React.Fragment key=cachedNodeKey>
    {switch%platform () {
     | Client =>
       React.createElement(
         NavigationResponse.internalProvider,
         {
           "value": Some(handleNavigationResponse),
           "children":
             React.createElement(
               provider,
               {
                 "value": routerValue,
                 "children": element,
               },
             ),
         },
       )
     | Server =>
       NavigationResponse.internalProvider(
         ~value=None,
         ~children=
           provider(
             ~value=
               Some({
                 navigate: (~replace=?, ~revalidate=?, ~shallow=?, _) =>
                   failwith("navigate isn't supported on server"),
                 params: dynamicParams,
                 url,
                 pathname,
                 searchParams,
                 isNavigating,
               }),
             ~children=element,
             (),
           ),
         (),
       )
     }}
  </React.Fragment>;
};

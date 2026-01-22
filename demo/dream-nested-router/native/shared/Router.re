/**
* Router is a component that provides the router context to the application.
* It provides the dynamic params, url and navigation function to the application.
* On navigation, it fetches the route component and updates the dynamic params.
* Depending on the mode (revalidate or not), it either updates the whole page or the specific route component.
*/
exception NoProvider(string);
module DOM = Webapi.Dom;
module Location = DOM.Location;
module History = DOM.History;

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

type t =
  (~replace: bool=?, ~revalidate: bool=?, ~shallow: bool=?, string) => unit;

let context: React.Context.t(option(t)) = React.createContext(None);
let provider = React.Context.provider(context);
let use = () => {
  switch (React.useContext(context)) {
  | Some(context) => context
  | None => raise(NoProvider("Router.use() requires the Router component"))
  };
};

[@react.client.component]
let make = (~children: React.element) => {
  let (element, setElement) = React.useState(() => children);
  let { DynamicParams.dynamicParams, setDynamicParams } =
    DynamicParams.useContext();
  let (cachedNodeKey, setCachedNodeKey) = React.useState(() => "");

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
      // If we don't find the virtualHistoryRoute, we use the main route and create a new state from it.
      |> Option.value(~default=VirtualHistory.state^ |> List.hd);

    VirtualHistory.cleanPathState(virtualHistoryRoute.path);
    virtualHistoryRoute.renderPage(element);
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

    // When shallow is true, we only update the url, without navigating.
    if (shallow) {
      ();
    } else {
      let _ =
        fetchComponent(endpoint)
        |> Js.Promise.then_(
             (
               (
                 parentRoute,
                 dynamicParams: DynamicParams.t,
                 element: React.element,
               ),
             ) => {
             setDynamicParams(dynamicParams);

             let historyState = {
               "dynamicParams": dynamicParams,
               "parentRoute": parentRoute,
               "path": to_,
             };

             let _ =
               shouldReplace
                 ? HistoryState.replace(
                     HistoryState.fromJs(historyState),
                     to_,
                   )
                 : HistoryState.push(HistoryState.fromJs(historyState), to_);

             let _ =
               if (revalidate) {
                 HistoryCache.set(
                   ~key=historyState,
                   ~page=FullPage(element),
                 );
                 renderFullPage(element);
               } else {
                 HistoryCache.set(
                   ~key=historyState,
                   ~page=SubRoute(element),
                 );
                 renderSubRoute(~parentRoute, element);
               };

             Js.Promise.resolve();
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

  <React.Fragment key=cachedNodeKey>
    {switch%platform () {
     | Client =>
       React.createElement(
         provider,
         {
           "value": Some(navigate),
           "children": element,
         },
       )
     | Server =>
       provider(
         ~value=
           Some(
             (~replace=?, ~revalidate=?, ~shallow=?, _) =>
               failwith("navigate isn't supported on server"),
           ),
         ~children=element,
         (),
       )
     }}
  </React.Fragment>;
};

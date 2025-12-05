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
[@mel.scope ("window", "history")]
external pushState: (Js.t('a), string, string) => unit = "pushState";
[@mel.scope ("window", "history")]
external replaceState: (Js.t('a), string, string) => unit = "replaceState";

/**
 * Melange webapi don't set state type, so we use Obj.magic to cast it to the correct type while the PR is not merged.
 * https://github.com/melange-community/melange-webapi/blob/80c6ededd06cc66b75445d1ed5c855e050b156a0/src/Webapi/Dom/Webapi__Dom__History.re#L2
 * PR: https://github.com/melange-community/melange-webapi/pull/29
 */
module HistoryState = {
  type t = History.state;

  let toJs: History.state => Js.t({..}) = state => state |> Obj.magic;
  let fromJs: Js.t({..}) => History.state = state => state |> Obj.magic;
};

module Url = {
  /**
    This module is a simplified copy of the ReasonReactRouter module adapted to URL (https://github.com/reasonml/reason-react/blob/db1b32369dd7c33c948c3fd14797ab0236fba82e/src/ReasonReactRouter.re#L4).
  */
  type t = URL.t;

  let to_json = url => {
    url |> URL.toString |> Melange_json.To_json.string;
  };

  let of_json = (json: Melange_json.t) => {
    URL.makeExn(json |> Melange_json.Of_json.string);
  };

  [@platform js]
  let push = (state, path) => {
    // Melange webapi don't set state type, so we use Obj.magic to cast it to the correct type
    // https://github.com/melange-community/melange-webapi/blob/80c6ededd06cc66b75445d1ed5c855e050b156a0/src/Webapi/Dom/Webapi__Dom__History.re#L2
    // PR: https://github.com/melange-community/melange-webapi/pull/29
    History.pushState(state, "", path, DOM.history);
    let _ =
      DOM.EventTarget.dispatchEvent(
        DOM.Event.make("popstate"),
        DOM.Window.asEventTarget(DOM.window),
      );
    ();
  };

  [@platform js]
  let replace = (state, path) => {
    History.replaceState(state, "", path, DOM.history);
    let _ =
      DOM.EventTarget.dispatchEvent(
        DOM.Event.make("popstate"),
        DOM.Window.asEventTarget(DOM.window),
      );
    ();
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

  let%browser_only useWatch = () => {
    let (url, setUrl) =
      React.useState(() =>
        URL.makeExn(Location.href(DOM.window->DOM.Window.location))
      );

    React.useEffect0(() => {
      let watcherId = watchUrl(url => setUrl(_ => url));

      Some(() => unwatchUrl(watcherId));
    });

    url;
  };
};

type t = {
  dynamicParams: DynamicParams.t,
  url: Url.t,
  navigate:
    (~replace: bool=?, ~revalidate: bool=?, ~shallow: bool=?, string) => unit,
};

let context: React.Context.t(option(t)) = React.createContext(None);
let provider = React.Context.provider(context);
let use = () => {
  switch (React.useContext(context)) {
  | Some(context) => context
  | None => raise(NoProvider("Router.use() requires the Router component"))
  };
};

[@react.client.component]
let make =
    (~dynamicParams: DynamicParams.t, ~url: Url.t, ~children: React.element) => {
  let (element, setElement) = React.useState(() => children);

  let url =
    switch%platform () {
    | Client =>
      // We don't need to use the url on the client because we can access it through the window object so we silence the warning by ignoring it
      // URL is just for server-side
      let _ = url;
      Url.useWatch();
    | Server => url
    };
  let (cachedNodeKey, setCachedNodeKey) =
    React.useState(() => url |> URL.toString);
  let (dynamicParams, setDynamicParams) = React.useState(() => dynamicParams);

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

  let splitPathQuery = to_ => {
    switch (to_ |> String.split_on_char('?')) {
    | [path, queryParams, ..._] => (path, Some(queryParams))
    | _ => (to_, None)
    };
  };

  let buildQueryString = (~prefix, queryParamsOpt) => {
    queryParamsOpt
    |> Option.map(q => prefix ++ q)
    |> Option.value(~default="");
  };

  let%browser_only fetchComponent = endpoint => {
    let headers =
      Fetch.HeadersInit.make({"Accept": "application/react.component"});

    Fetch.fetchWithInit(
      endpoint,
      Fetch.RequestInit.make(~method_=Fetch.Get, ~headers, ()),
    )
    |> Js.Promise.then_(response => {
         let body = Fetch.Response.body(response);
         ReactServerDOMEsbuild.createFromReadableStream(body);
       });
  };

  let%browser_only navigate =
                   (
                     ~replace as shouldReplace=false,
                     ~revalidate=false,
                     ~shallow=false,
                     to_,
                   ) => {
    let curPath = URL.pathname(url);
    let (toPath, queryParamsOpt) = splitPathQuery(to_);
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
                 routeDefinitionOwner,
                 dynamicParams: DynamicParams.t,
                 element: React.element,
               ),
             ) => {
             let virtualHistoryRoute =
               VirtualHistory.find(routeDefinitionOwner)
               // If we don't find the virtualHistoryRoute, we use the main route and create a new state from it.
               |> Option.value(~default=VirtualHistory.state^ |> List.hd);

             setDynamicParams(_ => dynamicParams);

             let state = {
               "dynamicParams": dynamicParams,
               "parentRoute": routeDefinitionOwner,
               "path": to_,
             };

             let _ =
               shouldReplace
                 ? Url.replace(HistoryState.fromJs(state), to_)
                 : Url.push(HistoryState.fromJs(state), to_);

             if (revalidate) {
               // Clear the virtual history when revalidating
               VirtualHistory.cleanup();

               /**
                * This is a hack to force a re-render of the route by changing the key
                * react-router do something similar
                * Is there a better way to do this?
                */
               setCachedNodeKey(_ => Js.Date.now() |> string_of_float);
               setElement(_ => element);

               /**
                * Cache the full page in the cache history.
                * This is used to avoid fetching the same page again when navigating back or forward.
                * For revalidated pages, we cache the whole page element.
                */
               HistoryCache.set(to_, dynamicParams, FullPage(element));
             } else {
               /**
                * Cache the sub-route in the cache history.
                * This is used to avoid fetching the same sub-route again when navigating back or forward.
                * For sub-routes, we cache only the sub-route element.
                */
               HistoryCache.set(to_, dynamicParams, SubRoute(element));
               VirtualHistory.cleanPathState(virtualHistoryRoute.path);
               virtualHistoryRoute.renderPage(element);
             };

             Js.Promise.resolve();
           });
      ();
    };

    ();
  };

  // Initialize cache and history state after hydration
  React.useEffect0(() => {
    HistoryCache.set(URL.pathname(url), dynamicParams, FullPage(element));

    /**
       * Replace the history state set by the browser to our own implementation.
       */
    Url.replace(
      HistoryState.fromJs({
        "dynamicParams": dynamicParams,
        "path": url |> URL.pathname,
        "parentRoute": url |> URL.pathname,
      }),
      url |> URL.pathname,
    );

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
          let state: {
            .
            "dynamicParams": DynamicParams.t,
            "path": string,
            "parentRoute": string,
          } =
            DOM.Event.target(event)
            ->DOM.EventTarget.unsafeAsWindow
            ->DOM.Window.history
            ->History.state
            ->HistoryState.toJs;

          let dynamicParams = state##dynamicParams;
          let path = state##path;
          let parentRoute = state##parentRoute;
          setDynamicParams(_ => dynamicParams);

          switch (HistoryCache.get(path, dynamicParams)) {
          | Some(FullPage(page)) =>
            VirtualHistory.cleanup();
            setCachedNodeKey(_ => Js.Date.now() |> string_of_float);
            setElement(_ => page);
          | Some(SubRoute(page)) =>
            let virtualHistoryRoute =
              VirtualHistory.find(parentRoute)
              |> Option.value(~default=VirtualHistory.state^ |> List.hd);

            VirtualHistory.cleanPathState(virtualHistoryRoute.path);
            virtualHistoryRoute.renderPage(page);
          | None =>
            /**
              * If we don't find the cached page, we navigate to the path and replace the history state.
              * That may happen when the user refreshes the page, as the cache is in-memory or when the cache was cleared from the cache history due to the max cache size.
              */
            navigate(~replace=true, path)
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
           "value":
             Some({
               dynamicParams,
               url,
               navigate,
             }),
           "children": element,
         },
       )
     | Server =>
       provider(
         ~value=
           Some({
             dynamicParams,
             url,
             navigate: (~replace=?, ~revalidate=?, ~shallow=?, _) =>
               failwith("navigate isn't supported on server"),
           }),
         ~children=element,
         (),
       )
     }}
  </React.Fragment>;
};

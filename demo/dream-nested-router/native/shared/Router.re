/**
* Router is a component that provides the router context to the application.
* It provides the path params, url and navigation function to the application.
* On navigation, it requests the target route URL with the SRR-Navigation-From
* and SRR-Registry headers; the server decides whether to answer with a full
* model or a patch for the non-shared branch, and the client applies it.
*/
exception No_provider(string);
module DOM = Webapi.Dom;
module Location = DOM.Location;
module History = DOM.History;

type url = URL.t;
let url_to_rsc = url => url |> URL.toString |> RSC.Primitives.string_to_rsc;
let url_of_rsc = rsc => URL.makeExn(rsc |> RSC.Primitives.string_of_rsc);

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
module BackForwardCache = {
  module BackForwardCacheConfig = {
    type key = {
      .
      "path": string,
      "pathParams": PathParams.t,
      "parentRoute": string,
    };
  };

  module BackForwardCache = BackForwardCache.Make(BackForwardCacheConfig);
  let cache = BackForwardCache.create();
  let set = (~key, ~page) => {
    BackForwardCache.set(cache, ~key, ~page);
  };
  let get = (~key) => {
    BackForwardCache.get(cache, ~key);
  };
};

[@platform js]
type fetchResult =
  | Payload(React.element)
  | ReloadRequired
  | InvalidResponse;

/* Navigation requests target the route URL itself and negotiate via headers.
   SRR-Navigation-From states where the client is committed; the server
   computes the shared branch and answers full or patch. Every header is a
   fact about the client, never a conclusion about the shared branch. */
let%browser_only fetchComponent = (~from, ~registry, endpoint) => {
  let baseHeaders = [|
    ("Accept", "application/react.component"),
    ("SRR-Registry", registry),
  |];
  let headers =
    Fetch.HeadersInit.makeWithArray(
      switch (from) {
      | Some(from) =>
        Array.append(baseHeaders, [|("SRR-Navigation-From", from)|])
      | None => baseHeaders
      },
    );

  Fetch.fetchWithInit(
    endpoint,
    Fetch.RequestInit.make(~method_=Fetch.Get, ~headers, ()),
  )
  |> Js.Promise.then_(response => {
       let responseHeaders = Fetch.Response.headers(response);
       let responseKind = Fetch.Headers.get("SRR-Response", responseHeaders);
       let isComponentPayload =
         switch (Fetch.Headers.get("Content-Type", responseHeaders)) {
         | Some(contentType) =>
           String.starts_with(
             ~prefix="application/react.component",
             contentType,
           )
         | None => false
         };
       switch (responseKind, isComponentPayload) {
       | (Some("reload-required"), _) => Js.Promise.resolve(ReloadRequired)
       | (_, false) => Js.Promise.resolve(InvalidResponse)
       | (_, true) =>
         Fetch.Response.body(response)
         |> ReactServerDOMEsbuild.createFromReadableStream
         |> ReactServerDOMEsbuild.toPromise
         |> Js.Promise.then_(element => Js.Promise.resolve(Payload(element)))
       };
     });
};

[@platform js]
type inflightNavigation = {
  path: string,
  shouldReplace: bool,
};

type t =
  (~replace: bool=?, ~revalidate: bool=?, ~shallow: bool=?, string) => unit;

type router = {
  navigate: t,
  params: PathParams.t,
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
      ~initialPathParams: PathParams.t,
      ~registryFingerprint: string,
      ~children: React.element,
    ) => {
  let (element, setElement) = React.useState(() => children);
  let (inflightPayload, setInflightPayload) =
    React.useState(() => React.null);
  let (url, setUrl) = React.useState(() => serverUrl);
  let (pathParams, setPathParams) = React.useState(() => initialPathParams);
  let setPathParams = params => setPathParams(_ => params);
  let pathname = URL.pathname(url);
  let searchParams = URL.searchParams(url);

  React.useEffect0(() => {
    let watcherId = watchUrl(url => setUrl(_ => url));
    Some(() => unwatchUrl(watcherId));
  });
  let (cachedNodeKey, setCachedNodeKey) = React.useState(() => "");
  let (isNavigating, setIsNavigating) = React.useState(() => false);
  let inflightNavigation = React.useRef(None);

  let%browser_only renderFullPage = element => {
    /**
      * This is a hack to force a re-render of the route by changing the key
      * react-router do something similar
      * Is there a better way to do this?
      */
    setCachedNodeKey(_ => Js.Date.now() |> string_of_float);
    setElement(_ => element);
    MountedLayouts.cleanup();
  };

  let%browser_only renderSubRoute = (~parentRoute, element) => {
    let mountedLayout =
      MountedLayouts.find(parentRoute)
      |> Option.value(~default=MountedLayouts.state^ |> List.hd);

    MountedLayouts.cleanPathState(mountedLayout.path);
    mountedLayout.renderPage(element);
  };

  let%browser_only commitNavigation =
                   (~parentRoute, ~pathParams, ~kind, ~element) => {
    switch (inflightNavigation.current) {
    | Some({ path, shouldReplace }) =>
      setPathParams(pathParams);

      let navigationEntry = {
        "pathParams": pathParams,
        "parentRoute": parentRoute,
        "path": path,
      };

      let _ =
        shouldReplace
          ? NavigationEntry.replace(
              NavigationEntry.fromJs(navigationEntry),
              path,
            )
          : NavigationEntry.push(
              NavigationEntry.fromJs(navigationEntry),
              path,
            );

      /* The server decides full versus patch; the client only applies it. */
      let _ =
        switch (kind) {
        | "patch" =>
          BackForwardCache.set(
            ~key=navigationEntry,
            ~page=SubRoute(element),
          );
          renderSubRoute(~parentRoute, element);
        | _ =>
          BackForwardCache.set(
            ~key=navigationEntry,
            ~page=FullPage(element),
          );
          renderFullPage(element);
        };

      inflightNavigation.current = None;
      setIsNavigating(_ => false);
      setInflightPayload(_ => React.null);
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
    if (shallow) {
      ();
    } else {
      /**
       * The committed location, stated as a fact. `revalidate` omits it so
       * the server answers with a full model instead of a patch.
       */
      let location = DOM.window->DOM.Window.location;
      let from =
        revalidate
          ? None
          : Some(Location.pathname(location) ++ Location.search(location));

      setIsNavigating(_ => true);
      inflightNavigation.current =
        Some({
          path: to_,
          shouldReplace,
        });

      let abandonNavigation = () => {
        inflightNavigation.current = None;
        setIsNavigating(_ => false);
      };

      let _ =
        fetchComponent(~from, ~registry=registryFingerprint, to_)
        |> Js.Promise.then_(result => {
             switch (result) {
             | Payload(element) => setInflightPayload(_ => element)
             | ReloadRequired =>
               abandonNavigation();
               Location.setHref(location, to_);
             | InvalidResponse => abandonNavigation()
             };
             Js.Promise.resolve();
           })
        |> Js.Promise.catch(error => {
             abandonNavigation();
             Js.Promise.reject(Obj.magic(error));
           });
      ();
    };

    ();
  };

  // Initialize cache and history state after hydration
  React.useEffect0(() => {
    let curPath = Location.pathname(DOM.window->DOM.Window.location);
    let navigationEntry = {
      "pathParams": pathParams,
      "path": curPath,
      "parentRoute": curPath,
    };
    BackForwardCache.set(~key=navigationEntry, ~page=FullPage(element));

    /**
       * Replace the history state set by the browser to our own implementation.
       */
    NavigationEntry.replace(
      NavigationEntry.fromJs(navigationEntry),
      curPath,
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
          let navigationEntry: {
            .
            "pathParams": PathParams.t,
            "path": string,
            "parentRoute": string,
          } =
            event->NavigationEntry.fromEvent->NavigationEntry.toJs;

          let pathParams = navigationEntry##pathParams;
          let parentRoute = navigationEntry##parentRoute;
          setPathParams(pathParams);

          switch (BackForwardCache.get(~key=navigationEntry)) {
          | Some(FullPage(page)) => renderFullPage(page)
          | Some(SubRoute(page)) => renderSubRoute(~parentRoute, page)
          | None =>
            /**
              * If we don't find the cached page, we navigate to the path and replace the history state.
              * That may happen when the user refreshes the page, as the cache is in-memory or when the cache was cleared from the cache history due to the max cache size.
              */
            navigate(~replace=true, navigationEntry##path)
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
      params: pathParams,
      url,
      pathname,
      searchParams,
      isNavigating,
    });

  <React.Fragment key=cachedNodeKey>
    {switch%platform () {
     | Client =>
       React.createElement(
         Navigation.internalProvider,
         {
           "value": Some(commitNavigation),
           "children":
             React.createElement(
               provider,
               {
                 "value": routerValue,
                 "children": React.array([|element, inflightPayload|]),
               },
             ),
         },
       )
     | Server =>
       Navigation.internalProvider(
         React.Context.makeProps(
           ~value=None,
           ~children=
             provider(
               React.Context.makeProps(
                 ~value=
                   Some({
                     navigate: (~replace=?, ~revalidate=?, ~shallow=?, _) =>
                       failwith("navigate isn't supported on server"),
                     params: pathParams,
                     url,
                     pathname,
                     searchParams,
                     isNavigating,
                   }),
                 ~children=element,
                 (),
               ),
             ),
           (),
         ),
       )
     }}
  </React.Fragment>;
};

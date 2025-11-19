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
  let push = path => {
    History.pushState(History.state(DOM.history), "", path, DOM.history);
    DOM.EventTarget.dispatchEvent(
      DOM.Event.make("popstate"),
      DOM.Window.asEventTarget(DOM.window),
    );
  };

  [@platform js]
  let replace = path => {
    History.replaceState(History.state(DOM.history), "", path, DOM.history);
    DOM.EventTarget.dispatchEvent(
      DOM.Event.make("popstate"),
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

module DynamicParams = {
  open Melange_json.Primitives;

  [@deriving json]
  type t = array((string, string));

  let create = () => [||];

  let add = (t, key, value) => {
    Array.append(t, [|(key, value)|]);
  };

  let find = (paramKey, t) =>
    if (Array.length(t) == 0) {
      None;
    } else {
      Array.find_map(
        ((key, value)) => {key == paramKey ? Some(value) : None},
        t,
      );
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
      // We don't need to use the url on the client so we silence the warning by ignoring it
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

    let _ = shouldReplace ? Url.replace(to_) : Url.push(to_);

    if (shallow) {
      // When shallow is true, we only update the url, without navigating to the sub-route.
      ()
    };
    if (!shallow) {
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
             let branch =
               VirtualHistory.find(routeDefinitionOwner)
               // If we don't find the branch, we use the base branch (the main route) and create a new branch from it.
               |> Option.value(~default=VirtualHistory.baseBranch);

             setDynamicParams(_ => dynamicParams);

             if (revalidate) {
               // Clear the virtual history when revalidating
               VirtualHistory.cleanup();

               // This is a hack to force a re-render of the route by changing the key
               // react-router do something similar
               // Is there a better way to do this?
               setCachedNodeKey(_ => Js.Date.now() |> string_of_float);
               setElement(_ => element);
             } else {
               VirtualHistory.cleanTreeBranch(branch.path);
               branch.renderPage(element);
             };

             Js.Promise.resolve();
           });
      ();
    };

    ();
  };

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

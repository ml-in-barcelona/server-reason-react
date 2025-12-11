/**
    This module is a simplified copy of the ReasonReactRouter module adapted to URL (https://github.com/reasonml/reason-react/blob/db1b32369dd7c33c948c3fd14797ab0236fba82e/src/ReasonReactRouter.re#L4).
  */
module DOM = Webapi.Dom;
module Location = DOM.Location;
module History = DOM.History;
type t = URL.t;

let to_json = url => {
  url |> URL.toString |> Melange_json.To_json.string;
};

let of_json = (json: Melange_json.t) => {
  URL.makeExn(json |> Melange_json.Of_json.string);
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
let context: React.Context.t(option(t)) = React.createContext(None);
let provider = React.Context.provider(context);

module Provider = {
  [@react.component]
  let make = (~serverUrl: t, ~children: React.element) => {
    let (url, setUrl) = React.useState(() => serverUrl);

    React.useEffect0(() => {
      let watcherId = watchUrl(url => setUrl(_ => url));
      Some(() => unwatchUrl(watcherId));
    });

    switch%platform () {
    | Client =>
      React.createElement(
        provider,
        {
          "value": Some(url),
          "children": children,
        },
      )
    | Server => provider(~value=Some(url), ~children, ())
    };
  };
};

let use = () =>
  switch (React.useContext(context)) {
  | Some(url) => url
  | None =>
    failwith(
      "UseUrl.use() requires the UseUrl.Context.Provider component on server side",
    )
  };

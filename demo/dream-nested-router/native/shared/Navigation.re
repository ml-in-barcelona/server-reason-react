type navigationCallback =
  (
    ~parentRoute: string,
    ~pathParams: PathParams.t,
    ~kind: string,
    ~element: React.element
  ) =>
  unit;

let internalContext: React.Context.t(option(navigationCallback)) =
  React.createContext(None);

let internalProvider = React.Context.provider(internalContext);

[@react.client.component]
let make =
    (
      ~parentRoute: string,
      ~pathParams: PathParams.t,
      ~kind: string,
      ~children: React.element,
    ) => {
  let callback = React.useContext(internalContext);

  switch%platform (Runtime.platform) {
  | Client =>
    React.useLayoutEffect0(() => {
      switch (callback) {
      | Some(cb) => cb(~parentRoute, ~pathParams, ~kind, ~element=children)
      | None => ()
      };
      None;
    })
  | Server => ()
  };

  React.null;
};

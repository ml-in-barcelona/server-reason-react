open Melange_json.Primitives;

type navigationCallback =
  (
    ~parentRoute: string,
    ~dynamicParams: DynamicParams.t,
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
      ~dynamicParams: DynamicParams.t,
      ~children: React.element,
    ) => {
  let callback = React.useContext(internalContext);

  switch%platform (Runtime.platform) {
  | Client =>
    React.useLayoutEffect0(() => {
      switch (callback) {
      | Some(cb) => cb(~parentRoute, ~dynamicParams, ~element=children)
      | None => ()
      };
      None;
    })
  | Server => ()
  };

  React.null;
};

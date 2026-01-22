open Melange_json.Primitives;
exception NoProvider(string);

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

type context = {
  dynamicParams: t,
  // For internal use only
  setDynamicParams: t => unit,
};
let context: React.Context.t(option(context)) = React.createContext(None);
let provider = React.Context.provider(context);
module Provider = {
  [@react.client.component]
  let make = (~initialDynamicParams: t, ~children: React.element) => {
    let (dynamicParams, setDynamicParams) =
      React.useState(() => initialDynamicParams);

    let setDynamicParams = dynamicParams => {
      setDynamicParams(_ => dynamicParams);
    };

    let value =
      React.useMemo1(
        () =>
          Some({
            dynamicParams,
            setDynamicParams,
          }),
        [|dynamicParams|],
      );

    switch%platform () {
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

// For internal use only, use DynamicParams.use() instead
let useContext = () => {
  switch (React.useContext(context)) {
  | Some(context) => context
  | None =>
    raise(NoProvider("DynamicParams.Provider wasn't declared in the tree"))
  };
};

let use = () => {
  switch (React.useContext(context)) {
  | Some({ dynamicParams, _ }) => dynamicParams
  | None =>
    raise(
      NoProvider(
        "DynamicParams.use() requires the DynamicParams.Provider component",
      ),
    )
  };
};

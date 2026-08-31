type navigationResult = RouterRuntime.Navigation.Result.t;
type navigate =
  (
    ~history: RouterRuntime.Navigation.historyAction=?,
    ~revalidate: bool=?,
    RouterRuntime.destination
  ) =>
  Js.Promise.t(navigationResult);
type updateSearch =
  (
    ~owned: list(string),
    ~values: list((string, list(string))),
    ~history: RouterRuntime.Navigation.historyAction=?,
    unit
  ) =>
  navigationResult;
type updateHash =
  (~hash: string, ~history: RouterRuntime.Navigation.historyAction=?, unit) =>
  navigationResult;

type contextValue = {committed: RouterRuntime.Navigation.committed};

let context: React.Context.t(option(contextValue)) =
  React.createContext(None);
let provider = React.Context.provider(context);

module Provider = {
  [@react.component]
  let make =
      (
        ~initial,
        ~protocolVersion as _=1,
        ~registryFingerprint as _,
        ~basePath as _,
        ~pageCacheCapacity as _=0,
        ~metadata,
        ~children,
      ) =>
    provider(
      React.Context.makeProps(
        ~value=Some({ committed: initial }),
        ~children=React.array([|metadata, children|]),
        (),
      ),
    );
};

let unavailable = () =>
  invalid_arg("router commands are unavailable during server rendering");
let navigate: navigate = (~history as _=?, ~revalidate as _=?, _destination) =>
  unavailable();
let updateSearch: updateSearch =
    (~owned as _, ~values as _, ~history as _=?, ()) =>
  unavailable();
let updateHash: updateHash = (~hash as _, ~history as _=?, ()) =>
  unavailable();

let useNavigation = () => (navigate, RouterRuntime.Navigation.Idle);
let useCurrentRoute = () =>
  switch (React.useContext(context)) {
  | Some(value) =>
    switch (List.rev(value.committed.matches)) {
    | [{ routeId, parameters }, ..._] => Some((routeId, parameters))
    | [] => None
    }
  | None => invalid_arg("router hooks require an ancestor Router.Provider")
  };
let useSearch = () => {
  let values =
    switch (React.useContext(context)) {
    | Some(value) =>
      let search = value.committed.location.search;
      let search =
        String.length(search) > 0 && search.[0] == '?'
          ? String.sub(search, 1, String.length(search) - 1) : search;
      Uri.query_of_encoded(search);
    | None => []
    };
  (values, updateSearch);
};
let useUpdateHash = () => updateHash;

let outlet = (~owner, ~children, ()) =>
  RouterOutlet.make(
    ~key=owner,
    RouterOutlet.makeProps(~owner, ~children, ()),
  );

let suspense = (~fallback, ~children, ()) =>
  <React.Suspense fallback> children </React.Suspense>;

let link =
    (
      ~destination,
      ~className=?,
      ~target=?,
      ~download=?,
      ~ariaCurrent=?,
      ~history as _=?,
      ~revalidate as _=?,
      ~children,
      (),
    ) =>
  <a
    href={RouterRuntime.href(destination)}
    ?className
    ?target
    ?download
    ?ariaCurrent>
    children
  </a>;

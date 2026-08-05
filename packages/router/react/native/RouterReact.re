type options = RouterRuntime.Link.options;
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
    ~options: RouterRuntime.Search.options=?,
    unit
  ) =>
  navigationResult;
type updateHash =
  (~hash: string, ~options: RouterRuntime.Search.options=?, unit) =>
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
        ~children,
      ) =>
    provider(
      React.Context.makeProps(
        ~value=Some({ committed: initial }),
        ~children,
        (),
      ),
    );
};

let useNavigation = () => (None, RouterRuntime.Navigation.Idle);
let useCommitted = () =>
  switch (React.useContext(context)) {
  | Some(value) => Some(value.committed)
  | None => None
  };
let useSearchValues = () =>
  switch (React.useContext(context)) {
  | Some(value) =>
    let search = value.committed.location.search;
    let search =
      String.length(search) > 0 && search.[0] == '?'
        ? String.sub(search, 1, String.length(search) - 1) : search;
    Uri.query_of_encoded(search);
  | None => []
  };
let useUpdateSearch = () => None;
let useUpdateHash = () => None;
let useIsActive = (~routeId, ~parameters, ~includeDescendants) =>
  switch (React.useContext(context)) {
  | Some(value) =>
    RouterRuntime.Navigation.isActive(
      value.committed,
      ~routeId,
      ~parameters,
      ~includeDescendants,
    )
  | None => false
  };

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
      ~options as _=?,
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

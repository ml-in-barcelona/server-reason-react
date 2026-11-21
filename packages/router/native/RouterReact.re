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

type navigationErrorRecovery =
  | StayOnPage
  | FullLoad;

type navigationError = {
  target: string,
  message: string,
  recovery: navigationErrorRecovery,
};

type blocker =
  | Unblocked
  | Blocked({
      target: string,
      action: RouterRuntime.Navigation.historyAction,
      proceed: unit => unit,
      cancel: unit => unit,
    });

type invalidation =
  | All
  | Prefix(RouterRuntime.destination);

type contextValue = {
  committed: RouterRuntime.Navigation.committed,
  search: list((string, list(string))),
};

let parseSearch = search =>
  switch (RouterQuery.parse(search)) {
  | Ok(values) => values
  | Error(_) => []
  };

let context: React.Context.t(option(contextValue)) =
  React.createContext(None);
let provider = React.Context.provider(context);

module Provider = {
  [@react.component]
  let make =
      (
        ~initial,
        ~protocolVersion as _=2,
        ~registryFingerprint as _,
        ~basePath as _,
        ~pageCacheCapacity as _=30,
        ~pageCacheMaxAge as _=0.0,
        ~routes as _: array(string)=[||],
        ~interceptLinks as _=true,
        ~viewTransitions as _=false,
        ~onNavigationError as _: option(navigationError => unit)=?,
        ~metadata as _,
        ~children,
      ) =>
    provider(
      React.Context.makeProps(
        ~value=
          Some({
            committed: initial,
            search: parseSearch(initial.location.search),
          }),
        ~children=React.array([|React.null, children|]),
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

let useContextValue = () =>
  switch (React.useContext(context)) {
  | Some(value) => value
  | None => invalid_arg("router hooks require an ancestor Router.Provider")
  };

let useNavigation = () => (navigate, RouterRuntime.Navigation.Idle);
let useCurrentRoute = () =>
  switch (List.rev(useContextValue().committed.matches)) {
  | [{ routeId, parameters }, ..._] => Some((routeId, parameters))
  | [] => None
  };
let useSearch = () => (useContextValue().search, updateSearch);
let useUpdateHash = () => updateHash;
let useLocation = () => useContextValue().committed.location;
let useMatches = () => useContextValue().committed.matches;
let locationScope =
    (~committed: RouterRuntime.Navigation.committed, ~children, ()) =>
  provider(
    React.Context.makeProps(
      ~value=
        Some({
          committed,
          search: parseSearch(committed.location.search),
        }),
      ~children,
      (),
    ),
  );

let useInvalidate = ((), _invalidation) => ();

let isCurrent = (~location: RouterRuntime.Navigation.location, href) =>
  RouterSearchKey.isCurrent(
    ~pathname=location.pathname,
    ~search=location.search,
    href,
  );

let useIsCurrent = destination =>
  isCurrent(~location=useLocation(), RouterRuntime.href(destination));
let useBlocker = _shouldBlock => Unblocked;

let outlet = (~owner, ~children, ()) =>
  RouterOutlet.make(
    ~key=owner,
    RouterOutlet.makeProps(~owner, ~children, ()),
  );

let suspense = (~fallback, ~children, ()) =>
  <React.Suspense fallback> children </React.Suspense>;

let errorBoundary = (~fallback, ~children, ()) =>
  RouterErrorBoundary.make(
    RouterErrorBoundary.makeProps(~fallback, ~children, ()),
  );

module Link = {
  type attributes = {
    id: option(string),
    title: option(string),
    rel: option(string),
    ariaLabel: option(string),
    style: option(ReactDOM.Style.t),
    data: list((string, string)),
  };

  let attributes =
      (
        ~id=?,
        ~title=?,
        ~rel=?,
        ~ariaLabel=?,
        ~style=?,
        ~data=[],
        ~anchorRef as _: option(ReactDOM.domRef)=?,
        ~onClick as _: option(React.Event.Mouse.t => unit)=?,
        ~onMouseEnter as _: option(React.Event.Mouse.t => unit)=?,
        (),
      ) => {
    id,
    title,
    rel,
    ariaLabel,
    style,
    data,
  };

  let noAttributes = attributes();

  [@react.component]
  let make =
      (
        ~destination,
        ~className=?,
        ~target=?,
        ~download=?,
        ~ariaCurrent=?,
        ~id=?,
        ~title=?,
        ~rel=?,
        ~ariaLabel=?,
        ~style=?,
        ~data=[],
        ~anchorRef as _: option(ReactDOM.domRef)=?,
        ~attributes=noAttributes,
        ~onClick as _=?,
        ~onMouseEnter as _=?,
        ~history as _=?,
        ~revalidate as _=?,
        ~children,
      ) => {
    let either = (flat, fromAttributes) =>
      switch (flat) {
      | Some(_) => flat
      | None => fromAttributes
      };
    let id = either(id, attributes.id);
    let title = either(title, attributes.title);
    let rel = either(rel, attributes.rel);
    let ariaLabel = either(ariaLabel, attributes.ariaLabel);
    let style = either(style, attributes.style);
    let href = RouterRuntime.href(destination);
    let dataRouterPrefetch =
      switch (RouterRuntime.prefetchLevel(destination)) {
      | RouterRuntime.PrefetchLevel.Intent => None
      | level => Some(RouterRuntime.PrefetchLevel.toString(level))
      };
    let routerContext = React.useContext(context);
    let dataRouterLink =
      switch (ariaCurrent, routerContext) {
      | (None, Some(_)) => Some("")
      | (Some(_), _)
      | (None, None) => None
      };
    let ariaCurrent =
      switch (ariaCurrent) {
      | Some(_) => ariaCurrent
      | None =>
        switch (routerContext) {
        | Some({ committed, _ })
            when isCurrent(~location=committed.location, href) =>
          Some("page")
        | Some(_)
        | None => None
        }
      };
    let link =
      <a
        href
        ?className
        ?target
        ?download
        ?ariaCurrent
        ?id
        ?title
        ?rel
        ?ariaLabel
        ?style
        ?dataRouterPrefetch
        ?dataRouterLink>
        children
      </a>;
    switch (
      List.filter(
        ((name, _)) => RouterTypes.validAttributeName(name),
        attributes.data @ data,
      )
    ) {
    | [] => link
    | data =>
      React.cloneElement(
        link,
        List.map(
          ((name, value)) => {
            let name = "data-" ++ name;
            React.JSX.String((name, name, value));
          },
          data,
        ),
      )
    };
  };
};

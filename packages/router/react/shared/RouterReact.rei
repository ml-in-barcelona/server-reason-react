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

module Provider: {
  [@react.component]
  let make:
    (
      ~initial: RouterRuntime.Navigation.committed,
      ~protocolVersion: int=?,
      ~registryFingerprint: string,
      ~basePath: string,
      ~children: React.element,
      unit
    ) =>
    React.element;
};

let useNavigation:
  unit => (option(navigate), RouterRuntime.Navigation.status);
let useCommitted: unit => option(RouterRuntime.Navigation.committed);
let useSearchValues: unit => list((string, list(string)));
let useUpdateSearch: unit => option(updateSearch);
let useUpdateHash: unit => option(updateHash);
let useIsActive:
  (
    ~routeId: string,
    ~parameters: list((string, string)),
    ~includeDescendants: bool
  ) =>
  bool;
let outlet: (~owner: string, ~children: React.element, unit) => React.element;
let suspense:
  (~fallback: React.element, ~children: React.element, unit) => React.element;

let link:
  (
    ~destination: RouterRuntime.destination,
    ~className: string=?,
    ~target: string=?,
    ~download: string=?,
    ~ariaCurrent: string=?,
    ~options: options=?,
    ~children: React.element,
    unit
  ) =>
  React.element;

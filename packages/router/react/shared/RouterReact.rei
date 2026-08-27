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

module Provider: {
  [@react.component]
  let make:
    (
      ~initial: RouterRuntime.Navigation.committed,
      ~protocolVersion: int=?,
      ~registryFingerprint: string,
      ~basePath: string,
      ~metadata: React.element,
      ~children: React.element,
      unit
    ) =>
    React.element;
};

let useNavigation: unit => (navigate, RouterRuntime.Navigation.status);
let useCurrentRoute: unit => option((string, list((string, string))));
let useSearch: unit => (list((string, list(string))), updateSearch);
let useUpdateHash: unit => updateHash;
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
    ~history: RouterRuntime.Navigation.historyAction=?,
    ~revalidate: bool=?,
    ~children: React.element,
    unit
  ) =>
  React.element;

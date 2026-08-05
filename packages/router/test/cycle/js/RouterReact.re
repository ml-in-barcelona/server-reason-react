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

let link =
    (
      ~destination as _,
      ~className as _=?,
      ~target as _=?,
      ~download as _=?,
      ~ariaCurrent as _=?,
      ~options as _=?,
      ~children,
      (),
    ) => children;
let useNavigation = () => (None, RouterRuntime.Navigation.Idle);
let useSearchValues = () => [];
let useUpdateSearch = () => None;
let useUpdateHash = () => None;
let useIsActive = (~routeId as _, ~parameters as _, ~includeDescendants as _) =>
  false;

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

let link =
    (
      ~destination as _,
      ~className as _=?,
      ~target as _=?,
      ~download as _=?,
      ~ariaCurrent as _=?,
      ~history as _=?,
      ~revalidate as _=?,
      ~children,
      (),
    ) => children;
let navigate: navigate = (~history as _=?, ~revalidate as _=?, _destination) =>
  assert(false);
let updateSearch: updateSearch =
    (~owned as _, ~values as _, ~history as _=?, ()) =>
  assert(false);
let updateHash: updateHash = (~hash as _, ~history as _=?, ()) =>
  assert(false);
let useNavigation = () => (navigate, RouterRuntime.Navigation.Idle);
let useSearch = () => ([], updateSearch);
let useUpdateHash = () => updateHash;
let useIsActive = (~routeId as _, ~parameters as _, ~includeDescendants as _) =>
  false;

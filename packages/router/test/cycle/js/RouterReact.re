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
type updateSearchWith =
  (
    ~owned: list(string),
    ~history: RouterRuntime.Navigation.historyAction=?,
    list((string, list(string))) => list((string, list(string)))
  ) =>
  navigationResult;
type updateHash =
  (~hash: string, ~history: RouterRuntime.Navigation.historyAction=?, unit) =>
  navigationResult;

module Link = {
  let makeProps =
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
  let make = children => children;
};
let navigate: navigate = (~history as _=?, ~revalidate as _=?, _destination) =>
  assert(false);
let searchValues: ref(list((string, list(string)))) = ref([]);
let searchUpdates:
  ref(list((list(string), list((string, list(string)))))) =
  ref([]);
let updateSearch: updateSearch = (~owned, ~values, ~history as _=?, ()) => {
  searchUpdates := [(owned, values), ...searchUpdates^];
  RouterRuntime.Navigation.Result.Canceled;
};
let updateSearchWith: updateSearchWith = (~owned, ~history as _=?, update) => {
  let values = update(searchValues^);
  searchUpdates := [(owned, values), ...searchUpdates^];
  searchValues := RouterRuntime.Search.update(~owned, ~values, searchValues^);
  RouterRuntime.Navigation.Result.Canceled;
};
let updateHash: updateHash = (~hash as _, ~history as _=?, ()) =>
  assert(false);
let useNavigation = () => (navigate, RouterRuntime.Navigation.Idle);
let useCurrentRoute = () => None;
let useSearch = () => (searchValues^, updateSearch);
let useUpdateSearchWith = () => updateSearchWith;
let useUpdateHash = () => updateHash;

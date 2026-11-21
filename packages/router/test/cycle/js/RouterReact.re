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

module Link = {
  type attributes = unit;
  let makeProps =
      (
        ~destination as _,
        ~attributes as _: option(attributes)=?,
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
let updateHash: updateHash = (~hash as _, ~history as _=?, ()) =>
  assert(false);
let useNavigation = () => (navigate, RouterRuntime.Navigation.Idle);
let currentRoute: ref(option((string, list((string, string))))) =
  ref(None);
let matches: ref(list(RouterRuntime.Navigation.matched)) = ref([]);
let useCurrentRoute = () => currentRoute^;
let useMatches = () => matches^;
let useLocation = () =>
  RouterRuntime.Navigation.{
    pathname: "/",
    search: "",
    hash: "",
    key: "test",
  };
let useIsCurrent = _destination => false;
let useBlocker = _shouldBlock => Unblocked;
let useInvalidate = ((), _invalidation) => ();
let useSearch = () => (searchValues^, updateSearch);
let useUpdateHash = () => updateHash;

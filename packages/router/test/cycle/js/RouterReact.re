type options = RouterRuntime.Link.options;
type navigationResult = RouterRuntime.Navigation.Result.t;
type navigate =
  (~options: options, RouterRuntime.destination) =>
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

let link = (~destination as _, ~children, ~options as _=?, ()) => children;
let useNavigate = () => None;
let useNavigation = () => RouterRuntime.Navigation.Idle;
let useSearchValues = () => [];
let useUpdateSearch = () => None;
let useUpdateHash = () => None;
let useIsActive = (~routeId as _, ~parameters as _, ~includeDescendants as _) =>
  false;

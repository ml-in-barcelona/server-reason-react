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

/** How the router recovered from a failed client navigation. */
type navigationErrorRecovery =
  | StayOnPage
  | FullLoad;

/** A failed client navigation: the URL it targeted and why it failed. */
type navigationError = {
  target: string,
  message: string,
  recovery: navigationErrorRecovery,
};

/** A navigation held by [useBlocker]. [proceed] resumes it; [cancel] drops it
    and its [navigate] promise resolves to [Canceled]. */
type blocker =
  | Unblocked
  | Blocked({
      target: string,
      action: RouterRuntime.Navigation.historyAction,
      proceed: unit => unit,
      cancel: unit => unit,
    });

/** Which cached navigation responses [useInvalidate] drops: every entry, or
    the entries whose path is the destination's path or below it. */
type invalidation =
  | All
  | Prefix(RouterRuntime.destination);

module Provider: {
  [@react.component]
  let make:
    (
      ~initial: RouterRuntime.Navigation.committed,
      ~protocolVersion: int=?,
      ~registryFingerprint: string,
      ~basePath: string,
      ~pageCacheCapacity: int=?,
      ~pageCacheMaxAge: float=?,
      ~routes: array(string)=?,
      ~interceptLinks: bool=?,
      ~viewTransitions: bool=?,
      ~onNavigationError: navigationError => unit=?,
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
let useLocation: unit => RouterRuntime.Navigation.location;

/** Every route active at the committed location, outermost first: the
    matched route and each route whose path is a prefix of it. */
let useMatches: unit => list(RouterRuntime.Navigation.matched);

/** Gives [Link]s rendered in server components the committed location, so
    their [aria-current] is the same in the Flight payload and in the HTML.
    The server wraps each routed element with it. In the browser it returns
    [children]. */
let locationScope:
  (
    ~committed: RouterRuntime.Navigation.committed,
    ~children: React.element,
    unit
  ) =>
  React.element;

/** Drops cached navigation responses. Call it after a change on the server
    that cached pages do not show. */
let useInvalidate: (unit, invalidation) => unit;

/** True when the destination has the path and search of the current location,
    in any query order. The hash is ignored. */
let useIsCurrent: RouterRuntime.destination => bool;

/** While the argument is true, [navigate], [Link], intercepted clicks, and
    Back or Forward to other content wait for [proceed] or [cancel]. */
let useBlocker: bool => blocker;
let outlet: (~owner: string, ~children: React.element, unit) => React.element;
let suspense:
  (~fallback: React.element, ~children: React.element, unit) => React.element;

/** Renders [children], or [fallback] once rendering [children] in the
    browser throws. It shows [children] again after the next content
    navigation commits. Generated routes wrap each scope that declares
    [~error] with it. */
let errorBoundary:
  (~fallback: React.element, ~children: React.element, unit) => React.element;

module Link: {
  /** Anchor attributes for a generated route link, whose labelled arguments
      are its path parameters. [data] entries render as [data-<name>]. */
  type attributes;

  let attributes:
    (
      ~id: string=?,
      ~title: string=?,
      ~rel: string=?,
      ~ariaLabel: string=?,
      ~style: ReactDOM.Style.t=?,
      ~data: list((string, string))=?,
      ~anchorRef: ReactDOM.domRef=?,
      ~onClick: React.Event.Mouse.t => unit=?,
      ~onMouseEnter: React.Event.Mouse.t => unit=?,
      unit
    ) =>
    attributes;

  [@react.component]
  let make:
    (
      ~destination: RouterRuntime.destination,
      ~className: string=?,
      ~target: string=?,
      ~download: string=?,
      ~ariaCurrent: string=?,
      ~id: string=?,
      ~title: string=?,
      ~rel: string=?,
      ~ariaLabel: string=?,
      ~style: ReactDOM.Style.t=?,
      ~data: list((string, string))=?,
      ~anchorRef: ReactDOM.domRef=?,
      ~attributes: attributes=?,
      ~onClick: React.Event.Mouse.t => unit=?,
      ~onMouseEnter: React.Event.Mouse.t => unit=?,
      ~history: RouterRuntime.Navigation.historyAction=?,
      ~revalidate: bool=?,
      ~children: React.element,
      unit
    ) =>
    React.element;
};

module DOM = Webapi.Dom;
module Location = DOM.Location;
module Response = RouterRuntime.NavigationResponse;
module Navigation = RouterRuntime.Navigation;

type navigationResult = Navigation.Result.t;
type navigate =
  (
    ~history: Navigation.historyAction=?,
    ~revalidate: bool=?,
    RouterRuntime.destination
  ) =>
  Js.Promise.t(navigationResult);
type updateSearch =
  (
    ~owned: list(string),
    ~values: list((string, list(string))),
    ~history: Navigation.historyAction=?,
    unit
  ) =>
  navigationResult;
type updateSearchWith =
  (
    ~owned: list(string),
    ~history: Navigation.historyAction=?,
    list((string, list(string))) => list((string, list(string)))
  ) =>
  navigationResult;
type updateHash =
  (~hash: string, ~history: Navigation.historyAction=?, unit) =>
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
      action: Navigation.historyAction,
      proceed: unit => unit,
      cancel: unit => unit,
    });

type invalidation =
  | All
  | Prefix(RouterRuntime.destination);

type activeWhen =
  | Url
  | Route
  | Subtree;

let activeRule =
  fun
  | Url => ""
  | Route => "route"
  | Subtree => "subtree";

let isActive = (~activeWhen, ~location, href) =>
  RouterPolicy.linkMatches(~rule=activeRule(activeWhen), ~location, href);

let pendingTarget = status =>
  switch (status) {
  | Navigation.Loading({ to_, _ }) => Some(to_)
  | Navigation.Idle
  | Navigation.Failed(_) => None
  };

type contextValue = {
  navigate,
  invalidate: invalidation => unit,
  navigation: Navigation.status,
  committed: Navigation.committed,
  search: list((string, list(string))),
  updateSearch,
  updateSearchWith,
  updateHash,
  blockers: RouterBlocker.t,
  blocked: option(RouterBlocker.request),
};

type actions = {
  navigate,
  invalidate: invalidation => unit,
  updateSearch,
  updateSearchWith,
  updateHash,
};

type model = {
  navigationState: Navigation.state,
  metadata: React.element,
  element: React.element,
  patchOperation: RouterOutlet.operation,
  restore: option((Navigation.historyAction, string, string)),
};

type pendingCommit = {
  next: model,
  finish: unit => unit,
  resolve: navigationResult => unit,
};

type activeRequest = {
  requestId: int,
  abort: unit => unit,
};

type options = {
  interceptLinks: bool,
  viewTransitions: bool,
  onNavigationError: option(navigationError => unit),
};

[@mel.send]
external addDocumentListener:
  (DOM.Document.t, string, RouterPolicy.event => unit) => unit =
  "addEventListener";
[@mel.send]
external removeDocumentListener:
  (DOM.Document.t, string, RouterPolicy.event => unit) => unit =
  "removeEventListener";
[@mel.send]
external preventDefault: RouterPolicy.event => unit = "preventDefault";
[@mel.set]
external setReturnValue: (RouterPolicy.event, string) => unit = "returnValue";
[@mel.get] external persisted: RouterPolicy.event => bool = "persisted";
[@mel.send]
external addWindowListener:
  (DOM.Window.t, string, RouterPolicy.event => unit) => unit =
  "addEventListener";
[@mel.send]
external removeWindowListener:
  (DOM.Window.t, string, RouterPolicy.event => unit) => unit =
  "removeEventListener";

let context: React.Context.t(option(contextValue)) =
  React.createContext(None);
let provider = React.Context.provider(context);
let outlet = (~owner, ~children, ()) =>
  <RouterOutlet key=owner owner> children </RouterOutlet>;

let suspense = (~fallback, ~children, ()) =>
  <React.Suspense fallback> children </React.Suspense>;

let errorBoundary = (~fallback, ~children, ()) =>
  <RouterErrorBoundary fallback> children </RouterErrorBoundary>;

let currentUrl = () => {
  let location = DOM.window->DOM.Window.location;
  Location.pathname(location)
  ++ Location.search(location)
  ++ Location.hash(location);
};

let currentPage = () => {
  let location = DOM.window->DOM.Window.location;
  RouterPolicy.{
    href: Location.href(location),
    origin: Location.origin(location),
    pathname: Location.pathname(location),
    search: Location.search(location),
  };
};

let locationFromUrl = (~key, url) => {
  let browserLocation = DOM.window->DOM.Window.location;
  let parsed =
    Webapi.Url.makeWith(url, ~base=Location.href(browserLocation));
  Navigation.{
    pathname: Webapi.Url.pathname(parsed),
    search: Webapi.Url.search(parsed),
    hash: Webapi.Url.hash(parsed),
    key,
  };
};

let clientErrorMessage = error =>
  switch (error) {
  | RouterClient.MissingResponseKind => "navigation response kind is missing"
  | RouterClient.InvalidResponseKind(_) => "navigation response kind is invalid"
  | RouterClient.InvalidContentType(_) => "navigation response has an invalid content type"
  | RouterClient.PrefetchRefused(_) => "the server refused a prefetch"
  };

let replayLayers =
    (~protocolVersion, ~registryFingerprint, ~canonicalUrlAllowed, layers) =>
  layers
  |> List.map((layer: RouterNavigationCache.layer(_)) =>
       layer.bytes
       |> Js.Promise.then_(bytes =>
            RouterClient.decodeBytes(
              ~kind=
                Option.is_some(layer.graftAt)
                  ? Response.PatchResponse : Response.FullResponse,
              bytes,
            )
          )
     )
  |> Array.of_list
  |> Js.Promise.all
  |> Js.Promise.then_(responses =>
       Js.Promise.resolve(
         switch (Array.to_list(responses)) {
         | [Response.Full(full), ...rest]
             when
               full.protocolVersion == protocolVersion
               && String.equal(full.registryFingerprint, registryFingerprint) =>
           let rec patches = (accumulated, responses) =>
             switch (responses) {
             | [] => Some(List.rev(accumulated))
             | [Response.Patch(patch), ...responses]
                 when
                   patch.protocolVersion == protocolVersion
                   && String.equal(
                        patch.registryFingerprint,
                        registryFingerprint,
                      ) =>
               patches([patch, ...accumulated], responses)
             | _ => None
             };
           switch (patches([], rest)) {
           | Some(patches) =>
             let (metadata, canonicalUrl, targetRevision, matches, layouts) =
               switch (List.rev(patches)) {
               | [last, ..._] => (
                   last.metadata,
                   last.canonicalUrl,
                   last.targetRevision,
                   last.matches,
                   last.layouts,
                 )
               | [] => (
                   full.metadata,
                   full.canonicalUrl,
                   full.targetRevision,
                   full.matches,
                   full.layouts,
                 )
               };
             canonicalUrlAllowed(canonicalUrl)
               ? Some((
                   metadata,
                   List.map(
                     (patch: Response.patch(React.element)) =>
                       (patch.replaceFrom, patch.payload),
                     patches,
                   ),
                   RouterTransaction.{
                     baseRevision: "",
                     canonicalUrl,
                     targetRevision,
                     matches,
                     layouts,
                     content: Replace(full.payload),
                   },
                 ))
               : None;
           | None => None
           };
         | _ => None
         },
       )
     );

module Provider = {
  [@react.component]
  let make =
      (
        ~initial: Navigation.committed,
        ~protocolVersion=1,
        ~registryFingerprint,
        ~basePath,
        ~pageCacheCapacity=30,
        ~pageCacheMaxAge=0.0,
        ~routes=[||],
        ~interceptLinks=true,
        ~viewTransitions=false,
        ~onNavigationError=?,
        ~metadata,
        ~children,
      ) => {
    let initialModel = {
      navigationState: Navigation.make(initial),
      metadata,
      element: children,
      patchOperation: RouterOutlet.NoPatch,
      restore: None,
    };
    let (routePatterns, _) =
      React.useState(() =>
        routes
        |> Array.to_list
        |> List.filter_map(route =>
             switch (RouterPattern.parse(route)) {
             | Ok(pattern) => Some(pattern)
             | Error(_) => None
             }
           )
      );
    let routed = RouterPolicy.routed(~basePath, ~patterns=routePatterns);
    let (cache, _) =
      React.useState(() =>
        RouterNavigationCache.make(
          ~capacity=pageCacheCapacity,
          ~maxAge=pageCacheMaxAge *. 1000.0,
        )
      );
    let cacheScope =
      RouterNavigationCache.scope(~protocolVersion, ~registryFingerprint);
    let currentLayers = React.useRef(None);
    let (model, setModel) = React.useState(() => initialModel);
    let modelRef = React.useRef(initialModel);
    let activeRequest = React.useRef(None);
    let nextLocationKey = React.useRef(1);
    let position = React.useRef(0);
    let (blockers, _) = React.useState(RouterBlocker.make);
    let (blocked, setBlocked) = React.useState(() => None);
    blockers.notify = (request => setBlocked(_ => request));
    let (viewTransition, _) = React.useState(RouterViewTransition.make);
    let announcer = React.useRef(None);
    let unloadAllowed = React.useRef(false);
    let options =
      React.useRef({
        interceptLinks,
        viewTransitions,
        onNavigationError,
      });
    options.current = {
      interceptLinks,
      viewTransitions,
      onNavigationError,
    };
    let (contentIdentityPrefix, _) =
      React.useState(RouterHistory.freshContentIdentity);
    let contentIdentity = React.useRef(contentIdentityPrefix ++ "-0");
    let restoredContentIdentity = React.useRef("");
    let mutateHistory = (~action, ~key, ~position as next, ~url) => {
      let state =
        RouterHistory.makeState(
          ~key,
          ~revision=contentIdentity.current,
          ~position=next,
        );
      position.current = next;
      switch (Navigation.historyMutation(action)) {
      | Navigation.PushEntry => RouterHistory.push(~state, ~url)
      | Navigation.ReplaceEntry => RouterHistory.replace(~state, ~url)
      };
    };
    let statePosition = () =>
      Option.bind(RouterHistory.state(), RouterHistory.position);
    let nextPosition = action =>
      switch (action) {
      | Navigation.Push => position.current + 1
      | Navigation.Replace => position.current
      | Navigation.Pop =>
        Option.value(statePosition(), ~default=position.current)
      };
    let freshKey = () => {
      let key = "location-" ++ string_of_int(nextLocationKey.current);
      nextLocationKey.current = nextLocationKey.current + 1;
      key;
    };
    let scrollId = key =>
      RouterScroll.entryId(~revision=contentIdentity.current, ~key);
    let rememberScroll = (committed: Navigation.committed) => {
      let window = DOM.window;
      RouterScroll.save(
        scrollId(committed.location.key),
        RouterScroll.capture((
          DOM.Window.scrollX(window),
          DOM.Window.scrollY(window),
        )),
      );
    };
    let reportError = (~target, ~recovery, message) =>
      switch (options.current.onNavigationError) {
      | Some(handler) =>
        handler({
          target,
          message,
          recovery,
        })
      | None => ()
      };
    let focusElement = element =>
      element |> DOM.Element.unsafeAsHtmlElement |> DOM.HtmlElement.focus;
    let restoreLocation = (~kind, action, hash, key) => {
      let window = DOM.window;
      let document = DOM.Window.document(window);
      let saved =
        switch (action) {
        | Navigation.Pop => RouterScroll.find(scrollId(key))
        | Navigation.Push
        | Navigation.Replace => None
        };
      Option.iter(RouterScroll.restoreContainers, saved);
      let saved =
        Option.map((saved: RouterScroll.saved) => saved.window, saved);
      switch (RouterPolicy.scrollFor(~kind, ~saved, hash)) {
      | RouterPolicy.ScrollTo(x, y) => DOM.Window.scrollTo(x, y, window)
      | RouterPolicy.Fragment(id) =>
        switch (DOM.Document.getElementById(id, document)) {
        | Some(element) =>
          focusElement(element);
          DOM.Element.scrollIntoView(element);
        | None => DOM.Window.scrollTo(0.0, 0.0, window)
        }
      | RouterPolicy.Stay => ()
      | RouterPolicy.Top =>
        switch (DOM.Document.getElementById("router-focus-root", document)) {
        | Some(element) => focusElement(element)
        | None => ()
        };
        DOM.Window.scrollTo(0.0, 0.0, window);
      };
    };
    let updateModel = next => {
      modelRef.current = next;
      setModel(_ => next);
    };
    let finishFailure = (~requestId, ~message) => {
      let current = modelRef.current;
      switch (Navigation.status(current.navigationState)) {
      | Navigation.Loading(active) when active.requestId == requestId =>
        let nextState =
          Navigation.fail(current.navigationState, ~requestId, ~message);
        updateModel({
          ...current,
          navigationState: nextState,
        });
        Navigation.Result.Failed(message);
      | Navigation.Idle
      | Navigation.Loading(_)
      | Navigation.Failed(_) => Navigation.Result.Canceled
      };
    };
    let clearActiveRequest = requestId =>
      switch (activeRequest.current) {
      | Some(active) when active.requestId == requestId =>
        activeRequest.current = None
      | _ => ()
      };
    let pendingCommit = React.useRef(None);
    let abortActiveRequest = () => {
      switch (activeRequest.current) {
      | Some(active) =>
        active.abort();
        activeRequest.current = None;
      | None => ()
      };
      switch (pendingCommit.current) {
      | Some(pending) =>
        pendingCommit.current = None;
        pending.resolve(Navigation.Result.Canceled);
      | None => ()
      };
      RouterViewTransition.supersede(viewTransition);
    };
    let hardNavigate = (~replace, url) => {
      let location = DOM.window->DOM.Window.location;
      unloadAllowed.current = true;
      replace
        ? Location.replace(url, location) : Location.assign(url, location);
      Navigation.Result.Redirected(url);
    };
    let failToDocument = (~replace, ~target, message) => {
      reportError(~target, ~recovery=FullLoad, message);
      hardNavigate(~replace, target);
    };
    let commitLocation =
        (~kind, ~action, ~browserEntry=false, location: Navigation.location) => {
      abortActiveRequest();
      let current = modelRef.current;
      let currentCommitted = Navigation.committed(current.navigationState);
      if (!browserEntry) {
        rememberScroll(currentCommitted);
      };
      let key =
        switch (action) {
        | _ when browserEntry => freshKey()
        | Navigation.Push => freshKey()
        | Navigation.Replace => currentCommitted.location.key
        | Navigation.Pop =>
          switch (RouterHistory.state()) {
          | Some(state) => state.key
          | None => currentCommitted.location.key
          }
        };
      let location = {
        ...location,
        key,
      };
      let navigationState =
        switch (kind) {
        | Navigation.Shallow =>
          Navigation.shallow(current.navigationState, ~location, ~action)
        | Navigation.HashOnly =>
          Navigation.hashOnly(current.navigationState, ~location, ~action)
        | Navigation.Content => current.navigationState
        };
      let committed = Navigation.committed(navigationState);
      let url = location.pathname ++ location.search ++ location.hash;
      mutateHistory(
        ~action,
        ~key,
        ~position=browserEntry ? position.current + 1 : nextPosition(action),
        ~url,
      );
      updateModel({
        ...current,
        navigationState,
      });
      switch (kind, action) {
      | (Navigation.HashOnly, _)
      | (Navigation.Shallow, Navigation.Pop) =>
        restoreLocation(~kind, action, location.hash, key)
      | (Navigation.Shallow, Navigation.Push | Navigation.Replace)
      | (Navigation.Content, _) => ()
      };
      Navigation.Result.Committed(committed);
    };
    let searchPushedThisTick = React.useRef(false);
    let commitSearch = (~action, location) => {
      let action =
        switch (action) {
        | Navigation.Push when searchPushedThisTick.current => Navigation.Replace
        | Navigation.Push =>
          searchPushedThisTick.current = true;
          let _ =
            Js.Promise.resolve()
            |> Js.Promise.then_(() => {
                 searchPushedThisTick.current = false;
                 Js.Promise.resolve();
               });
          Navigation.Push;
        | action => action
        };
      commitLocation(~kind=Navigation.Shallow, ~action, location);
    };
    let updateSearch = (~owned, ~values, ~history=Navigation.Replace, ()) => {
      let current = Navigation.committed(modelRef.current.navigationState);
      let nextValues =
        RouterRuntime.Search.update(
          ~owned,
          ~values,
          RouterSearch.valuesFromString(current.location.search),
        );
      let search = RouterSearch.toString(nextValues);
      if (RouterSearch.unchanged(
            ~current=current.location.search,
            ~next=nextValues,
          )) {
        Navigation.Result.Committed(current);
      } else {
        commitSearch(
          ~action=history,
          {
            ...current.location,
            search,
          },
        );
      };
    };
    let updateSearchWith = (~owned, ~history=Navigation.Replace, update) => {
      let current = Navigation.committed(modelRef.current.navigationState);
      updateSearch(
        ~owned,
        ~values=
          update(RouterSearch.valuesFromString(current.location.search)),
        ~history,
        (),
      );
    };
    let updateHash = (~hash, ~history=Navigation.Replace, ()) => {
      let current = Navigation.committed(modelRef.current.navigationState);
      let hash =
        String.equal(hash, "") || String.starts_with(~prefix="#", hash)
          ? hash : "#" ++ hash;
      if (String.equal(hash, current.location.hash)) {
        Navigation.Result.Committed(current);
      } else {
        commitLocation(
          ~kind=Navigation.HashOnly,
          ~action=history,
          {
            ...current.location,
            hash,
          },
        );
      };
    };
    let rec navigateTarget =
            (~action, ~revalidate=false, ~redirects=0, target) => {
      abortActiveRequest();
      let startedIn = RouterNavigationCache.generation(cache);
      let current = modelRef.current;
      rememberScroll(Navigation.committed(current.navigationState));
      let targetLocation =
        locationFromUrl(
          ~key=current.navigationState->Navigation.committed.location.key,
          target,
        );
      let (startedState, requestId) =
        Navigation.start(
          current.navigationState,
          ~to_=targetLocation,
          ~action,
        );
      updateModel({
        ...current,
        navigationState: startedState,
      });
      let committed = Navigation.committed(current.navigationState);
      let from = committed.location.pathname ++ committed.location.search;
      let failNavigation = message =>
        switch (action) {
        | Navigation.Pop =>
          Navigation.isActive(modelRef.current.navigationState, ~requestId)
            ? failToDocument(~replace=true, ~target, message)
            : Navigation.Result.Canceled
        | Navigation.Push
        | Navigation.Replace =>
          switch (finishFailure(~requestId, ~message)) {
          | Navigation.Result.Failed(_) as failed =>
            reportError(~target, ~recovery=StayOnPage, message);
            failed;
          | result => result
          }
        };
      let commitResponse =
          (
            ~metadata,
            ~validatedRequestId,
            ~grafts=[],
            ~fromCache=false,
            ~layers,
            response,
          ) => {
        let current = modelRef.current;
        let currentCommitted = Navigation.committed(current.navigationState);
        let currentHistoryState = RouterHistory.state();
        let historyKey =
          switch (currentHistoryState) {
          | Some(state) => Some(state.key)
          | None => None
          };
        let nextContentIdentity =
          switch (action, currentHistoryState) {
          | (Navigation.Pop, Some(state)) => state.revision
          | (Navigation.Pop, None)
          | (Navigation.Push, _)
          | (Navigation.Replace, _) =>
            contentIdentityPrefix ++ "-" ++ string_of_int(requestId)
          };
        switch (
          RouterTransaction.prepare(
            ~action,
            ~requestId,
            ~validatedRequestId,
            ~currentState=current.navigationState,
            ~currentCommitted,
            ~targetHash=targetLocation.hash,
            ~historyKey,
            ~locationFromUrl,
            response,
          )
        ) {
        | Error(RouterTransaction.InvalidGraft) =>
          failToDocument(
            ~replace=action != Navigation.Push,
            ~target,
            "navigation patch does not fit the current layouts",
          )
          |> Js.Promise.resolve
        | Error(RouterTransaction.Canceled) =>
          Js.Promise.resolve(Navigation.Result.Canceled)
        | Ok(prepared) =>
          let direction =
            switch (action) {
            | Navigation.Push => RouterViewTransition.Push
            | Navigation.Replace => RouterViewTransition.Replace
            | Navigation.Pop =>
              switch (statePosition()) {
              | Some(target) when target < position.current => RouterViewTransition.Back
              | Some(_)
              | None => RouterViewTransition.Forward
              }
            };
          let (element, patchOperation) =
            switch (prepared.render) {
            | RouterTransaction.ReplacePayload(element) => (
                element,
                RouterOutlet.RefreshFull({
                  serial: requestId,
                  grafts,
                }),
              )
            | RouterTransaction.GraftPayload({
                serial,
                graftAt,
                targetLayouts,
                payload,
              }) => (
                current.element,
                RouterOutlet.ApplyPatch({
                  serial,
                  graftAt,
                  targetLayouts,
                  payload,
                }),
              )
            };
          let next = {
            navigationState: prepared.navigationState,
            metadata,
            element,
            patchOperation,
            restore: Some(prepared.restore),
          };
          let finish = () => {
            contentIdentity.current = nextContentIdentity;
            mutateHistory(
              ~action,
              ~key=prepared.key,
              ~position=nextPosition(action),
              ~url=prepared.url,
            );
            currentLayers.current =
              RouterNavigationCache.invalidatedSince(
                cache,
                ~startedIn,
                prepared.committed.location.pathname,
              )
                ? None : layers;
            modelRef.current = next;
          };
          switch (layers) {
          | Some(layers) when !fromCache =>
            RouterNavigationCache.store(
              cache,
              ~scope=cacheScope,
              ~pathname=prepared.committed.location.pathname,
              ~search=prepared.committed.location.search,
              ~now=Js.Date.now(),
              ~startedIn,
              layers,
            )
          | Some(_)
          | None => ()
          };
          if (options.current.viewTransitions
              && RouterViewTransition.supported()
              && !RouterViewTransition.reducedMotion()) {
            finish();
            RouterViewTransition.run(
              viewTransition, ~enabled=true, ~direction, () =>
              ReactDOM.flushSync(() => setModel(_ => modelRef.current))
            );
            Js.Promise.resolve(
              Navigation.Result.Committed(prepared.committed),
            );
          } else {
            Js.Promise.make((~resolve, ~reject as _) => {
              pendingCommit.current =
                Some({
                  next,
                  finish,
                  resolve: result => resolve(. result),
                });
              React.startTransition(() => setModel(_ => next));
            });
          };
        };
      };
      let fetchNetwork = () => {
        let pending =
          RouterClient.fetch(
            ~protocolVersion,
            ~registryFingerprint,
            ~requestId,
            ~baseRevision=committed.revision,
            ~from=
              RouterNavigationCache.sendsPatchBase(
                cache,
                ~revalidate,
                ~composable=Option.is_some(currentLayers.current),
              )
                ? Some(from) : None,
            ~target,
            (),
          );
        activeRequest.current =
          Some({
            requestId,
            abort: pending.abort,
          });
        pending.response
        |> Js.Promise.then_(decoded => {
             clearActiveRequest(requestId);
             switch (decoded) {
             | Error(RouterClient.MissingResponseKind as error) =>
               Navigation.isActive(
                 modelRef.current.navigationState,
                 ~requestId,
               )
                 ? failToDocument(
                     ~replace=action != Navigation.Push,
                     ~target,
                     clientErrorMessage(error),
                   )
                   |> Js.Promise.resolve
                 : Js.Promise.resolve(Navigation.Result.Canceled)
             | Error(error) =>
               failNavigation(clientErrorMessage(error))
               |> Js.Promise.resolve
             | Ok(decoded: RouterClient.decoded) =>
               let current = modelRef.current;
               let currentCommitted =
                 Navigation.committed(current.navigationState);
               let activeRequestId =
                 switch (Navigation.status(current.navigationState)) {
                 | Navigation.Loading(active) => active.requestId
                 | Navigation.Idle
                 | Navigation.Failed(_) => (-1)
                 };
               switch (
                 Response.validate(
                   ~expectedProtocolVersion=protocolVersion,
                   ~expectedRegistryFingerprint=registryFingerprint,
                   ~activeRequestId,
                   ~committedRevision=currentCommitted.revision,
                   ~canonicalUrlAllowed=
                     url =>
                       Option.is_some(
                         RouterPolicy.routerUrl(
                           ~basePath,
                           ~page=currentPage(),
                           url,
                         ),
                       ),
                   decoded.facts,
                   decoded.response,
                 )
               ) {
               | Error(error) =>
                 switch (RouterPolicy.validationOutcome(error)) {
                 | RouterPolicy.Ignore =>
                   Js.Promise.resolve(Navigation.Result.Canceled)
                 | RouterPolicy.FullLoad(message) =>
                   failToDocument(
                     ~replace=action != Navigation.Push,
                     ~target,
                     message,
                   )
                   |> Js.Promise.resolve
                 | RouterPolicy.Fail(message) =>
                   failNavigation(message) |> Js.Promise.resolve
                 }
               | Ok(validated) =>
                 switch (validated.response) {
                 | Response.ReloadRequired =>
                   hardNavigate(~replace=action != Navigation.Push, target)
                   |> Js.Promise.resolve
                 | Response.Redirect(redirect) =>
                   switch (
                     RouterPolicy.redirect(
                       ~basePath,
                       ~page=currentPage(),
                       ~followed=redirects,
                       redirect.location,
                     )
                   ) {
                   | RouterPolicy.FollowRedirect(url) =>
                     navigateTarget(
                       ~action,
                       ~revalidate,
                       ~redirects=redirects + 1,
                       url,
                     )
                   | RouterPolicy.LoadDocument(url) =>
                     hardNavigate(~replace=action != Navigation.Push, url)
                     |> Js.Promise.resolve
                   | RouterPolicy.RefuseRedirect(_) =>
                     failNavigation(
                       "redirect target is not an http or https URL",
                     )
                     |> Js.Promise.resolve
                   }
                 | Response.Patch(response) =>
                   commitResponse(
                     ~metadata=response.metadata,
                     ~validatedRequestId=validated.requestId,
                     ~layers=
                       switch (currentLayers.current, decoded.bytes) {
                       | (Some(layers), Some(bytes))
                           when
                             RouterNavigationCache.storable(
                               ~httpStatus=decoded.facts.status,
                               ~status=response.status,
                             ) =>
                         Some(
                           RouterNavigationCache.compose(
                             layers,
                             ~graftAt=response.replaceFrom,
                             ~layouts=
                               List.map(
                                 (layout: Navigation.layout) =>
                                   layout.instanceKey,
                                 response.layouts,
                               ),
                             bytes,
                           ),
                         )
                       | _ => None
                       },
                     RouterTransaction.{
                       baseRevision: response.baseRevision,
                       canonicalUrl: response.canonicalUrl,
                       targetRevision: response.targetRevision,
                       matches: response.matches,
                       layouts: response.layouts,
                       content:
                         Graft({
                           graftAt: response.replaceFrom,
                           payload: response.payload,
                         }),
                     },
                   )
                 | Response.Full(response) =>
                   commitResponse(
                     ~metadata=response.metadata,
                     ~validatedRequestId=validated.requestId,
                     ~layers=
                       RouterNavigationCache.storable(
                         ~httpStatus=decoded.facts.status,
                         ~status=response.status,
                       )
                         ? Option.map(
                             bytes =>
                               [
                                 RouterNavigationCache.{
                                   graftAt: None,
                                   bytes,
                                 },
                               ],
                             decoded.bytes,
                           )
                         : None,
                     RouterTransaction.{
                       baseRevision: validated.baseRevision,
                       canonicalUrl: response.canonicalUrl,
                       targetRevision: response.targetRevision,
                       matches: response.matches,
                       layouts: response.layouts,
                       content: Replace(response.payload),
                     },
                   )
                 }
               };
             };
           })
        |> Js.Promise.catch(_error => {
             clearActiveRequest(requestId);
             failNavigation("navigation request failed") |> Js.Promise.resolve;
           });
      };
      let fetchIfActive = () =>
        Navigation.isActive(modelRef.current.navigationState, ~requestId)
          ? fetchNetwork() : Js.Promise.resolve(Navigation.Result.Canceled);
      switch (
        RouterNavigationCache.read(
          cache,
          ~scope=cacheScope,
          ~pathname=targetLocation.pathname,
          ~search=targetLocation.search,
          ~action,
          ~revalidate,
          ~now=Js.Date.now(),
        )
      ) {
      | Some(entry) =>
        replayLayers(
          ~protocolVersion,
          ~registryFingerprint,
          ~canonicalUrlAllowed=
            url =>
              Option.is_some(
                RouterPolicy.routerUrl(~basePath, ~page=currentPage(), url),
              ),
          entry.layers,
        )
        |> Js.Promise.then_(replayed =>
             switch (replayed) {
             | Some((metadata, grafts, response)) =>
               commitResponse(
                 ~metadata,
                 ~validatedRequestId=requestId,
                 ~grafts,
                 ~fromCache=true,
                 ~layers=Some(entry.layers),
                 {
                   ...response,
                   RouterTransaction.baseRevision: committed.revision,
                 },
               )
             | None => fetchIfActive()
             }
           )
        |> Js.Promise.catch(_ => fetchIfActive())
      | None => fetchNetwork()
      };
    };
    let guarded = (~action, ~target, run) =>
      if (RouterBlocker.blocking(blockers)) {
        Js.Promise.make((~resolve, ~reject as _) =>
          RouterBlocker.hold(
            blockers,
            ~target,
            ~action,
            ~resume=
              () => {
                let _ =
                  run()
                  |> Js.Promise.then_(result => {
                       resolve(. result);
                       Js.Promise.resolve();
                     });
                ();
              },
            ~drop=() => resolve(. Navigation.Result.Canceled),
          )
        );
      } else {
        run();
      };
    let guardedNavigate = (~action, ~revalidate, target) =>
      guarded(~action, ~target, () =>
        navigateTarget(~action, ~revalidate, target)
      );
    let navigateUrl = (~action, ~revalidate, ~shallowKeys=[], target) => {
      let state = modelRef.current.navigationState;
      let committed = Navigation.committed(state);
      if (RouterPolicy.unchangedTarget(
            ~location=committed.location,
            ~status=Navigation.status(state),
            ~action,
            ~revalidate,
            target,
          )) {
        Js.Promise.resolve(Navigation.Result.Committed(committed));
      } else {
        switch (
          RouterPolicy.hashOnlyTarget(
            ~location=committed.location,
            ~action,
            ~revalidate,
            target,
          ),
          RouterPolicy.shallowSearchTarget(
            ~location=committed.location,
            ~action,
            ~revalidate,
            ~shallowKeys,
            target,
          ),
        ) {
        | (Some(hash), _) =>
          guarded(~action, ~target, () =>
            Js.Promise.resolve(updateHash(~hash, ~history=action, ()))
          )
        | (None, Some((search, hash))) =>
          Js.Promise.resolve(
            commitSearch(
              ~action,
              {
                ...committed.location,
                search,
                hash,
              },
            ),
          )
        | (None, None) => guardedNavigate(~action, ~revalidate, target)
        };
      };
    };
    let navigate = (~history=Navigation.Push, ~revalidate=false, destination) =>
      navigateUrl(
        ~action=history,
        ~revalidate,
        ~shallowKeys=RouterRuntime.shallowSearch(destination),
        RouterRuntime.href(destination),
      );
    let (prefetcher, _) =
      React.useState(() => RouterPrefetch.make(~limit=4));
    let prefetchAborts = React.useRef([]);
    let invalidate = invalidation => {
      let invalidation =
        switch (invalidation) {
        | All => RouterNavigationCache.All
        | Prefix(destination) =>
          RouterNavigationCache.Prefix(
            fst(RouterSearchKey.splitHref(RouterRuntime.href(destination))),
          )
        };
      RouterNavigationCache.invalidate(cache, invalidation);
      RouterPrefetch.clear(prefetcher);
      List.iter(((_, abort)) => abort(), prefetchAborts.current);
      prefetchAborts.current = [];
      if (RouterNavigationCache.matches(
            invalidation,
            Navigation.committed(modelRef.current.navigationState).location.
              pathname,
          )) {
        currentLayers.current = None;
      };
    };
    let nextPrefetchId = React.useRef(0);
    let viewportObserver = React.useRef(None);
    let runPrefetch = (request: RouterPrefetch.request, finish) => {
      let committed = Navigation.committed(modelRef.current.navigationState);
      let startedIn = RouterNavigationCache.generation(cache);
      nextPrefetchId.current = nextPrefetchId.current + 1;
      let requestId = - nextPrefetchId.current;
      let pending =
        RouterClient.fetch(
          ~protocolVersion,
          ~registryFingerprint,
          ~requestId,
          ~baseRevision=committed.revision,
          ~from=None,
          ~prefetch=request.trigger,
          ~target=request.url,
          (),
        );
      prefetchAborts.current = [
        (requestId, pending.abort),
        ...prefetchAborts.current,
      ];
      let settle = () => {
        prefetchAborts.current =
          List.remove_assoc(requestId, prefetchAborts.current);
        finish();
        Js.Promise.resolve();
      };
      let _ =
        pending.response
        |> Js.Promise.then_(result => {
             switch (result) {
             | Error(RouterClient.PrefetchRefused(level)) =>
               RouterPrefetch.refuse(prefetcher, ~url=request.url, level)
             | Ok(decoded: RouterClient.decoded) =>
               switch (
                 Response.validate(
                   ~expectedProtocolVersion=protocolVersion,
                   ~expectedRegistryFingerprint=registryFingerprint,
                   ~activeRequestId=requestId,
                   ~committedRevision=committed.revision,
                   ~canonicalUrlAllowed=
                     url =>
                       Option.is_some(
                         RouterPolicy.routerUrl(
                           ~basePath,
                           ~page=currentPage(),
                           url,
                         ),
                       ),
                   decoded.facts,
                   decoded.response,
                 ),
                 decoded.bytes,
               ) {
               | (Ok({ response: Response.Full(full), _ }), Some(bytes))
                   when
                     RouterNavigationCache.storable(
                       ~httpStatus=decoded.facts.status,
                       ~status=full.status,
                     ) =>
                 let location = locationFromUrl(~key="", full.canonicalUrl);
                 RouterNavigationCache.store(
                   cache,
                   ~scope=cacheScope,
                   ~pathname=location.pathname,
                   ~search=location.search,
                   ~now=Js.Date.now(),
                   ~startedIn,
                   ~prefetched=true,
                   [
                     {
                       graftAt: None,
                       bytes,
                     },
                   ],
                 );
               | _ => ()
               }
             | Error(_) => ()
             };
             settle();
           })
        |> Js.Promise.catch(_ => settle());
      ();
    };
    let prefetchUrl = (~trigger, ~level, url) =>
      if (pageCacheCapacity > 0 && !RouterPolicy.saveData()) {
        let location = locationFromUrl(~key="", url);
        let committed =
          Navigation.committed(modelRef.current.navigationState).location;
        let url = location.pathname ++ location.search;
        if (!String.equal(url, committed.pathname ++ committed.search)
            && !
                 RouterNavigationCache.hasFresh(
                   cache,
                   ~scope=cacheScope,
                   ~pathname=location.pathname,
                   ~search=location.search,
                   ~now=Js.Date.now(),
                 )) {
          RouterPrefetch.request(
            prefetcher,
            ~run=runPrefetch,
            ~url,
            ~level,
            ~trigger,
          );
        };
      };
    let prefetchAnchor = (~trigger, anchor) =>
      switch (
        RouterPolicy.prefetchTarget(~basePath, ~page=currentPage(), anchor)
      ) {
      | Some((url, level)) when routed(url) =>
        prefetchUrl(~trigger, ~level, url)
      | Some(_)
      | None => ()
      };
    React.useEffect1(
      () =>
        if (pageCacheCapacity > 0) {
          if (Option.is_none(viewportObserver.current)) {
            viewportObserver.current =
              Js.Nullable.toOption(
                RouterPolicy.observeAnchors(
                  prefetchAnchor(
                    ~trigger=RouterRuntime.PrefetchLevel.Viewport,
                  ),
                ),
              );
          };
          switch (viewportObserver.current) {
          | Some(observer) =>
            Array.iter(
              RouterPolicy.observe(observer),
              RouterPolicy.anchorsWithLevels([|"viewport", "idle"|]),
            )
          | None => ()
          };
          let cancelIdle =
            RouterPolicy.onIdle(() =>
              RouterPolicy.anchorsWithLevels([|"idle"|])
              |> Array.to_list
              |> RouterPrefetch.take(15)
              |> List.iter(
                   prefetchAnchor(~trigger=RouterRuntime.PrefetchLevel.Idle),
                 )
            );
          Some(cancelIdle);
        } else {
          None;
        },
      [|Navigation.committed(model.navigationState)|],
    );
    React.useEffect0(() => {
      RouterHistory.scrollRestoration("manual");
      let window = DOM.window;
      let document = DOM.Window.document(window);
      let current = modelRef.current;
      let committed = Navigation.committed(current.navigationState);
      let browserHash = window->DOM.Window.location->Location.hash;
      let previousEntry = RouterHistory.state();
      position.current = (
        switch (Option.bind(previousEntry, RouterHistory.position)) {
        | Some(previous) => previous
        | None => RouterHistory.length() - 1
        }
      );
      let committed =
        if (String.equal(browserHash, committed.location.hash)) {
          committed;
        } else {
          let location = {
            ...committed.location,
            hash: browserHash,
          };
          let navigationState =
            Navigation.shallow(
              current.navigationState,
              ~location,
              ~action=Navigation.Replace,
            );
          let next = {
            ...current,
            navigationState,
          };
          updateModel(next);
          Navigation.committed(navigationState);
        };
      switch (previousEntry) {
      | Some(state) when String.equal(browserHash, "") =>
        switch (
          RouterScroll.find(
            RouterScroll.entryId(~revision=state.revision, ~key=state.key),
          )
        ) {
        | Some(saved) =>
          RouterScroll.restoreContainers(saved);
          let (x, y) = saved.window;
          DOM.Window.scrollTo(x, y, window);
        | None => ()
        }
      | Some(_)
      | None => ()
      };
      mutateHistory(
        ~action=Navigation.Replace,
        ~key=committed.location.key,
        ~position=position.current,
        ~url=currentUrl(),
      );
      announcer.current = Some(RouterAnnouncer.mount());
      let stopServerCalls =
        ReactServerDOMEsbuild.onServerCallSuccess(() => invalidate(All));
      let stopActionRedirects =
        ReactServerDOMEsbuild.onServerCallRedirect(href => {
          invalidate(All);
          let _ =
            switch (
              RouterPolicy.actionRedirect(
                ~basePath,
                ~patterns=routePatterns,
                ~page=currentPage(),
                href,
              )
            ) {
            | RouterPolicy.FollowRedirect(url) =>
              guardedNavigate(~action=Navigation.Push, ~revalidate=false, url)
            | RouterPolicy.LoadDocument(url) =>
              Js.Promise.resolve(hardNavigate(~replace=false, url))
            | RouterPolicy.RefuseRedirect(target) =>
              reportError(
                ~target,
                ~recovery=StayOnPage,
                "redirect target is not an http or https URL",
              );
              Js.Promise.resolve(Navigation.Result.Canceled);
            };
          ();
        });
      let onClick = event =>
        if (options.current.interceptLinks) {
          switch (
            RouterPolicy.clickedUrl(~basePath, ~page=currentPage(), event)
          ) {
          | Some(url) when routed(url) =>
            preventDefault(event);
            let _ =
              navigateUrl(~action=Navigation.Push, ~revalidate=false, url);
            ();
          | Some(_)
          | None => ()
          };
        };
      let onBeforeUnload = event =>
        if (RouterBlocker.blocking(blockers) && !unloadAllowed.current) {
          preventDefault(event);
          setReturnValue(event, "");
        };
      let onPageHide = _event => {
        RouterHistory.scrollRestoration("auto");
        rememberScroll(
          Navigation.committed(modelRef.current.navigationState),
        );
      };
      let onPageShow = event =>
        if (persisted(event)) {
          RouterHistory.scrollRestoration("manual");
        };
      let hoverTimer = ref(None);
      let cancelHover = _event =>
        switch (hoverTimer^) {
        | Some(timer) =>
          Js.Global.clearTimeout(timer);
          hoverTimer := None;
        | None => ()
        };
      let onIntent = (~delay, event) =>
        switch (RouterPolicy.eventAnchor(event)) {
        | Some(anchor) =>
          cancelHover(event);
          let run = () =>
            prefetchAnchor(
              ~trigger=RouterRuntime.PrefetchLevel.Intent,
              anchor,
            );
          delay
            ? hoverTimer := Some(Js.Global.setTimeout(~f=run, 50)) : run();
        | None => ()
        };
      let onHover = onIntent(~delay=true);
      let onTouch = onIntent(~delay=false);
      addDocumentListener(document, "pointerover", onHover);
      addDocumentListener(document, "focusin", onHover);
      addDocumentListener(document, "pointerout", cancelHover);
      addDocumentListener(document, "focusout", cancelHover);
      addDocumentListener(document, "touchstart", onTouch);
      addDocumentListener(document, "click", onClick);
      addWindowListener(window, "beforeunload", onBeforeUnload);
      addWindowListener(window, "pagehide", onPageHide);
      addWindowListener(window, "pageshow", onPageShow);
      let stopListening =
        RouterHistory.listen(() => {
          let current =
            Navigation.committed(modelRef.current.navigationState);
          let historyState = RouterHistory.state();
          let key =
            switch (historyState) {
            | Some(state) => state.key
            | None => current.location.key
            };
          let target = locationFromUrl(~key, currentUrl());
          let targetIdentity =
            switch (historyState) {
            | Some(state) => Some(state.revision)
            | None => None
            };
          let kind =
            RouterPolicy.popKind(~search=target.search) @@
            (
              switch (historyState) {
              | None
                  when
                    String.equal(target.pathname, current.location.pathname)
                    && String.equal(target.search, current.location.search) => Navigation.HashOnly
              | Some(_)
              | None =>
                Navigation.classifyPopByContentIdentity(
                  current,
                  ~target,
                  ~currentIdentity=contentIdentity.current,
                  ~targetIdentity,
                )
              }
            );
          RouterBlocker.pop(
            blockers,
            ~current=Some(position.current),
            ~target=Option.bind(historyState, RouterHistory.position),
            ~content=kind == Navigation.Content,
            ~url=currentUrl(),
            ~traverse=RouterHistory.traverse,
            ~handle=() =>
            switch (kind) {
            | Navigation.HashOnly =>
              let _ =
                commitLocation(
                  ~kind=Navigation.HashOnly,
                  ~action=Navigation.Pop,
                  ~browserEntry=Option.is_none(historyState),
                  target,
                );
              ();
            | Navigation.Shallow =>
              let _ =
                commitLocation(
                  ~kind=Navigation.Shallow,
                  ~action=Navigation.Pop,
                  target,
                );
              ();
            | Navigation.Content =>
              let _ = navigateTarget(~action=Navigation.Pop, currentUrl());
              ();
            }
          );
        });
      Some(
        () => {
          RouterHistory.scrollRestoration("auto");
          stopListening();
          removeDocumentListener(document, "click", onClick);
          removeDocumentListener(document, "pointerover", onHover);
          removeDocumentListener(document, "focusin", onHover);
          removeDocumentListener(document, "pointerout", cancelHover);
          removeDocumentListener(document, "focusout", cancelHover);
          removeDocumentListener(document, "touchstart", onTouch);
          cancelHover();
          Option.iter(RouterPolicy.disconnect, viewportObserver.current);
          viewportObserver.current = None;
          RouterPrefetch.clear(prefetcher);
          List.iter(((_, abort)) => abort(), prefetchAborts.current);
          prefetchAborts.current = [];
          removeWindowListener(window, "beforeunload", onBeforeUnload);
          removeWindowListener(window, "pagehide", onPageHide);
          removeWindowListener(window, "pageshow", onPageShow);
          stopServerCalls();
          stopActionRedirects();
          Option.iter(RouterAnnouncer.unmount, announcer.current);
          announcer.current = None;
          abortActiveRequest();
        },
      );
    });
    React.useLayoutEffect1(
      () => {
        switch (pendingCommit.current) {
        | Some(pending) when pending.next === model =>
          pendingCommit.current = None;
          pending.finish();
          pending.resolve(
            Navigation.Result.Committed(
              Navigation.committed(model.navigationState),
            ),
          );
        | Some(_)
        | None => ()
        };
        None;
      },
      [|model|],
    );
    React.useLayoutEffect1(
      () => {
        switch (model.restore) {
        | Some(restore)
            when
              !
                String.equal(
                  restoredContentIdentity.current,
                  contentIdentity.current,
                ) =>
          restoredContentIdentity.current = contentIdentity.current;
          let (action, hash, key) = restore;
          restoreLocation(~kind=Navigation.Content, action, hash, key);
          Option.iter(RouterAnnouncer.announce, announcer.current);
        | Some(_)
        | None => ()
        };
        None;
      },
      [|model.navigationState|],
    );
    React.useLayoutEffect1(
      () => {
        RouterPolicy.markCurrentLinks(
          ~location=Navigation.committed(model.navigationState).location,
          RouterPolicy.routerLinks(),
        );
        None;
      },
      [|Navigation.committed(model.navigationState)|],
    );
    React.useLayoutEffect1(
      () => {
        RouterPolicy.markPendingLinks(
          ~target=pendingTarget(Navigation.status(model.navigationState)),
          RouterPolicy.routerLinks(),
        );
        None;
      },
      [|Navigation.status(model.navigationState)|],
    );
    let latest =
      React.useRef({
        navigate,
        invalidate,
        updateSearch,
        updateSearchWith,
        updateHash,
      });
    latest.current = {
      navigate,
      invalidate,
      updateSearch,
      updateSearchWith,
      updateHash,
    };
    let (stable, _) =
      React.useState(() =>
        {
          navigate: (~history=?, ~revalidate=?, destination) =>
            latest.current.navigate(~history?, ~revalidate?, destination),
          invalidate: invalidation => latest.current.invalidate(invalidation),
          updateSearch: (~owned, ~values, ~history=?, ()) =>
            latest.current.updateSearch(~owned, ~values, ~history?, ()),
          updateSearchWith: (~owned, ~history=?, update) =>
            latest.current.updateSearchWith(~owned, ~history?, update),
          updateHash: (~hash, ~history=?, ()) =>
            latest.current.updateHash(~hash, ~history?, ()),
        }
      );
    let committed = Navigation.committed(model.navigationState);
    React.createElement(
      RouterOutlet.provider,
      {
        "value": model.patchOperation,
        "children":
          React.createElement(
            provider,
            {
              "value":
                Some({
                  navigate: stable.navigate,
                  invalidate: stable.invalidate,
                  navigation: Navigation.status(model.navigationState),
                  committed,
                  search:
                    RouterSearch.valuesFromString(committed.location.search),
                  updateSearch: stable.updateSearch,
                  updateSearchWith: stable.updateSearchWith,
                  updateHash: stable.updateHash,
                  blockers,
                  blocked,
                }),
              "children": React.array([|model.metadata, model.element|]),
            },
          ),
      },
    );
  };
};

let useContextValue = () =>
  switch (React.useContext(context)) {
  | Some(value) => value
  | None => invalid_arg("router hooks require an ancestor Router.Provider")
  };

let useNavigation = () => {
  let value = useContextValue();
  (value.navigate, value.navigation);
};

let useCurrentRoute = () => {
  let value = useContextValue();
  switch (List.rev(value.committed.matches)) {
  | [{ routeId, parameters }, ..._] => Some((routeId, parameters))
  | [] => None
  };
};

let useSearch = () => {
  let value = useContextValue();
  (value.search, value.updateSearch);
};

let useUpdateSearchWith = () => useContextValue().updateSearchWith;

let useUpdateHash = () => useContextValue().updateHash;

let useLocation = () => useContextValue().committed.location;

let useMatches = () => useContextValue().committed.matches;

let locationScope = (~committed as _, ~children, ()) => children;

let useInvalidate = () => useContextValue().invalidate;

let useIsCurrent = destination =>
  RouterPolicy.isCurrent(
    ~location=useLocation(),
    RouterRuntime.href(destination),
  );

let useIsActive = (~activeWhen=Route, destination) =>
  isActive(
    ~activeWhen,
    ~location=useLocation(),
    RouterRuntime.href(destination),
  );

let useIsPending = (~activeWhen=Route, destination) =>
  switch (pendingTarget(useContextValue().navigation)) {
  | Some(location) =>
    isActive(~activeWhen, ~location, RouterRuntime.href(destination))
  | None => false
  };

let useBlocker = shouldBlock => {
  let value = useContextValue();
  React.useEffect2(
    () => shouldBlock ? Some(RouterBlocker.retain(value.blockers)) : None,
    (shouldBlock, value.blockers),
  );
  let request = shouldBlock ? value.blocked : None;
  React.useMemo2(
    () =>
      switch (request) {
      | Some(request) =>
        Blocked({
          target: request.target,
          action: request.action,
          proceed: () => RouterBlocker.proceed(value.blockers, request.id),
          cancel: () => RouterBlocker.cancel(value.blockers, request.id),
        })
      | None => Unblocked
      },
    (request, value.blockers),
  );
};

module Link = {
  type attributes = {
    id: option(string),
    title: option(string),
    rel: option(string),
    ariaLabel: option(string),
    style: option(ReactDOM.Style.t),
    data: list((string, string)),
    anchorRef: option(ReactDOM.domRef),
    onClick: option(React.Event.Mouse.t => unit),
    onMouseEnter: option(React.Event.Mouse.t => unit),
  };

  let attributes =
      (
        ~id=?,
        ~title=?,
        ~rel=?,
        ~ariaLabel=?,
        ~style=?,
        ~data=[],
        ~anchorRef=?,
        ~onClick=?,
        ~onMouseEnter=?,
        (),
      ) => {
    id,
    title,
    rel,
    ariaLabel,
    style,
    data,
    anchorRef,
    onClick,
    onMouseEnter,
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
        ~activeWhen=Url,
        ~id=?,
        ~title=?,
        ~rel=?,
        ~ariaLabel=?,
        ~style=?,
        ~data=[],
        ~anchorRef=?,
        ~attributes=noAttributes,
        ~onClick as userOnClick=?,
        ~onMouseEnter=?,
        ~history=Navigation.Push,
        ~revalidate=false,
        ~children,
      ) => {
    let value = useContextValue();
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
    let anchorRef = either(anchorRef, attributes.anchorRef);
    let userOnClick = either(userOnClick, attributes.onClick);
    let onMouseEnter = either(onMouseEnter, attributes.onMouseEnter);
    let href = RouterRuntime.href(destination);
    let dataRouterPrefetch =
      switch (RouterRuntime.prefetchLevel(destination)) {
      | RouterRuntime.PrefetchLevel.Intent => None
      | level => Some(RouterRuntime.PrefetchLevel.toString(level))
      };
    let explicitAriaCurrent = ariaCurrent;
    let ariaCurrent =
      switch (ariaCurrent) {
      | Some(_) => ariaCurrent
      | None =>
        isActive(~activeWhen, ~location=value.committed.location, href)
          ? Some("page") : None
      };
    let onClick = event => {
      Option.iter(handler => handler(event), userOnClick);
      let plainClick =
        !React.Event.Mouse.defaultPrevented(event)
        && React.Event.Mouse.button(event) == 0
        && !React.Event.Mouse.altKey(event)
        && !React.Event.Mouse.ctrlKey(event)
        && !React.Event.Mouse.metaKey(event)
        && !React.Event.Mouse.shiftKey(event)
        && Option.is_none(download)
        && (
          switch (target) {
          | None
          | Some("_self") => true
          | Some(_) => false
          }
        );
      if (plainClick) {
        React.Event.Mouse.preventDefault(event);
        let _ = value.navigate(~history, ~revalidate, destination);
        ();
      };
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
        ref=?anchorRef
        ?onMouseEnter
        onClick>
        children
      </a>;
    let extra = Js.Dict.empty();
    List.iter(
      ((name, value)) =>
        if (RouterTypes.validAttributeName(name)) {
          Js.Dict.set(extra, "data-" ++ name, value);
        },
      attributes.data @ data,
    );
    Option.iter(
      level => Js.Dict.set(extra, "data-router-prefetch", level),
      dataRouterPrefetch,
    );
    if (Option.is_none(explicitAriaCurrent)) {
      Js.Dict.set(
        extra,
        RouterPolicy.routerLinkAttribute,
        activeRule(activeWhen),
      );
    };
    Js.Array.length(Js.Dict.keys(extra)) == 0
      ? link : React.cloneElement(link, extra);
  };
};

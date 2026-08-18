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
type updateHash =
  (~hash: string, ~history: Navigation.historyAction=?, unit) =>
  navigationResult;

type contextValue = {
  navigate,
  navigation: Navigation.status,
  committed: Navigation.committed,
  search: list((string, list(string))),
  updateSearch,
  updateHash,
};

type model = {
  navigationState: Navigation.state,
  metadata: React.element,
  element: React.element,
  patchOperation: RouterOutlet.operation,
  restore: option((Navigation.historyAction, string, string)),
};

type activeRequest = {
  requestId: int,
  abort: unit => unit,
};

let context: React.Context.t(option(contextValue)) =
  React.createContext(None);
let provider = React.Context.provider(context);
let outlet = (~owner, ~children, ()) =>
  <RouterOutlet key=owner owner> children </RouterOutlet>;

let suspense = (~fallback, ~children, ()) =>
  <React.Suspense fallback> children </React.Suspense>;

let currentUrl = () => {
  let location = DOM.window->DOM.Window.location;
  Location.pathname(location)
  ++ Location.search(location)
  ++ Location.hash(location);
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

let canonicalUrlAllowed = (~basePath, url) =>
  try({
    let browserLocation = DOM.window->DOM.Window.location;
    let parsed =
      Webapi.Url.makeWith(url, ~base=Location.href(browserLocation));
    let pathname = Webapi.Url.pathname(parsed);
    String.equal(
      Webapi.Url.origin(parsed),
      Location.origin(browserLocation),
    )
    && (
      String.equal(basePath, "/")
      || String.equal(pathname, basePath)
      || String.starts_with(~prefix=basePath ++ "/", pathname)
    );
  }) {
  | _ => false
  };

let searchValuesFromString = search =>
  Webapi.Url.URLSearchParams.make(search)
  |> Webapi.Url.URLSearchParams.entries
  |> Js.Array.from
  |> Array.fold_left(
       (values, (name, value)) =>
         switch (List.assoc_opt(name, values)) {
         | None => [(name, [value]), ...values]
         | Some(current) => [
             (name, current @ [value]),
             ...List.remove_assoc(name, values),
           ]
         },
       [],
     )
  |> List.rev;

let validationMessage = error =>
  switch (error) {
  | Response.SupersededResponse => "navigation was superseded"
  | Response.StaleResponse => "navigation response has a stale base revision"
  | Response.InvalidHttpStatus(_) => "navigation response has an invalid HTTP status"
  | Response.InvalidContentType(_) => "navigation response has an invalid content type"
  | Response.ResponseKindMismatch => "navigation response kind does not match its envelope"
  | Response.ProtocolVersionMismatch => "navigation protocol version does not match"
  | Response.RegistryFingerprintMismatch => "route registry fingerprint does not match"
  | Response.CanonicalUrlRejected(_) => "navigation response has an invalid canonical URL"
  };

let clientErrorMessage = error =>
  switch (error) {
  | RouterClient.MissingResponseKind => "navigation response kind is missing"
  | RouterClient.InvalidResponseKind(_) => "navigation response kind is invalid"
  | RouterClient.InvalidContentType(_) => "navigation response has an invalid content type"
  };

module Provider = {
  [@react.component]
  let make =
      (
        ~initial: Navigation.committed,
        ~protocolVersion=1,
        ~registryFingerprint,
        ~basePath,
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
    let (model, setModel) = React.useState(() => initialModel);
    let modelRef = React.useRef(initialModel);
    let activeRequest = React.useRef(None);
    let nextLocationKey = React.useRef(1);
    let scrollPositions = React.useRef([]);
    let (contentIdentityPrefix, _) =
      React.useState(RouterHistory.freshContentIdentity);
    let contentIdentity = React.useRef(contentIdentityPrefix ++ "-0");
    let restoredContentIdentity = React.useRef("");
    let mutateHistory = (~action, ~state, ~url) =>
      switch (Navigation.historyMutation(action)) {
      | Navigation.PushEntry => RouterHistory.push(~state, ~url)
      | Navigation.ReplaceEntry => RouterHistory.replace(~state, ~url)
      };
    let rec take = (count, values) =>
      if (count <= 0) {
        [];
      } else {
        switch (values) {
        | [] => []
        | [value, ...values] => [value, ...take(count - 1, values)]
        };
      };
    let rememberScroll = committed => {
      let window = DOM.window;
      scrollPositions.current =
        [
          (
            committed.Navigation.location.key,
            (DOM.Window.scrollX(window), DOM.Window.scrollY(window)),
          ),
          ...List.remove_assoc(
               committed.location.key,
               scrollPositions.current,
             ),
        ]
        |> take(100);
    };
    let focusElement = element =>
      element |> DOM.Element.unsafeAsHtmlElement |> DOM.HtmlElement.focus;
    let restoreLocation = (action, hash, key) => {
      let window = DOM.window;
      let document = DOM.Window.document(window);
      let anchor =
        if (String.equal(hash, "")) {
          None;
        } else {
          let encoded = String.sub(hash, 1, String.length(hash) - 1);
          try(Some(Js.Global.decodeURIComponent(encoded))) {
          | _ => None
          };
        };
      switch (anchor) {
      | Some(anchor) =>
        switch (DOM.Document.getElementById(anchor, document)) {
        | Some(element) =>
          focusElement(element);
          DOM.Element.scrollIntoView(element);
        | None => DOM.Window.scrollTo(0.0, 0.0, window)
        }
      | None =>
        switch (action, List.assoc_opt(key, scrollPositions.current)) {
        | (Navigation.Pop, Some((x, y))) =>
          DOM.Window.scrollTo(x, y, window)
        | _ =>
          switch (DOM.Document.getElementById("router-focus-root", document)) {
          | Some(element) => focusElement(element)
          | None => ()
          };
          DOM.Window.scrollTo(0.0, 0.0, window);
        }
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
    let hardNavigate = (~replace, url) => {
      let location = DOM.window->DOM.Window.location;
      replace
        ? Location.replace(url, location) : Location.assign(url, location);
      Navigation.Result.Redirected(url);
    };
    let commitLocation = (~kind, ~action, location: Navigation.location) => {
      switch (activeRequest.current) {
      | Some(active) =>
        active.abort();
        activeRequest.current = None;
      | None => ()
      };
      let current = modelRef.current;
      let currentCommitted = Navigation.committed(current.navigationState);
      let key =
        switch (action) {
        | Navigation.Push =>
          let key = "location-" ++ string_of_int(nextLocationKey.current);
          nextLocationKey.current = nextLocationKey.current + 1;
          key;
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
      let historyState: RouterHistory.state = {
        key,
        revision: contentIdentity.current,
      };
      mutateHistory(~action, ~state=historyState, ~url);
      updateModel({
        ...current,
        navigationState,
      });
      switch (kind) {
      | Navigation.HashOnly => restoreLocation(action, location.hash, key)
      | Navigation.Shallow
      | Navigation.Content => ()
      };
      Navigation.Result.Committed(committed);
    };
    let updateSearch = (~owned, ~values, ~history=Navigation.Replace, ()) => {
      let current = Navigation.committed(modelRef.current.navigationState);
      let nextValues =
        RouterRuntime.Search.update(
          ~owned,
          ~values,
          searchValuesFromString(current.location.search),
        );
      let parameters = Webapi.Url.URLSearchParams.make("");
      List.iter(
        ((name, values)) =>
          List.iter(
            value =>
              Webapi.Url.URLSearchParams.append(name, value, parameters),
            values,
          ),
        nextValues,
      );
      Webapi.Url.URLSearchParams.sort(parameters);
      let encoded = Webapi.Url.URLSearchParams.toString(parameters);
      let search = String.equal(encoded, "") ? "" : "?" ++ encoded;
      if (String.equal(search, current.location.search)) {
        Navigation.Result.Committed(current);
      } else {
        commitLocation(
          ~kind=Navigation.Shallow,
          ~action=history,
          {
            ...current.location,
            search,
          },
        );
      };
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
    let navigateTarget = (~action, ~revalidate=false, target) => {
      switch (activeRequest.current) {
      | Some(active) => active.abort()
      | None => ()
      };
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
        | Navigation.Pop => hardNavigate(~replace=true, target)
        | Navigation.Push
        | Navigation.Replace => finishFailure(~requestId, ~message)
        };
      let pending =
        RouterClient.fetch(
          ~protocolVersion,
          ~registryFingerprint,
          ~requestId,
          ~baseRevision=committed.revision,
          ~from=revalidate ? None : Some(from),
          ~target,
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
           | Error(error) =>
             failNavigation(clientErrorMessage(error)) |> Js.Promise.resolve
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
                 ~canonicalUrlAllowed=canonicalUrlAllowed(~basePath),
                 decoded.facts,
                 decoded.response,
               )
             ) {
             | Error(Response.SupersededResponse) =>
               Js.Promise.resolve(Navigation.Result.Canceled)
             | Error(Response.StaleResponse)
             | Error(Response.ProtocolVersionMismatch)
             | Error(Response.RegistryFingerprintMismatch) =>
               hardNavigate(~replace=action != Navigation.Push, target)
               |> Js.Promise.resolve
             | Error(error) =>
               failNavigation(validationMessage(error)) |> Js.Promise.resolve
             | Ok(validated) =>
               let commitResponse = (~metadata, response) => {
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
                     ~validatedRequestId=validated.requestId,
                     ~currentState=current.navigationState,
                     ~currentCommitted,
                     ~targetHash=targetLocation.hash,
                     ~historyKey,
                     ~locationFromUrl,
                     response,
                   )
                 ) {
                 | Error(RouterTransaction.InvalidGraft) =>
                   hardNavigate(~replace=action != Navigation.Push, target)
                   |> Js.Promise.resolve
                 | Error(RouterTransaction.Canceled) =>
                   Js.Promise.resolve(Navigation.Result.Canceled)
                 | Ok(prepared) =>
                   let historyState: RouterHistory.state = {
                     key: prepared.key,
                     revision: nextContentIdentity,
                   };
                   mutateHistory(
                     ~action,
                     ~state=historyState,
                     ~url=prepared.url,
                   );
                   contentIdentity.current = nextContentIdentity;
                   let (element, patchOperation) =
                     switch (prepared.render) {
                     | RouterTransaction.ReplacePayload(element) => (
                         element,
                         RouterOutlet.RefreshFull({ serial: requestId }),
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
                   updateModel({
                     navigationState: prepared.navigationState,
                     metadata,
                     element,
                     patchOperation,
                     restore: Some(prepared.restore),
                   });
                   Js.Promise.resolve(
                     Navigation.Result.Committed(prepared.committed),
                   );
                 };
               };
               switch (validated.response) {
               | Response.ReloadRequired =>
                 hardNavigate(~replace=action != Navigation.Push, target)
                 |> Js.Promise.resolve
               | Response.Redirect(redirect) =>
                 hardNavigate(
                   ~replace=action != Navigation.Push,
                   redirect.location,
                 )
                 |> Js.Promise.resolve
               | Response.Failed(failure) =>
                 failNavigation(failure.message) |> Js.Promise.resolve
               | Response.Patch(response) =>
                 commitResponse(
                   ~metadata=response.metadata,
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
                   RouterTransaction.{
                     baseRevision: validated.baseRevision,
                     canonicalUrl: response.canonicalUrl,
                     targetRevision: response.targetRevision,
                     matches: response.matches,
                     layouts: response.layouts,
                     content: Replace(response.payload),
                   },
                 )
               };
             };
           };
         })
      |> Js.Promise.catch(_error => {
           clearActiveRequest(requestId);
           failNavigation("navigation request failed") |> Js.Promise.resolve;
         });
    };
    let navigate = (~history=Navigation.Push, ~revalidate=false, destination) =>
      navigateTarget(
        ~action=history,
        ~revalidate,
        RouterRuntime.href(destination),
      );
    React.useEffect0(() => {
      RouterHistory.scrollRestoration("manual");
      let current = modelRef.current;
      let committed = Navigation.committed(current.navigationState);
      let browserHash = DOM.window->DOM.Window.location->Location.hash;
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
      RouterHistory.replace(
        ~state={
          key: committed.location.key,
          revision: contentIdentity.current,
        },
        ~url=currentUrl(),
      );
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
          let _ =
            switch (
              Navigation.classifyPopByContentIdentity(
                current,
                ~target,
                ~currentIdentity=contentIdentity.current,
                ~targetIdentity,
              )
            ) {
            | Navigation.HashOnly =>
              commitLocation(
                ~kind=Navigation.HashOnly,
                ~action=Navigation.Pop,
                target,
              )
            | Navigation.Shallow =>
              commitLocation(
                ~kind=Navigation.Shallow,
                ~action=Navigation.Pop,
                target,
              )
            | Navigation.Content =>
              let _ = navigateTarget(~action=Navigation.Pop, currentUrl());
              Navigation.Result.Canceled;
            };
          ();
        });
      Some(
        () => {
          RouterHistory.scrollRestoration("auto");
          stopListening();
          switch (activeRequest.current) {
          | Some(active) => active.abort()
          | None => ()
          };
        },
      );
    });
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
          restoreLocation(action, hash, key);
        | Some(_)
        | None => ()
        };
        None;
      },
      [|model.navigationState|],
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
                  navigate,
                  navigation: Navigation.status(model.navigationState),
                  committed,
                  search: searchValuesFromString(committed.location.search),
                  updateSearch,
                  updateHash,
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

let useUpdateHash = () => useContextValue().updateHash;

module Link = {
  [@react.component]
  let make =
      (
        ~destination,
        ~className=?,
        ~target=?,
        ~download=?,
        ~ariaCurrent=?,
        ~history=Navigation.Push,
        ~revalidate=false,
        ~children,
      ) => {
    let (navigate, _) = useNavigation();
    let onClick = event => {
      let plainClick =
        React.Event.Mouse.button(event) == 0
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
        let _ = navigate(~history, ~revalidate, destination);
        ();
      };
    };
    <a
      href={RouterRuntime.href(destination)}
      ?className
      ?target
      ?download
      ?ariaCurrent
      onClick>
      children
    </a>;
  };
};

let link =
    (
      ~destination,
      ~className=?,
      ~target=?,
      ~download=?,
      ~ariaCurrent=?,
      ~history=?,
      ~revalidate=?,
      ~children,
      (),
    ) =>
  <Link
    destination ?className ?target ?download ?ariaCurrent ?history ?revalidate>
    children
  </Link>;

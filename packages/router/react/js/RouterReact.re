module DOM = Webapi.Dom;
module Location = DOM.Location;
module Response = RouterRuntime.NavigationResponse;
module Navigation = RouterRuntime.Navigation;

type options = RouterRuntime.Link.options;
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
    ~options: RouterRuntime.Search.options=?,
    unit
  ) =>
  navigationResult;
type updateHash =
  (~hash: string, ~options: RouterRuntime.Search.options=?, unit) =>
  navigationResult;

type contextValue = {
  navigate,
  navigation: Navigation.status,
  committed: Navigation.committed,
  updateSearch,
  updateHash,
};

type model = {
  navigationState: Navigation.state,
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
        ~children,
      ) => {
    let callServer = FlightProvider.useCallServer();
    let decodeNavigation = FlightProvider.useNavigationDecoder();
    let initialModel = {
      navigationState: Navigation.make(initial),
      element: children,
      patchOperation: RouterOutlet.NoPatch,
      restore: None,
    };
    let (model, setModel) = React.useState(() => initialModel);
    let modelRef = React.useRef(initialModel);
    let activeRequest = React.useRef(None);
    let nextLocationKey = React.useRef(1);
    let scrollPositions = React.useRef([]);
    let restoredRevision = React.useRef("");
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
        revision: committed.revision,
      };
      switch (Navigation.historyMutation(action)) {
      | Navigation.PushEntry => RouterHistory.push(~state=historyState, ~url)
      | Navigation.ReplaceEntry =>
        RouterHistory.replace(~state=historyState, ~url)
      };
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
    let updateSearch =
        (~owned, ~values, ~options=RouterRuntime.Search.defaultOptions, ()) => {
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
          ~action=options.history,
          {
            ...current.location,
            search,
          },
        );
      };
    };
    let updateHash = (~hash, ~options=RouterRuntime.Search.defaultOptions, ()) => {
      let current = Navigation.committed(modelRef.current.navigationState);
      let hash =
        String.equal(hash, "") || String.starts_with(~prefix="#", hash)
          ? hash : "#" ++ hash;
      if (String.equal(hash, current.location.hash)) {
        Navigation.Result.Committed(current);
      } else {
        commitLocation(
          ~kind=Navigation.HashOnly,
          ~action=options.history,
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
        | Navigation.Pop =>
          hardNavigate(
            ~replace=true,
            committed.location.pathname
            ++ committed.location.search
            ++ committed.location.hash,
          )
        | Navigation.Push
        | Navigation.Replace => finishFailure(~requestId, ~message)
        };
      let pending =
        RouterClient.fetch(
          ~callServer,
          ~decodeNavigation,
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
             | Error(Response.StaleResponse) =>
               hardNavigate(~replace=action != Navigation.Push, target)
               |> Js.Promise.resolve
             | Error(Response.ProtocolVersionMismatch)
             | Error(Response.RegistryFingerprintMismatch) =>
               hardNavigate(~replace=action != Navigation.Push, target)
               |> Js.Promise.resolve
             | Error(error) =>
               failNavigation(validationMessage(error)) |> Js.Promise.resolve
             | Ok(validated) =>
               switch (validated.response) {
               | Response.ReloadRequired =>
                 hardNavigate(~replace=action != Navigation.Push, target)
                 |> Js.Promise.resolve
               | Response.Redirect(redirect) =>
                 hardNavigate(~replace=false, redirect.location)
                 |> Js.Promise.resolve
               | Response.Failed(failure) =>
                 failNavigation(failure.message) |> Js.Promise.resolve
               | Response.Patch(response) =>
                 if (!
                       List.exists(
                         (layout: Navigation.layout) =>
                           String.equal(
                             layout.instanceKey,
                             response.replaceFrom,
                           ),
                         currentCommitted.layouts,
                       )) {
                   hardNavigate(~replace=action != Navigation.Push, target)
                   |> Js.Promise.resolve;
                 } else {
                   let key =
                     switch (action) {
                     | Navigation.Push =>
                       "navigation-" ++ string_of_int(requestId)
                     | Navigation.Replace => currentCommitted.location.key
                     | Navigation.Pop =>
                       switch (RouterHistory.state()) {
                       | Some(state) => state.key
                       | None => currentCommitted.location.key
                       }
                     };
                   let canonicalLocation =
                     locationFromUrl(~key, response.canonicalUrl);
                   let location = {
                     ...canonicalLocation,
                     hash:
                       String.equal(canonicalLocation.hash, "")
                         ? targetLocation.hash : canonicalLocation.hash,
                   };
                   let canonicalUrl =
                     location.pathname ++ location.search ++ location.hash;
                   let nextCommitted =
                     Navigation.{
                       location,
                       matches: response.matches,
                       layouts: response.layouts,
                       revision: response.targetRevision,
                     };
                   switch (
                     Navigation.commit(
                       current.navigationState,
                       ~requestId=validated.requestId,
                       ~baseRevision=response.baseRevision,
                       ~next=nextCommitted,
                     )
                   ) {
                   | Error(_) =>
                     Js.Promise.resolve(Navigation.Result.Canceled)
                   | Ok(navigationState) =>
                     let historyState: RouterHistory.state = {
                       key,
                       revision: response.targetRevision,
                     };
                     switch (Navigation.historyMutation(action)) {
                     | Navigation.PushEntry =>
                       RouterHistory.push(
                         ~state=historyState,
                         ~url=canonicalUrl,
                       )
                     | Navigation.ReplaceEntry =>
                       RouterHistory.replace(
                         ~state=historyState,
                         ~url=canonicalUrl,
                       )
                     };
                     updateModel({
                       navigationState,
                       element: current.element,
                       patchOperation:
                         RouterOutlet.ApplyPatch({
                           serial: requestId,
                           graftAt: response.replaceFrom,
                           targetLayouts:
                             List.map(
                               (layout: Navigation.layout) =>
                                 layout.instanceKey,
                               response.layouts,
                             ),
                           payload: response.payload,
                         }),
                       restore: Some((action, location.hash, key)),
                     });
                     Js.Promise.resolve(
                       Navigation.Result.Committed(nextCommitted),
                     );
                   };
                 }
               | Response.Full(response) =>
                 let key =
                   switch (action) {
                   | Navigation.Push =>
                     "navigation-" ++ string_of_int(requestId)
                   | Navigation.Replace => currentCommitted.location.key
                   | Navigation.Pop =>
                     switch (RouterHistory.state()) {
                     | Some(state) => state.key
                     | None => currentCommitted.location.key
                     }
                   };
                 let canonicalLocation =
                   locationFromUrl(~key, response.canonicalUrl);
                 let location = {
                   ...canonicalLocation,
                   hash:
                     String.equal(canonicalLocation.hash, "")
                       ? targetLocation.hash : canonicalLocation.hash,
                 };
                 let canonicalUrl =
                   location.pathname ++ location.search ++ location.hash;
                 let nextCommitted =
                   Navigation.{
                     location,
                     matches: response.matches,
                     layouts: response.layouts,
                     revision: response.targetRevision,
                   };
                 switch (
                   Navigation.commit(
                     current.navigationState,
                     ~requestId=validated.requestId,
                     ~baseRevision=validated.baseRevision,
                     ~next=nextCommitted,
                   )
                 ) {
                 | Error(_) => Js.Promise.resolve(Navigation.Result.Canceled)
                 | Ok(navigationState) =>
                   let historyState: RouterHistory.state = {
                     key,
                     revision: response.targetRevision,
                   };
                   switch (Navigation.historyMutation(action)) {
                   | Navigation.PushEntry =>
                     RouterHistory.push(
                       ~state=historyState,
                       ~url=canonicalUrl,
                     )
                   | Navigation.ReplaceEntry =>
                     RouterHistory.replace(
                       ~state=historyState,
                       ~url=canonicalUrl,
                     )
                   };
                   updateModel({
                     navigationState,
                     element: response.payload,
                     patchOperation:
                       RouterOutlet.RefreshFull({ serial: requestId }),
                     restore: Some((action, location.hash, key)),
                   });
                   Js.Promise.resolve(
                     Navigation.Result.Committed(nextCommitted),
                   );
                 };
               }
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
          revision: committed.revision,
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
          let targetRevision =
            switch (historyState) {
            | Some(state) => Some(state.revision)
            | None => None
            };
          let _ =
            switch (Navigation.classifyPop(current, ~target, ~targetRevision)) {
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
        let committed = Navigation.committed(model.navigationState);
        switch (model.restore) {
        | Some(restore)
            when !String.equal(restoredRevision.current, committed.revision) =>
          restoredRevision.current = committed.revision;
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
                  updateSearch,
                  updateHash,
                }),
              "children": model.element,
            },
          ),
      },
    );
  };
};

let useNavigation = () =>
  switch (React.useContext(context)) {
  | Some(value) => (Some(value.navigate), value.navigation)
  | None => (None, Navigation.Idle)
  };

let useCommitted = () =>
  switch (React.useContext(context)) {
  | Some(value) => Some(value.committed)
  | None => None
  };

let useSearchValues = () =>
  switch (React.useContext(context)) {
  | None => []
  | Some(value) => searchValuesFromString(value.committed.location.search)
  };

let useUpdateSearch = () =>
  switch (React.useContext(context)) {
  | Some(value) => Some(value.updateSearch)
  | None => None
  };

let useUpdateHash = () =>
  switch (React.useContext(context)) {
  | Some(value) => Some(value.updateHash)
  | None => None
  };

let useIsActive = (~routeId, ~parameters, ~includeDescendants) =>
  switch (React.useContext(context)) {
  | Some(value) =>
    Navigation.isActive(
      value.committed,
      ~routeId,
      ~parameters,
      ~includeDescendants,
    )
  | None => false
  };

module Link = {
  [@react.component]
  let make =
      (
        ~destination,
        ~className=?,
        ~target=?,
        ~download=?,
        ~ariaCurrent=?,
        ~options=RouterRuntime.Link.defaultOptions,
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
      switch (plainClick, navigate) {
      | (true, Some(navigate)) =>
        React.Event.Mouse.preventDefault(event);
        let _ =
          navigate(
            ~history=options.history,
            ~revalidate=options.revalidate,
            destination,
          );
        ();
      | _ => ()
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
      ~options=?,
      ~children,
      (),
    ) =>
  <Link destination ?className ?target ?download ?ariaCurrent ?options>
    children
  </Link>;

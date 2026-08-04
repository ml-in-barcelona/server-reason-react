let debug = Sys.getenv_opt("DEMO_ENV") == Some("development");

let serverFunctionHandler =
  DreamRSC.streamFunctionResponse(~debug, ~lookup=FunctionReferences.get);

let getAndPost = (path, handler) =>
  Dream.scope(
    "/",
    [],
    [Dream.get(path, handler), Dream.post(path, serverFunctionHandler)],
  );

type nestedRouterResponse =
  RouterServer.ServerEngine.full(React.element, NestedRouterPages.AppError.t);
type nestedRouterPatch =
  RouterServer.ServerEngine.patch(
    React.element,
    NestedRouterPages.AppError.t,
  );

let nestedRouterElement = (response: nestedRouterResponse) =>
  response.RouterServer.ServerEngine.resolved.element
  |> Option.value(~default=React.null);

let nestedRouterMatches = (response: nestedRouterResponse) =>
  response.RouterServer.ServerEngine.matches
  |> List.map((matched: RouterRuntime.Navigation.matched) =>
       {
         RouterWire.routeId: matched.routeId,
         parameters: matched.parameters,
       }
     );

let nestedRouterLayouts = layouts =>
  layouts
  |> List.map((layout: RouterRuntime.Navigation.layout) =>
       {
         RouterWire.id: layout.id,
         instanceKey: layout.instanceKey,
       }
     );

let nestedRouterDocument = (response: nestedRouterResponse) => {
  let (pathname, query) =
    response.RouterServer.ServerEngine.canonical_url |> Dream.split_target;
  let search = query == "" ? "" : "?" ++ query;
  let initial: NestedRouter_ClientRoot.initial = {
    pathname,
    search,
    key: "server",
    revision: response.revision,
    matches: nestedRouterMatches(response),
    layouts: nestedRouterLayouts(response.layouts),
  };
  let children =
    <NestedRouter_ClientRoot
      initial
      registryFingerprint={response.registry_fingerprint}
      basePath=RouterRegistry.basePath>
      {nestedRouterElement(response)}
    </NestedRouter_ClientRoot>;
  NestedRouterPages.Document.make(
    NestedRouterPages.Document.makeProps(~children, ()),
  );
};

let nestedRouterModel = (response: nestedRouterResponse) => {
  let full: RouterWire.full = {
    protocolVersion: response.protocol_version,
    registryFingerprint: response.registry_fingerprint,
    canonicalUrl: response.canonical_url,
    status: RouterRuntime.Status.toInt(response.resolved.status),
    matches: nestedRouterMatches(response),
    layouts: nestedRouterLayouts(response.layouts),
    targetRevision: response.revision,
    payload: nestedRouterElement(response),
  };
  full |> RouterWire.full_to_rsc |> RSC.to_model;
};

let nestedRouterPatchModel = (response: nestedRouterPatch) => {
  let patch: RouterWire.patch = {
    protocolVersion: response.protocol_version,
    registryFingerprint: response.registry_fingerprint,
    baseRevision: response.base_revision,
    targetRevision: response.revision,
    replaceFrom: response.replace_from,
    canonicalUrl: response.canonical_url,
    status: RouterRuntime.Status.toInt(response.resolved.status),
    matches:
      response.matches
      |> List.map((matched: RouterRuntime.Navigation.matched) =>
           {
             RouterWire.routeId: matched.routeId,
             parameters: matched.parameters,
           }
         ),
    layouts: nestedRouterLayouts(response.layouts),
    payload: response.resolved.element |> Option.value(~default=React.null),
  };
  patch |> RouterWire.patch_to_rsc |> RSC.to_model;
};

let nestedRouterRedirectModel = destination => {
  let redirect: RouterWire.redirect = {
    protocolVersion: 1,
    registryFingerprint:
      RouterServer.EndpointRegistry.fingerprint(RouterRegistry.registry),
    location: RouterRuntime.href(destination),
    status: 200,
  };
  redirect |> RouterWire.redirect_to_rsc |> RSC.to_model;
};

let nestedRouterHandler =
  DreamRouterAdapter.handler(
    ~registry=RouterRegistry.registry,
    ~basePath=RouterRegistry.basePath,
    ~fallback=RouterRegistry.fallback,
    ~applicationStatus=RouterRegistry.applicationStatus,
    ~diagnosticId=_ => string_of_int(Random.bits()),
    ~revision=() => string_of_int(Random.bits()),
    ~protocolVersion=1,
    ~bootstrapModules=["/static/demo/NestedRouterRSC.re.js"],
    ~document=nestedRouterDocument,
    ~rscModel=nestedRouterModel,
    ~rscPatch=nestedRouterPatchModel,
    ~rscRedirect=nestedRouterRedirectModel,
  );

let server =
  Dream.logger(
    Dream.router([
      getAndPost("/", Pages.Home.handler),
      Dream.get("/demo", req => Dream.redirect(req, "/")),
      Dream.get(
        "/output.css",
        Dream.from_filesystem("./_build/default/demo", "output.css"),
      ),
      Dream.get(
        "/static/**",
        Dream.static("./_build/default/demo/client/app"),
      ),
      getAndPost(Routes.renderToString, _request =>
        Dream.html(
          ReactDOM.renderToString(
            <Document script="/static/demo/RenderRoot.re.js">
              <App />
            </Document>,
          ),
        )
      ),
      getAndPost(Routes.renderToStaticMarkup, _request =>
        Dream.html(
          ReactDOM.renderToStaticMarkup(
            <Document script="/static/demo/HydrateRoot.re.js">
              <App />
            </Document>,
          ),
        )
      ),
      getAndPost(Routes.renderToStream, Pages.Comments.handler),
      getAndPost(Routes.singlePageRSC, Pages.SinglePageRSC.handler),
      getAndPost(Routes.dummyRouterRSC, Pages.DummyRouterRSC.handler),
      getAndPost(Routes.serverOnlyRSC, Pages.ServerOnlyRSC.handler),
      ...DreamRouterAdapter.routes(
           ~basePath=RouterRegistry.basePath,
           ~actionHandler=serverFunctionHandler,
           nestedRouterHandler,
         ),
    ]),
  );

let interface = {
  switch (Sys.getenv_opt("SERVER_INTERFACE")) {
  | Some(env) => env
  | None => "localhost"
  };
};

let port = {
  switch (Sys.getenv_opt("PORT")) {
  | Some(env) =>
    switch (int_of_string_opt(env)) {
    | Some(port) => port
    | None => failwith("PORT must be a number, got: " ++ env)
    }
  | None => 8080
  };
};

Dream.run(~port, ~interface, server);

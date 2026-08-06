let debug = Sys.getenv_opt("DEMO_ENV") == Some("development");

let serverFunctionHandler =
  DreamRouter.streamFunctionResponse(~debug, ~lookup=FunctionReferences.get);

let getAndPost = (path, handler) =>
  Dream.scope(
    "/",
    [],
    [Dream.get(path, handler), Dream.post(path, serverFunctionHandler)],
  );

type routerResponse =
  RouterServer.ServerEngine.full(React.element, RouterPages.AppError.t);
type routerPatch =
  RouterServer.ServerEngine.patch(React.element, RouterPages.AppError.t);

let routerElement = (response: routerResponse) =>
  response.RouterServer.ServerEngine.resolved.element
  |> Option.value(~default=React.null);

let routerDocument = (response: routerResponse) => {
  let (pathname, query) =
    response.RouterServer.ServerEngine.canonical_url |> Dream.split_target;
  let search = query == "" ? "" : "?" ++ query;
  let initial: RouterRuntime.Navigation.committed = {
    location:
      RouterRuntime.Navigation.{
        pathname,
        search,
        hash: "",
        key: "server",
      },
    revision: response.revision,
    matches: response.matches,
    layouts: response.layouts,
  };
  let children =
    <ClientRoot
      initial
      registryFingerprint={response.registry_fingerprint}
      basePath=RouterRegistry.basePath>
      {routerElement(response)}
    </ClientRoot>;
  RouterPages.Document.make(RouterPages.Document.makeProps(~children, ()));
};

let routerModel = (response: routerResponse) => {
  let full: RouterRuntime.NavigationResponse.full(React.element) = {
    protocolVersion: response.protocol_version,
    registryFingerprint: response.registry_fingerprint,
    canonicalUrl: response.canonical_url,
    status: RouterRuntime.Status.toInt(response.resolved.status),
    matches: response.matches,
    layouts: response.layouts,
    targetRevision: response.revision,
    payload: routerElement(response),
  };
  RouterRuntime.NavigationResponse.full_to_rsc(
    RSC.Primitives.react_element_to_rsc,
    full,
  )
  |> RSC.to_model;
};

let routerPatchModel = (response: routerPatch) => {
  let patch: RouterRuntime.NavigationResponse.patch(React.element) = {
    protocolVersion: response.protocol_version,
    registryFingerprint: response.registry_fingerprint,
    baseRevision: response.base_revision,
    targetRevision: response.revision,
    replaceFrom: response.replace_from,
    canonicalUrl: response.canonical_url,
    status: RouterRuntime.Status.toInt(response.resolved.status),
    matches: response.matches,
    layouts: response.layouts,
    payload: response.resolved.element |> Option.value(~default=React.null),
  };
  RouterRuntime.NavigationResponse.patch_to_rsc(
    RSC.Primitives.react_element_to_rsc,
    patch,
  )
  |> RSC.to_model;
};

let routerRedirectModel = destination => {
  let redirect: RouterRuntime.NavigationResponse.redirect = {
    protocolVersion: 1,
    registryFingerprint:
      RouterServer.EndpointRegistry.fingerprint(RouterRegistry.registry),
    location: RouterRuntime.href(destination),
    status: 200,
  };
  redirect |> RouterRuntime.NavigationResponse.redirect_to_rsc |> RSC.to_model;
};

let routerHandler =
  DreamRouter.handler(
    ~registry=RouterRegistry.registry,
    ~basePath=RouterRegistry.basePath,
    ~fallback=RouterRegistry.fallback,
    ~applicationStatus=RouterRegistry.applicationStatus,
    ~diagnosticId=_ => string_of_int(Random.bits()),
    ~revision=() => string_of_int(Random.bits()),
    ~protocolVersion=1,
    ~bootstrapModules=["/static/demo/RouterDemo.re.js"],
    ~document=routerDocument,
    ~rscModel=routerModel,
    ~rscPatch=routerPatchModel,
    ~rscRedirect=routerRedirectModel,
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
      getAndPost(Routes.serverOnlyRSC, Pages.ServerOnlyRSC.handler),
      ...DreamRouter.routes(
           ~basePath=RouterRegistry.basePath,
           ~actionHandler=serverFunctionHandler,
           routerHandler,
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

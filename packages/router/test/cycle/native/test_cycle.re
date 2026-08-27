let testGeneratedHref = () => {
  let href =
    Router.Note.href(
      ~workspaceId=WorkspaceId.make(7),
      ~id=NoteId.make(42),
      ~filter=Filter.make("active/ü"),
      (),
    );
  Alcotest.check(
    Alcotest.string,
    "typed href",
    "/fixture/workspaces/7/notes/42?filter=active%2F%C3%BC",
    href,
  );
};

let testCanonicalSearch = () => {
  let href =
    Router.Note.href(
      ~workspaceId=WorkspaceId.make(7),
      ~id=NoteId.make(42),
      ~page=2,
      ~filter=Filter.make("active/ü"),
      (),
    );
  Alcotest.check(
    Alcotest.string,
    "canonical search",
    "/fixture/workspaces/7/notes/42?filter=active%2F%C3%BC&page=2",
    href,
  );
};

let testEncodeURIComponentParity = () => {
  let href =
    Router.Note.href(
      ~workspaceId=WorkspaceId.make(7),
      ~id=NoteId.make(42),
      ~filter=Filter.make("it's"),
      (),
    );
  Alcotest.check(
    Alcotest.string,
    "encodeURIComponent",
    "/fixture/workspaces/7/notes/42?filter=it's",
    href,
  );
};

let testCatchAllHref = () => {
  let href = Router.Asset.href(~parts=["img", "café", "a+b"], ());
  Alcotest.check(
    Alcotest.string,
    "catch-all href",
    "/fixture/assets/img/caf%C3%A9/a%2Bb",
    href,
  );
};

let testCustomScalarHref = () => {
  let value = ScalarId.make("café+@");
  let href = Router.Scalar.href(~scalarId=value, ());
  Alcotest.check(
    Alcotest.string,
    "custom scalar href",
    "/fixture/scalar/caf%C3%A9%2B%40",
    href,
  );
  let search =
    switch (RouterServer.Search.parse("")) {
    | Ok(search) => search
    | Error(_) => Alcotest.fail("expected valid search")
    };
  ScalarId.reset();
  switch (
    RouterServer.EndpointRegistry.find(
      RouterRegistry.registry,
      ~pathname="/scalar/caf%C3%A9%2B%40",
    )
  ) {
  | Ok(Some(matched)) =>
    switch (RouterServer.EndpointRegistry.decode(matched, ~search)) {
    | Error(_) => Alcotest.fail("expected custom scalar decode")
    | Ok(_) =>
      Alcotest.check(
        Alcotest.option(Alcotest.string),
        "decoded custom scalar",
        Some("café+@"),
        ScalarId.parsed(),
      )
    }
  | _ => Alcotest.fail("expected custom scalar match")
  };
};

let testCustomScalarRejectsSlash = () => {
  let rejected =
    try(
      {
        ignore(Router.Scalar.href(~scalarId=ScalarId.make("a/b"), ()));
        false;
      }
    ) {
    | Invalid_argument(_) => true
    };
  Alcotest.check(Alcotest.bool, "slash rejected", true, rejected);
};

let testGeneratedLink = () => {
  let link =
    Router.Note.make(
      ~workspaceId=WorkspaceId.make(7),
      ~id=NoteId.make(42),
      ~className="note-link",
      ~target="_blank",
      ~download="note.txt",
      ~ariaCurrent="page",
      ~children=React.string("Open"),
      (),
    );
  let html = ReactDOM.renderToStaticMarkup(link);
  Alcotest.check(
    Alcotest.string,
    "progressive link",
    {js|<a class="note-link" href="/fixture/workspaces/7/notes/42" target="_blank" download="note.txt" aria-current="page">Open</a>|js},
    html,
  );
};

let testGeneratedEndpoint = () => {
  WorkspaceLoader.reset();
  Attachments.reset();
  let search =
    switch (RouterServer.Search.parse("")) {
    | Ok(search) => search
    | Error(_) => Alcotest.fail("expected valid search")
    };
  switch (
    RouterServer.EndpointRegistry.find(
      RouterRegistry.registry,
      ~pathname="/workspaces/7/notes/42",
    )
  ) {
  | Ok(Some(matched)) =>
    switch (RouterServer.EndpointRegistry.decode(matched, ~search)) {
    | Error(_) => Alcotest.fail("expected decoded endpoint")
    | Ok(prepared) =>
      switch (
        Lwt_main.run(
          RouterServer.Execution.run(
            RouterServer.Endpoint.execution(prepared),
          ),
        )
      ) {
      | RouterRuntime.Loader.Data(plan) =>
        let result =
          Lwt_main.run(
            RouterServer.Plan.resolve(plan, ~applicationStatus=_ =>
              RouterRuntime.Status.InternalServerError
            ),
          );
        Alcotest.check(
          Alcotest.bool,
          "page result",
          true,
          Option.is_some(result.element),
        );
        Alcotest.check(
          Alcotest.list(Alcotest.string),
          "loader order",
          ["workspace", "note:7:1"],
          WorkspaceLoader.events(),
        );
        Alcotest.check(
          Alcotest.option(Alcotest.string),
          "metadata title",
          Some("Note"),
          result.metadata.title,
        );
        Alcotest.check(
          Alcotest.option(Alcotest.string),
          "metadata description",
          Some("Workspace"),
          result.metadata.description,
        );
        Alcotest.check(
          Alcotest.list(Alcotest.pair(Alcotest.string, Alcotest.string)),
          "headers",
          [
            ("Cache-Control", "private"),
            ("X-Route", "note"),
            ("Vary", "Accept"),
          ],
          RouterRuntime.Headers.toList(result.headers),
        );
        Alcotest.check(
          Alcotest.list(Alcotest.string),
          "attachment order",
          [
            "root-metadata",
            "root-headers",
            "workspace-metadata",
            "workspace-headers",
            "note-metadata",
            "note-headers",
          ],
          Attachments.events(),
        );
      | _ => Alcotest.fail("expected loader data")
      }
    }
  | _ => Alcotest.fail("expected generated endpoint")
  };
};

let testGeneratedDecodeIsLazy = () => {
  let search =
    switch (RouterServer.Search.parse("")) {
    | Ok(search) => search
    | Error(_) => Alcotest.fail("expected valid search")
    };
  NotePage.fail();
  switch (
    RouterServer.EndpointRegistry.find(
      RouterRegistry.registry,
      ~pathname="/workspaces/7/notes/42",
    )
  ) {
  | Ok(Some(matched)) =>
    switch (RouterServer.EndpointRegistry.decode(matched, ~search)) {
    | Ok(prepared) =>
      let _branch = RouterServer.Endpoint.branch(prepared);
      NotePage.reset();
    | Error(_) => Alcotest.fail("expected decoded endpoint")
    }
  | _ => Alcotest.fail("expected generated endpoint")
  };
};

let testGeneratedDecodeError = () => {
  WorkspaceLoader.reset();
  Attachments.reset();
  let search =
    switch (RouterServer.Search.parse("")) {
    | Ok(search) => search
    | Error(_) => Alcotest.fail("expected valid search")
    };
  switch (
    RouterServer.EndpointRegistry.find(
      RouterRegistry.registry,
      ~pathname="/workspaces/7/notes/nope",
    )
  ) {
  | Ok(Some(matched)) =>
    switch (RouterServer.EndpointRegistry.decode(matched, ~search)) {
    | Error(_) => Alcotest.fail("expected recoverable typed path error")
    | Ok(prepared) =>
      switch (
        Lwt_main.run(
          RouterServer.Execution.run(
            RouterServer.Endpoint.execution(prepared),
          ),
        )
      ) {
      | RouterRuntime.Loader.Data(plan) =>
        let resolved =
          Lwt_main.run(
            RouterServer.Plan.resolve(plan, ~applicationStatus=_ =>
              RouterRuntime.Status.InternalServerError
            ),
          );
        switch (resolved.error) {
        | Some(RouterRuntime.Error.InvalidPathParameter({ name: "id" })) =>
          ()
        | _ => Alcotest.fail("expected typed path error")
        };
        Alcotest.check(
          Alcotest.bool,
          "workspace boundary",
          true,
          List.mem("workspace-error", Attachments.events()),
        );
        Alcotest.check(
          Alcotest.list(Alcotest.string),
          "loaders skipped",
          [],
          WorkspaceLoader.events(),
        );
      | _ => Alcotest.fail("expected decode failure plan")
      }
    }
  | _ => Alcotest.fail("expected structural route match")
  };
};

let testGeneratedLoaderShortCircuit = () => {
  WorkspaceLoader.reset();
  Attachments.reset();
  WorkspaceLoader.notFound();
  let search =
    switch (RouterServer.Search.parse("")) {
    | Ok(search) => search
    | Error(_) => Alcotest.fail("expected valid search")
    };
  switch (
    RouterServer.EndpointRegistry.find(
      RouterRegistry.registry,
      ~pathname="/workspaces/7/notes/42",
    )
  ) {
  | Ok(Some(matched)) =>
    switch (RouterServer.EndpointRegistry.decode(matched, ~search)) {
    | Error(_) => Alcotest.fail("expected decoded endpoint")
    | Ok(prepared) =>
      switch (
        Lwt_main.run(
          RouterServer.Execution.run(
            RouterServer.Endpoint.execution(prepared),
          ),
        )
      ) {
      | RouterRuntime.Loader.Data(plan) =>
        let result =
          Lwt_main.run(
            RouterServer.Plan.resolve(plan, ~applicationStatus=_ =>
              RouterRuntime.Status.InternalServerError
            ),
          );
        Alcotest.check(
          Alcotest.int,
          "status",
          404,
          RouterRuntime.Status.toInt(result.status),
        );
        Alcotest.check(
          Alcotest.list(Alcotest.string),
          "child skipped",
          ["workspace"],
          WorkspaceLoader.events(),
        );
        Alcotest.check(
          Alcotest.bool,
          "nearest boundary",
          true,
          Option.is_some(result.element),
        );
        Alcotest.check(
          Alcotest.list(Alcotest.string),
          "failure attachments",
          ["root-metadata", "root-headers"],
          Attachments.events(),
        );
      | _ => Alcotest.fail("expected failure plan")
      }
    }
  | _ => Alcotest.fail("expected generated endpoint")
  };
};

let testGeneratedSearchDecodeError = () => {
  WorkspaceLoader.reset();
  let search =
    switch (RouterServer.Search.parse("?page=nope")) {
    | Ok(search) => search
    | Error(_) => Alcotest.fail("expected structurally valid search")
    };
  switch (
    RouterServer.EndpointRegistry.find(
      RouterRegistry.registry,
      ~pathname="/workspaces/7/notes/42",
    )
  ) {
  | Ok(Some(matched)) =>
    switch (RouterServer.EndpointRegistry.decode(matched, ~search)) {
    | Error(RouterRuntime.Error.InvalidSearchParameter({ name: "page" })) =>
      Alcotest.check(
        Alcotest.list(Alcotest.string),
        "loaders skipped",
        [],
        WorkspaceLoader.events(),
      )
    | _ => Alcotest.fail("expected typed search error")
    }
  | _ => Alcotest.fail("expected generated endpoint")
  };
};

let runEngine =
    (
      ~pathname,
      ~search="",
      ~kind=RouterServer.ServerEngine.Rsc,
      ~navigation=None,
      (),
    ) =>
  Lwt_main.run(
    RouterServer.ServerEngine.run(
      ~registry=RouterRegistry.registry,
      ~basePath=RouterRegistry.basePath,
      ~trailingSlash=RouterServer.TrailingSlash.Redirect,
      ~fallback=RouterRegistry.fallback,
      ~applicationStatus=RouterRegistry.applicationStatus,
      ~diagnosticId=_ => "diagnostic-1",
      ~revision=() => "revision-1",
      ~protocolVersion=1,
      {
        RouterServer.ServerEngine.pathname,
        search,
        hash: "",
        kind,
        navigation,
      },
    ),
  );

let testRscFullResponse = () => {
  WorkspaceLoader.reset();
  Attachments.reset();
  NotePage.reset();
  switch (runEngine(~pathname="/fixture/workspaces/7/notes/42", ())) {
  | Redirect(_)
  | PermanentRedirect(_) => Alcotest.fail("expected full response")
  | Patch(_)
  | ReloadRequired => Alcotest.fail("unexpected navigation response")
  | Full(response) =>
    Alcotest.check(
      Alcotest.int,
      "status",
      200,
      RouterRuntime.Status.toInt(response.resolved.status),
    );
    Alcotest.check(
      Alcotest.string,
      "content type",
      "application/react.component",
      RouterRuntime.Headers.toList(response.resolved.headers)
      |> List.assoc("Content-Type"),
    );
    Alcotest.check(
      Alcotest.string,
      "response kind",
      "full",
      RouterRuntime.Headers.toList(response.resolved.headers)
      |> List.assoc("Router-Response"),
    );
    Alcotest.check(
      Alcotest.string,
      "cache",
      "private, no-store",
      RouterRuntime.Headers.toList(response.resolved.headers)
      |> List.assoc("Cache-Control"),
    );
    Alcotest.check(
      Alcotest.string,
      "revision",
      "revision-1",
      response.revision,
    );
    Alcotest.check(
      Alcotest.int,
      "matches",
      2,
      List.length(response.matches),
    );
  };
};

let testDocumentNotFoundResponse = () => {
  Attachments.reset();
  switch (
    runEngine(
      ~pathname="/fixture/missing",
      ~kind=RouterServer.ServerEngine.Document,
      (),
    )
  ) {
  | Redirect(_)
  | PermanentRedirect(_) => Alcotest.fail("expected full response")
  | Patch(_)
  | ReloadRequired => Alcotest.fail("unexpected navigation response")
  | Full(response) =>
    Alcotest.check(
      Alcotest.int,
      "status",
      404,
      RouterRuntime.Status.toInt(response.resolved.status),
    );
    Alcotest.check(
      Alcotest.bool,
      "boundary",
      true,
      Option.is_some(response.resolved.element),
    );
    Alcotest.check(
      Alcotest.string,
      "content type",
      "text/html; charset=utf-8",
      RouterRuntime.Headers.toList(response.resolved.headers)
      |> List.assoc("Content-Type"),
    );
  };
};

let testInternalResponseIsSafe = () => {
  WorkspaceLoader.reset();
  Attachments.reset();
  NoteLoader.fail();
  switch (runEngine(~pathname="/fixture/workspaces/7/notes/42", ())) {
  | Redirect(_)
  | PermanentRedirect(_) => Alcotest.fail("expected full response")
  | Patch(_)
  | ReloadRequired => Alcotest.fail("unexpected navigation response")
  | Full(response) =>
    NoteLoader.reset();
    Alcotest.check(
      Alcotest.int,
      "status",
      500,
      RouterRuntime.Status.toInt(response.resolved.status),
    );
    switch (response.resolved.error) {
    | Some(RouterRuntime.Error.Internal({ diagnosticId: "diagnostic-1" })) =>
      ()
    | _ => Alcotest.fail("expected safe diagnostic id")
    };
    Alcotest.check(
      Alcotest.bool,
      "error boundary",
      true,
      Option.is_some(response.resolved.element),
    );
  };
};

let testEngineDecodeError = () => {
  WorkspaceLoader.reset();
  Attachments.reset();
  switch (runEngine(~pathname="/fixture/workspaces/7/notes/nope", ())) {
  | Redirect(_)
  | PermanentRedirect(_) => Alcotest.fail("expected full response")
  | Patch(_)
  | ReloadRequired => Alcotest.fail("unexpected navigation response")
  | Full(response) =>
    Alcotest.check(
      Alcotest.int,
      "status",
      400,
      RouterRuntime.Status.toInt(response.resolved.status),
    );
    Alcotest.check(
      Alcotest.bool,
      "boundary",
      true,
      Option.is_some(response.resolved.element),
    );
    Alcotest.check(
      Alcotest.bool,
      "workspace boundary",
      true,
      List.mem("workspace-error", Attachments.events()),
    );
    Alcotest.check(
      Alcotest.bool,
      "root boundary skipped",
      false,
      List.mem("root-error", Attachments.events()),
    );
    Alcotest.check(
      Alcotest.list(Alcotest.string),
      "loaders skipped",
      [],
      WorkspaceLoader.events(),
    );
    Alcotest.check(
      Alcotest.list(Alcotest.string),
      "safe active routes",
      ["Workspaces"],
      response.matches
      |> List.map(({ RouterRuntime.Navigation.routeId, _ }) => routeId),
    );
    let initial =
      RouterRuntime.Navigation.{
        location: {
          pathname: "/fixture/workspaces/7/notes/nope",
          search: "",
          hash: "",
          key: "decode-error",
        },
        matches: response.matches,
        layouts: response.layouts,
        revision: response.revision,
      };
    let probe =
      Attachments.ActiveRouteProbe.make(
        Attachments.ActiveRouteProbe.makeProps(),
      );
    let provider =
      RouterReact.Provider.make(
        RouterReact.Provider.makeProps(
          ~initial,
          ~registryFingerprint=response.registry_fingerprint,
          ~basePath=RouterRegistry.basePath,
          ~metadata=React.null,
          ~children=probe,
          (),
        ),
      );
    Alcotest.check(
      Alcotest.string,
      "generated active route decodes",
      "workspaces",
      ReactDOM.renderToStaticMarkup(provider),
    );
  };
};

let testNestedSearchDecodeError = () => {
  WorkspaceLoader.reset();
  Attachments.reset();
  switch (
    runEngine(
      ~pathname="/fixture/workspaces/7/search",
      ~search="?view=nope",
      (),
    )
  ) {
  | Redirect(_)
  | PermanentRedirect(_) => Alcotest.fail("expected full response")
  | Patch(_)
  | ReloadRequired => Alcotest.fail("unexpected navigation response")
  | Full(response) =>
    Alcotest.check(
      Alcotest.int,
      "status",
      400,
      RouterRuntime.Status.toInt(response.resolved.status),
    );
    switch (response.resolved.error) {
    | Some(RouterRuntime.Error.InvalidSearchParameter({ name: "view" })) =>
      ()
    | _ => Alcotest.fail("expected nested search error")
    };
    Alcotest.check(
      Alcotest.bool,
      "workspace boundary",
      true,
      List.mem("workspace-error", Attachments.events()),
    );
    Alcotest.check(
      Alcotest.bool,
      "root boundary skipped",
      false,
      List.mem("root-error", Attachments.events()),
    );
    Alcotest.check(
      Alcotest.list(Alcotest.string),
      "loaders skipped",
      [],
      WorkspaceLoader.events(),
    );
  };
};

let testInvalidRootSearchBoundary = () => {
  WorkspaceLoader.reset();
  Attachments.reset();
  switch (
    runEngine(
      ~pathname="/fixture/workspaces/7/notes/42",
      ~search="?page=nope",
      (),
    )
  ) {
  | Redirect(_)
  | PermanentRedirect(_) => Alcotest.fail("expected full response")
  | Patch(_)
  | ReloadRequired => Alcotest.fail("unexpected navigation response")
  | Full(response) =>
    Alcotest.check(
      Alcotest.int,
      "status",
      400,
      RouterRuntime.Status.toInt(response.resolved.status),
    );
    Alcotest.check(
      Alcotest.bool,
      "boundary",
      true,
      Option.is_some(response.resolved.element),
    );
    Alcotest.check(
      Alcotest.bool,
      "root invalid-search fallback",
      true,
      List.mem("invalid-search", Attachments.events()),
    );
    Alcotest.check(
      Alcotest.bool,
      "nested boundary skipped",
      false,
      List.mem("workspace-error", Attachments.events()),
    );
    Alcotest.check(
      Alcotest.list(Alcotest.string),
      "loaders skipped",
      [],
      WorkspaceLoader.events(),
    );
  };
};

let testEngineRedirect = () => {
  WorkspaceLoader.reset();
  WorkspaceLoader.redirect();
  switch (runEngine(~pathname="/fixture/workspaces/7/notes/42", ())) {
  | Full(_) => Alcotest.fail("expected redirect")
  | Patch(_)
  | PermanentRedirect(_)
  | ReloadRequired => Alcotest.fail("unexpected navigation response")
  | Redirect(destination) =>
    Alcotest.check(
      Alcotest.string,
      "destination",
      "/login",
      RouterRuntime.href(destination),
    )
  };
};

let testDeclaredRedirect = () => {
  WorkspaceLoader.reset();
  switch (
    runEngine(
      ~pathname="/fixture/legacy/7/notes/42",
      ~search="?page=2&searchText=legacy",
      (),
    )
  ) {
  | Full(_)
  | Patch(_)
  | PermanentRedirect(_)
  | ReloadRequired => Alcotest.fail("expected redirect")
  | Redirect(destination) =>
    Alcotest.check(
      Alcotest.string,
      "destination",
      "/fixture/workspaces/7/notes/42?page=2&searchText=legacy",
      RouterRuntime.href(destination),
    )
  };
  Alcotest.check(
    Alcotest.list(Alcotest.string),
    "no loaders",
    [],
    WorkspaceLoader.events(),
  );
};

let testApplicationErrorPolicy = () => {
  WorkspaceLoader.reset();
  WorkspaceLoader.error();
  switch (runEngine(~pathname="/fixture/workspaces/7/notes/42", ())) {
  | Redirect(_)
  | PermanentRedirect(_) => Alcotest.fail("expected full response")
  | Patch(_)
  | ReloadRequired => Alcotest.fail("unexpected navigation response")
  | Full(response) =>
    Alcotest.check(
      Alcotest.int,
      "status",
      403,
      RouterRuntime.Status.toInt(response.resolved.status),
    );
    Alcotest.check(
      Alcotest.bool,
      "boundary",
      true,
      Option.is_some(response.resolved.element),
    );
  };
};

let registryFingerprint = () =>
  "1." ++ RouterServer.EndpointRegistry.fingerprint(RouterRegistry.registry);

let navigationFacts = (~from, ~registry, ~baseRevision) =>
  Some({
    RouterServer.ServerEngine.from: Some(from),
    registry: Some(registry),
    base_revision: Some(baseRevision),
  });

let navigateFrom = from =>
  navigationFacts(
    ~from,
    ~registry=registryFingerprint(),
    ~baseRevision="base-1",
  );

/* [~revalidate=true] on the client drops the [from] fact. */
let revalidate =
  Some({
    RouterServer.ServerEngine.from: None,
    registry: Some(registryFingerprint()),
    base_revision: Some("base-1"),
  });

let testPatchResponse = () => {
  WorkspaceLoader.reset();
  let navigation = navigateFrom("/fixture/workspaces/7/notes/42");
  switch (
    runEngine(
      ~pathname="/fixture/workspaces/7/notes/42/edit",
      ~navigation,
      (),
    )
  ) {
  | Patch(response) =>
    Alcotest.check(
      Alcotest.string,
      "base revision",
      "base-1",
      response.base_revision,
    );
    Alcotest.check(
      Alcotest.string,
      "graft",
      "7:group:111:workspaceId1:7",
      response.replace_from,
    );
    Alcotest.check(
      Alcotest.string,
      "cache",
      "private, no-store",
      RouterRuntime.Headers.toList(response.resolved.headers)
      |> List.assoc("Cache-Control"),
    );
  | Full(_)
  | ReloadRequired
  | Redirect(_)
  | PermanentRedirect(_) => Alcotest.fail("expected patch")
  };
};

/* [Branch.Scope.instanceKey] prefixes every part with its length so that
   names and values cannot alias. */
let frame = value => string_of_int(String.length(value)) ++ ":" ++ value;
let rootGraft = frame("root");
let workspaceGraft = workspaceId =>
  frame("group:1") ++ frame("workspaceId") ++ frame(workspaceId);
let teamGraft = teamId =>
  frame("group:2") ++ frame("teamId") ++ frame(teamId);

let resetFixture = () => {
  WorkspaceLoader.reset();
  NoteLoader.reset();
  MemberLoader.reset();
  NotePage.reset();
  Attachments.reset();
};

let expectPatch = (~to_, ~navigation) =>
  switch (runEngine(~pathname=to_, ~navigation, ())) {
  | Patch(response) => response
  | Full(_) => Alcotest.fail("expected patch, got full")
  | ReloadRequired => Alcotest.fail("expected patch, got reload")
  | Redirect(_)
  | PermanentRedirect(_) => Alcotest.fail("expected patch, got redirect")
  };

let expectFull = (~to_, ~navigation) =>
  switch (runEngine(~pathname=to_, ~navigation, ())) {
  | Full(response) => response
  | Patch(_) => Alcotest.fail("expected full, got patch")
  | ReloadRequired => Alcotest.fail("expected full, got reload")
  | Redirect(_)
  | PermanentRedirect(_) => Alcotest.fail("expected full, got redirect")
  };

let checkLayouts = expected =>
  Alcotest.check(
    Alcotest.list(Alcotest.string),
    "rendered layouts",
    expected,
    Attachments.layouts(),
  );

let checkPatchGraft = (~from, ~to_, ~graft, ~layouts) => {
  let response = expectPatch(~to_, ~navigation=navigateFrom(from));
  Alcotest.check(Alcotest.string, "graft", graft, response.replace_from);
  Alcotest.check(
    Alcotest.int,
    "status",
    200,
    RouterRuntime.Status.toInt(response.resolved.status),
  );
  checkLayouts(layouts);
};

let checkFullResponse = (~to_, ~navigation, ~layouts) => {
  let response = expectFull(~to_, ~navigation);
  Alcotest.check(
    Alcotest.int,
    "status",
    200,
    RouterRuntime.Status.toInt(response.resolved.status),
  );
  checkLayouts(layouts);
};

/* A patch omits exactly the layouts the client already owns, so the layouts a
   patch renders plus the layouts above the graft must equal the layouts a full
   response renders for the same destination. */
let checkPatchMatchesFull = (~from, ~to_, ~arrange, ~graft, ~above) => {
  resetFixture();
  arrange();
  let response = expectPatch(~to_, ~navigation=navigateFrom(from));
  Alcotest.check(Alcotest.string, "graft", graft, response.replace_from);
  let patchLayouts = Attachments.layouts();
  resetFixture();
  arrange();
  ignore(expectFull(~to_, ~navigation=None));
  Alcotest.check(
    Alcotest.list(Alcotest.string),
    "patch omits only the layouts above the graft",
    Attachments.layouts(),
    above @ patchLayouts,
  );
};

let testPatchLoaderGroupRegularNavigation = () => {
  resetFixture();
  checkPatchGraft(
    ~from="/fixture/workspaces/7/notes/42",
    ~to_="/fixture/workspaces/7/notes/42/edit",
    ~graft=workspaceGraft("7"),
    ~layouts=[],
  );
};

let testPatchLoaderGroupRevalidate = () => {
  resetFixture();
  checkFullResponse(
    ~to_="/fixture/workspaces/7/notes/42/edit",
    ~navigation=revalidate,
    ~layouts=["root-layout", "workspace-layout"],
  );
};

let testPatchLoaderGroupCrossInstance = () => {
  resetFixture();
  checkPatchGraft(
    ~from="/fixture/workspaces/7/notes/42",
    ~to_="/fixture/workspaces/8/notes/42",
    ~graft=rootGraft,
    ~layouts=["workspace-layout"],
  );
};

let testPatchPlainGroupRegularNavigation = () => {
  resetFixture();
  checkPatchGraft(
    ~from="/fixture/teams/9",
    ~to_="/fixture/teams/9/members",
    ~graft=teamGraft("9"),
    ~layouts=[],
  );
};

let testPatchPlainGroupRevalidate = () => {
  resetFixture();
  checkFullResponse(
    ~to_="/fixture/teams/9/members",
    ~navigation=revalidate,
    ~layouts=["root-layout", "team-layout"],
  );
};

let testPatchPlainGroupCrossInstance = () => {
  resetFixture();
  checkPatchGraft(
    ~from="/fixture/teams/9",
    ~to_="/fixture/teams/10/members",
    ~graft=rootGraft,
    ~layouts=["team-layout"],
  );
};

let testPatchGroupLoaderFailureClampsGraft = () =>
  checkPatchMatchesFull(
    ~from="/fixture/workspaces/7/notes/42",
    ~to_="/fixture/workspaces/7/notes/42/edit",
    ~arrange=WorkspaceLoader.error,
    ~graft=rootGraft,
    ~above=["root-layout"],
  );

let testPatchGroupLoaderNotFoundClampsGraft = () =>
  checkPatchMatchesFull(
    ~from="/fixture/workspaces/7/notes/42",
    ~to_="/fixture/workspaces/7/notes/42/edit",
    ~arrange=WorkspaceLoader.notFound,
    ~graft=rootGraft,
    ~above=["root-layout"],
  );

let testPatchRouteLoaderFailureKeepsGroupGraft = () =>
  checkPatchMatchesFull(
    ~from="/fixture/workspaces/7/notes/42",
    ~to_="/fixture/workspaces/7/notes/42/edit",
    ~arrange=NoteLoader.notFound,
    ~graft=workspaceGraft("7"),
    ~above=["root-layout", "workspace-layout"],
  );

let testPatchPlainGroupRouteLoaderFailureKeepsGraft = () =>
  checkPatchMatchesFull(
    ~from="/fixture/teams/9",
    ~to_="/fixture/teams/9/members",
    ~arrange=MemberLoader.notFound,
    ~graft=teamGraft("9"),
    ~above=["root-layout", "team-layout"],
  );

let testPatchGroupLoaderRedirectEscapes = () => {
  resetFixture();
  WorkspaceLoader.redirect();
  switch (
    runEngine(
      ~pathname="/fixture/workspaces/7/notes/42/edit",
      ~navigation=navigateFrom("/fixture/workspaces/7/notes/42"),
      (),
    )
  ) {
  | Redirect(destination) =>
    Alcotest.check(
      Alcotest.string,
      "destination",
      "/login",
      RouterRuntime.href(destination),
    )
  | Full(_)
  | Patch(_)
  | ReloadRequired
  | PermanentRedirect(_) => Alcotest.fail("expected redirect")
  };
};

let testDecodeErrorPatchResponse = () => {
  WorkspaceLoader.reset();
  let navigation = navigateFrom("/fixture/workspaces");
  switch (
    runEngine(~pathname="/fixture/workspaces/7/notes/nope", ~navigation, ())
  ) {
  | Patch(response) =>
    Alcotest.check(
      Alcotest.int,
      "status",
      400,
      RouterRuntime.Status.toInt(response.resolved.status),
    );
    Alcotest.check(
      Alcotest.list(Alcotest.string),
      "safe active routes",
      ["Workspaces"],
      response.matches
      |> List.map(({ RouterRuntime.Navigation.routeId, _ }) => routeId),
    );
    Alcotest.check(
      Alcotest.list(Alcotest.string),
      "loaders skipped",
      [],
      WorkspaceLoader.events(),
    );
  | Full(_)
  | ReloadRequired
  | Redirect(_)
  | PermanentRedirect(_) => Alcotest.fail("expected decode-error patch")
  };
};

let testRegistryMismatchReloadsBeforeLoaders = () => {
  WorkspaceLoader.reset();
  let navigation =
    navigationFacts(
      ~from="/fixture/workspaces/7/notes/42",
      ~registry="1.not-the-registry",
      ~baseRevision="base-1",
    );
  switch (
    runEngine(
      ~pathname="/fixture/workspaces/7/notes/42/edit",
      ~navigation,
      (),
    )
  ) {
  | ReloadRequired =>
    Alcotest.check(
      Alcotest.list(Alcotest.string),
      "loaders skipped",
      [],
      WorkspaceLoader.events(),
    )
  | Full(_)
  | Patch(_)
  | Redirect(_)
  | PermanentRedirect(_) => Alcotest.fail("expected reload-required")
  };
};

let testMissingNavigationFactsDegradeToFull = () => {
  switch (runEngine(~pathname="/fixture/workspaces/7/notes/42/edit", ())) {
  | Full(_) => ()
  | Patch(_)
  | ReloadRequired
  | Redirect(_)
  | PermanentRedirect(_) => Alcotest.fail("expected full response")
  };
};

let testOversizedNavigationFromDegradesToFull = () => {
  let navigation = navigateFrom(String.make(2049, 'x'));
  switch (
    runEngine(
      ~pathname="/fixture/workspaces/7/notes/42/edit",
      ~navigation,
      (),
    )
  ) {
  | Full(_) => ()
  | Patch(_)
  | ReloadRequired
  | Redirect(_)
  | PermanentRedirect(_) => Alcotest.fail("expected full response")
  };
};

let () =
  Alcotest.run(
    "router generation cycle",
    [
      (
        "native",
        [
          Alcotest.test_case("generated href", `Quick, testGeneratedHref),
          Alcotest.test_case("canonical search", `Quick, testCanonicalSearch),
          Alcotest.test_case(
            "encodeURIComponent parity",
            `Quick,
            testEncodeURIComponentParity,
          ),
          Alcotest.test_case("catch-all href", `Quick, testCatchAllHref),
          Alcotest.test_case(
            "custom scalar href",
            `Quick,
            testCustomScalarHref,
          ),
          Alcotest.test_case(
            "custom scalar rejects slash",
            `Quick,
            testCustomScalarRejectsSlash,
          ),
          Alcotest.test_case("generated link", `Quick, testGeneratedLink),
          Alcotest.test_case(
            "generated endpoint",
            `Quick,
            testGeneratedEndpoint,
          ),
          Alcotest.test_case(
            "generated endpoint decode is lazy",
            `Quick,
            testGeneratedDecodeIsLazy,
          ),
          Alcotest.test_case(
            "generated decode error",
            `Quick,
            testGeneratedDecodeError,
          ),
          Alcotest.test_case(
            "generated loader short circuit",
            `Quick,
            testGeneratedLoaderShortCircuit,
          ),
          Alcotest.test_case(
            "generated search decode error",
            `Quick,
            testGeneratedSearchDecodeError,
          ),
          Alcotest.test_case(
            "RSC full response",
            `Quick,
            testRscFullResponse,
          ),
          Alcotest.test_case(
            "document not-found response",
            `Quick,
            testDocumentNotFoundResponse,
          ),
          Alcotest.test_case(
            "internal response is safe",
            `Quick,
            testInternalResponseIsSafe,
          ),
          Alcotest.test_case(
            "engine decode error",
            `Quick,
            testEngineDecodeError,
          ),
          Alcotest.test_case(
            "nested search decode error",
            `Quick,
            testNestedSearchDecodeError,
          ),
          Alcotest.test_case(
            "invalid root search boundary",
            `Quick,
            testInvalidRootSearchBoundary,
          ),
          Alcotest.test_case("engine redirect", `Quick, testEngineRedirect),
          Alcotest.test_case(
            "declared redirect",
            `Quick,
            testDeclaredRedirect,
          ),
          Alcotest.test_case(
            "application error policy",
            `Quick,
            testApplicationErrorPolicy,
          ),
          Alcotest.test_case("patch response", `Quick, testPatchResponse),
          Alcotest.test_case(
            "loader group patch",
            `Quick,
            testPatchLoaderGroupRegularNavigation,
          ),
          Alcotest.test_case(
            "loader group revalidate",
            `Quick,
            testPatchLoaderGroupRevalidate,
          ),
          Alcotest.test_case(
            "loader group cross instance",
            `Quick,
            testPatchLoaderGroupCrossInstance,
          ),
          Alcotest.test_case(
            "plain group patch",
            `Quick,
            testPatchPlainGroupRegularNavigation,
          ),
          Alcotest.test_case(
            "plain group revalidate",
            `Quick,
            testPatchPlainGroupRevalidate,
          ),
          Alcotest.test_case(
            "plain group cross instance",
            `Quick,
            testPatchPlainGroupCrossInstance,
          ),
          Alcotest.test_case(
            "group loader failure clamps graft",
            `Quick,
            testPatchGroupLoaderFailureClampsGraft,
          ),
          Alcotest.test_case(
            "group loader not-found clamps graft",
            `Quick,
            testPatchGroupLoaderNotFoundClampsGraft,
          ),
          Alcotest.test_case(
            "route loader failure keeps group graft",
            `Quick,
            testPatchRouteLoaderFailureKeepsGroupGraft,
          ),
          Alcotest.test_case(
            "plain group route loader failure keeps graft",
            `Quick,
            testPatchPlainGroupRouteLoaderFailureKeepsGraft,
          ),
          Alcotest.test_case(
            "group loader redirect escapes patch",
            `Quick,
            testPatchGroupLoaderRedirectEscapes,
          ),
          Alcotest.test_case(
            "decode-error patch response",
            `Quick,
            testDecodeErrorPatchResponse,
          ),
          Alcotest.test_case(
            "registry mismatch reloads before loaders",
            `Quick,
            testRegistryMismatchReloadsBeforeLoaders,
          ),
          Alcotest.test_case(
            "missing navigation facts degrade to full",
            `Quick,
            testMissingNavigationFactsDegradeToFull,
          ),
          Alcotest.test_case(
            "oversized navigation-from degrades to full",
            `Quick,
            testOversizedNavigationFromDegradesToFull,
          ),
        ],
      ),
    ],
  );

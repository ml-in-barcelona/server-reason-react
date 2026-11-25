let string = Alcotest.string;
let pairs = Alcotest.(list(pair(string, string)));
let active = Alcotest.(list(pair(string, pairs)));

let markup = element => {
  let (html, _rest) =
    Lwt_main.run(ReactServerDOM.render_html(~skipRoot=false, element));
  let rec scriptStart = index =>
    if (index + 7 > String.length(html)) {
      String.length(html);
    } else if (String.sub(html, index, 7) == "<script") {
      index;
    } else {
      scriptStart(index + 1);
    };
  String.sub(html, 0, scriptStart(0));
};

let resolve = (~query="", pathname) => {
  let search =
    switch (RouterEngine.Search.parse(query)) {
    | Ok(search) => search
    | Error(_) => Alcotest.fail("expected valid search")
    };
  switch (
    RouterEngine.EndpointRegistry.find(RouterRegistry.registry, ~pathname)
  ) {
  | Ok(Some(matched)) =>
    switch (RouterEngine.EndpointRegistry.decode(matched, ~search)) {
    | Error(_) => Alcotest.fail("expected decoded endpoint for " ++ pathname)
    | Ok(prepared) =>
      let matches =
        RouterEngine.EndpointRegistry.matches(matched, prepared)
        |> List.map(({ RouterRuntime.Navigation.routeId, parameters }) =>
             (routeId, parameters)
           );
      switch (
        Lwt_main.run(
          RouterEngine.Execution.run(
            RouterEngine.Endpoint.execution(prepared, ~context=""),
          ),
        )
      ) {
      | RouterRuntime.Loader.Data(plan) =>
        let resolved =
          Lwt_main.run(
            RouterEngine.Plan.resolve(plan, ~applicationStatus=_ =>
              RouterRuntime.Status.InternalServerError
            ),
          );
        (matches, markup(RouterEngine.Plan.resolvedElement(resolved)));
      | _ => Alcotest.fail("expected page plan for " ++ pathname)
      };
    }
  | Ok(None) => Alcotest.fail("expected a match for " ++ pathname)
  | Error(_) => Alcotest.fail("expected a valid pathname " ++ pathname)
  };
};

let page = pathname => snd(resolve(pathname));

let unprefixed = href => {
  let prefix = "/site";
  let length = String.length(prefix);
  String.sub(href, length, String.length(href) - length);
};

let testOptionalCatchAllHref = () => {
  Alcotest.check(string, "zero segments", "/site/docs", Router.Docs.href());
  Alcotest.check(
    string,
    "explicit empty list",
    "/site/docs",
    Router.Docs.href(~rest=[], ()),
  );
  Alcotest.check(
    string,
    "many segments",
    "/site/docs/guide/caf%C3%A9/a%20b",
    Router.Docs.href(~rest=["guide", "café", "a b"], ()),
  );
};

let testOptionalCatchAllMatch = () => {
  Alcotest.check(string, "zero segments", "docs:", page("/docs"));
  Alcotest.check(string, "two segments", "docs:a|b", page("/docs/a/b"));
  Alcotest.check(
    string,
    "decoded segments",
    {js|docs:guide|café|a b|js},
    page(unprefixed(Router.Docs.href(~rest=["guide", "café", "a b"], ()))),
  );
  Alcotest.check(
    active,
    "zero-segment active route",
    [("Docs", [])],
    fst(resolve("/docs")),
  );
  Alcotest.check(
    active,
    "many-segment active route",
    [("Docs", [("rest", "a/b")])],
    fst(resolve("/docs/a/b")),
  );
};

let testOptionalCatchAllPrecedence = () => {
  Alcotest.check(
    string,
    "finite sibling wins one segment",
    "topic:intro",
    page("/docs/intro"),
  );
  Alcotest.check(
    string,
    "static sibling wins",
    "api:list",
    page("/docs/api/list"),
  );
  Alcotest.check(
    string,
    "catch-all takes the rest",
    "docs:api|list|more",
    page("/docs/api/list/more"),
  );
};

let testOptionalSegmentHref = () => {
  Alcotest.check(string, "absent", "/site/help", Router.Help.href());
  Alcotest.check(
    string,
    "present",
    "/site/help/fr",
    Router.Help.href(~lang="fr", ()),
  );
  Alcotest.check(
    string,
    "forwarded option",
    "/site/help/topics/3",
    Router.HelpTopic.href(~lang=?None, ~topic=3, ()),
  );
  Alcotest.check(
    string,
    "inner optional present",
    "/site/help/de%20ch/topics/3",
    Router.HelpTopic.href(~lang="de ch", ~topic=3, ()),
  );
};

let testOptionalSegmentMatch = () => {
  Alcotest.check(string, "absent", "help:-", page("/help"));
  Alcotest.check(string, "present", "help:fr", page("/help/fr"));
  Alcotest.check(
    string,
    "inner absent",
    "help-topic:-:3",
    page("/help/topics/3"),
  );
  Alcotest.check(
    string,
    "inner present",
    "help-topic:de ch:3",
    page(unprefixed(Router.HelpTopic.href(~lang="de ch", ~topic=3, ()))),
  );
  Alcotest.check(
    active,
    "active routes without the optional segment",
    [("Help", []), ("HelpTopic", [("topic", "3")])],
    fst(resolve("/help/topics/3")),
  );
  Alcotest.check(
    active,
    "active routes with the optional segment",
    [
      ("Help", [("lang", "fr")]),
      ("HelpTopic", [("lang", "fr"), ("topic", "3")]),
    ],
    fst(resolve("/help/fr/topics/3")),
  );
};

let testHash = () => {
  Alcotest.check(
    string,
    "hash",
    "/site/notes/1#comments",
    Router.Note.href(~id=1, ~hash="comments", ()),
  );
  Alcotest.check(
    string,
    "hash after search",
    "/site/notes/1?tab=a%20b#top",
    Router.Note.href(~id=1, ~search={ tab: Some("a b") }, ~hash="top", ()),
  );
  Alcotest.check(
    string,
    "encoded hash",
    "/site/notes/1#a%20b%23%C3%A9",
    Router.Note.href(~id=1, ~hash={js|a b#é|js}, ()),
  );
  Alcotest.check(
    string,
    "empty hash",
    "/site/notes/1",
    Router.Note.href(~id=1, ~hash="", ()),
  );
  Alcotest.check(
    string,
    "destination hash",
    "/site/docs/a#part-2",
    RouterRuntime.href(
      Router.Docs.destination(~rest=["a"], ~hash="part-2", ()),
    ),
  );
  Alcotest.check(
    string,
    "link hash",
    {|<a href="/site/help/fr#faq">FAQ</a>|},
    ReactDOM.renderToStaticMarkup(
      <Router.Help lang="fr" hash="faq"> {React.string("FAQ")} </Router.Help>,
    ),
  );
};

let testSearchRecord = () => {
  Alcotest.check(
    string,
    "record literal",
    "/site/inspector?error=e&hash=a&hash=b&pattern=p&target=example.com&value=3",
    Router.Inspector.href(
      ~search={
        target: "example.com",
        error: Some("e"),
        input: "all",
        hash: ["a", "b"],
        value: Some(3),
        pattern: Some("p"),
      },
      (),
    ),
  );
  Alcotest.check(
    string,
    "constructor",
    "/site/inspector?input=x&target=a%20b",
    Router.Inspector.href(
      ~search=Router.Inspector.search(~target="a b", ~input="x", ()),
      (),
    ),
  );
  Alcotest.check(
    string,
    "jsx record literal",
    {|<a href="/site/inspector?hash=h&amp;target=example.com" target="_blank">x</a>|},
    ReactDOM.renderToStaticMarkup(
      <Router.Inspector
        target="_blank"
        search={
          target: "example.com",
          error: None,
          input: "all",
          hash: ["h"],
          value: None,
          pattern: None,
        }>
        {React.string("x")}
      </Router.Inspector>,
    ),
  );
  Alcotest.check(
    string,
    "jsx constructor",
    {|<a href="/site/inspector?error=e&amp;target=t" target="_self">y</a>|},
    ReactDOM.renderToStaticMarkup(
      <Router.Inspector
        target="_self"
        search={Router.Inspector.search(~target="t", ~error="e", ())}>
        {React.string("y")}
      </Router.Inspector>,
    ),
  );
  let record =
    Router.Inspector.search(
      ~target="t",
      ~input="i",
      ~hash=["a", "b"],
      ~value=2,
      (),
    );
  Alcotest.(check(bool))(
    "rsc round trip",
    true,
    Router.Inspector.search_of_rsc(Router.Inspector.search_to_rsc(record))
    == record,
  );
  let chunks = ref([]);
  Lwt_main.run(
    ReactServerDOM.render_model(
      ~subscribe=
        chunk => {
          chunks := [chunk, ...chunks^];
          Lwt.return();
        },
      <InspectorBadge search=record />,
    ),
  );
  let model = String.concat("", List.rev(chunks^));
  let needle = {|"search":[["target",["t"]],["input",["i"]],["hash",["a","b"]],["value",["2"]]]|};
  let rec contains = index =>
    index
    + String.length(needle) <= String.length(model)
    && (
      String.sub(model, index, String.length(needle)) == needle
      || contains(index + 1)
    );
  Alcotest.(check(bool))("client component prop", true, contains(0));
  Alcotest.check(
    string,
    "registry decodes the record",
    "t|e|all|a,b|7|p",
    snd(
      resolve(
        ~query="?target=t&error=e&hash=a&hash=b&value=7&pattern=p",
        "/inspector",
      ),
    ),
  );
};

let level = destination =>
  RouterRuntime.PrefetchLevel.toString(
    RouterRuntime.prefetchLevel(destination),
  );

let testPrefetchLevels = () => {
  Alcotest.check(
    string,
    "default",
    "intent",
    level(Router.Note.destination(~id=1, ())),
  );
  Alcotest.check(
    string,
    "group",
    "viewport",
    level(Router.Settings.destination()),
  );
  Alcotest.check(
    string,
    "route overrides group",
    "off",
    level(Router.SettingsBilling.destination()),
  );
  Alcotest.check(
    string,
    "nested route overrides",
    "idle",
    level(Router.SettingsTeam.destination()),
  );
  Alcotest.check(
    string,
    "nested group inherits",
    "viewport",
    level(Router.SettingsMembers.destination()),
  );
  Alcotest.check(
    string,
    "hash keeps the level",
    "viewport",
    level(Router.Settings.destination(~hash="top", ())),
  );
};

let testPrefetchRegistry = () => {
  let prefetch = pathname =>
    switch (
      RouterEngine.EndpointRegistry.find(RouterRegistry.registry, ~pathname)
    ) {
    | Ok(Some(matched)) =>
      RouterRuntime.PrefetchLevel.toString(
        RouterEngine.EndpointRegistry.prefetch(matched),
      )
    | _ => Alcotest.fail("expected a match for " ++ pathname)
    };
  Alcotest.check(string, "default", "intent", prefetch("/notes/1"));
  Alcotest.check(string, "group", "viewport", prefetch("/settings"));
  Alcotest.check(string, "override", "off", prefetch("/settings/billing"));
  Alcotest.check(
    string,
    "nested override",
    "idle",
    prefetch("/settings/team"),
  );
  Alcotest.check(
    string,
    "nested inherit",
    "viewport",
    prefetch("/settings/team/members"),
  );
};

let testClientOptions = () => {
  let initial: RouterRuntime.Navigation.committed = {
    location: {
      pathname: "/site/help",
      search: "",
      hash: "",
      key: "k",
    },
    matches: [],
    layouts: [],
    revision: "r",
  };
  let (html, _subscribe) =
    Lwt_main.run(
      ReactServerDOM.render_html(
        ~skipRoot=false,
        RouterEngine.Server.clientRoot(
          RouterRegistry.server,
          ~initial,
          ~metadata=React.null,
          ~children=React.null,
        ),
      ),
    );
  let contains = needle => {
    let limit = String.length(html) - String.length(needle);
    let rec loop = index =>
      index <= limit
      && (
        String.sub(html, index, String.length(needle)) == needle
        || loop(index + 1)
      );
    loop(0);
  };
  Alcotest.check(
    Alcotest.bool,
    "client options",
    true,
    contains({|"interceptLinks":false,"viewTransitions":true|}),
  );
  Alcotest.check(
    Alcotest.bool,
    "page cache max age",
    true,
    contains({|"pageCacheMaxAge":30,|}),
  );
};

let renderPage = (~search, pathname) =>
  switch (
    Lwt_main.run(
      RouterEngine.Server.run(
        RouterRegistry.server,
        ~diagnosticId=_ => "diagnostic",
        ~context="",
        {
          pathname,
          search,
          hash: "",
          kind: RouterEngine.ServerEngine.Document,
          navigation: None,
        },
      ),
    )
  ) {
  | RouterEngine.ServerEngine.Full(full) =>
    markup(RouterEngine.Plan.resolvedElement(full.resolved))
  | _ => Alcotest.fail("expected a full response for " ++ pathname)
  };

let testSearchKey = () => {
  Alcotest.check(
    string,
    "href writes keys sorted by key",
    "/site/support?a-zone=w&info-page=x&resources-projectId=7&z=q",
    Router.Support.href(
      ~search={
        infoPage: Some("x"),
        resourcesProjectId: 7,
        alpha: Some("q"),
        zone: ["w"],
      },
      (),
    ),
  );
  Alcotest.check(
    string,
    "default omitted",
    "/site/support?info-page=x",
    Router.Support.href(
      ~search=Router.Support.search(~infoPage="x", ()),
      (),
    ),
  );
  Alcotest.check(
    string,
    "server decodes keys into labels",
    "x|7|q|w",
    renderPage(
      ~search="?info-page=x&resources-projectId=7&z=q&a-zone=w",
      "/site/support",
    ),
  );
  Alcotest.check(
    string,
    "labels are not keys",
    "-|0|-|",
    renderPage(
      ~search="?infoPage=x&resourcesProjectId=7&alpha=q&zone=w",
      "/site/support",
    ),
  );
  let record =
    Router.Support.search(~infoPage="x", ~resourcesProjectId=3, ());
  Alcotest.(check(bool))(
    "rsc round trip",
    true,
    Router.Support.search_of_rsc(Router.Support.search_to_rsc(record))
    == record,
  );
};

let reportExecution = () => {
  Pages.ReportGates.reset();
  let search =
    switch (RouterEngine.Search.parse("")) {
    | Ok(search) => search
    | Error(_) => Alcotest.fail("expected valid search")
    };
  switch (
    RouterEngine.EndpointRegistry.find(
      RouterRegistry.registry,
      ~pathname="/reports/r1",
    )
  ) {
  | Ok(Some(matched)) =>
    switch (RouterEngine.EndpointRegistry.decode(matched, ~search)) {
    | Ok(prepared) =>
      RouterEngine.Execution.run(
        RouterEngine.Endpoint.execution(prepared, ~context=""),
      )
    | Error(_) => Alcotest.fail("expected decoded report endpoint")
    }
  | _ => Alcotest.fail("expected a report match")
  };
};

let reportPage = execution =>
  switch (Lwt_main.run(execution)) {
  | RouterRuntime.Loader.Data(plan) =>
    Lwt_main.run(
      RouterEngine.Plan.resolve(plan, ~applicationStatus=_ =>
        RouterRuntime.Status.InternalServerError
      ),
    )
    |> RouterEngine.Plan.resolvedElement
    |> markup
  | _ => Alcotest.fail("expected a report plan")
  };

let testParallelLoaderOverlap = () => {
  let execution = reportExecution();
  Alcotest.check(
    Alcotest.list(string),
    "both loaders start before either finishes",
    ["stats:start", "report:start"],
    Pages.ReportGates.events^,
  );
  Pages.ReportGates.(resolve(stats, RouterRuntime.Loader.Data("s")));
  Pages.ReportGates.(resolve(report, RouterRuntime.Loader.Data("r")));
  Alcotest.check(string, "page", "r1:r:s", reportPage(execution));
  Alcotest.check(
    Alcotest.list(string),
    "child finished first",
    ["stats:start", "report:start", "stats:done", "report:done"],
    Pages.ReportGates.events^,
  );
};

let testParallelLoaderParentFailureWins = () => {
  let execution = reportExecution();
  Pages.ReportGates.(resolve(stats, RouterRuntime.Loader.Error("stats")));
  Pages.ReportGates.(resolve(report, RouterRuntime.Loader.Error("report")));
  Alcotest.check(
    string,
    "parent error",
    "report-error:report",
    reportPage(execution),
  );
};

let testParallelLoaderChildFailure = () => {
  let execution = reportExecution();
  Pages.ReportGates.(resolve(stats, RouterRuntime.Loader.NotFound));
  Pages.ReportGates.(resolve(report, RouterRuntime.Loader.Data("r")));
  Alcotest.check(
    string,
    "child not found",
    "report-error",
    reportPage(execution),
  );
};

let testActionErrorBoundary = () => {
  let render = pathname => {
    let outcome =
      Lwt_main.run(
        RouterEngine.Server.run(
          RouterRegistry.server,
          ~diagnosticId=_ => "diagnostic",
          ~actionError=RouterRuntime.Error.Internal({ diagnosticId: "d" }),
          ~context="",
          {
            pathname,
            search: "",
            hash: "",
            kind: RouterEngine.ServerEngine.Document,
            navigation: None,
          },
        ),
      );
    switch (outcome) {
    | RouterEngine.ServerEngine.Full(full) => (
        RouterRuntime.Status.toInt(full.resolved.status),
        markup(RouterEngine.Plan.resolvedElement(full.resolved)),
      )
    | _ => Alcotest.fail("expected a full response for " ++ pathname)
    };
  };
  let (status, html) = render("/site/settings/billing");
  Alcotest.check(Alcotest.int, "status", 500, status);
  Alcotest.check(string, "nearest boundary", "settings-error", html);
  let (status, html) = render("/site/help");
  Alcotest.check(Alcotest.int, "root status", 500, status);
  Alcotest.check(string, "root boundary", "", html);
};

let testLoaderContext = () => {
  let outcome =
    Lwt_main.run(
      RouterEngine.Server.run(
        RouterRegistry.server,
        ~diagnosticId=_ => "diagnostic",
        ~context="ada",
        {
          pathname: "/site/account",
          search: "",
          hash: "",
          kind: RouterEngine.ServerEngine.Document,
          navigation: None,
        },
      ),
    );
  switch (outcome) {
  | RouterEngine.ServerEngine.Full(full) =>
    Alcotest.check(
      string,
      "loader",
      "viewer:ada",
      markup(RouterEngine.Plan.resolvedElement(full.resolved)),
    );
    Alcotest.check(
      Alcotest.option(string),
      "metadata",
      Some("account:ada"),
      full.resolved.metadata.title,
    );
    Alcotest.check(
      Alcotest.option(string),
      "headers",
      Some("ada"),
      List.assoc_opt(
        "X-Viewer",
        RouterRuntime.Headers.toList(full.resolved.headers),
      ),
    );
  | _ => Alcotest.fail("expected a full response")
  };
};

let committed = (~search="", ~matches, pathname) =>
  RouterRuntime.Navigation.{
    location: {
      pathname,
      search,
      hash: "",
      key: "test",
    },
    matches:
      List.map(
        ((routeId, parameters)) =>
          {
            routeId,
            parameters,
          },
        matches,
      ),
    layouts: [],
    revision: "",
  };

let routeName =
  fun
  | Router.Note({ id }) => "Note " ++ Int.to_string(id)
  | Router.DocsTopic({ topic }) => "DocsTopic " ++ topic
  | Router.Inspector => "Inspector"
  | _ => "other";

module RouteProbe = {
  [@react.component]
  let make = () => {
    let route =
      switch (Router.useRoute()) {
      | Some(route) => routeName(route)
      | None => "none"
      };
    let matches = Router.useMatches() |> List.map(routeName);
    let active =
      switch (Router.useActiveSearch()) {
      | Some(Router.ActiveSearch.Note(search)) =>
        "Note tab=" ++ Option.value(search.tab, ~default="-")
      | Some(Router.ActiveSearch.Inspector(search)) =>
        "Inspector target=" ++ search.target
      | Some(_) => "other"
      | None => "none"
      };
    let inspector =
      switch (Router.Inspector.useSearch()) {
      | (Some(search), _) => search.target
      | (None, _) => "missing"
      };
    let location = Router.useLocation();
    React.string(
      String.concat(
        "|",
        [
          route,
          String.concat(",", matches),
          active,
          inspector,
          location.pathname,
        ],
      ),
    );
  };
};

let probe = committed =>
  ReactDOM.renderToStaticMarkup(
    RouterReact.locationScope(~committed, ~children=<RouteProbe />, ()),
  );

let testActiveRouteHooks = () => {
  Alcotest.check(
    string,
    "matched route",
    "Note 42|Note 42|Note tab=x|missing|/site/notes/42",
    probe(
      committed(
        ~search="?tab=x",
        ~matches=[("Note", [("id", "42")])],
        "/site/notes/42",
      ),
    ),
  );
  Alcotest.check(
    string,
    "unknown route and invalid parameters",
    "none|DocsTopic a|none|missing|/site/x",
    probe(
      committed(
        ~matches=[
          ("DocsTopic", [("topic", "a")]),
          ("Note", [("id", "not-a-number")]),
          ("Removed", []),
        ],
        "/site/x",
      ),
    ),
  );
  Alcotest.check(
    string,
    "required search present",
    "Inspector|Inspector|Inspector target=t|t|/site/inspector",
    probe(
      committed(
        ~search="?target=t",
        ~matches=[("Inspector", [])],
        "/site/inspector",
      ),
    ),
  );
  Alcotest.check(
    string,
    "required search missing",
    "Inspector|Inspector|none|missing|/site/inspector",
    probe(committed(~matches=[("Inspector", [])], "/site/inspector")),
  );
};

let result = Alcotest.(result(string, string));

let testTryHref = () => {
  Alcotest.check(
    result,
    "valid",
    Ok("/site/docs/a%20b"),
    Router.DocsTopic.tryHref(~topic="a b", ()),
  );
  Alcotest.check(
    result,
    "slash",
    Error("route parameters must be valid non-empty path segments"),
    Router.DocsTopic.tryHref(~topic="a/b", ()),
  );
  Alcotest.check(
    result,
    "empty",
    Error("route parameters must be valid non-empty path segments"),
    Router.DocsTopic.tryHref(~topic="", ()),
  );
  Alcotest.check(
    result,
    "dot",
    Error("route parameters must be valid non-empty path segments"),
    Router.DocsTopic.tryHref(~topic="..", ()),
  );
  Alcotest.(check(bool))(
    "destination",
    true,
    Result.map(RouterRuntime.href, Router.Note.tryDestination(~id=1, ()))
    == Ok("/site/notes/1"),
  );
};

let testLinkAttributes = () => {
  Alcotest.check(
    string,
    "path parameter id and anchor id",
    {|<a style="color:red" href="/site/notes/7" id="note-link" title="Seven" data-testid="note" data-kind="primary">x</a>|},
    ReactDOM.renderToStaticMarkup(
      <Router.Note
        id=7
        attributes={RouterReact.Link.attributes(
          ~id="note-link",
          ~title="Seven",
          ~style=ReactDOM.Style.make(~color="red", ()),
          ~data=[("testid", "note"), ("kind", "primary")],
          (),
        )}>
        {React.string("x")}
      </Router.Note>,
    ),
  );
  Alcotest.check(
    string,
    "flat props win",
    {|<a href="/site/account" id="flat" data-a="1">y</a>|},
    ReactDOM.renderToStaticMarkup(
      <RouterReact.Link
        destination={Router.Account.destination()}
        id="flat"
        data=[("a", "1")]
        attributes={RouterReact.Link.attributes(~id="ignored", ())}>
        {React.string("y")}
      </RouterReact.Link>,
    ),
  );
  Alcotest.check(
    string,
    "data names that are not attribute names are dropped",
    {|<a href="/site/account" data-ok_1.a:b-c="2">z</a>|},
    ReactDOM.renderToStaticMarkup(
      <RouterReact.Link
        destination={Router.Account.destination()}
        data=[
          ("x autofocus onfocus=alert(1) y", "1"),
          ("ok_1.a:b-c", "2"),
          ("", "3"),
          ("a\"b", "4"),
          ("a>b", "5"),
        ]>
        {React.string("z")}
      </RouterReact.Link>,
    ),
  );
};

let testAbsoluteHref = () => {
  Alcotest.check(
    string,
    "origin and href",
    "https://example.com/site/notes/1?tab=a",
    RouterRuntime.absoluteHref(
      ~origin="https://example.com/",
      Router.Note.destination(~id=1, ~search={ tab: Some("a") }, ()),
    ),
  );
  Alcotest.check(
    string,
    "absolute destination",
    "https://docs.example.com/x",
    RouterRuntime.absoluteHref(
      ~origin="https://example.com",
      Router.unsafeDestination("https://docs.example.com/x"),
    ),
  );
};

let () =
  Alcotest.run(
    "router path patterns",
    [
      (
        "optional catch-all",
        [
          Alcotest.test_case("href", `Quick, testOptionalCatchAllHref),
          Alcotest.test_case("match", `Quick, testOptionalCatchAllMatch),
          Alcotest.test_case(
            "precedence",
            `Quick,
            testOptionalCatchAllPrecedence,
          ),
        ],
      ),
      (
        "optional segment",
        [
          Alcotest.test_case("href", `Quick, testOptionalSegmentHref),
          Alcotest.test_case("match", `Quick, testOptionalSegmentMatch),
        ],
      ),
      ("hash", [Alcotest.test_case("href", `Quick, testHash)]),
      (
        "hooks",
        [Alcotest.test_case("active route", `Quick, testActiveRouteHooks)],
      ),
      (
        "destinations",
        [
          Alcotest.test_case("try href", `Quick, testTryHref),
          Alcotest.test_case("absolute href", `Quick, testAbsoluteHref),
          Alcotest.test_case("link attributes", `Quick, testLinkAttributes),
        ],
      ),
      (
        "search",
        [
          Alcotest.test_case("record", `Quick, testSearchRecord),
          Alcotest.test_case("key", `Quick, testSearchKey),
        ],
      ),
      (
        "context",
        [
          Alcotest.test_case(
            "loader, metadata, headers",
            `Quick,
            testLoaderContext,
          ),
        ],
      ),
      (
        "parallel loader",
        [
          Alcotest.test_case("overlap", `Quick, testParallelLoaderOverlap),
          Alcotest.test_case(
            "parent failure wins",
            `Quick,
            testParallelLoaderParentFailureWins,
          ),
          Alcotest.test_case(
            "child failure",
            `Quick,
            testParallelLoaderChildFailure,
          ),
        ],
      ),
      (
        "form action",
        [
          Alcotest.test_case(
            "nearest error boundary",
            `Quick,
            testActionErrorBoundary,
          ),
        ],
      ),
      (
        "prefetch",
        [
          Alcotest.test_case("destination level", `Quick, testPrefetchLevels),
          Alcotest.test_case("registry level", `Quick, testPrefetchRegistry),
          Alcotest.test_case("client options", `Quick, testClientOptions),
        ],
      ),
    ],
  );

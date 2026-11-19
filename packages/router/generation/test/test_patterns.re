let string = Alcotest.string;
let pairs = Alcotest.(list(pair(string, string)));
let active = Alcotest.(list(pair(string, pairs)));

let resolve = (~query="", pathname) => {
  let search =
    switch (RouterServer.Search.parse(query)) {
    | Ok(search) => search
    | Error(_) => Alcotest.fail("expected valid search")
    };
  switch (
    RouterServer.EndpointRegistry.find(RouterRegistry.registry, ~pathname)
  ) {
  | Ok(Some(matched)) =>
    switch (RouterServer.EndpointRegistry.decode(matched, ~search)) {
    | Error(_) => Alcotest.fail("expected decoded endpoint for " ++ pathname)
    | Ok(prepared) =>
      let matches =
        RouterServer.EndpointRegistry.matches(matched, prepared)
        |> List.map(({ RouterRuntime.Navigation.routeId, parameters }) =>
             (routeId, parameters)
           );
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
        (
          matches,
          ReactDOM.renderToStaticMarkup(
            RouterServer.Plan.resolvedElement(resolved),
          ),
        );
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
      RouterServer.EndpointRegistry.find(RouterRegistry.registry, ~pathname)
    ) {
    | Ok(Some(matched)) =>
      RouterRuntime.PrefetchLevel.toString(
        RouterServer.EndpointRegistry.prefetch(matched),
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
        RouterServer.Server.clientRoot(
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
};

let testActionErrorBoundary = () => {
  let render = pathname => {
    let outcome =
      Lwt_main.run(
        RouterServer.Server.run(
          RouterRegistry.server,
          ~diagnosticId=_ => "diagnostic",
          ~revision=() => "revision",
          ~actionError=RouterRuntime.Error.Internal({ diagnosticId: "d" }),
          {
            pathname,
            search: "",
            hash: "",
            kind: RouterServer.ServerEngine.Document,
            navigation: None,
          },
        ),
      );
    switch (outcome) {
    | RouterServer.ServerEngine.Full(full) => (
        RouterRuntime.Status.toInt(full.resolved.status),
        ReactDOM.renderToStaticMarkup(
          RouterServer.Plan.resolvedElement(full.resolved),
        ),
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
      ("search", [Alcotest.test_case("record", `Quick, testSearchRecord)]),
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

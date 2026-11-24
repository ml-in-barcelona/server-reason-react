let expect = (message, condition) =>
  if (!condition) {
    failwith(message);
  };

expect(
  "content identities were reused across documents",
  !
    String.equal(
      RouterHistory.freshContentIdentity(),
      RouterHistory.freshContentIdentity(),
    ),
);

module Cache = RouterNavigationCache;
let scope = Cache.scope(~protocolVersion=1, ~registryFingerprint="f1");
let full = name =>
  Cache.[
    {
      graftAt: None,
      bytes: name,
    },
  ];
let cache = Cache.make(~capacity=2, ~maxAge=1000.0);
let store = (~scope=scope, ~now=0.0, pathname, layers) =>
  Cache.store(
    cache,
    ~scope,
    ~pathname,
    ~search="",
    ~now,
    ~startedIn=0,
    layers,
  );
let read =
    (
      ~scope=scope,
      ~action=RouterRuntime.Navigation.Pop,
      ~revalidate=false,
      ~now=0.0,
      pathname,
    ) =>
  Cache.read(cache, ~scope, ~pathname, ~search="", ~action, ~revalidate, ~now)
  |> Option.map((entry: Cache.entry(string)) => entry.layers);
store("/one", full("one"));
store("/two", full("two"));
let _ = read("/one");
store("/three", full("three"));
expect(
  "the navigation cache exceeded its capacity",
  Cache.length(cache) == 2,
);
expect(
  "the least recently used entry was not evicted",
  read("/two") == None,
);
expect("a recent entry was evicted", read("/one") == Some(full("one")));
expect(
  "a pop did not read an old entry",
  read(~now=5000.0, "/one") == Some(full("one")),
);
expect(
  "a push read an entry older than maxAge",
  read(~action=RouterRuntime.Navigation.Push, ~now=5000.0, "/one") == None,
);
expect(
  "a push did not read a fresh entry",
  read(~action=RouterRuntime.Navigation.Push, ~now=500.0, "/one")
  == Some(full("one")),
);
expect(
  "a revalidating pop read the cache",
  read(~revalidate=true, "/one") == None,
);
expect(
  "an entry was shared across registry fingerprints",
  read(
    ~scope=Cache.scope(~protocolVersion=1, ~registryFingerprint="f2"),
    "/one",
  )
  == None,
);
expect(
  "an entry was shared across protocol versions",
  read(
    ~scope=Cache.scope(~protocolVersion=3, ~registryFingerprint="f1"),
    "/one",
  )
  == None,
);
let disabled = Cache.make(~capacity=0, ~maxAge=0.0);
Cache.store(
  disabled,
  ~scope,
  ~pathname="/one",
  ~search="",
  ~now=0.0,
  ~startedIn=0,
  full("one"),
);
expect(
  "a cache with no capacity stored an entry",
  Cache.length(disabled) == 0,
);

let composed =
  Cache.compose(
    full("page"),
    ~graftAt="workspace",
    ~layouts=["root", "workspace", "note"],
    "workspace patch",
  );
let composed =
  Cache.compose(
    composed,
    ~graftAt="note",
    ~layouts=["root", "workspace", "note"],
    "note patch",
  );
expect(
  "a deeper patch did not stack on its ancestor",
  composed
  == Cache.[
       {
         graftAt: None,
         bytes: "page",
       },
       {
         graftAt: Some("workspace"),
         bytes: "workspace patch",
       },
       {
         graftAt: Some("note"),
         bytes: "note patch",
       },
     ],
);
expect(
  "a shallower patch kept a deeper patch it replaces",
  Cache.compose(
    composed,
    ~graftAt="workspace",
    ~layouts=["root", "workspace", "note"],
    "new workspace patch",
  )
  == Cache.[
       {
         graftAt: None,
         bytes: "page",
       },
       {
         graftAt: Some("workspace"),
         bytes: "new workspace patch",
       },
     ],
);

let generations = Cache.make(~capacity=10, ~maxAge=0.0);
let storeAt = (~startedIn, pathname) =>
  Cache.store(
    generations,
    ~scope,
    ~pathname,
    ~search="",
    ~now=0.0,
    ~startedIn,
    full(pathname),
  );
let cachedAt = pathname =>
  Cache.hasFresh(generations, ~scope, ~pathname, ~search="", ~now=0.0)
  || List.exists(
       (entry: Cache.entry(string)) => entry.pathname == pathname,
       generations.entries,
     );
let beforeLogout = Cache.generation(generations);
Cache.invalidate(generations, All);
storeAt(~startedIn=beforeLogout, "/account");
expect(
  "a response that started before an invalidation was stored",
  !cachedAt("/account"),
);
storeAt(~startedIn=Cache.generation(generations), "/account");
expect(
  "a response that started after an invalidation was not stored",
  cachedAt("/account"),
);
let beforePrefix = Cache.generation(generations);
Cache.invalidate(generations, Prefix("/notes"));
storeAt(~startedIn=beforePrefix, "/notes/1");
storeAt(~startedIn=beforePrefix, "/teams");
expect(
  "a response under an invalidated prefix was stored",
  !cachedAt("/notes/1"),
);
expect(
  "a response outside an invalidated prefix was dropped",
  cachedAt("/teams"),
);
for (_ in 1 to 70) {
  Cache.invalidate(generations, Prefix("/other"));
};
storeAt(~startedIn=beforePrefix, "/teams/2");
expect(
  "a response older than the remembered invalidations was stored",
  !cachedAt("/teams/2"),
);
expect(
  "a successful response was not storable",
  Cache.storable(~httpStatus=200, ~status=200),
);
List.iter(
  ((httpStatus, status)) =>
    expect(
      "an error response was storable: "
      ++ string_of_int(httpStatus)
      ++ "/"
      ++ string_of_int(status),
      !Cache.storable(~httpStatus, ~status),
    ),
  [
    (500, 200),
    (200, 500),
    (200, 404),
    (200, 401),
    (200, 403),
    (204, 302),
  ],
);

let prefixCache = Cache.make(~capacity=10, ~maxAge=0.0);
List.iter(
  pathname =>
    Cache.store(
      prefixCache,
      ~scope,
      ~pathname,
      ~search="",
      ~now=0.0,
      ~startedIn=0,
      full(pathname),
    ),
  ["/app/notes", "/app/notes/1", "/app/notesheet", "/app/teams"],
);
Cache.invalidate(prefixCache, Prefix("/app/notes"));
let cachedPaths = () =>
  List.map(
    (entry: Cache.entry(string)) => entry.pathname,
    prefixCache.entries,
  )
  |> List.sort(compare);
expect(
  "a prefix invalidation did not keep only the paths outside the prefix",
  cachedPaths() == ["/app/notesheet", "/app/teams"],
);
Cache.invalidate(prefixCache, All);
expect(
  "invalidating everything kept an entry",
  Cache.length(prefixCache) == 0,
);

let original = React.string("original");
let firstPayload = React.string("first patch");
let initial: RouterOutlet.saved = {
  serial: 0,
  child: original,
};
let firstPatch =
  RouterOutlet.ApplyPatch({
    serial: 1,
    graftAt: "root",
    targetLayouts: ["root", "nested"],
    payload: firstPayload,
  });
let (firstVisible, firstSaved) =
  RouterOutlet.transition(
    ~owner="root",
    ~children=original,
    initial,
    firstPatch,
  );
expect("the first patch was not rendered", firstVisible == firstPayload);
let firstSaved =
  switch (firstSaved) {
  | Some(saved) => saved
  | None => failwith("the first patch was not saved")
  };
let secondPatch =
  RouterOutlet.ApplyPatch({
    serial: 2,
    graftAt: "nested",
    targetLayouts: ["root", "nested"],
    payload: React.string("second patch"),
  });
let (secondVisible, secondSaved) =
  RouterOutlet.transition(
    ~owner="root",
    ~children=original,
    firstSaved,
    secondPatch,
  );
expect(
  "a deeper patch restored the original children",
  secondVisible == firstPayload,
);
switch (secondSaved) {
| Some(saved) =>
  expect(
    "a deeper patch replaced the saved subtree",
    saved.child == firstPayload,
  )
| None => failwith("the second patch was not recorded")
};

let cachedGraft = React.string("cached workspace patch");
let refresh =
  RouterOutlet.RefreshFull({
    serial: 5,
    grafts: [("workspace", cachedGraft)],
  });
let (graftedVisible, graftedSaved) =
  RouterOutlet.transition(
    ~owner="workspace",
    ~children=original,
    initial,
    refresh,
  );
expect(
  "a cached page did not show its grafted payload",
  graftedVisible == cachedGraft
  && (
    switch (graftedSaved) {
    | Some(saved) => saved.child == cachedGraft && saved.serial == 5
    | None => false
    }
  ),
);
let (ungraftedVisible, _) =
  RouterOutlet.transition(
    ~owner="root",
    ~children=original,
    initial,
    refresh,
  );
expect(
  "an outlet without a cached graft did not show its children",
  ungraftedVisible == original,
);

let location =
  RouterRuntime.Navigation.{
    pathname: "/items",
    search: "?view=server-a",
    hash: "",
    key: "current",
  };
let committed =
  RouterRuntime.Navigation.{
    location,
    matches: [],
    layouts: [],
    revision: "reused-server-revision",
  };
let searchTarget = {
  ...location,
  search: "?view=server-b",
  key: "target",
};
expect(
  "different content identities were classified as shallow",
  RouterRuntime.Navigation.classifyPopByContentIdentity(
    committed,
    ~target=searchTarget,
    ~currentIdentity="content-2",
    ~targetIdentity=Some("content-1"),
  )
  == RouterRuntime.Navigation.Content,
);
expect(
  "a shallow search entry was classified as content",
  RouterRuntime.Navigation.classifyPopByContentIdentity(
    committed,
    ~target=searchTarget,
    ~currentIdentity="content-2",
    ~targetIdentity=Some("content-2"),
  )
  == RouterRuntime.Navigation.Shallow,
);
expect(
  "a hash entry was not classified as hash-only",
  RouterRuntime.Navigation.classifyPopByContentIdentity(
    committed,
    ~target={
      ...location,
      hash: "#details",
    },
    ~currentIdentity="content-2",
    ~targetIdentity=Some("content-2"),
  )
  == RouterRuntime.Navigation.HashOnly,
);

let navigationState = RouterRuntime.Navigation.make(committed);
let (firstState, firstRequest) =
  RouterRuntime.Navigation.start(
    navigationState,
    ~to_=searchTarget,
    ~action=RouterRuntime.Navigation.Pop,
  );
expect(
  "a loading request was not active",
  RouterRuntime.Navigation.isActive(firstState, ~requestId=firstRequest),
);
let (secondState, secondRequest) =
  RouterRuntime.Navigation.start(
    firstState,
    ~to_=searchTarget,
    ~action=RouterRuntime.Navigation.Push,
  );
expect(
  "a superseded request was still active",
  !RouterRuntime.Navigation.isActive(secondState, ~requestId=firstRequest),
);
expect(
  "the newest request was not active",
  RouterRuntime.Navigation.isActive(secondState, ~requestId=secondRequest),
);
expect(
  "a request was active after the navigation went idle",
  !
    RouterRuntime.Navigation.isActive(
      RouterRuntime.Navigation.shallow(
        secondState,
        ~location=searchTarget,
        ~action=RouterRuntime.Navigation.Push,
      ),
      ~requestId=secondRequest,
    ),
);

expect(
  "the removed failed response kind was still accepted",
  RouterRuntime.NavigationResponse.kindOfString("failed") == None,
);

let encodingTable = [
  ("abc", "abc"),
  ("a b", "a%20b"),
  ("/", "%2F"),
  ("?", "%3F"),
  ("#", "%23"),
  ("&", "%26"),
  ("=", "%3D"),
  ("+", "%2B"),
  ("%", "%25"),
  ("caf" ++ Js.String.fromCharCode(0xe9), "caf%C3%A9"),
  ("M" ++ Js.String.fromCharCode(0xfc) ++ "nchen", "M%C3%BCnchen"),
  ({js|😀|js}, "%F0%9F%98%80"),
  ("a-b_c.d~e!*'()", "a-b_c.d~e!*'()"),
];
let encodingPattern = RouterRuntime.pattern("/:v<string>");
List.iter(
  ((input, expected)) => {
    expect(
      "search encoding differs for " ++ input,
      RouterRuntime.encodeSearch([("k", [input])]) == "k=" ++ expected,
    );
    expect(
      "destination search encoding differs for " ++ input,
      RouterRuntime.href(
        RouterRuntime.destinationFromPattern(
          ~pattern=encodingPattern,
          ~parameters=[("v", "x")],
          ~search=[("k", [input])],
        ),
      )
      == "/x?k="
      ++ expected,
    );
    if (!String.contains(input, '/')) {
      expect(
        "path encoding differs for " ++ input,
        RouterRuntime.href(
          RouterRuntime.destinationFromPattern(
            ~pattern=encodingPattern,
            ~parameters=[("v", input)],
            ~search=[],
          ),
        )
        == "/"
        ++ expected,
      );
    };
  },
  encodingTable,
);
expect(
  "search is not sorted by name",
  RouterRuntime.encodeSearch([("b", ["1"]), ("a", ["2", "3"])])
  == "a=2&a=3&b=1",
);

expect(
  "search names are not sorted by code point",
  RouterRuntime.encodeSearch([
    (Js.String.fromCodePoint(0x1f600), ["2"]),
    (Js.String.fromCodePoint(0xff21), ["1"]),
  ])
  == "%EF%BC%A1=1&%F0%9F%98%80=2",
);

let rejects = encode =>
  try(
    {
      ignore(encode());
      false;
    }
  ) {
  | Invalid_argument(_) => true
  };
expect(
  "a lone surrogate in a search value was printed",
  rejects(() =>
    RouterRuntime.encodeSearch([("k", [Js.String.fromCharCode(0xd800)])])
  ),
);
expect(
  "a lone surrogate in a search name was printed",
  rejects(() =>
    RouterRuntime.encodeSearch([(Js.String.fromCharCode(0xdc00), ["v"])])
  ),
);
expect(
  "a surrogate pair in a search value was replaced",
  RouterRuntime.encodeSearch([("k", [{js|😀|js}])]) == "k=%F0%9F%98%80",
);

List.iter(
  ((input, expected)) =>
    expect(
      "parseInt differs for " ++ input,
      RouterRuntime.Search.parseInt(input) == expected,
    ),
  [
    ("2147483647", Ok(2147483647)),
    ("-2147483648", Ok(-2147483648)),
    ("0", Ok(0)),
    ("2147483648", Error("expected an integer")),
    ("-2147483649", Error("expected an integer")),
    ("99999999999999999999", Error("expected an integer")),
    ("+5", Error("expected an integer")),
    ("0x10", Error("expected an integer")),
    ("1_000", Error("expected an integer")),
    ("", Error("expected an integer")),
    ("-", Error("expected an integer")),
  ],
);

let badSearch = [
  ("page", ["nope"]),
  ("n", ["1", "x", "3", ""]),
  ("o", ["nope"]),
  ("r", ["nope"]),
];
let parseInt = RouterRuntime.Search.parseInt;
expect(
  "a bad optional search value was not read as None",
  RouterRuntime.Search.optional(~name="o", ~parse=parseInt, badSearch) == None,
);
expect(
  "a bad defaulted search value did not fall back to the default",
  RouterRuntime.Search.default(
    ~name="page",
    ~parse=parseInt,
    ~fallback=1,
    badSearch,
  )
  == 1,
);
expect(
  "bad repeated search values were not skipped",
  RouterRuntime.Search.many(~name="n", ~parse=parseInt, badSearch) == [1, 3],
);
expect(
  "a bad required search value was not read as None",
  RouterRuntime.Search.required(~name="r", ~parse=parseInt, badSearch) == None,
);
expect(
  "a missing required search value was not read as None",
  RouterRuntime.Search.required(~name="missing", ~parse=parseInt, badSearch)
  == None,
);
expect(
  "a good required search value was not read",
  RouterRuntime.Search.required(
    ~name="r",
    ~parse=parseInt,
    [("r", ["7", "8"])],
  )
  == Some(7),
);

let sameSearch = (current, next) => RouterSearch.unchanged(~current, ~next);
expect(
  "a plus-encoded space counted as a search change",
  sameSearch("?q=a+b", [("q", ["a b"])]),
);
expect(
  "a percent-encoded space counted as a search change",
  sameSearch("?q=a%20b", [("q", ["a b"])]),
);
expect(
  "a reordered query counted as a search change",
  sameSearch("?b=1&a=2", [("a", ["2"]), ("b", ["1"])]),
);
expect(
  "an empty query counted as a search change",
  sameSearch("", []) && sameSearch("?", []),
);
expect(
  "a different value did not count as a search change",
  !sameSearch("?q=a+b", [("q", ["a c"])]),
);
expect(
  "a removed value did not count as a search change",
  !sameSearch("?q=a", []),
);

let installStorage: unit => unit = [%mel.raw
  {|() => {
  const data = new Map();
  globalThis.sessionStorage = {
    getItem: (key) => (data.has(key) ? data.get(key) : null),
    setItem: (key, value) => { data.set(key, String(value)); },
  };
}|}
];
let writeStorage: (string, string) => unit = [%mel.raw
  {|(key, value) => globalThis.sessionStorage.setItem(key, value)|}
];
let storedScrollCount: unit => int = [%mel.raw
  {|() => JSON.parse(globalThis.sessionStorage.getItem("server-reason-react.router.scroll")).length|}
];
let storedScrollEntry: string => string = [%mel.raw
  {|(id) => JSON.stringify(JSON.parse(globalThis.sessionStorage.getItem("server-reason-react.router.scroll")).find((entry) => entry[0] === id))|}
];
let onlyWindow = window =>
  Some(
    RouterScroll.{
      window,
      containers: [],
    },
  );
let breakStorage: unit => unit = [%mel.raw
  {|() => {
  globalThis.sessionStorage = {
    getItem() { throw new Error("storage denied"); },
    setItem() { throw new Error("storage denied"); },
  };
}|}
];

installStorage();
writeStorage(
  RouterScroll.storageKey,
  {|[["content-previous server",0,480],["with-containers",0,20,[["sidebar",0,300],["broken",1],["panel",5,60]]]]|},
);
expect(
  "a scroll position saved by a previous document was not restored",
  RouterScroll.find(
    RouterScroll.entryId(~revision="content-previous", ~key="server"),
  )
  == onlyWindow((0.0, 480.0)),
);
expect(
  "stored container positions were not decoded",
  RouterScroll.find("with-containers")
  == Some(
       RouterScroll.{
         window: (0.0, 20.0),
         containers: [("sidebar", (0.0, 300.0)), ("panel", (5.0, 60.0))],
       },
     ),
);
RouterScroll.save(
  "saved-containers",
  RouterScroll.{
    window: (0.0, 10.0),
    containers: [("list", (0.0, 250.0))],
  },
);
expect(
  "container positions were not stored with the entry",
  String.equal(
    storedScrollEntry("saved-containers"),
    {|["saved-containers",0,10,[["list",0,250]]]|},
  ),
);
RouterScroll.save(
  "saved-window",
  RouterScroll.{
    window: (0.0, 10.0),
    containers: [],
  },
);
expect(
  "an entry without containers was not stored in the original format",
  String.equal(storedScrollEntry("saved-window"), {|["saved-window",0,10]|}),
);
for (index in 0 to 149) {
  RouterScroll.save(
    "entry-" ++ string_of_int(index),
    RouterScroll.{
      window: (0.0, float_of_int(index)),
      containers: [],
    },
  );
};
expect(
  "stored scroll positions were not bounded",
  storedScrollCount() == RouterScroll.limit,
);
expect(
  "the oldest scroll position was kept past the bound",
  RouterScroll.find("entry-0") == None,
);
expect(
  "the newest scroll position was not stored",
  RouterScroll.find("entry-149") == onlyWindow((0.0, 149.0)),
);
breakStorage();
RouterScroll.save(
  "unstored",
  RouterScroll.{
    window: (3.0, 4.0),
    containers: [("list", (0.0, 7.0))],
  },
);
expect(
  "a scroll position was lost when sessionStorage threw",
  RouterScroll.find("unstored")
  == Some(
       RouterScroll.{
         window: (3.0, 4.0),
         containers: [("list", (0.0, 7.0))],
       },
     ),
);

let page =
  RouterPolicy.{
    href: "https://app.test/app/notes?view=list",
    origin: "https://app.test",
    pathname: "/app/notes",
    search: "?view=list",
  };
let redirectTo = (~followed=0, location) =>
  RouterPolicy.redirect(~basePath="/app", ~page, ~followed, location);
expect(
  "a same-origin redirect under the base path was not followed on the client",
  redirectTo("/app/login?next=%2Fapp")
  == FollowRedirect("/app/login?next=%2Fapp"),
);
expect(
  "a relative redirect was not resolved against the page",
  redirectTo("login") == FollowRedirect("/app/login"),
);
expect(
  "a cross-origin redirect was followed on the client",
  redirectTo("https://other.test/app/x")
  == LoadDocument("https://other.test/app/x"),
);
expect(
  "a redirect outside the base path was followed on the client",
  redirectTo("/application") == LoadDocument("https://app.test/application"),
);
expect(
  "a redirect chain was followed past the limit",
  redirectTo(~followed=RouterPolicy.maxRedirects, "/app/login")
  == LoadDocument("https://app.test/app/login"),
);

List.iter(
  location =>
    expect(
      "a redirect to a script URL was not refused: " ++ location,
      redirectTo(location) == RefuseRedirect(location)
      && RouterPolicy.actionRedirect(
           ~basePath="/app",
           ~patterns=[],
           ~page,
           location,
         )
      == RefuseRedirect(location),
    ),
  [
    "javascript:alert(1)",
    "JavaScript:alert(1)",
    " javascript:alert(1)",
    "data:text/html,<script>alert(1)</script>",
    "vbscript:msgbox(1)",
    "file:///etc/passwd",
  ],
);
expect(
  "a relative redirect outside the base path did not resolve against the page",
  redirectTo("../other?x=1") == LoadDocument("https://app.test/other?x=1"),
);

let click: (Js.Dict.t(string), Js.Dict.t(bool)) => RouterPolicy.event = [%mel.raw
  {|(attributes, flags) => {
  const anchor = {
    getAttribute: (name) => (name in attributes ? attributes[name] : null),
    hasAttribute: (name) => name in attributes,
  };
  return {
    defaultPrevented: !!flags.defaultPrevented,
    button: flags.middle ? 1 : 0,
    altKey: !!flags.altKey,
    ctrlKey: !!flags.ctrlKey,
    metaKey: !!flags.metaKey,
    shiftKey: !!flags.shiftKey,
    target: flags.textTarget
      ? {}
      : { closest: (selector) => (selector === "a[href]" && "href" in attributes ? anchor : null) },
  };
}|}
];
let clickedUrl = (~flags=[], attributes) =>
  RouterPolicy.clickedUrl(
    ~basePath="/app",
    ~page,
    click(Js.Dict.fromList(attributes), Js.Dict.fromList(flags)),
  );
expect(
  "a plain click on a router link was not intercepted",
  clickedUrl([("href", "/app/notes/2")]) == Some("/app/notes/2"),
);
expect(
  "a _self target was not intercepted",
  clickedUrl([("href", "/app/notes/2"), ("target", "_self")])
  == Some("/app/notes/2"),
);
expect(
  "a hash link to another search was not intercepted",
  clickedUrl([("href", "/app/notes#top")]) == Some("/app/notes#top"),
);
List.iter(
  ((message, flags, attributes)) =>
    expect(message, clickedUrl(~flags, attributes) == None),
  [
    (
      "a meta click was intercepted",
      [("metaKey", true)],
      [("href", "/app/a")],
    ),
    (
      "a ctrl click was intercepted",
      [("ctrlKey", true)],
      [("href", "/app/a")],
    ),
    (
      "a shift click was intercepted",
      [("shiftKey", true)],
      [("href", "/app/a")],
    ),
    (
      "an alt click was intercepted",
      [("altKey", true)],
      [("href", "/app/a")],
    ),
    (
      "a middle click was intercepted",
      [("middle", true)],
      [("href", "/app/a")],
    ),
    (
      "a prevented click was intercepted",
      [("defaultPrevented", true)],
      [("href", "/app/a")],
    ),
    (
      "a text node target was intercepted",
      [("textTarget", true)],
      [("href", "/app/a")],
    ),
    (
      "a download link was intercepted",
      [],
      [("href", "/app/a"), ("download", "")],
    ),
    (
      "a _blank link was intercepted",
      [],
      [("href", "/app/a"), ("target", "_blank")],
    ),
    (
      "a data-router-reload link was intercepted",
      [],
      [("href", "/app/a"), ("data-router-reload", "")],
    ),
    (
      "a cross-origin link was intercepted",
      [],
      [("href", "https://other.test/app/a")],
    ),
    (
      "a link outside the base path was intercepted",
      [],
      [("href", "/other")],
    ),
    ("a same-page hash link was intercepted", [], [("href", "#details")]),
    (
      "a same-page hash link with the full path was intercepted",
      [],
      [("href", "/app/notes?view=list#details")],
    ),
    ("an anchor without href was intercepted", [], []),
  ],
);

let currentLocation =
  RouterRuntime.Navigation.{
    pathname: "/app/notes",
    search: "?b=1&q=a+b",
    hash: "#top",
    key: "k",
  };
let isCurrent = href =>
  RouterPolicy.isCurrent(~location=currentLocation, href);
expect(
  "a link with the same path and reordered search was not current",
  isCurrent("/app/notes?q=a%20b&b=1"),
);
expect(
  "the hash changed whether a link is current",
  isCurrent("/app/notes?b=1&q=a%20b#other"),
);
expect("a link without the search was current", !isCurrent("/app/notes"));
expect(
  "a link to a child path was current",
  !isCurrent("/app/notes/1?b=1&q=a%20b"),
);

expect(
  "a superseded response was reported",
  RouterPolicy.validationOutcome(SupersededResponse) == Ignore,
);
expect(
  "a registry mismatch did not fall back to a full load",
  switch (RouterPolicy.validationOutcome(RegistryFingerprintMismatch)) {
  | FullLoad(_) => true
  | Ignore
  | Fail(_) => false
  },
);
expect(
  "an invalid content type did not fail the navigation",
  switch (RouterPolicy.validationOutcome(InvalidContentType(None))) {
  | Fail(_) => true
  | Ignore
  | FullLoad(_) => false
  },
);

let searchKey = (search, href) =>
  RouterSearchKey.isCurrent(~pathname="/app/notes", ~search, href);
expect(
  "a malformed UTF-8 escape matched its replacement character",
  !searchKey("?q=%FF", "/app/notes?q=%EF%BF%BD"),
);
expect(
  "an empty pair changed whether a link is current",
  searchKey("?a=1&&b=2", "/app/notes?b=2&a=1"),
);
expect(
  "a lower-case escape changed whether a link is current",
  searchKey("?q=%c3%a9", "/app/notes?q=%C3%A9"),
);
expect(
  "a broken escape compared as text",
  !searchKey("?q=%zz", "/app/notes?q=%25zz"),
);
expect(
  "a malformed pair changed whether a link is current",
  searchKey("?x=%FF&q=1", "/app/notes?q=1"),
);
expect(
  "the order of repeated values was ignored",
  !searchKey("?a=1&a=2", "/app/notes?a=2&a=1"),
);
expect(
  "a name without a value differed from an empty value",
  searchKey("?flag", "/app/notes?flag="),
);

let mutableAnchor: (string, Js.Nullable.t(string)) => RouterPolicy.anchor = [%mel.raw
  {|(href, current) => {
  const attributes = { href };
  if (current !== null) attributes["aria-current"] = current;
  return {
    getAttribute: (name) => (name in attributes ? attributes[name] : null),
    hasAttribute: (name) => name in attributes,
    setAttribute: (name, value) => { attributes[name] = value; },
    removeAttribute: (name) => { delete attributes[name]; },
  };
}|}
];
let ariaCurrentOf: RouterPolicy.anchor => Js.Nullable.t(string) = [%mel.raw
  {|(anchor) => anchor.getAttribute("aria-current")|}
];
let layoutNotes =
  mutableAnchor("/app/notes?q=a%20b&b=1", Js.Nullable.return("page"));
let layoutTeams = mutableAnchor("/app/teams", Js.Nullable.null);
let markAt = (pathname, search) =>
  RouterPolicy.markCurrentLinks(
    ~location={
      pathname,
      search,
      hash: "",
      key: "k",
    },
    [|layoutNotes, layoutTeams|],
  );
markAt("/app/teams", "");
expect(
  "a layout link kept aria-current after a navigation away",
  ariaCurrentOf(layoutNotes) == Js.Nullable.null,
);
expect(
  "a layout link did not get aria-current after a navigation to it",
  ariaCurrentOf(layoutTeams) == Js.Nullable.return("page"),
);
markAt("/app/notes", "?b=1&q=a+b");
markAt("/app/notes", "?b=2");
expect(
  "a layout link kept aria-current after a search update",
  ariaCurrentOf(layoutNotes) == Js.Nullable.null
  && ariaCurrentOf(layoutTeams) == Js.Nullable.null,
);

let hashOnly =
    (~action=RouterRuntime.Navigation.Push, ~revalidate=false, href) =>
  RouterPolicy.hashOnlyTarget(
    ~location=currentLocation,
    ~action,
    ~revalidate,
    href,
  );
expect(
  "a navigation that changes only the hash was not hash-only",
  hashOnly("/app/notes?q=a%20b&b=1#details") == Some("#details"),
);
expect(
  "a replace that changes only the hash was not hash-only",
  hashOnly(
    ~action=RouterRuntime.Navigation.Replace,
    "/app/notes?b=1&q=a%20b#details",
  )
  == Some("#details"),
);
expect(
  "a revalidating navigation was hash-only",
  hashOnly(~revalidate=true, "/app/notes?b=1&q=a%20b#details") == None,
);
expect(
  "a navigation without a hash was hash-only",
  hashOnly("/app/notes?b=1&q=a%20b") == None,
);
expect(
  "a navigation to another search was hash-only",
  hashOnly("/app/notes?b=2#details") == None,
);
expect(
  "a navigation to another path was hash-only",
  hashOnly("/app/other?b=1&q=a%20b#details") == None,
);
expect(
  "a pop was hash-only",
  hashOnly(
    ~action=RouterRuntime.Navigation.Pop,
    "/app/notes?b=1&q=a%20b#details",
  )
  == None,
);

let unchanged =
    (
      ~action=RouterRuntime.Navigation.Push,
      ~revalidate=false,
      ~status=RouterRuntime.Navigation.Idle,
      href,
    ) =>
  RouterPolicy.unchangedTarget(
    ~location=currentLocation,
    ~status,
    ~action,
    ~revalidate,
    href,
  );
expect(
  "a push to the committed URL was not unchanged",
  unchanged("/app/notes?q=a%20b&b=1#top"),
);
expect(
  "a replace to the committed URL was not unchanged",
  unchanged(
    ~action=RouterRuntime.Navigation.Replace,
    "/app/notes?b=1&q=a+b#top",
  ),
);
expect(
  "a navigation after a failed one to the committed URL was not unchanged",
  unchanged(
    ~status=
      RouterRuntime.Navigation.Failed({
        requestId: 1,
        message: "failed",
      }),
    "/app/notes?b=1&q=a+b#top",
  ),
);
expect(
  "a revalidating navigation to the committed URL was unchanged",
  !unchanged(~revalidate=true, "/app/notes?b=1&q=a+b#top"),
);
expect(
  "a pop to the committed URL was unchanged",
  !
    unchanged(
      ~action=RouterRuntime.Navigation.Pop,
      "/app/notes?b=1&q=a+b#top",
    ),
);
expect(
  "a navigation to the committed URL during another navigation was unchanged",
  !
    unchanged(
      ~status=
        RouterRuntime.Navigation.Loading({
          requestId: 2,
          fromRevision: "r",
          to_: {
            ...currentLocation,
            pathname: "/app/other",
          },
          action: RouterRuntime.Navigation.Push,
        }),
      "/app/notes?b=1&q=a+b#top",
    ),
);
expect(
  "a navigation without the committed hash was unchanged",
  !unchanged("/app/notes?b=1&q=a+b"),
);
expect(
  "a navigation to another hash was unchanged",
  !unchanged("/app/notes?b=1&q=a+b#details"),
);
expect(
  "a navigation to another search was unchanged",
  !unchanged("/app/notes?b=2#top"),
);
expect(
  "a navigation to another path was unchanged",
  !unchanged("/app/other?b=1&q=a+b#top"),
);

expect(
  "a content navigation with a hash did not scroll to the fragment",
  RouterPolicy.scrollFor(
    ~kind=RouterRuntime.Navigation.Content,
    ~saved=None,
    "#details",
  )
  == Fragment("details"),
);
expect(
  "an encoded fragment was not decoded",
  RouterPolicy.scrollFor(
    ~kind=RouterRuntime.Navigation.Content,
    ~saved=None,
    "#caf%C3%A9",
  )
  == Fragment("caf" ++ Js.String.fromCharCode(0xe9)),
);
expect(
  "a content navigation without a hash did not scroll to the top",
  RouterPolicy.scrollFor(
    ~kind=RouterRuntime.Navigation.Content,
    ~saved=None,
    "",
  )
  == Top,
);
expect(
  "a shallow navigation without a hash scrolled",
  RouterPolicy.scrollFor(
    ~kind=RouterRuntime.Navigation.Shallow,
    ~saved=None,
    "",
  )
  == Stay,
);
expect(
  "a saved position did not win over the fragment",
  RouterPolicy.scrollFor(
    ~kind=RouterRuntime.Navigation.Content,
    ~saved=Some((0.0, 9.0)),
    "#details",
  )
  == ScrollTo(0.0, 9.0),
);

module Level = RouterRuntime.PrefetchLevel;
let prefetcher = RouterPrefetch.make(~limit=2);
let started = ref([]);
let finishers = ref([]);
let run = (request: RouterPrefetch.request, finish) => {
  started := started^ @ [(request.url, request.trigger)];
  finishers := finishers^ @ [(request.url, finish)];
};
let prefetch = (~level=Level.Intent, ~trigger, url) =>
  RouterPrefetch.request(prefetcher, ~run, ~url, ~level, ~trigger);
let finish = url => List.assoc(url, finishers^, ());
prefetch(~trigger=Level.Intent, "/a");
expect(
  "an intent prefetch did not run",
  started^ == [("/a", Level.Intent)],
);
prefetch(~trigger=Level.Intent, "/a");
expect("a prefetch already in flight ran twice", List.length(started^) == 1);
prefetch(~trigger=Level.Viewport, "/intent-only");
expect(
  "a viewport prefetch ran for an intent route",
  List.length(started^) == 1,
);
prefetch(~level=Level.Off, ~trigger=Level.Intent, "/off");
expect(
  "an intent prefetch ran for an off route",
  List.length(started^) == 1,
);
prefetch(~level=Level.Idle, ~trigger=Level.Idle, "/b");
prefetch(~level=Level.Idle, ~trigger=Level.Viewport, "/c");
prefetch(~trigger=Level.Intent, "/d");
expect(
  "prefetches ran past the limit in flight",
  List.map(fst, started^) == ["/a", "/b"],
);
finish("/a");
expect(
  "an intent prefetch did not go ahead of queued viewport prefetches",
  List.map(fst, started^) == ["/a", "/b", "/d"],
);
finish("/b");
expect(
  "a queued prefetch did not run when a slot opened",
  List.map(fst, started^) == ["/a", "/b", "/d", "/c"],
);
finish("/d");
finish("/c");
RouterPrefetch.refuse(prefetcher, ~url="/e", Level.Intent);
prefetch(~level=Level.Viewport, ~trigger=Level.Viewport, "/e");
expect(
  "a refused prefetch was asked for again",
  !List.exists(((url, _)) => url == "/e", started^),
);
prefetch(~level=Level.Viewport, ~trigger=Level.Intent, "/e");
expect(
  "a refusal blocked a prefetch the route allows",
  List.exists(((url, _)) => url == "/e", started^),
);
expect(
  "prefetch levels did not parse from the attribute",
  RouterPrefetch.levelOfAttribute(None) == Level.Intent
  && RouterPrefetch.levelOfAttribute(Some("viewport")) == Level.Viewport
  && RouterPrefetch.levelOfAttribute(Some("idle")) == Level.Idle
  && RouterPrefetch.levelOfAttribute(Some("off")) == Level.Off
  && RouterPrefetch.levelOfAttribute(Some("eager")) == Level.Intent,
);

let fakeAnchor: Js.Dict.t(string) => RouterPolicy.anchor = [%mel.raw
  {|(attributes) => ({
  getAttribute: (name) => (name in attributes ? attributes[name] : null),
  hasAttribute: (name) => name in attributes,
})|}
];
let prefetchTarget = attributes =>
  RouterPolicy.prefetchTarget(
    ~basePath="/app",
    ~page,
    fakeAnchor(Js.Dict.fromList(attributes)),
  );
expect(
  "a viewport link did not give its prefetch level",
  prefetchTarget([
    ("href", "/app/notes/3"),
    ("data-router-prefetch", "viewport"),
  ])
  == Some(("/app/notes/3", Level.Viewport)),
);
expect(
  "a plain anchor was not an intent prefetch",
  prefetchTarget([("href", "/app/notes/3")])
  == Some(("/app/notes/3", Level.Intent)),
);
expect(
  "a reload link was prefetched",
  prefetchTarget([("href", "/app/notes/3"), ("data-router-reload", "")])
  == None,
);
expect(
  "a link outside the base path was prefetched",
  prefetchTarget([("href", "/elsewhere")]) == None,
);

expect(
  "a page with no stored response asked for a patch it cannot store",
  !Cache.sendsPatchBase(cache, ~revalidate=false, ~composable=false),
);
expect(
  "a page with a stored response did not ask for a patch",
  Cache.sendsPatchBase(cache, ~revalidate=false, ~composable=true),
);
expect(
  "a revalidation asked for a patch",
  !Cache.sendsPatchBase(cache, ~revalidate=true, ~composable=true),
);
expect(
  "without a cache, a navigation did not ask for a patch",
  Cache.sendsPatchBase(disabled, ~revalidate=false, ~composable=false),
);

let prefetchCache = Cache.make(~capacity=4, ~maxAge=0.0);
let storePrefetched = pathname =>
  Cache.store(
    prefetchCache,
    ~scope,
    ~pathname,
    ~search="",
    ~now=0.0,
    ~startedIn=0,
    ~prefetched=true,
    full(pathname),
  );
let readPrefetched = (~action=RouterRuntime.Navigation.Push, ~now, pathname) =>
  Cache.read(
    prefetchCache,
    ~scope,
    ~pathname,
    ~search="",
    ~action,
    ~revalidate=false,
    ~now,
  )
  != None;
storePrefetched("/p");
expect(
  "a fresh prefetched entry was not found",
  Cache.hasFresh(
    prefetchCache,
    ~scope,
    ~pathname="/p",
    ~search="",
    ~now=10.0,
  ),
);
expect(
  "a push did not read a fresh prefetched entry",
  readPrefetched(~now=29000.0, "/p"),
);
expect(
  "a push read a prefetched entry twice",
  !readPrefetched(~now=29000.0, "/p"),
);
expect(
  "a used prefetched entry was dropped for back and forward",
  readPrefetched(~action=RouterRuntime.Navigation.Pop, ~now=29000.0, "/p"),
);
storePrefetched("/q");
expect(
  "a push read a prefetched entry past the prefetch window",
  !readPrefetched(~now=Cache.prefetchWindow +. 1.0, "/q"),
);

let routePatterns =
  ["/notes", "/notes/:id<int>", "/files/:rest<string...>"]
  |> List.map(route =>
       switch (RouterPattern.parse(route)) {
       | Ok(pattern) => pattern
       | Error(_) => failwith("a test route did not parse")
       }
     );
let routed = RouterPolicy.routed(~basePath="/app", ~patterns=routePatterns);
expect(
  "a URL of a route was not routed",
  routed("/app/notes/42?view=a#top"),
);
expect("a catch-all URL was not routed", routed("/app/files/a/b.txt"));
expect("a URL without a route was routed", !routed("/app/export.csv"));
expect("a URL past a route was routed", !routed("/app/notes/42/raw"));
expect("a URL outside the base path was routed", !routed("/notes/42"));
expect(
  "a URL with an encoded slash was routed",
  !routed("/app/files/a%2Fb"),
);
expect(
  "a URL with an encoded dot segment was routed",
  !routed("/app/files/%2E"),
);
let actionRedirect =
  RouterPolicy.actionRedirect(
    ~basePath="/app",
    ~patterns=routePatterns,
    ~page,
  );
expect(
  "an action redirect to a route was not a client navigation",
  actionRedirect("/app/notes/7?from=action")
  == FollowRedirect("/app/notes/7?from=action"),
);
expect(
  "an action redirect to a URL without a route was a client navigation",
  actionRedirect("/app/export.csv")
  == LoadDocument("https://app.test/app/export.csv"),
);
expect(
  "an action redirect to another origin was a client navigation",
  actionRedirect("https://other.test/app/notes")
  == LoadDocument("https://other.test/app/notes"),
);
expect(
  "without routes, a URL was not routed",
  RouterPolicy.routed(~basePath="/app", ~patterns=[], "/app/anything"),
);

let blocker = RouterBlocker.make();
let notified = ref([]);
blocker.notify = (request => notified := [request, ...notified^]);
let resumed = ref(0);
let dropped = ref(0);
let guardNavigation = () =>
  RouterBlocker.guard(
    blocker,
    ~target="/app/next",
    ~action=RouterRuntime.Navigation.Push,
    ~resume=() => incr(resumed),
    ~drop=() => incr(dropped),
  );
guardNavigation();
expect("an unblocked navigation did not run", resumed^ == 1);
let release = RouterBlocker.retain(blocker);
guardNavigation();
expect("a blocked navigation ran", resumed^ == 1);
let pendingId = () =>
  switch (blocker.pending) {
  | Some(request) => request.id
  | None => failwith("a blocked navigation was not pending")
  };
expect(
  "the blocked state was not published",
  switch (notified^) {
  | [Some({ target: "/app/next", _ }), ..._] => true
  | _ => false
  },
);
let first = pendingId();
RouterBlocker.proceed(blocker, first);
RouterBlocker.proceed(blocker, first);
expect("a resumed navigation did not run exactly once", resumed^ == 2);
expect("a resumed navigation stayed pending", blocker.pending == None);
guardNavigation();
let second = pendingId();
RouterBlocker.cancel(blocker, second);
RouterBlocker.proceed(blocker, second);
expect("a canceled navigation ran", resumed^ == 2 && dropped^ == 1);
guardNavigation();
guardNavigation();
expect("a replaced blocked navigation was not canceled", dropped^ == 2);
release();
release();
expect(
  "releasing the last blocker did not cancel the pending navigation",
  dropped^ == 3,
);
expect("a released blocker still blocked", !RouterBlocker.blocking(blocker));

let traversed = ref([]);
let handled = ref(0);
let popTo = (~content=true, ~current=Some(4), target) =>
  RouterBlocker.pop(
    blocker,
    ~current,
    ~target,
    ~content,
    ~url="/app/previous",
    ~traverse=delta => traversed := [delta, ...traversed^],
    ~handle=() => incr(handled),
  );
let releasePop = RouterBlocker.retain(blocker);
popTo(Some(2));
expect("a blocked pop was handled", handled^ == 0);
expect("a blocked pop was not undone", traversed^ == [2]);
popTo(Some(4));
expect("the undo pop was handled", handled^ == 0);
RouterBlocker.proceed(blocker, pendingId());
expect("a resumed pop did not go back again", traversed^ == [(-2), 2]);
popTo(Some(2));
expect("the resumed pop was not handled", handled^ == 1);
popTo(~content=false, Some(3));
expect("a shallow pop was blocked", handled^ == 2);
popTo(None);
expect("a pop without a known position was blocked", handled^ == 3);
releasePop();

type fakeRegion;
let installAnnouncerDocument: unit => array(fakeRegion) = [%mel.raw
  {|() => {
  const children = [];
  globalThis.document = {
    title: "Note 42",
    body: {
      appendChild: (child) => { children.push(child); },
    },
    createElement: (tag) => {
      const attributes = {};
      const element = {
        tag,
        attributes,
        textContent: "",
        setAttribute: (name, value) => { attributes[name] = value; },
        remove: () => { children.splice(children.indexOf(element), 1); },
      };
      return element;
    },
  };
  return children;
}|}
];
let regionFacts: fakeRegion => (string, string, string) = [%mel.raw
  {|(region) => [region.attributes["aria-live"], region.attributes["aria-atomic"], region.textContent]|}
];

let regions = installAnnouncerDocument();
let region = RouterAnnouncer.mount();
expect(
  "the announcer region was not mounted once",
  Array.length(regions) == 1,
);
expect(
  "the announcer region is not a polite atomic live region",
  regionFacts(regions[0]) == ("polite", "true", ""),
);
RouterAnnouncer.announce(region);
expect(
  "the document title was not announced",
  regionFacts(regions[0]) == ("polite", "true", "Note 42"),
);
RouterAnnouncer.unmount(region);
expect("the announcer region was not removed", Array.length(regions) == 0);

type fakeTransition;
let installViewTransitions: unit => array(fakeTransition) = [%mel.raw
  {|() => {
  const attributes = new Map();
  const transitions = [];
  globalThis.document = {
    title: "Notes",
    documentElement: {
      setAttribute: (name, value) => { attributes.set(name, value); },
      removeAttribute: (name) => { attributes.delete(name); },
      getAttribute: (name) => (attributes.has(name) ? attributes.get(name) : null),
    },
    startViewTransition(update) {
      let finish;
      const transition = {
        update,
        skipped: false,
        ready: Promise.resolve(),
        finished: new Promise((resolve) => { finish = resolve; }),
        skipTransition() { transition.skipped = true; },
      };
      transition.finish = () => finish();
      transitions.push(transition);
      return transition;
    },
  };
  return transitions;
}|}
];
let runUpdate: (array(fakeTransition), int) => unit = [%mel.raw
  {|(transitions, index) => transitions[index].update()|}
];
let finishTransition: (array(fakeTransition), int) => unit = [%mel.raw
  {|(transitions, index) => transitions[index].finish()|}
];
let skipped: (array(fakeTransition), int) => bool = [%mel.raw
  {|(transitions, index) => transitions[index].skipped|}
];
let navAttribute: unit => Js.Nullable.t(string) = [%mel.raw
  {|() => globalThis.document.documentElement.getAttribute("data-router-nav")|}
];
let removeViewTransitions: unit => unit = [%mel.raw
  {|() => { delete globalThis.document.startViewTransition; }|}
];

let transitions = installViewTransitions();
let viewTransition = RouterViewTransition.make();
let applied = ref([]);
let apply = (~direction, name) =>
  RouterViewTransition.run(viewTransition, ~enabled=true, ~direction, () =>
    applied := [name, ...applied^]
  );
apply(~direction=Push, "first");
expect(
  "the push direction was not set during the transition",
  navAttribute() == Js.Nullable.return("push"),
);
apply(~direction=Back, "second");
expect("a stale transition was not skipped", skipped(transitions, 0));
expect(
  "the newer direction was not set",
  navAttribute() == Js.Nullable.return("back"),
);
runUpdate(transitions, 0);
runUpdate(transitions, 1);
expect("a stale transition applied its update", applied^ == ["second"]);
RouterViewTransition.run(viewTransition, ~enabled=false, ~direction=Push, () =>
  applied := ["disabled", ...applied^]
);
expect(
  "a disabled transition did not apply its update at once",
  applied^ == ["disabled", "second"] && Array.length(transitions) == 2,
);
apply(~direction=Forward, "third");
finishTransition(transitions, 1);
let _ =
  Js.Global.setTimeout(
    ~f=
      () => {
        expect(
          "a stale transition cleared the direction of a newer one",
          navAttribute() == Js.Nullable.return("forward"),
        );
        runUpdate(transitions, 2);
        finishTransition(transitions, 2);
        let _ =
          Js.Global.setTimeout(
            ~f=
              () => {
                expect(
                  "the direction stayed after the transition finished",
                  navAttribute() == Js.Nullable.null,
                );
                apply(~direction=Replace, "fourth");
                RouterViewTransition.supersede(viewTransition);
                runUpdate(transitions, 3);
                expect(
                  "a transition superseded by a navigation applied its update",
                  List.hd(applied^) == "third" && skipped(transitions, 3),
                );
                expect(
                  "a superseded transition kept the direction",
                  navAttribute() == Js.Nullable.null,
                );
                removeViewTransitions();
                apply(~direction=Push, "unsupported");
                expect(
                  "an update without view transition support was not applied",
                  List.hd(applied^) == "unsupported",
                );
              },
            0,
          );
        ();
      },
    0,
  );

switch (
  SearchKeyCases.failures((~pathname, ~search, href) =>
    RouterPolicy.isCurrent(
      ~location={
        pathname,
        search,
        hash: "",
        key: "k",
      },
      href,
    )
  )
) {
| [] => ()
| names =>
  failwith("JS isCurrent answers differ: " ++ String.concat(", ", names))
};

switch (
  SearchKeyCases.activeFailures((~prefix, ~pathname, href) =>
    RouterPolicy.linkMatches(
      ~rule=prefix ? "subtree" : "route",
      ~location={
        pathname,
        search: "",
        hash: "",
        key: "k",
      },
      href,
    )
  )
) {
| [] => ()
| names =>
  failwith("JS isActive answers differ: " ++ String.concat(", ", names))
};

switch (
  SearchParseCases.failures(
    ~parse=
      search =>
        switch (RouterSearch.parse(search)) {
        | Ok(values) => Ok(values)
        | Error(RouterSearchParse.QueryTooLong) => Error("too long")
        },
    ~encode=Js.Global.encodeURIComponent,
  )
) {
| [] => ()
| names =>
  failwith(
    "the JS search parser differs from the case table: "
    ++ String.concat(", ", names),
  )
};
expect(
  "a raw non-ASCII search was not read as its UTF-8 escapes",
  RouterSearch.parse("?q=caf" ++ Js.String.fromCharCode(0xe9))
  == Ok([("q", ["caf" ++ Js.String.fromCharCode(0xe9)])]),
);
expect(
  "a lone surrogate in a raw search was kept",
  RouterSearch.parse("?a=1&q=" ++ Js.String.fromCharCode(0xd800))
  == Ok([("a", ["1"])]),
);
expect(
  "a shallow pop to an unreadable search stayed on the client",
  RouterPolicy.popKind(
    ~search="?text=" ++ String.make(8190, 'a'),
    RouterRuntime.Navigation.Shallow,
  )
  == RouterRuntime.Navigation.Content,
);
expect(
  "a shallow pop to a search with a malformed pair went to the server",
  RouterPolicy.popKind(~search="?text=%FF", RouterRuntime.Navigation.Shallow)
  == RouterRuntime.Navigation.Shallow,
);
expect(
  "a hash-only pop on a page with an unreadable search went to the server",
  RouterPolicy.popKind(~search="?text=%ZZ", RouterRuntime.Navigation.HashOnly)
  == RouterRuntime.Navigation.HashOnly,
);
expect(
  "a shallow pop to a readable search went to the server",
  RouterPolicy.popKind(~search="?text=a+b", RouterRuntime.Navigation.Shallow)
  == RouterRuntime.Navigation.Shallow,
);

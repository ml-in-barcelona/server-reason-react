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

let pageCache = RouterPageCache.make(~capacity=2, ());
let cachedPage = {
  RouterPageCache.canonicalUrl: "/one",
  revision: "one",
  matches: [],
  layouts: [],
  metadata: React.null,
  element: React.string("one"),
};
RouterPageCache.set(pageCache, "/one", cachedPage);
RouterPageCache.set(
  pageCache,
  "/two",
  {
    ...cachedPage,
    canonicalUrl: "/two",
  },
);
let _ = RouterPageCache.find(pageCache, "/one");
RouterPageCache.set(
  pageCache,
  "/three",
  {
    ...cachedPage,
    canonicalUrl: "/three",
  },
);
expect(
  "page cache exceeded capacity",
  RouterPageCache.length(pageCache) == 2,
);
expect(
  "least recently used page was not evicted",
  Option.is_none(RouterPageCache.find(pageCache, "/two")),
);
expect(
  "recent page was evicted",
  Option.is_some(RouterPageCache.find(pageCache, "/one")),
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

/* Plain string literals are UTF-8 bytes in Melange, so non-ASCII text is built from code units. */
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

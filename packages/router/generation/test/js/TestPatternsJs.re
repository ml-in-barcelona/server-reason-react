let expect = (label, expected, actual) =>
  if (expected != actual) {
    failwith(label ++ ": expected " ++ expected ++ ", got " ++ actual);
  };

expect("optional catch-all absent", "/site/docs", Router.Docs.href());
expect(
  "optional catch-all present",
  "/site/docs/guide/caf%C3%A9/a%20b",
  Router.Docs.href(
    ~rest=["guide", "caf" ++ Js.String.fromCharCode(233), "a b"],
    (),
  ),
);
expect("optional segment absent", "/site/help", Router.Help.href());
expect(
  "optional segment present",
  "/site/help/de%20ch/topics/3",
  Router.HelpTopic.href(~lang="de ch", ~topic=3, ()),
);
expect(
  "hash after search",
  "/site/notes/1?tab=a%20b#top",
  Router.Note.href(~id=1, ~search={ tab: Some("a b") }, ~hash="top", ()),
);
expect(
  "encoded hash",
  "/site/notes/1#a%20b%23%C3%A9",
  Router.Note.href(~id=1, ~hash="a b#" ++ Js.String.fromCharCode(233), ()),
);
expect(
  "lone surrogate hash",
  "/site/notes/1#%EF%BF%BD",
  Router.Note.href(~id=1, ~hash=Js.String.fromCharCode(0xd800), ()),
);
expect("empty hash", "/site/notes/1", Router.Note.href(~id=1, ~hash="", ()));
expect(
  "search record",
  "/site/inspector?error=e&hash=a&target=x",
  SearchJsx.recordHref,
);
expect(
  "search constructor",
  "/site/inspector?input=x&target=a%20b",
  SearchJsx.constructorHref,
);
expect(
  "search elements",
  "2",
  string_of_int(List.length(SearchJsx.elements)),
);

let level = destination =>
  RouterRuntime.PrefetchLevel.toString(
    RouterRuntime.prefetchLevel(destination),
  );
expect(
  "prefetch default",
  "intent",
  level(Router.Note.destination(~id=1, ())),
);
expect("prefetch group", "viewport", level(Router.Settings.destination()));
expect(
  "prefetch override",
  "off",
  level(Router.SettingsBilling.destination()),
);
expect(
  "prefetch hash",
  "viewport",
  level(Router.Settings.destination(~hash="top", ())),
);

let matches = (path, pathname) =>
  switch (RouterPattern.parse(path)) {
  | Ok(pattern) => RouterPattern.matchesPath(pattern, pathname)
  | Error(_) => failwith("invalid pattern " ++ path)
  };
let expectMatch = (path, pathname, expected) =>
  if (matches(path, pathname) != expected) {
    failwith(
      "matchesPath "
      ++ path
      ++ " "
      ++ pathname
      ++ " should be "
      ++ string_of_bool(expected),
    );
  };
expectMatch("/", "/", true);
expectMatch("/app/notes", "/app/notes", true);
expectMatch("/app/notes", "/app/notes/", false);
expectMatch("/app/notes", "/app/%6Eotes", true);
expectMatch("/app/notes/:id<int>", "/app/notes/abc", true);
expectMatch("/app/notes/:id<int>", "/app/notes", false);
expectMatch("/assets/:parts<string...>", "/assets/a/b", true);
expectMatch("/assets/:parts<string...>", "/assets", false);
let unicode = Js.String.fromCharCode(233);
expectMatch("/caf" ++ unicode, "/caf%C3%A9", true);
expectMatch("/caf" ++ unicode, "/caf%c3%a9", true);
expectMatch("/caf" ++ unicode, "/caf%E9", false);
expectMatch("/" ++ Js.String.fromCharCode(0x20ac), "/%E2%82%AC", true);
expectMatch(
  "/" ++ Js.String.fromCharCodeMany([|0xd83d, 0xde00|]),
  "/%F0%9F%98%80",
  true,
);

let within = (basePath, path, pathname, expected) =>
  switch (RouterPattern.parse(path)) {
  | Ok(pattern) =>
    if (RouterPattern.matchesPath(~basePath, pattern, pathname) != expected) {
      failwith("matchesPath ~basePath:" ++ basePath ++ " " ++ pathname);
    }
  | Error(_) => failwith("invalid pattern " ++ path)
  };
within("/a%20b", "/notes/:id<int>", "/a%20b/notes/1", true);
within("/a%20b", "/", "/a%20b", true);
within("/a%20b", "/notes/:id<int>", "/a%20bc/notes/1", false);
within("/m%C3%BCnchen", "/docs", "/m%c3%bcnchen/docs", true);

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
switch (Router.Note.href(~id=1, ~hash=Js.String.fromCharCode(0xd800), ())) {
| href => failwith("lone surrogate hash: expected an error, got " ++ href)
| exception (Invalid_argument(_)) => ()
};
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
expect("search rsc round trip", "true", string_of_bool(SearchJsx.roundTrip));
expect(
  "search elements",
  "2",
  string_of_int(List.length(SearchJsx.elements)),
);

RouterReact.searchValues :=
  [
    ("info-page", ["x"]),
    ("infoPage", ["label"]),
    ("resources-projectId", ["7"]),
    ("a-zone", ["w"]),
  ];
let supportSearch = ref(None);
SearchJsx.renderSupportSearch((search, update) =>
  supportSearch := Some((search, update))
)
|> ignore;
switch (supportSearch^) {
| None => failwith("Support.useSearch did not render")
| Some((search, update)) =>
  expect(
    "useSearch reads key",
    "x",
    Option.value(search.infoPage, ~default="-"),
  );
  expect(
    "useSearch reads default key",
    "7",
    string_of_int(search.resourcesProjectId),
  );
  expect("useSearch reads many key", "w", String.concat(",", search.zone));
  update({
    ...search,
    infoPage: Some("y"),
    alpha: Some("q"),
  })
  |> ignore;
  let describe = values =>
    values
    |> List.map(((name, values)) =>
         name ++ "=" ++ String.concat(",", values)
       )
    |> String.concat("&");
  switch (RouterReact.searchUpdates^) {
  | [(owned, values)] =>
    expect(
      "useSearch owns keys",
      "info-page resources-projectId z a-zone",
      String.concat(" ", owned),
    );
    expect(
      "useSearch writes keys",
      "info-page=y&resources-projectId=7&z=q&a-zone=w",
      describe(values),
    );
  | _ => failwith("expected one search update")
  };
};

RouterReact.searchValues := [("info-page", ["x"]), ("other", ["kept"])];
RouterReact.searchUpdates := [];
let supportUpdate = ref(None);
SearchJsx.renderSupportUpdate(update => supportUpdate := Some(update))
|> ignore;
switch (supportUpdate^) {
| None => failwith("Support.useUpdateSearch did not render")
| Some(update) =>
  update(search =>
    {
      ...search,
      infoPage: Some(Option.value(search.infoPage, ~default="") ++ "1"),
    }
  )
  |> ignore;
  update(search =>
    {
      ...search,
      infoPage: Some(Option.value(search.infoPage, ~default="") ++ "2"),
      alpha: Some("a"),
    }
  )
  |> ignore;
  expect(
    "useUpdateSearch composes updates from the latest value",
    "info-page=x12&other=kept&z=a",
    RouterReact.searchValues^
    |> List.sort(((left, _), (right, _)) => String.compare(left, right))
    |> List.map(((name, values)) =>
         name ++ "=" ++ String.concat(",", values)
       )
    |> String.concat("&"),
  );
  expect(
    "useUpdateSearch owns the route keys",
    "info-page resources-projectId z a-zone",
    switch (RouterReact.searchUpdates^) {
    | [(owned, _), _] => String.concat(" ", owned)
    | _ => "expected two updates"
    },
  );
};

expect(
  "shallow search keys",
  "z",
  String.concat(
    ",",
    RouterRuntime.shallowSearch(Router.Support.destination()),
  ),
);
expect(
  "no shallow search keys",
  "",
  String.concat(
    ",",
    RouterRuntime.shallowSearch(
      Router.Inspector.destination(
        ~search=Router.Inspector.search(~target="t", ()),
        (),
      ),
    ),
  ),
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

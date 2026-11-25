module Response = RouterTypes.NavigationResponse;

type page = {
  href: string,
  origin: string,
  pathname: string,
  search: string,
};

let underBasePath = (~basePath, pathname) =>
  String.equal(basePath, "/")
  || String.equal(pathname, basePath)
  || String.starts_with(~prefix=basePath ++ "/", pathname);

let parse = (~base, url) =>
  try(Some(Webapi.Url.makeWith(url, ~base))) {
  | _ => None
  };

let routerUrl = (~basePath, ~page, url) =>
  switch (parse(~base=page.href, url)) {
  | Some(parsed)
      when
        String.equal(Webapi.Url.origin(parsed), page.origin)
        && underBasePath(~basePath, Webapi.Url.pathname(parsed)) =>
    Some(
      Webapi.Url.pathname(parsed)
      ++ Webapi.Url.search(parsed)
      ++ Webapi.Url.hash(parsed),
    )
  | Some(_)
  | None => None
  };

let maxRedirects = 5;

type redirect =
  | FollowRedirect(string)
  | LoadDocument(string)
  | RefuseRedirect(string);

let documentUrl = (~page, location) =>
  switch (parse(~base=page.href, location)) {
  | Some(parsed)
      when
        String.equal(Webapi.Url.protocol(parsed), "http:")
        || String.equal(Webapi.Url.protocol(parsed), "https:") =>
    LoadDocument(Webapi.Url.href(parsed))
  | Some(_)
  | None => RefuseRedirect(location)
  };

let redirect = (~basePath, ~page, ~followed, location) =>
  switch (routerUrl(~basePath, ~page, location)) {
  | Some(url) when followed < maxRedirects => FollowRedirect(url)
  | Some(_)
  | None => documentUrl(~page, location)
  };

type event;
type anchor;

[@mel.get] external defaultPrevented: event => bool = "defaultPrevented";
[@mel.get] external button: event => int = "button";
[@mel.get] external altKey: event => bool = "altKey";
[@mel.get] external ctrlKey: event => bool = "ctrlKey";
[@mel.get] external metaKey: event => bool = "metaKey";
[@mel.get] external shiftKey: event => bool = "shiftKey";
[@mel.send] [@mel.return nullable]
external getAttribute: (anchor, string) => option(string) = "getAttribute";
[@mel.send] external hasAttribute: (anchor, string) => bool = "hasAttribute";

let anchorOf: event => Js.Nullable.t(anchor) = [%mel.raw
  {|(event) => {
  const target = event.target;
  return target && typeof target.closest === "function" ? target.closest("a[href]") : null;
}|}
];

let plainClick = event =>
  !defaultPrevented(event)
  && button(event) == 0
  && !altKey(event)
  && !ctrlKey(event)
  && !metaKey(event)
  && !shiftKey(event);

let anchorUrl = (~basePath, ~page, anchor) =>
  if (!hasAttribute(anchor, "download")
      && !hasAttribute(anchor, "data-router-reload")
      && (
        switch (getAttribute(anchor, "target")) {
        | None
        | Some("")
        | Some("_self") => true
        | Some(_) => false
        }
      )) {
    switch (getAttribute(anchor, "href")) {
    | Some(href) =>
      switch (
        routerUrl(~basePath, ~page, href),
        parse(~base=page.href, href),
      ) {
      | (Some(url), Some(parsed)) =>
        let samePage =
          String.equal(Webapi.Url.pathname(parsed), page.pathname)
          && String.equal(Webapi.Url.search(parsed), page.search);
        samePage && !String.equal(Webapi.Url.hash(parsed), "")
          ? None : Some(url);
      | _ => None
      }
    | None => None
    };
  } else {
    None;
  };

let routed = (~basePath, ~patterns, url) =>
  switch (patterns) {
  | [] => true
  | patterns =>
    let pathname = fst(RouterSearchKey.splitHref(url));
    List.exists(
      pattern => RouterPattern.matchesPath(~basePath, pattern, pathname),
      patterns,
    );
  };

let actionRedirect = (~basePath, ~patterns, ~page, href) =>
  switch (routerUrl(~basePath, ~page, href)) {
  | Some(url) when routed(~basePath, ~patterns, url) => FollowRedirect(url)
  | Some(_)
  | None => documentUrl(~page, href)
  };

let clickedUrl = (~basePath, ~page, event) =>
  switch (plainClick(event), Js.Nullable.toOption(anchorOf(event))) {
  | (true, Some(anchor)) => anchorUrl(~basePath, ~page, anchor)
  | _ => None
  };

let prefetchTarget = (~basePath, ~page, anchor) =>
  Option.map(
    url =>
      (
        url,
        RouterPrefetch.levelOfAttribute(
          getAttribute(anchor, RouterPrefetch.attribute),
        ),
      ),
    anchorUrl(~basePath, ~page, anchor),
  );

let eventAnchor = event => Js.Nullable.toOption(anchorOf(event));

type observer;

let observeAnchors: (anchor => unit) => Js.Nullable.t(observer) = [%mel.raw
  {|(visible) => {
  if (typeof IntersectionObserver !== "function") return null;
  const observer = new IntersectionObserver((entries) => {
    for (const entry of entries) {
      if (entry.isIntersecting) {
        observer.unobserve(entry.target);
        visible(entry.target);
      }
    }
  }, { rootMargin: "200px" });
  return observer;
}|}
];
[@mel.send] external observe: (observer, anchor) => unit = "observe";
[@mel.send] external disconnect: observer => unit = "disconnect";

let anchorsWithLevels: array(string) => array(anchor) = [%mel.raw
  {|(levels) => Array.from(document.querySelectorAll(levels.map((level) => "a[href][data-router-prefetch=" + level + "]").join(",")))|}
];

let onIdle: (unit => unit, unit) => unit = [%mel.raw
  {|(callback) => {
  if (typeof requestIdleCallback !== "function") return () => {};
  const handle = requestIdleCallback(() => callback(), { timeout: 2000 });
  return () => cancelIdleCallback(handle);
}|}
];

let saveData: unit => bool = [%mel.raw
  {|() => { const connection = typeof navigator !== "undefined" ? navigator.connection : undefined; return !!(connection && connection.saveData); }|}
];

let isCurrent = (~location: RouterTypes.Navigation.location, href) =>
  RouterSearchKey.isCurrent(
    ~pathname=location.pathname,
    ~search=location.search,
    href,
  );

[@mel.send]
external setAttribute: (anchor, string, string) => unit = "setAttribute";
[@mel.send]
external removeAttribute: (anchor, string) => unit = "removeAttribute";

let routerLinkAttribute = "data-router-link";

let routerLinks: unit => array(anchor) = [%mel.raw
  {|() => Array.from(document.querySelectorAll("a[data-router-link]"))|}
];

let routerPendingAttribute = "data-router-pending";

let linkMatches = (~rule, ~location: RouterTypes.Navigation.location, href) =>
  switch (rule) {
  | "route" =>
    RouterSearchKey.isActive(~prefix=false, ~pathname=location.pathname, href)
  | "subtree" =>
    RouterSearchKey.isActive(~prefix=true, ~pathname=location.pathname, href)
  | _ => isCurrent(~location, href)
  };

let anchorMatches = (~location, anchor) =>
  switch (getAttribute(anchor, "href")) {
  | Some(href) =>
    Some(
      linkMatches(
        ~rule=
          Option.value(
            getAttribute(anchor, routerLinkAttribute),
            ~default="",
          ),
        ~location,
        href,
      ),
    )
  | None => None
  };

let markCurrentLinks = (~location, anchors) =>
  Array.iter(
    anchor =>
      switch (anchorMatches(~location, anchor)) {
      | Some(true) => setAttribute(anchor, "aria-current", "page")
      | Some(false) => removeAttribute(anchor, "aria-current")
      | None => ()
      },
    anchors,
  );

let markPendingLinks = (~target, anchors) =>
  Array.iter(
    anchor =>
      switch (
        Option.bind(target, location => anchorMatches(~location, anchor))
      ) {
      | Some(true) => setAttribute(anchor, routerPendingAttribute, "")
      | Some(false)
      | None => removeAttribute(anchor, routerPendingAttribute)
      },
    anchors,
  );

let popKind = (~search, kind) =>
  switch (kind) {
  | RouterTypes.Navigation.Shallow when !RouterSearch.valid(search) => RouterTypes.Navigation.Content
  | kind => kind
  };

type outcome =
  | Ignore
  | FullLoad(string)
  | Fail(string);

let validationOutcome = error =>
  switch (error) {
  | Response.SupersededResponse => Ignore
  | Response.StaleResponse =>
    FullLoad("navigation response has a stale base revision")
  | Response.ProtocolVersionMismatch =>
    FullLoad("navigation protocol version does not match")
  | Response.RegistryFingerprintMismatch =>
    FullLoad("route registry fingerprint does not match")
  | Response.InvalidHttpStatus(_) =>
    Fail("navigation response has an invalid HTTP status")
  | Response.InvalidContentType(_) =>
    Fail("navigation response has an invalid content type")
  | Response.ResponseKindMismatch =>
    Fail("navigation response kind does not match its envelope")
  | Response.CanonicalUrlRejected(_) =>
    Fail("navigation response has an invalid canonical URL")
  };

let hashOf = href =>
  switch (String.index_opt(href, '#')) {
  | Some(index) => String.sub(href, index, String.length(href) - index)
  | None => ""
  };

let hashOnlyTarget =
    (~location: RouterTypes.Navigation.location, ~action, ~revalidate, href) =>
  switch (action) {
  | RouterTypes.Navigation.Pop => None
  | RouterTypes.Navigation.Push
  | RouterTypes.Navigation.Replace =>
    let hash = hashOf(href);
    !revalidate && hash != "" && isCurrent(~location, href)
      ? Some(hash) : None;
  };

let unchangedTarget =
    (
      ~location: RouterTypes.Navigation.location,
      ~status: RouterTypes.Navigation.status,
      ~action,
      ~revalidate,
      href,
    ) =>
  switch (action, status) {
  | (RouterTypes.Navigation.Pop, _)
  | (_, RouterTypes.Navigation.Loading(_)) => false
  | (
      RouterTypes.Navigation.Push | RouterTypes.Navigation.Replace,
      RouterTypes.Navigation.Idle | RouterTypes.Navigation.Failed(_),
    ) =>
    !revalidate
    && String.equal(hashOf(href), location.hash)
    && isCurrent(~location, href)
  };

let changedSearchKeys = (~current, ~next) => {
  let values = (search, key) =>
    Option.value(List.assoc_opt(key, search), ~default=[]);
  List.map(fst, current @ next)
  |> List.sort_uniq(String.compare)
  |> List.filter(key => values(current, key) != values(next, key));
};

let shallowSearchTarget =
    (
      ~location: RouterTypes.Navigation.location,
      ~action,
      ~revalidate,
      ~shallowKeys,
      href,
    ) =>
  switch (action, shallowKeys) {
  | (RouterTypes.Navigation.Pop, _)
  | (_, []) => None
  | (RouterTypes.Navigation.Push | RouterTypes.Navigation.Replace, _) =>
    let (_, search) = RouterSearchKey.splitHref(href);
    let next = RouterSearch.valuesFromString(search);
    let changed =
      changedSearchKeys(
        ~current=RouterSearch.valuesFromString(location.search),
        ~next,
      );
    !revalidate
    && changed != []
    && List.for_all(key => List.mem(key, shallowKeys), changed)
    && RouterSearchKey.isActive(
         ~prefix=false,
         ~pathname=location.pathname,
         href,
       )
      ? Some((RouterSearch.toString(next), hashOf(href))) : None;
  };

type scroll =
  | ScrollTo(float, float)
  | Fragment(string)
  | Top
  | Stay;

let scrollFor = (~kind, ~resetScroll, ~saved, hash) =>
  switch (saved) {
  | Some((x, y)) => ScrollTo(x, y)
  | None =>
    let fragment =
      if (String.equal(hash, "")) {
        None;
      } else {
        try(
          Some(
            Js.Global.decodeURIComponent(
              String.sub(hash, 1, String.length(hash) - 1),
            ),
          )
        ) {
        | _ => None
        };
      };
    switch (fragment, kind) {
    | (Some(id), _) => Fragment(id)
    | (None, RouterTypes.Navigation.Shallow) => Stay
    | (None, RouterTypes.Navigation.Content)
    | (None, RouterTypes.Navigation.HashOnly) => resetScroll ? Top : Stay
    };
  };

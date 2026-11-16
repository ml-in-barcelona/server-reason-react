module Response = RouterRuntime.NavigationResponse;

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

let isCurrent = (~location: RouterRuntime.Navigation.location, href) =>
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

let markCurrentLinks = (~location, anchors) =>
  Array.iter(
    anchor =>
      switch (getAttribute(anchor, "href")) {
      | Some(href) when isCurrent(~location, href) =>
        setAttribute(anchor, "aria-current", "page")
      | Some(_) => removeAttribute(anchor, "aria-current")
      | None => ()
      },
    anchors,
  );

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
    (~location: RouterRuntime.Navigation.location, ~action, ~revalidate, href) =>
  switch (action) {
  | RouterRuntime.Navigation.Pop => None
  | RouterRuntime.Navigation.Push
  | RouterRuntime.Navigation.Replace =>
    let hash = hashOf(href);
    !revalidate && hash != "" && isCurrent(~location, href)
      ? Some(hash) : None;
  };

type scroll =
  | ScrollTo(float, float)
  | Fragment(string)
  | Top
  | Stay;

let scrollFor = (~kind, ~saved, hash) =>
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
    | (None, RouterRuntime.Navigation.Shallow) => Stay
    | (None, RouterRuntime.Navigation.Content)
    | (None, RouterRuntime.Navigation.HashOnly) => Top
    };
  };

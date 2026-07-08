# Area — webapi & Dom (native stubs)

Native stubs of melange-webapi (0.22.0) and Dom so universal code compiles server-side.

## Stubbing strategy
- Arrow externals → runtime raise `Runtime.Impossible_in_ssr` (via melange.ppx), printing two banners to **stdout** first. **No `[@alert]`**, so server misuse compiles clean, fails at runtime. CONFIRMED.
- Value (non-arrow) externals → compile error unless `[@platform js]`; that's why `window`/`document`/`history`/`location` are commented out (`Webapi__Dom.re:70-73`) — any universal `Webapi.Dom.document` reference is a native compile hole. CONFIRMED.

## Silent wrong values (worse than raising)
- `Webapi__Dom__EventTarget.re:6-46` — all `add/removeEventListener*` are `=> ()` no-ops (259 of them); `dispatchEvent` returns constant `false` (= "canceled by preventDefault"). Included into every node type. Server code branching on `dispatchEvent` takes the canceled path. CONFIRMED.
- `Webapi__Dom__Document.re:6` — `asHtmlDocument = _ => None` (Melange returns `Some`). Universal `Option.forEach` chains silently skip. CONFIRMED.
- `Webapi__Dom__DomStringMap.re:11` — `unsafeDeleteKey = ()` no-op. CONFIRMED.
- `Webapi__Base64.re` — `btoa`/`atob` raise despite being trivially implementable natively. CONFIRMED.

## Type-surface divergences (break universal compilation)
- **~150 zero-arg `[@mel.send.pipe]` externals get backwards `ret -> t` types** (melange.ppx `:693-694`): `Event.preventDefault : unit -> Dom.event` (Melange `t -> unit`), `Node.hasChildNodes`, `HtmlElement.blur/click/focus`, `Element.getBoundingClientRect/scrollIntoView`, `Location.reload`, `Window.blur/close/focus`, `Dom_storage.clear`, etc. `event |> Event.preventDefault` — the most common webapi call — is a native type error. CONFIRMED via `.cmi`. (Root cause = finding 2.18.)
- **`[@mel.as]` constant args become phantom `'a` params** (arity drift): `Node.cloneNodeDeep : 'a -> t -> t`, `Element.attachShadowOpen`, `Canvas.getContext2d : element -> 'a -> _`, etc. Upstream's own tests don't typecheck natively. CONFIRMED.
- Missing values present in melange-webapi: `Blob.arrayBuffer/text`, `ReadableStream.closed/cancel/DefaultReader.read`, `FormData.makeWithHtmlFormElement`, `Element.asHtmlElement`, `Storage.localStorage/sessionStorage`; `Dom.ml` missing `worker`/`messageEvent`/`messagePort`/`serviceWorker`. CONFIRMED compile holes.

## Unsoundness
- `HtmlElement.re:6` `let%browser_only ofElement = <ident>` → `Obj.magic () : 'a` → segfault, types as anything (browser_ppx `:220-222`, finding 2.19). CONFIRMED (SIGSEGV).
- `%identity` upcasts (`asNode`, `asElement`) are rewritten to raising stubs by melange.ppx (no `%identity` special case), so a free upcast that's an identity in Melange **crashes** on native — a silent cast→crash divergence. CONFIRMED.

## Tests
- `packages/webapi/tests/_dune` is an **empty file named `_dune`** → invisible to dune, never built. The 50 test files are stale melange-webapi browser smoke tests that wouldn't compile natively anyway (use deleted `document`, raising constructors, backwards-typed calls). Zero native coverage. CONFIRMED.

## Maintenance
- File inventory matches melange-webapi 0.22.0 exactly; value-level drift is per the compile holes above. Upstream migrated to `[@mel.send]`+`[@mel.this]`; this fork keeps `[@mel.send.pipe]`, which is exactly where the systemic type bugs live — so the gap widens with each upstream release.

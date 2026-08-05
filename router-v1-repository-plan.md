# Typed router v1 repository implementation plan

Status: Proposed execution plan

Date: 2026-08-03

Source design: [`router-v1-plan.md`](router-v1-plan.md)

Prototype evidence: [`router-prototype-audit.md`](router-prototype-audit.md)

This document maps the v1 design onto the current repository. It covers the new package under `packages/router`, the generated application router, the Dream/RSC adapter seam, and migration of the router demo. It does not implement the design.

## Repository outcome

The completed change has three layers:

1. `packages/router` owns reusable codecs, generated destinations, matching, loader execution, response envelopes, React navigation state, and route-compiler tooling.
2. `demo/router` owns the application route manifest, route components, and route-aware client components.
3. `demo/server` owns only final Dream registration and the rest of the demo server.

The existing `demo/dream-nested-router` implementation is removed after migration. It is not copied wholesale into the package. Its pure behavior is rewritten behind the v1 types; its mutable layout registry, response sentinel component, and React element cache are deleted.

The working internal names in this plan are `RouterRuntime`, `RouterServer`, and `RouterCompiler`. The final package name remains a pre-implementation decision. The application-facing generated compilation unit remains `Router`.

## Findings that constrain the implementation

### The package is one directory with several libraries

The repository currently publishes one opam package, `server-reason-react`, and exposes libraries through `public_name server-reason-react.*`. Adding `packages/router` does not require a second `(package ...)` stanza. The new directory should contain native, Melange, server, and route-compiler libraries, following the existing `packages/rsc` and `packages/url` splits.

Trying to put the entire router in one dual-mode library would mix incompatible dependency sets: Dream and Lwt on the server; Fetch, History, Webapi, and reason-react in Melange. The package directory is one product boundary, not one Dune library.

### Universal handles and native attachments need separate units

The route declaration references `AppLayout`, pages, loaders, and boundaries. Those components render client components that must call generated APIs such as `Router.Note.Link`. Without an interface, the dependency is cyclic:

```text
Router implementation
  -> RouterPages.AppLayout
  -> CreateNoteButton
  -> Router.NewNote
```

The Phase 0 fixture proved that Dune still rejects the implementation cycle even when a generated `Router.rei` is available. The authored manifest must therefore be a non-compiled `RouterDefinition.re`, and the route compiler must emit separate universal handles and native attachments.

The required build flow is:

```text
RouterDefinition.re manifest
  -> router generator --mode interface -> Router.rei
  -> router generator --mode handles   -> Router.re
  -> router generator --mode registry  -> RouterRegistry.re

native application
  -> Router.re + Router.rei + RouterRegistry.re

Melange application
  -> Router.re + Router.rei
```

One generator module consumes the shared parser and declaration IR and selects the artifact with `--mode`. A Dune rule runs `refmt` to parse the authored Reason source into the AST consumed by the generator and passes the manifest path explicitly with `--source` for diagnostics. Generate one canonical `Router.re`/`Router.rei` pair and copy it into the native and Melange compilation roots. Compile `RouterRegistry.re` only in native. The native and Melange public signatures are therefore identical by construction.

Do not reintroduce a single generated implementation unit, duplicate route declarations, or process-global registration to evade the cycle.

### The Dream adapter cannot depend from `packages` into `demo`

`DreamRSC` currently lives under `demo/dream-rsc`, and Dream is a development dependency in `dune-project`. A public package library must not depend on a demo library.

The first package cut therefore exposes a Dream-neutral native server engine. A thin demo adapter converts Dream requests into router request facts, runs the engine inside `DreamRSC`'s existing request-local Lwt scope, and streams the returned document or RSC plan. `DreamRSC` must expose a callback-style `withRequestContext` API because its current context installer is private and `createFromRequest` accepts an element only after pre-render work has happened. Publishing a Dream adapter or moving `DreamRSC` into `packages` is a separate decision after the router contract stabilizes.

### The demo needs more generated client API than `destination`, `href`, and `link`

Current callsites also need:

- A `useNavigation` hook returning an imperative navigator over opaque destinations and the current navigation state
- A typed navigation-options record for push, replace, revalidate, shallow search, hash behavior, and scroll policy
- A typed current-search hook and shallow search updater
- A route-specific active-match hook for selected sidebar entries
- Navigation state for disabling mutation controls and displaying pending state

These contracts must be frozen in the handwritten-expansion phase. Falling back to raw URL, packed-match, or search-map access is not an acceptable migration shortcut.

## Target package map

The precise public names are finalized before scaffolding. The following internal layout is the target:

```text
packages/router/
  shared/
    RouterTypes.re
    RouterDestination.re
    RouterLocation.re
    RouterProtocol.re
    RouterMetadata.re
    RouterHeaders.re
    RouterStatus.re
  native/
    dune
    shared/                 copied universal React/runtime sources
    RouterRuntime.re
    RouterServer.re
    RouterMatcher.re
    RouterLoader.re
  js/
    dune
    shared/                 copied universal React/runtime sources
    RouterRuntime.re
    RouterHistory.re
    RouterFetch.re
  ppx_common/
    dune
    RouterDeclaration.re
    RouterDeclarationParser.ml
    RouterExpansion.ml
  gen/
    dune
    RouterGen.ml
  test/
    dune
    codec_*.re
    matcher_*.re
    reducer_*.re
    protocol_*.re
  cram/
    dune
    expansion fixtures
    diagnostic fixtures
```

Names may change, but the boundaries may not collapse accidentally.

### Shared runtime responsibilities

The shared runtime compiles for native and Melange and owns:

- Opaque destinations
- Route IDs and layout-instance keys
- Canonical locations including pathname, search, hash, and history key
- History and navigation action variants
- Link and navigation option records
- Loader and normalized error variants
- Structured metadata and headers
- Full, patch, redirect, failed, and reload-required envelopes
- Pure reducer types and transitions where they do not touch browser APIs
- RSC serialization types shared across targets

It does not own Dream requests, browser globals, React rendering callbacks, or route-declaration parsing.

### Native runtime responsibilities

The native side owns:

- Segment decoding and custom codec invocation
- Search decoding, defaults, repetition, canonical ordering, and error construction
- Registry validation and deterministic fingerprinting
- Branch matching and longest decoded prefix retention
- Parent-first loader execution and Lwt cancellation
- Error normalization and boundary selection
- Async metadata and header composition
- Layout instance identity and full/patch render planning
- A server engine that consumes request facts and returns a response/render plan

The server engine must not import Dream. The demo adapter supplies target, method, headers, request-local execution, and streaming functions.

### Melange runtime responsibilities

The client side owns:

- Router provider and committed navigation state
- Abortable fetch and response validation
- Atomic reducer dispatch
- Browser history adapter
- Typed search subscriptions and shallow updates
- Route active-match subscriptions
- Generic link behavior and generated link wrappers
- Focus, scroll, and hash restoration
- Reload behavior on protocol or registry mismatch

It never matches routes independently for authorization or patch splitting.

Navigation Flight decoding must use the same server-function `callServer` callback as initial hydration. The router client runtime therefore exposes a `FlightProvider` or equivalent adapter. `demo/client/RouterDemo.re` wraps the initial model with that provider, and every later navigation decode reads it from context. Do not decode navigation payloads through a callback-free `createFromFetch` path.

### Route compiler responsibilities

`ppx_common` owns one declaration parser and platform-neutral IR. Every generated artifact consumes that IR.

The registry generator emits:

- Type-checking calls for pages and attachments
- Custom codec references
- Search codecs
- Loader adapters
- Packed registry nodes
- Native render adapters

The generator's `handles` mode emits:

- The same public destination modules and signatures
- Route IDs and printer/search metadata needed by links and hooks
- No references to native pages, loaders, metadata callbacks, headers, or Dream

The generator's `interface` mode emits only the common public API. It must never expose packed registry internals. `Router.re` and `Router.rei` are copied unchanged into both target roots.

## Target dependency graph

```text
router_ppx_common
  -> ppxlib

router_gen
  -> router_ppx_common
  -> ppxlib
  -> refmt in its Dune generation rule

router_native
  -> URI, Lwt
  -> exposes RouterRuntime and RouterServer

router_runtime_js
  -> reason-react, URL JS, RSC JS, ReactServerDOMEsbuild, Fetch, Webapi

router tests
  -> runtime and route-compiler libraries

demo_router_native
  -> router_native
  -> demo_shared_native

dream_router
  -> demo_router_native
  -> dream
  -> dream_rsc

demo_router_js
  -> router_runtime_js
  -> demo_shared_js

demo server
  -> dream_router
```

The runtime libraries must not depend on the route compiler. Generated source depends on runtime libraries in the ordinary target dependency graph. Because `implicit_transitive_deps` is disabled, every direct library dependency must be listed in its Dune stanza.

## Target demo layout

Move router-demo-specific application code out of the general shared demo library:

```text
demo/router/
  native/
    dune
    RouterPages.re             current server page/layout/document modules
    shared/
      RouterDefinition.re      single authored route manifest
      Router.re/.rei           generated universal handles
      RouterRegistry.re        generated native attachments
      NoteId.re                universal custom path codec
      *.re                     route-aware shared/client components
  js/
    dune
    shared/                    copied generated Router.re/.rei and route-aware client components
  dream/
    dune
    DreamRouterAdapter.re      thin Dream/RSC integration
```

`demo_shared_native` and `demo_shared_js` continue to provide generic UI, DB/domain modules, server functions, theme, and RSC utilities. They stop depending on `nested_router_native` and `nested_router_js`.

The native and JS router demo libraries both compile the generated `Router` public API. Dune generates one `Router.re`/`Router.rei` pair from the canonical manifest and copies it beside the JS sources. Only native compiles `RouterRegistry.re`, which references `RouterPages` and builds the packed registry.

The current `demo/server/pages/NestedRouter.re` is migrated into `demo/router/native/RouterPages.re`. The final server executable references `RouterPages.Document` and the generated router adapter. A temporary forwarding module is allowed during the move, but it must be removed in the cutover change.

## Prototype file disposition

| Current file | V1 disposition |
| --- | --- |
| `demo/dream-nested-router/native/RouterRSC.re` | Split. Move pure registry, matching, loader, metadata, error, response-plan, and protocol behavior into package native modules. Rewrite the small Dream request/streaming portion as `DreamRouter`. Delete definition-string traversal. |
| `demo/dream-nested-router/native/RouterRSC.rei` | Replace with package interfaces and generated application `Router.rei`. No prototype compatibility interface remains. |
| `demo/dream-nested-router/native/shared/Router.re` | Rewrite provider, fetch, and navigation behavior under the package client runtime and reducer. Do not preserve its state shape or raw-string API. |
| `demo/dream-nested-router/native/shared/Router.rei` | Replace with package runtime interfaces and generated application hooks. |
| `demo/dream-nested-router/native/shared/Route.re` | Delete. Committed match state and deterministic layout keys replace mutable page-consumer callbacks. |
| `demo/dream-nested-router/native/shared/Navigation.re` | Delete. Explicit response envelopes dispatch directly to the reducer instead of rendering a hidden effect component. |
| `demo/dream-nested-router/native/shared/PathParams.re` | Delete after typed generated inputs migrate every caller. |
| `demo/dream-nested-router/js/MountedLayouts.re` | Delete without replacement. |
| `demo/dream-nested-router/js/BackForwardCache.re` | Delete. Restoration state may cache locations, revisions, and loader data under an explicit policy, never React elements. |
| `demo/dream-nested-router/js/NavigationEntry.re` | Replace with the package history adapter. Remove synthetic `popstate` dispatch and untyped params/element state. |
| `demo/dream-nested-router/test_router_rsc.ml` | Move still-valid matcher, shared-prefix, and fingerprint vectors into package tests; rewrite them against typed definitions. |
| `demo/dream-nested-router/native/README.md` | Replace obsolete prototype API documentation with links to package documentation and executable examples. |

Nothing under `demo/dream-nested-router` is copied as an architectural compatibility layer. Reuse is limited to behavior vectors whose expectations remain valid.

## Concrete demo declaration

The migrated `demo/router/generated/RouterDefinition.re` should exercise the package features rather than merely reproduce the old strings:

```reason
Router.make(
  ~basePath="/demo/router",
  ~layout=RouterPages.AppLayout.make,
  ~loading=RouterPages.GlobalLoading.make,
  ~notFound=RouterPages.NotFound.make,
  ~error=RouterPages.AppError,
  ~search={
    searchText: Router.Search.optional(string),
  },
  [
    Router.route(
      Home,
      ~page=RouterPages.App.make,
      ~path="/",
    ),
    Router.route(
      NewNote,
      ~page=RouterPages.NewNote.make,
      ~path="/new",
      ~loading=RouterPages.NewNoteLoading.make,
    ),
    Router.group(
      ~path="/:id<NoteId.t>",
      ~layout=RouterPages.NoteLayout.make,
      ~loader=RouterPages.NoteLoader.load,
      ~loaderAs_=note,
      [
        Router.route(
          Note,
          ~page=RouterPages.Note.make,
          ~path="/",
          ~loading=RouterPages.NoteLoading.make,
        ),
        Router.route(
          EditNote,
          ~page=RouterPages.EditNote.make,
          ~path="/edit",
          ~loading=RouterPages.EditNoteLoading.make,
        ),
      ],
    ),
  ],
);
```

The positional route identifier is the stable generated module name. `~loaderAs_` supplies the loader result label (`note` in this branch).

For the demo, `NoteId.t` may initially be a transparent alias of `int` with `parse` and `print`; package compile fixtures must use abstract domain IDs to prove that generated signatures distinguish same-representation identifiers. Avoid migrating unrelated dummy-router and server-function APIs solely to make the demo ID abstract.

## Target page and attachment contracts

The native route components replace raw params and query maps with generated labels:

```reason
module App = {
  [@react.component]
  let make = (~searchText as _) => /* empty state */;
};

module AppLayout = {
  [@react.component]
  let make = (~children, ~searchText) => /* shell */;
};

module NewNote = {
  [@react.component]
  let make = (~searchText as _) => /* editor */;
};

module NoteLoader = {
  let load = (~id, ~searchText as _) => {
    let+ note = DB.fetchNoteOption(id);
    switch (note) {
    | Ok(Some(note)) => Router.Loader.Data(note)
    | Ok(None) => Router.Loader.NotFound
    | Error(error) => Router.Loader.Error(error)
    };
  };
};

module NewNoteLoading = {
  [@react.component]
  let make = (~searchText as _) => <NoteSkeleton isEditing=true />;
};

module EditNoteLoading = {
  [@react.component]
  let make = (~id as _, ~searchText as _, ~note as _) =>
    <NoteSkeleton isEditing=true />;
};

module Note = {
  [@react.component]
  let make = (~id, ~searchText as _, ~note) => /* viewer */;
};

module EditNote = {
  [@react.component]
  let make = (~id, ~searchText as _, ~note) => /* editor */;
};
```

The current DB API returns every missing-note case as `Error(string)`. Add a lower-level `DB.fetchNoteOption` returning `result(option(Note.t), string)` and preserve the existing `DB.fetchNote` wrapper for the other demos. The loader uses the option-returning API and never parses error strings. This avoids an unrelated migration of `demo/server/pages/NoteItem.re`.

Add `RouterPages.AppError` explicitly. Its `t`, `status`, and `make` members establish the shared loader error type and root boundary. Rewrite `NotFound.make` to accept the full normalized router error rather than the prototype's raw `~path` string.

The route-level `NoteLoading` runs after the group loader succeeds and therefore receives `~id`, `~searchText`, and `~note`. `NotFound` and error boundaries for a failed group loader receive decoded `~id` and root search, but not `~note`.

## Required generated client contracts

Freeze these signatures during the handwritten expansion. Exact names may change, but raw URL access cannot remain.

### Imperative navigation

```reason
let (navigate, navigation) = Router.useNavigation();

navigate(
  ~history=#replace,
  ~revalidate=true,
  Router.Note.destination(~id, ~searchText?, ()),
);
```

The destination owns route inputs. Navigation options own history action, revalidation, shallow behavior, and scroll policy. The return value must report committed, redirected, canceled, or failed rather than silently returning `unit`.

### Navigation state

```reason
let (_, navigation) = Router.useNavigation();
```

The hook exposes `Idle`, `Loading`, and `Failed` without leaking packed route internals. Mutation pending state and route navigation pending state remain distinct.

### Typed search

The root search schema generates a typed subscription and updater, conceptually:

```reason
let {searchText} = Router.useSearch();

Router.updateSearch(
  ~searchText=nextSearchText,
  ~options={history: #replace},
  (),
);
```

Generated hook records are acceptable here; the prohibition on generated records applies to page inputs, where they create declaration/component dependency cycles. Search updates commit synchronously without an RSC request when no content dependency requests revalidation.

### Active routes

```reason
let isActive = Router.Note.useIsActive(~id, ~includeDescendants=true, ());
```

Active matching compares route ID and canonical typed params, not string prefixes or raw param maps.

## Demo callsite migration

### `CreateNoteButton.re`

- Replace the button plus `Router.use()` string navigation with `Router.NewNote.Link`.
- Preserve root `searchText` when the product behavior requires it.
- Remove the local navigation transition; use generated link pending/disabled behavior only if the interaction still needs it.
- Remove invalid `menuitem` semantics as part of the same component rewrite.

### `EditButton.re`

- Replace ID string concatenation with `Router.EditNote.Link`.
- Keep mutation and navigation state separate.
- Remove `menuitem` semantics.

### `SidebarNoteContent.re`

- Replace `PathParams.find`, `window.location`, query serialization, and string navigation.
- Use `Router.Note.useIsActive(~id, ~includeDescendants=true, ())`.
- Render note selection as a generated link.
- Render expansion as a separate native button with `aria-expanded` and `aria-controls`; do not nest disclosure behavior in the route link.

### `DeleteNoteButton.re`

- Remove direct DOM location and query parsing.
- After deletion, navigate to `Router.Home.destination(~searchText?, ())` with replace and revalidation options.
- Use `Router.useNavigation` for route pending state and retain separate mutation pending state.

### `NoteEditor.re`

- Replace post-save URL construction with `Router.Note.destination(~id=result.id, ~searchText?, ())`.
- Use imperative navigation options for revalidation.
- Keep the server function contract unchanged in the first router migration.

### `SearchField.re`

- Replace raw URL and `URL.SearchParams` access with generated typed search hooks.
- Replace the broken `~shallow=true` string navigation with `Router.updateSearch`.
- Use a deferred or transitioned local input only for responsiveness; committed search state remains router-owned.

### `NoteList.re`

- Replace raw router URL parsing with `Router.useSearch`.
- Keep note fetching in the RSC component; the route loader owns only the selected note needed for status.

### `NoteItem.re`

- Accept the loader-provided selected note on note and edit routes instead of fetching it again.
- Keep new-note editor initialization local to the new route.
- Pass typed IDs to generated route consumers.

### `demo/universal/native/shared/Routes.re`

- Stop treating the nested router's internal destinations as global string constants.
- The demo menu entry may use the generated root href only after the application-library dependency remains acyclic. Otherwise treat `/demo/router` as an external mount link owned by the server demo menu, not as internal router navigation.

## Server registration migration

Replace this ownership:

```text
server.re
  -> RouterRSC.routeDefinitionsHandlers(basePath, routeDefinitions)
  -> one Dream route per generated string pattern
```

with:

```text
server.re
  -> DreamRouterAdapter.routes(
       registry=Router.registry,
       document=RouterPages.Document.make,
       bootstrapModules=[...]
     )
  -> one base-path catch-all owned by the router adapter
  -> package matcher selects the branch
```

The adapter must register canonical GET handling and an application-level catch-all under `/demo/router`. Dream must no longer be the authoritative dynamic matcher. Static/dynamic precedence, decoding, and ambiguity belong to the package matcher.

Do not register the server-function POST dispatcher once per route. Keep action dispatch at its dedicated endpoint or at one explicit base endpoint until typed actions are designed.

The adapter must:

- Parse `Accept` rather than compare one exact header string
- Enforce a path-segment boundary for `basePath`
- Run matching, decoding, and loaders inside the existing DreamRSC request context
- Set status and headers before streaming
- Negotiate document versus RSC on the same canonical URL
- Preserve `Vary: Accept`
- Return `private, no-store` for patches
- Degrade malformed or missing navigation headers to a correct full response

## Client state migration

Replace the current state split across `Router.re`, `Navigation.re`, `MountedLayouts`, `NavigationEntry`, and `BackForwardCache` with one reducer-owned model:

```reason
type committed = {
  location: RouterLocation.t,
  matches: array(RouterMatch.committed),
  revision: string,
  payload: RouterPayload.committed,
};

type navigation =
  | Idle
  | Loading({
      from: committed,
      to_: destination,
      action: historyAction,
      requestId: int,
    })
  | Failed({
      from: committed,
      to_: destination,
      action: historyAction,
      requestId: int,
      error: RouterClientError.t,
    });
```

The concrete payload remains abstract and one-shot. It is not a durable `React.element` cache.

Every transition defines URL timing, visible content, history mutation, request cancellation, focus, scroll, and completion result. A response commits only when its request ID is active and its base revision matches the committed revision.

History state stores a small location key and revision, not params or React elements. A pop with no restorable data issues a replace navigation and never pushes a new entry.

## Implementation phases

Each phase must end green and leave one authoritative route owner.

### Phase 0: prove the build architecture

Create a minimal fixture, not production modules, that proves:

- One Reason `RouterDefinition.re` declaration can generate `Router.re`, `Router.rei`, and `RouterRegistry.re`.
- A Dune rule can parse `RouterDefinition.re` through `refmt` and copy one canonical handle implementation/interface into both compilation roots.
- A page component can import `Router.Note` while `RouterRegistry` references that page.
- The same generated `Router.re`/`.rei` pair compiles natively and with Melange.
- Only native compiles the generated server-only registry attachments.
- The route compiler, JSX PPXs, browser PPX, RSC PPXs, and Melange PPX compose in the required Dune graph.
- The fixture compiles on OCaml 4.14.1 and 5.4.0.

Exit criterion: a native and Melange compile-pass fixture demonstrates the real dependency shape. This spike rejected a single implementation unit and selected separate generated handle and registry units.

### Phase 1: scaffold `packages/router`

- Add package directories and Dune stanzas.
- Choose final internal and public names.
- Add shared type skeletons and platform libraries.
- Add the declaration/parser library and the multi-mode router generator executable.
- Add the direct ReactServerDOMEsbuild dependency required by client navigation decoding.
- Add package-level native, Melange, Alcotest, and cram test aliases.
- Do not add Dream as a package dependency.

Exit criterion: empty runtime and route-compiler surfaces build in release profile and package tests run under `make test`.

### Phase 2: hand-write the demo expansion

- Write the expected `Router.rei` for Home, NewNote, Note, and EditNote.
- Hand-write equivalent native route modules and a packed registry fixture.
- Hand-write equivalent Melange route modules.
- Freeze destination, link, navigation options, search hooks, active-match hooks, page props, loader props, and boundary props with the compiler as referee.
- Add compile-fail fixtures before route-compiler implementation expands.

Exit criterion: all current demo callsite shapes can be expressed without raw paths, raw params, raw search maps, or imports from packed runtime internals.

### Phase 3: implement destinations, codecs, and registry validation

- Implement opaque destinations and base-path-aware href printing.
- Implement segment percent encoding and canonical printing.
- Implement built-in and `<Module.t>` codecs.
- Implement search schema composition and canonicalization.
- Implement registry validation and deterministic route IDs/fingerprints.
- Add native/Melange parity tests.

Exit criterion: handwritten route modules use only package runtime functions and all codec/diagnostic fixtures pass.

### Phase 4: implement route generation

- Parse `Router.make`, `route`, `group`, path annotations, search records, loaders, and attachments into one IR.
- Parse Reason through `refmt`, generate one canonical `Router.rei` from that IR, and copy it into both target roots.
- Generate universal public modules in `Router.re`.
- Generate packed native adapters in `RouterRegistry.re` without adding page references to `Router.re`.
- Preserve source locations in generated calls and diagnostics.
- Snapshot expansions and diagnostics.

Exit criterion: delete handwritten expansion bodies while preserving all compile-pass, compile-fail, and native/Melange API parity tests.

### Phase 5: implement native full-request execution

- Implement authoritative matching independent of Dream.
- Decode path and search values.
- Run loaders parent-first before headers.
- Expose and use `DreamRSC.withRequestContext` so matching, loaders, metadata, headers, and rendering share the existing request-local scope.
- Normalize 400, 404, redirect, application, and internal outcomes.
- Resolve metadata and headers.
- Render full document and full RSC responses only.
- Add direct-load and RSC request conformance tests.

Exit criterion: the package integration fixture serves all four demo routes correctly without partial patches.

### Phase 6: implement the client reducer with full navigation

- Implement opaque destination fetches, request IDs, AbortController, and response validation.
- Implement atomic full commits.
- Implement push, replace, pop fallback, shallow root-search updates, and hash-only updates.
- Implement generated link, navigation, search, active-match, and navigation-state hooks.
- Add the router Flight provider and make every navigation decode use the hydration entrypoint's `callServer` callback.
- Preserve full URL during hydration.
- Update `demo/client/RouterDemo.re` in the browser fixture rather than testing a callback-free decoder.
- Add deterministic reducer and race tests.

Exit criterion: a browser fixture navigates all four routes, search works, queries survive hydration, and latest navigation wins without `MountedLayouts` or element caching.

### Phase 7: restructure and migrate the demo

- Create `demo/router` native and JS application libraries plus the separate Dream adapter library.
- Move route-aware shared components out of `demo_shared_*`.
- Move the current `NestedRouter.re` route components into `RouterPages.re` and replace raw props with generated labels.
- Add the single `RouterDefinition.re` manifest and generated handle/registry rules.
- Add the universal `NoteId` codec, `DB.fetchNoteOption`, `NoteLoader`, root `AppError` policy, full-error `NotFound`, and depth-specific new/edit loading components.
- Replace every raw navigation/search/active callsite listed above.
- Update `demo/server/dune`, `demo/universal/*/dune`, and `demo/client/dune` dependencies.
- Replace server registration with the thin Dream adapter.
- Keep the old router unregistered; never register both implementations at `/demo/router`.

Exit criterion: the main demo uses only package router libraries and generated route APIs. Direct load, full RSC navigation, mutations, search, and back/forward pass.

### Phase 8: implement partial RSC patches and restoration

- Implement shared-prefix comparison by route identity and canonical decoded path values.
- Add base and target revisions to response envelopes.
- Reconcile full and patch payloads from committed match state.
- Add focus and scroll restoration.
- Add stripped-header, stale-revision, deployment-skew, and payload-size fixtures.

Exit criterion: patches are correct under races and deployment skew, and a leaf patch is measurably smaller than a full response.

### Phase 9: remove the prototype

- Move still-relevant pure test vectors into package tests.
- Delete `Route.re`, `Navigation.re`, `MountedLayouts.re`, `BackForwardCache.re`, `PathParams.re`, and obsolete `RouterRSC` traversal.
- Delete old `nested_router_native` and `nested_router_js` Dune stanzas.
- Remove dev-only prototype tests and stale README API examples.
- Confirm no application code references `RouterRSC`, `PathParams`, raw internal route URLs, or element caches.

Exit criterion: `demo/dream-nested-router` contains no runtime implementation and can be removed entirely.

## Dune and dependency edits

The implementation plan must update:

- `demo/server/dune`: replace `nested_router_native` with the new Dream adapter and native application/router libraries.
- `demo/universal/native/dune`: remove `nested_router_native` after route-aware components move; retain generic shared dependencies only.
- `demo/universal/js/dune`: remove `nested_router_js` after route-aware components move.
- `demo/client/dune`: add the router demo JS application library and router Flight runtime because hydration and later navigation share `callServer`.
- `demo/dream-router/dune`: list Dream and RSC dependencies directly because transitive dependencies are disabled.
- `demo/dream-nested-router/*/dune`: delete after package and app migration.
- `demo/dream-rsc/DreamRSC.re` and `.rei`: expose a callback-style request-context scope used around pre-render router work.
- `demo/client/RouterDemo.re`: provide `callServer` to initial hydration and every later Flight navigation decode.
- `demo/universal/native/DB.re`: add the option-returning note lookup while preserving the existing wrapper.
- `demo/server/server.re`: replace per-pattern `RouterRSC` registration with the single generated registry adapter.
- `dune-project`: no change for the first Dream-neutral package cut unless final package libraries introduce an external dependency not already declared.
- `server-reason-react.opam`: regenerate through Dune only if `dune-project` dependencies change; do not edit it independently.

Package tests must not be guarded by `DUNE_PROFILE=dev`. Current router tests are dev-only and therefore skipped by release CI.

## Test plan

### Package unit tests

- Path parser and printer round trips
- Custom codec success and failure
- Percent encoding, malformed escapes, dot segments, and encoded slash policy
- Search required, optional, defaulted, repeated, aliases, collisions, ordering, and unknown preservation
- Registry duplicates, ambiguity, generated names, and fingerprints
- Parent-child loader sequencing and cancellation
- Error normalization and status mapping
- Metadata and header composition
- Shared-prefix and layout-instance identity
- Pure reducer transition table

### Route compiler and interface tests

- Generated handle and registry snapshots
- Generated `Router.rei` snapshots
- Public signature parity between native and Melange
- Wrong page/layout/loading/boundary props
- Missing, extra, and wrongly typed path/search destination labels
- Wrong loader data or application error type
- Duplicate route names and search keys
- Invalid path annotation and missing codec members
- Source locations in diagnostics
- Generated-source composition with JSX, browser, RSC, Melange, and Lwt PPXs

### Native HTTP integration tests

- Home, new, note, edit, and unknown direct loads
- Invalid ID and invalid search return 400
- Missing note returns loader 404 before streaming
- Operational loader error uses `AppError.status`
- Internal exception exposes only diagnostic ID
- Redirect loops and same-origin/base-path enforcement
- Document and RSC content negotiation with realistic `Accept` lists
- Missing, malformed, and oversized navigation headers degrade to full responses
- Fingerprint mismatch returns reload-required
- Patch responses are private and non-cacheable

### Reducer and browser tests

- Push, replace, pop, shallow search, and hash-only transitions
- Latest navigation wins and superseded fetch cancellation
- Stale patch revision rejection
- Hydration preserves pathname, search, and hash
- Search updates filter notes and update the URL
- Modified-click, target, download, external, and no-JavaScript links
- Active note and edit descendant matching
- Mutation followed by typed replace/revalidation
- Focus and scroll restoration
- Mobile reflow and keyboard/accessibility checks retained from the audit

## Cutover rules

- Do not mount old and new routers under `/demo/router` simultaneously.
- Do not make Dream route order part of new matching behavior.
- Do not keep compatibility wrappers for raw string navigation.
- Do not cache React elements during an intermediate phase.
- Do not promote snapshots to hide unexplained output differences.
- Do not delete prototype code until full navigation parity is green; partial patch optimization may land after the demo is already on the new committed-state runtime.
- Each phase must pass `make format-check`, `make build`, and `make test` in its final tree. Browser-specific phases also run their dedicated browser fixtures.

## First implementation slice

The cheapest high-information slice is not the matcher. It is the build and type-generation spike:

1. Add the minimal route-compiler parser and runtime skeleton.
2. Create a two-route fixture with one custom ID, one search default, one page, and one client component that imports the generated route module.
3. Generate its `.rei`.
4. Compile the same manifest natively and with Melange.
5. Add one compile-fail href call and one mismatched page prop.

Only after this proves the central module cycle and generated API should runtime implementation begin.

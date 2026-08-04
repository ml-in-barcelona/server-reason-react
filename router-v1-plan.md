# Typed router v1 plan

Status: Proposed

Date: 2026-08-03

Related documents:

- [`router-prototype-audit.md`](router-prototype-audit.md) records evidence about the current prototype.
- [`router-adr-spec.md`](router-adr-spec.md) remains the source for compatible transport, history, reconciliation, and conformance decisions.
- [`router-v1-repository-plan.md`](router-v1-repository-plan.md) maps this design onto the package layout and nested-router demo.
- [`router-v2-brainstorm.md`](router-v2-brainstorm.md) records possible follow-up work without adding it to v1.

This plan supersedes the route declaration, format-string path, generated API, loader, metadata, and error-interface decisions in `router-adr-spec.md`. In particular, v1 uses a Dune route compiler built on Ppxlib that generates labeled route APIs; it does not use positional format-string handles.

## Outcome

V1 provides one visible route tree from which Dune preprocessing generates:

- Typed path and search decoding before application code runs
- Direct labeled props for pages, layouts, metadata, headers, loaders, and boundaries
- Route-specific `destination`, `href`, and `link` functions
- A packed server registry shared by document and RSC navigation requests
- Deterministic route identities and registry fingerprints
- Compile-time rejection of missing, extra, or wrongly typed destination arguments

The router also replaces the prototype's mutable mounted-layout registry and element cache with committed match state, request identity, cancellation, and atomic navigation commits.

## Caller API

The application owns a `RouterDefinition.re` manifest. Its top-level `Router.make(...)` expression is route-compiler input and is never type-checked as application code. Dune generates the universal `Router.re`/`Router.rei` namespace and the native-only `RouterRegistry.re` attachment unit from that one manifest.

```reason
Router.make(
  ~basePath="/demo/router",
  ~layout=AppLayout.make,
  ~loading=GlobalLoading.make,
  ~notFound=NotFound.make,
  ~error=AppError,
  [
    Router.route(
      App.make,
      ~path="/",
    ),
    Router.route(
      NewNote.make,
      ~path="/new",
      ~loading=NewNoteLoading.make,
    ),
    Router.group(
      ~path="/:id<NoteId.t>",
      ~layout=NoteLayout.make,
      ~loader=Note.load,
      ~search={
        filter: Router.Search.optional(Filter.t),
        page: Router.Search.default(int, 1),
      },
      [
        Router.route(
          Note.make,
          ~path="/",
          ~loading=NoteLoading.make,
          ~metadata=Note.metadata,
          ~headers=Note.headers,
        ),
        Router.route(
          EditNote.make,
          ~path="/edit",
          ~loading=EditNoteLoading.make,
        ),
      ],
    ),
  ],
);
```

### Declaration rules

- `Router.make` is the implicit root group. It owns `basePath`, root attachments, and the root child list.
- `Router.route(page, ...)` declares a navigable leaf and never accepts children.
- `Router.group(...)` declares a page-less structural node and accepts children.
- A group may omit `path`, making it pathless.
- Every declared path is relative to its parent. `"/"` is the index destination at the current depth.
- Static, multi-segment, and typed dynamic paths are valid in v1. Optional segments and splats are deferred.
- A route's generated module name defaults to the page module name. `~as_` provides an explicit override for reused pages or collisions. The generator does not strip naming suffixes.
- Groups generate internal registry nodes, not public destination modules.
- Root and nested attachments use optional labeled arguments. The initial set is `layout`, `loading`, `notFound`, `error`, `loader`, `search`, `metadata`, and `headers`.

## Generated public API

For the example above, the route compiler generates an opaque destination constructor and matching helpers:

```reason
module Note: {
  let destination:
    (
      ~id: NoteId.t,
      ~filter: Filter.t=?,
      ~page: int=?,
      unit
    ) =>
    RouterRuntime.destination;

  let href:
    (
      ~id: NoteId.t,
      ~filter: Filter.t=?,
      ~page: int=?,
      unit
    ) =>
    string;

  let link:
    (
      ~id: NoteId.t,
      ~filter: Filter.t=?,
      ~page: int=?,
      ~children: React.element,
      ~options: RouterRuntime.Link.options=?,
      unit
    ) =>
    React.element;
};
```

Expected usage:

```reason
let target = Router.Note.destination(~id, ~filter?, ());
let href = Router.Note.href(~id, ~filter?, ());

Router.Note.link(
  ~id,
  ~filter?,
  ~children=React.string("Open note"),
  ~options={className: "note-link", history: #push},
  (),
);

Router.Loader.Redirect(Router.Login.destination(~returnTo=href, ()));
```

`destination` is opaque. Application code cannot construct one from an arbitrary URL string. `href` and `link` delegate to the same generated constructor. Route arguments and link configuration occupy separate namespaces; DOM and navigation settings live in the `options` record.

## Generation boundary

The source uses no extension node and no marker attribute. A top-level `Router.make(...)` structure expression is the manifest marker. A Dune rule parses Reason through `refmt`, feeds the AST to the route compiler, and writes generated Reason implementation and interface units.

Dune generates `Router.re`, `Router.rei`, and native-only `RouterRegistry.re` from the same declaration. Separating universal handles from native page attachments makes the dependency graph acyclic when page and layout components import generated routes. The source and interface generators share one parser and declaration IR; users still author exactly one route tree.

The route compiler must generate only route-specific static glue:

- Public route modules and labeled function signatures
- The matching generated `Router.rei` public signature
- Path and search codec assembly
- Typed calls into pages and attachments
- Loader result adapters
- Packed route and match values
- Registry assembly, route identities, source locations, and fingerprint input
- Native-only decoding and rendering glue
- Universal destination printing needed by native and Melange

Ordinary library code owns matching, canonicalization, loader execution, metadata composition, rendering traversal, RSC transport, history, cancellation, and navigation state. The route compiler must not generate those algorithms.

The generated expansion must preserve useful source locations so compile errors point to the route declaration or attached function.

## Path codecs

Typed parameters use named path annotations:

```reason
~path="/workspaces/:workspaceId<WorkspaceId.t>/notes/:noteId<NoteId.t>"
```

Built-in primitive types use router codecs. For a custom `<SomeModule.t>` parameter, the route compiler resolves `SomeModule.parse` and `SomeModule.print` by convention and emits constraints equivalent to:

```reason
module SomeModule: {
  type t;
  let parse: string => result(t, string);
  let print: t => string;
};
```

Codecs operate on decoded path segments. The router owns percent encoding. `parse(print(value))` must return the original value, and printing a successfully parsed value must produce its canonical representation.

A path codec failure becomes `Router.Error.InvalidPathParameter` with HTTP 400. It is not a 404 and does not fall through to an equivalent dynamic sibling. Duplicate and ambiguous sibling patterns are rejected when constructing the registry. Malformed URL escapes are location errors handled before matching.

## Search schemas

Search parameters use a record-shaped schema:

```reason
~search={
  filter: Router.Search.optional(Filter.t),
  page: Router.Search.default(int, 1),
  tags: Router.Search.many(Tag.t),
}
```

The record label is the generated prop name and URL key by default. A key override is allowed for external URL compatibility.

Search schemas compose from parent to child:

- Descendants receive ancestor and local search values as direct labeled props.
- Required search values are required destination arguments.
- Optional values are optional destination arguments and decode to `option`.
- Defaulted values are optional destination arguments and decode to their concrete type.
- Repeated values decode to a list and are omitted when empty.
- Values equal to declared defaults are omitted from canonical URLs.
- Duplicate labels or URL keys in one matched branch are compile-time diagnostics.
- Siblings may independently reuse labels and keys.
- Unknown inbound keys remain opaque. They are preserved only when navigation explicitly carries them forward and are never passed as generated application props.

A declared search codec failure becomes `Router.Error.InvalidSearchParameter` with HTTP 400.

## Generated application inputs

Path parameters, search values, and successful loader results are passed as direct labels. No string map or generated params record crosses into application code.

Inputs are scoped to declaration depth:

- A page receives all path, search, and successful loader values in its matched branch.
- A layout receives ancestor values plus values owned by its node.
- Metadata and headers receive the values available at their node after its loader succeeds.
- A render-phase loading component receives the successful loader values available at its node.
- An error or not-found boundary receives decoded inputs plus successful loader values from ancestors of the failed node.
- Descendant-owned values are never passed to ancestor attachments.

Example generated calls:

```reason
NoteLayout.make(
  ~children,
  ~id,
  ~filter,
  ~page,
  ~note,
);

Note.make(
  ~id,
  ~filter,
  ~page,
  ~note,
);
```

The compiler checks attached functions by checking these generated calls. A component with missing, extra, or wrongly typed props fails compilation.

## Loaders

Loaders are optional. Ordinary rendering data may still be fetched from RSC pages and layouts. A loader is required when fetched data controls status, redirect, headers, or metadata before streaming.

V1 does not promise that a not-found discovered after RSC rendering starts can change a document's committed status. Resource absence that must produce HTTP 404 belongs in a loader.

Each route or group may declare one loader function:

```reason
~loader=Note.load
```

The loader returns:

```reason
module Loader = {
  type result('data, 'error) =
    | Data('data)
    | Error('error)
    | NotFound
    | Redirect(RouterRuntime.destination);
};
```

Every loader has the async-only shape:

```reason
(/* prefix inputs and inherited loader values */) =>
Lwt.t(Router.Loader.result('data, AppError.t));
```

Immediate loaders use `Lwt.return`. Loaders access request-local data through the existing `DreamRSC.RequestContext`; the router does not introduce a second `~context` argument.

The loader result prop name defaults to the loader module name in lower camel case. A naming override resolves collisions or non-standard function references. A loader that needs to return several related values returns one application record.

Matched loaders execute parent-first. Child loaders receive successful ancestor loader results. Every matched loader finishes before response headers or RSC rendering begin. This is what permits `NotFound`, `Redirect`, and `Error` to select status and boundaries reliably. Loader latency therefore delays initial streaming; non-critical data stays in RSC rendering.

## Errors and boundaries

One application error type is shared by all loaders in a generated router.

```reason
module Error = {
  type notFoundReason =
    | NoMatchingRoute
    | LoaderNotFound;

  type t('applicationError) =
    | NotFound({reason: notFoundReason})
    | Application('applicationError)
    | InvalidPathParameter({name: string})
    | InvalidSearchParameter({name: string})
    | Internal({diagnosticId: string});
};
```

`Router.Loader.Error(error)` normalizes to `Router.Error.Application(error)`. Unexpected loader, metadata, header, or render exceptions normalize to `Internal` with an opaque diagnostic ID; arbitrary exception text and stack traces are never serialized to clients.

The root application-error policy is an optional module:

```reason
module type ERROR = {
  type t;
  let status: t => Router.Status.t;

  [@react.component]
  let make:
    (~error: Router.Error.t(t), unit) =>
    React.element;
};
```

It is attached once:

```reason
Router.make(~error=AppError, /* ... */);
```

The generated code constrains `AppError` against `ERROR` and unifies `AppError.t` with every loader's error type. If omitted, application errors use the built-in generic boundary and HTTP 500.

Nested `~error` and `~notFound` attachments remain ordinary components because their generated prefix props differ. Both receive the complete `Router.Error.t(AppError.t)`. For a `NotFound` value, the nearest `~notFound` boundary wins; the nearest `~error` is the fallback. Other errors select the nearest `~error` boundary.

Router-owned status policy is fixed:

- No matching route and loader not-found: 404
- Invalid path or search parameter: 400
- Redirect: the redirect's valid redirect status
- Internal error: 500
- Application error: `AppError.status`

## Loading

`~loading` is a render-phase React Suspense fallback. It is not loader-pending UI.

All loaders have completed before rendering starts, so a loading component receives successful loader values available at its node. Navigation-pending UI is a separate concern and is deferred from this declaration API.

## Metadata and headers

Metadata callbacks are async-only:

```reason
(/* available typed inputs */) =>
Lwt.t(Router.Metadata.t);
```

Immediate metadata uses `Lwt.return`. Metadata is structured data, not arbitrary `<head>` elements. Parent metadata is composed before child metadata; child values override singleton fields, while keyed repeatable values merge and deduplicate deterministically.

HTTP headers use a separate async `~headers` callback returning `Router.Headers.t`. Header composition has dedicated validation and merge rules. Successful route responses default to 200; non-200 statuses come from typed router outcomes and the application error policy.

## Server processing

For both document and RSC navigation requests:

1. Parse and canonicalize the target location within `basePath`.
2. Match the generated registry and retain the longest successfully matched prefix.
3. Decode path and composed search schemas.
4. Run matched loaders parent-first inside the existing request-local Lwt scope.
5. Normalize loader outcomes and select status, redirects, and boundaries.
6. Resolve async metadata and headers from successful inputs.
7. Start document or RSC rendering.
8. Encode the response using the content-negotiated protocol in `router-adr-spec.md`.

Client-supplied navigation state may reduce the rendered payload but never changes matching, decoding, loader execution, status, authorization, or canonicalization.

## Client navigation

V1 retains the navigation invariants in `router-adr-spec.md`:

- Direct requests and client navigations target the same canonical URL.
- The `Accept` header selects a document or RSC response.
- The client sends its committed location and registry fingerprint as facts, not a proposed patch split.
- The server computes the shared route-and-param prefix.
- URL, match, decoded inputs, loader values, metadata, and rendered content commit atomically.
- Every navigation has a request identity.
- Superseded requests are aborted and late responses are ignored.
- A patch applies only to the committed base revision for which it was produced.
- Fingerprint mismatch triggers a hard reload.
- Push, replace, and pop remain distinct from content, shallow-search, and hash-only navigation kinds.
- Standard modified-click, external-link, download, focus, scroll, and no-JavaScript behavior is preserved.

V1 may expose generic imperative navigation over generated destinations. Route-specific `navigate` helpers are unnecessary because `destination` already carries the typed target.

## Implementation plan

### 1. Freeze the generated contract

- Hand-write the expected expansion for the demo's four routes.
- Compile native and Melange callers against the expected public route modules.
- Add compile-pass and compile-fail fixtures for labeled path and search arguments.
- Verify that page, layout, loader, metadata, headers, loading, error, and not-found attachments receive the intended props.
- Treat repeated expansion friction as evidence that the declaration design is wrong before implementing the route compiler.

### 2. Build URL codecs and the packed registry

- Implement segment parsing, percent encoding, custom codec invocation, and canonical printing.
- Implement search ownership, composition, defaults, repetition, unknown-key preservation, and canonical ordering.
- Define packed route and match representations that preserve typed adapters behind existential boundaries.
- Validate duplicates, ambiguous patterns, unsupported path syntax, search collisions, missing destinations, and generated-name collisions.
- Generate deterministic route IDs, source locations, and registry fingerprint inputs.

### 3. Implement the Dune route compiler

- Detect exactly one top-level `Router.make(...)` declaration in the router compilation unit.
- Parse `route`, `group`, path annotations, search schemas, loaders, and attachments.
- Emit universal public destination modules and platform-specific registry glue.
- Preserve source locations and produce focused declaration diagnostics.
- Keep native and Melange generated-handle fixtures together so public signatures cannot drift.

### 4. Implement server matching and pre-render execution

- Parse locations and enforce `basePath`.
- Match one branch and retain the nearest successfully decoded prefix.
- Run loaders parent-first with Lwt cancellation.
- Normalize outcomes into statuses, redirects, and full router errors.
- Compose metadata and headers before rendering.
- Render nearest boundaries with only inputs available at the failure point.
- Add a catch-all under `basePath` so unknown URLs render application not-found UI with 404.

### 5. Replace prototype render-state mutation

- Remove process-global mounted-layout callbacks and render-time mutation.
- Represent the committed branch as route IDs, canonical path prefixes, decoded inputs, and loader values.
- Give each preserved layout a deterministic instance key.
- Reconcile patches from committed match state rather than cached React elements.

### 6. Implement navigation and transport

- Implement the versioned content-negotiated document/RSC response protocol.
- Implement full, patch, redirect, failed, and reload-required outcomes.
- Add request IDs, abort superseded work, and reject stale revisions.
- Implement push, replace, pop, shallow-search, and hash-only reducer transitions.
- Preserve search and hash through hydration and history restoration.
- Validate status, content type, registry fingerprint, canonical URL, and response envelope before commit.

### 7. Implement generated links and browser behavior

- Implement opaque destinations and canonical `href` generation.
- Implement generated route-specific `link` wrappers over one generic link runtime.
- Preserve modified clicks, targets, downloads, external URLs, and no-JavaScript navigation.
- Add focus and scroll restoration after atomic commits.
- Keep link options separate from route labels.

### 8. Migrate and harden the demo

- Replace `PathParams.find`, raw search access, `int_of_string`, and URL concatenation.
- Move note existence checks needed for 404 into loaders; leave ordinary rendering fetches in RSC components.
- Exercise root and nested metadata, headers, loading, not-found, and error boundaries.
- Show the active branch, decoded inputs, loader outcomes, and response kind in the demo during development.
- Retain the separate UI accessibility and responsive fixes identified by the prototype audit.

## Verification

V1 requires:

- Route compiler output snapshots for native and Melange
- Compile-fail fixtures for missing, extra, transposed, and wrongly typed destination arguments
- Codec round-trip and canonicalization tests for primitives and custom modules
- Search composition, default omission, repetition, collision, and unknown-key tests
- Registry diagnostics for duplicate names, paths, and ambiguous patterns
- Loader sequencing, inheritance, cancellation, and every outcome constructor
- Boundary-selection tests at root, group, and leaf failure points
- Correct 400, 404, application, redirect, and 500 statuses before streaming
- Metadata and header composition tests
- Paired document and RSC-navigation tests for every route outcome
- Latest-navigation-wins and stale-revision model tests
- Browser tests for generated links, modified clicks, push, replace, pop, hydration, query/hash preservation, focus, and scroll
- Deployment-skew tests requiring reload on registry mismatch
- A measured patch response smaller than the corresponding full response

## V1 definition of done

V1 is complete only when:

- The demo route tree is declared once through the agreed `Router.make`, `route`, and `group` API.
- Application components receive no raw path or search maps.
- Generated route APIs use labeled inherited parameters and custom domain types.
- Every application link, redirect, and imperative navigation uses an opaque generated destination.
- All matched loaders settle before status, metadata, headers, or rendering.
- Unknown routes, invalid inputs, loader outcomes, and internal failures select typed boundaries and correct statuses.
- Direct load, client navigation, and history restoration produce the same canonical match.
- Nested layouts preserve state without process-global callbacks or cached React trees.
- Superseded or deployment-stale navigation cannot commit.
- Native, Melange, server, reducer, and browser conformance suites pass deterministically.

## Remaining design work before implementation

- Choose the package and internal runtime module names; the application compilation unit remains `Router`.
- Settle the precise path and search grammar accepted by the route compiler.
- Settle explicit override syntax for route names, loader result labels, and external search keys.
- Define `RouterRuntime.Link.options` without colliding with route labels.
- Define generated typed hooks for current search, active matches, imperative navigation, and navigation state; the demo cannot migrate without them.
- Define header merge rules and forbidden hop-by-hop headers.
- Define the packed route/match representation and layout instance key.
- Complete the history reducer table and response-envelope types retained from `router-adr-spec.md`.
- Decide eager versus deferred browser URL updates.

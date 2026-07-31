# Nested router architecture decision record and draft specification

Status: Proposed

Date: 2026-07-30

Companion document: [`router-prototype-audit.md`](router-prototype-audit.md)

## Purpose

This document describes the proposed replacement architecture and the behavior a credible v1 must guarantee. The prototype audit owns evidence about the current implementation; this document owns future design decisions and implementation constraints.

The router remains enabled only in the Dune `dev` profile. Compatibility with the prototype API is not a requirement.

## Context

The prototype proves that native React server rendering and partial RSC navigation can preserve nested layouts while replacing a descendant branch. Its current implementation also couples matching, rendering, transport, history mutation, and component callbacks. Stringly typed routes and several independent owners of URL state make that model unsafe to extend.

The replacement must preserve the useful part of the prototype: one nested route definition shared by direct server rendering and client RSC navigation.

## Decision drivers

1. Path and search values are typed before application code receives them.
2. Direct requests and client navigation use the same matcher and route registry.
3. URL, match, params, loader data, and rendered content commit atomically.
4. Nested layouts preserve state without process-global callbacks or render-time mutation.
5. The server independently validates every target route and authorization decision.
6. Standard browser link, history, focus, and scroll behavior remains available.
7. The design compiles for both native OCaml and Melange where its modules are shared.

## Scope

The v1 design covers typed route declarations and destinations, path and search codecs, nested matching, SSR, partial RSC navigation, cancellation, history, route errors, redirects, not-found boundaries, links, focus, scroll, and deterministic tests.

Loaders, actions, inherited context, and data caching need core type contracts before implementation begins, even if their complete behavior lands after the first navigation slice.

File-based routing, route masks, custom search serialization, and development tools are deferred until the code-based API and URL semantics are stable.

## Design rules

1. A route definition owns the types of its path params, search params, loader data, and context contribution.
2. A route handle builds destinations. Application code never concatenates route strings.
3. The same codec parses inbound requests and prints outbound URLs.
4. A successful match contains parsed values. Page components never call `int_of_string`.
5. Search parsing returns a typed result with explicit defaults and errors.
6. Parent and child route types compose. Children can access inherited context and parent params without string lookup.
7. Server and client consume generated artifacts from the same declaration and use stable route IDs.
8. Matching returns a branch of route IDs and typed values, not mutable render callbacks.
9. Client-supplied navigation state (`SRR-Navigation-From`) affects how much UI a response carries — never authorization, matching, status, or canonicalization.
10. Related location and render state changes commit through one navigation state machine.

## Route declaration and generated API

Use one route declaration to generate typed handles and a packed runtime registry. The implementation mechanism, PPX or standalone generator, remains an open decision. It must not infer route types from arbitrary strings or component implementations scattered across the application.

One possible declaration style is:

```reason
module Routes = [%routes
  {
    route home("/"),
    route newNote("/new"),
    route note("/:id", ~params={id: int}),
    route editNote("/:id/edit", ~params={id: int}),
  }
];
```

Expected generated usage:

```reason
Routes.Note.href(~id=42, ());
Routes.EditNote.navigate(router, ~id=42, ());

module NotePage: Router.Page with type params = Routes.Note.params = {
  [@react.component]
  let make = (~params, ~search) => {
    let id: int = params.id;
    /* ... */
  };
};
```

An ADT could also be generated for exhaustive destination handling:

```reason
type destination =
  | Home
  | NewNote
  | Note({id: int})
  | EditNote({id: int});
```

Before implementation, the declaration must show a complete nested tree with layouts, pages, index routes, pathless routes, loaders, boundaries, and inherited params. The generated API must separate universal typed handles from server-only render and loader modules.

## Core types to settle before implementation

```reason
module type Codec = {
  type t;
  let parse: string => result(t, Router.ParseError.t);
  let print: t => string;
};

type routeId;
type packedRoute;
type packedMatch;

type location = {
  pathname: string,
  search: string,
  hash: string,
  key: string,
};

type historyAction =
  | Push
  | Replace
  | Pop;

type navigationKind =
  | Content
  | Shallow
  | HashOnly;

type navigationState =
  | Idle(packedMatch)
  | Loading({
      from: packedMatch,
      to_: location,
      action: historyAction,
      requestId: int,
    })
  | Failed({
      from: packedMatch,
      to_: location,
      action: historyAction,
      requestId: int,
      error: Router.Error.t,
    });
```

`navigationKind` is orthogonal to `historyAction`: a shallow navigation may push or replace. Only `Content` navigations create a request and enter `Loading`. `Shallow` commits location and search state synchronously without fetching route content; `HashOnly` commits the hash and scroll position without fetching or rematching. Representing the kind in the type prevents the prototype's failure mode, where a `~shallow` argument existed but silently did nothing.

The packed types are the internal boundary that lets differently typed routes share one registry and navigation state. Generated route handles recover route-specific types for application code.

The exact syntax can change. This invariant must not: path params, search, data, location, and rendered branch come from one matched value and commit together.

## Generated diagnostics

The declaration tooling should reject:

- Duplicate route names
- Duplicate full paths
- Ambiguous route patterns where the supported codecs permit static analysis
- Duplicate param names in one ancestry chain
- Unsupported or malformed patterns
- A page module with the wrong params or search type
- A route without a page, layout, redirect, or children
- Parent and child context types that do not compose
- Search key collisions in one matched branch

Generated function signatures, rather than custom PPX diagnostics, should let the OCaml type checker reject links with missing or invalid params.

## Processing phases

The current implementation mixes Dream route registration, matching, param extraction, React element construction, transport, history writes, and cache restoration. The replacement uses typed boundaries:

| Phase | Input | Output |
| --- | --- | --- |
| Parse location | Request target | Canonical `location` |
| Match | Route registry and pathname | Matched branch or typed miss with matched prefix |
| Decode | Raw params and search | Typed route inputs or parse error |
| Guard and context | Match and request context | Authorized branch context or redirect/error |
| Load | Match and context | Typed loader data or redirect/error |
| Render | Match and loader data | Component payload plus metadata |
| Transport | Navigation request | Versioned response envelope |
| Commit | Active request and response | URL, history, match, data, focus, and scroll |

Match and decode semantics must define whether a codec failure is a malformed request or permits another route candidate. The result must retain the matched prefix so the router can select the nearest nested not-found or error boundary.

Status, headers, redirects, cookies, and metadata must settle before the server writes the first response byte. Errors after streaming begins retain the committed HTTP status and travel through a rendered error boundary with a server-side diagnostic identifier.

## URL and codec contract

The server and client must share one segment-based matching and canonicalization contract. Before implementation, specify:

- Percent decoding and malformed escape handling
- Encoded slash policy
- Empty and duplicate segments
- Dot segments
- Unicode and case sensitivity
- Trailing slash policy and redirect status by HTTP method
- Static, dynamic, optional, and splat precedence
- Index and pathless route behavior
- Relative and absolute destination resolution

The router owns URL percent encoding. Path codecs operate on decoded segment values and must satisfy parse/print round-trip and canonicalization laws.

Search schemas must define owned keys, repeated values, absent versus empty values, defaults, unknown-key preservation, parent-child composition, collision diagnostics, canonical serialization order, and loader invalidation dependencies.

## Partial RSC navigation protocol

### Decision: content negotiation on route URLs, headers carry facts

Navigation requests target the same URL as document requests and are distinguished by content negotiation. Nothing router-specific appears in the path or query: a query parameter would squat on a key any page might want, would split one URL across two response bodies for caches, and — as the prototype demonstrated (see the audit) — invites carrying the client's *conclusion* about which branch is shared, leaving both sides to guess the split with different algorithms on different inputs.

A dedicated navigation endpoint (such as `/__router/navigate`) is rejected: it solves nothing content negotiation does not, gives up free cacheability of full responses, and adds a second URL space to secure, mount, and version. This closes the former open decision.

The replacement principle: **the client transmits facts about itself, never conclusions about the shared branch.** All matching happens on the server.

### Request contract

```
GET /demo/router/42/edit
Accept:              application/react.component
SRR-Navigation-From: /demo/router/42?filter=done
SRR-Registry:        1.9f3ac21
```

| Header | Content | Size |
| --- | --- | --- |
| `Accept` | `application/react.component` selects a flight payload over a document | fixed |
| `SRR-Navigation-From` | The client's committed location: pathname plus search, percent-encoded per the URL contract | O(URL), capped |
| `SRR-Registry` | Protocol version and registry fingerprint, separated by `.` | fixed |

Request rules:

- Every header is a statement about the client's own state. "Where I am" is a fact; "what changed" is a conclusion and never crosses the wire. This also keeps every header O(1)-sized — no tree structure is ever serialized into headers, avoiding the header-size failure class of state-tree designs.
- No request identifier crosses the wire. HTTP already correlates each response with its request; the reducer's `requestId` is a client-side concept for discarding superseded work.
- Every header is droppable. A stripped or malformed header degrades to a correct, less-optimal response (`Full`), never a wrong one.
- Navigation requests are `GET` and idempotent. Mutations belong to the action contract, not this protocol.
- Requests are same-origin with default credential behavior. A later `SRR-Base-Revision` header joins this contract when loader data makes revision divergence possible; until then the committed location and fingerprint determine the base.
- `Referer` is not a substitute for `SRR-Navigation-From`. It reflects `document.URL` at request time, not the committed tree, and the two diverge under eager URL commit (where `Referer` would name the target itself, making the server compute a fully shared branch — a wrong patch, not a degraded one), during concurrent navigations, and after failures. It is also subject to `Referrer-Policy`, proxies, and extensions the router does not control, and it cannot carry the fingerprint or future revision fields. The committed location must come from the navigation reducer, stated explicitly.

### Server algorithm

For target `T` with `From` header `F` and fingerprint `fp`:

1. If `fp` does not match the running registry, respond `ReloadRequired` with an empty body.
2. Match `T` against the registry. A miss renders the nearest not-found boundary as a `Full` response with status 404.
3. If `F` is absent, unmatchable, outside the router mount, or oversized, ignore it: authorize and render the full target branch.
4. Otherwise match `F` and compute the shared prefix: the longest run of levels where the route definition **and** the decoded param values are both equal. Definition equality alone is insufficient — `/note/1` and `/note/2` share no level below their common static ancestor, which is what makes stale-layout reuse impossible by construction.
5. Run guards and context construction for the **complete** target branch, parent-first, regardless of sharing.
6. Render only the levels below the shared prefix. Respond `Patch` with `replaceFrom` naming the first non-shared level, or `Full` when nothing is shared.

`F` influences how much UI the response carries — nothing else. Authorization, matching, status, and canonicalization are computed from `T` alone (design rule 9).

A navigation response is a versioned result rather than a success-only record:

```reason
module ComponentPayload: {
  type t;
};

type layoutInstanceKey;
type scrollPolicy;
type redirect;
type routeError;

type navigationResponse =
  | Full({
      protocolVersion: int,
      registryFingerprint: string,
      targetRevision: string,
      canonicalUrl: string,
      status: int,
      matches: array(routeId),
      payload: ComponentPayload.t,
      scroll: scrollPolicy,
    })
  | Patch({
      protocolVersion: int,
      registryFingerprint: string,
      baseRevision: string,
      targetRevision: string,
      replaceFrom: layoutInstanceKey,
      canonicalUrl: string,
      status: int,
      matches: array(routeId),
      payload: ComponentPayload.t,
      scroll: scrollPolicy,
    })
  | Redirect(redirect)
  | NotFound(routeError)
  | Failed(routeError)
  | ReloadRequired;
```

The envelope splits across the response by audience. Response headers carry what the client must know before parsing the stream; the flight payload carries what React needs to commit:

```
200 OK
Content-Type:  application/react.component
Vary:          Accept
SRR-Response:  full | patch | reload-required
Cache-Control: private, no-store          (patch responses only)

body: flight stream carrying the in-band envelope —
      canonicalUrl, matches, replaceFrom, scroll, payload
```

`SRR-Response` in a header lets the client short-circuit: `reload-required` triggers a hard navigation without parsing any stream. `replaceFrom`, `canonicalUrl`, and `matches` travel in-band because the commit is atomic with payload arrival anyway, flight serialization gives them structure for free, and header size limits never enter the picture. The `status` field of the parsed envelope mirrors the HTTP response status; it is not separately encoded in the body.

`Router.ComponentPayload.t` is the streamed flight payload, deliberately abstract rather than `React.element`, for three reasons:

- Its concrete backing differs per platform: on the native server it is the flight byte stream produced by the render phase, and in Melange it is the readable stream handed to the flight deserializer. The envelope is universal code, so no single concrete type is correct on both sides.
- The signature exposes no equality, inspection, caching, or re-render operations, which makes the "do not cache React element trees as data" rule compiler-enforced instead of prose. The prototype's element-tree history cache existed because `React.element` made it easy.
- A flight payload arrives progressively and is consumed exactly once; `React.element` implies a materialized, reusable value that the payload is not.

The server render phase produces one payload per response; the client consumes it exactly once. The platform-specific constructors and the consuming function are part of the core-type work in the immediate phase.

`scrollPolicy`, `redirect`, and `routeError` are named here so the envelope is complete, but their contents are settled by the history, redirect, and error sections below.

`replaceFrom` identifies the layout instance at which the client grafts the patch. It is a `layoutInstanceKey` rather than a bare `routeId` because a route ID alone cannot distinguish `/note/1` from `/note/2`; the key's composition — route ID plus whichever inputs participate in layout instance identity — follows the layout identity decision below.

The client applies a patch only when its committed revision matches `baseRevision` and the response corresponds to the still-active navigation; superseded fetches are aborted, and any late response for a stale `requestId` is ignored. Otherwise it discards the response or requests a full payload.

### Redirects on this transport

Internal redirects are resolved server-side, with a loop limit, and answered as the final destination's response with the final `canonicalUrl` — the client commits history to the real URL in one round trip. External redirects return the in-band `Redirect` variant, which the client applies as a hard navigation. Document requests keep ordinary 3xx responses. Both encodings must resolve to the same canonical destination. Targets and canonical URLs must remain same-origin and inside the router mount unless the external redirect policy permits otherwise.

### Caching

Documents and `Full` flight responses are cacheable under `Vary: Accept`. `Patch` responses opt out of shared caching explicitly with `Cache-Control: private, no-store` rather than relying on `Vary: SRR-Navigation-From`: CDN `Vary` handling is unreliable, and the from-times-target cardinality makes shared caching of patches worthless anyway. Serving a patch from the wrong base is the failure this rule exists to prevent.

### Failure handling

| Condition | Server behavior | Client behavior |
| --- | --- | --- |
| Fingerprint mismatch | `reload-required`, empty body | Hard navigation to the target |
| `From` missing or stripped | `Full` | Commit full |
| `From` outside mount, unparseable, or oversized | Ignore it, `Full` | Commit full |
| Target does not match | 404, `Full` of nearest not-found boundary | Commit, status-aware |
| Param or search decode failure | Per codec status policy, boundary rendered | Commit boundary |
| Network error or wrong content type | — | `Failed`, keep current tree, offer retry |
| Superseded navigation | — | Aborted, or ignored by client-side `requestId` |

Every row ends in a defined state.

### Staging

The header transport does not need the typed registry to land. In the prototype: `navigate` sends the three headers and stops computing path suffixes; the server matches `SRR-Navigation-From` against the generated route definitions with a small segment matcher, computes the shared prefix by definition-and-param equality, and feeds the same parent/sub split into the existing sub-route rendering; `layoutInstanceKey` is provisionally serialized as the definition path plus bound params. With the typed registry, the fingerprint becomes generated, `matches` become route IDs, guards and loaders slot into step 5, and `SRR-Base-Revision` is added when loader data can diverge from location.

Still unsettled for this transport: response size limits, malformed flight payload behavior, and the exact `SRR-Navigation-From` length cap.

## History and navigation contract

Define reducer transitions for push, replace, pop, shallow, hash-only, redirect, cancellation, failure, retry, hydration, and restoration after a cache miss.

Each transition must state:

- When the browser URL changes
- Which content remains visible while work is pending
- Whether failure restores, preserves, or replaces the attempted URL
- Whether the operation creates, replaces, or reuses a history entry
- How superseded requests are cancelled and ignored
- How focus, scroll, and hash anchors are restored
- What the navigation promise returns to the caller

A `Pop` transition must not create a new history entry. Direct load, client navigation, and history restoration must produce the same canonical location and match.

## Errors, redirects, and disclosure

Define separate error variants for location parsing, no match, parameter decoding, search decoding, authorization, loader execution, action validation, rendering, transport, protocol mismatch, cancellation, and deployment mismatch.

Each variant needs a boundary selection rule, public-safe payload, status policy, retry behavior, and server logging policy. Production responses must not serialize arbitrary exception messages or stack traces. They should expose an opaque diagnostic identifier that correlates with server logs.

Redirects need a typed destination, valid status code, history action, same-origin policy, and loop limit. Direct document requests and RSC navigation encode redirects differently — 3xx responses for documents, server-side resolution or the in-band `Redirect` variant for navigation, as decided in the transport section — but they must resolve to the same canonical destination.

## Layout identity and reconciliation

Stable route IDs identify route definitions, not complete rendered instances. The specification must define whether layout instance identity — the composition of `layoutInstanceKey` — also includes selected path params or declared search dependencies beyond the route ID.

For every navigation, each matched level must have a deterministic rule for preserving, rerendering, or remounting its layout. Navigating from `/note/1` to `/note/2` must not retain stale params or loader data merely because both locations share one route ID.

## Loaders, actions, context, and caches

Request-scoped server context must remain separate from explicitly serializable client context. Parent and child context types need a defined input/output composition rule.

Guards and context transformations run parent-first. Loaders may run concurrently only when their declared dependencies permit it. Every loader contract needs cancellation, cache identity, error and redirect results, and a declaration of which data may cross the RSC boundary.

Actions need method and input types, validation results, authorization, CSRF and origin policy, redirect behavior, progressive enhancement, idempotency expectations, and invalidation effects.

Keep route data separate from history restoration and prefetched-navigation caches. Do not cache React element trees as durable data. Define cache ownership, keys, authentication scope, freshness, invalidation, garbage collection, memory limits, and restoration behavior independently.

## Deployment and mount behavior

Route IDs must be deterministic. Requests and responses carry a generated registry fingerprint so an old hydrated client cannot apply a payload from an incompatible deployment. A mismatch produces `ReloadRequired`.

The router mount or basename is a router-instance value used by matching, destination generation, canonical URL validation, SSR hydration, and validation of the `SRR-Navigation-From` header. Generated handles must not hard-code `/demo/router`.

## Implementation sequence

The audit's P0–P3 priorities map to this sequence as follows: P0 items land in the immediate and short-term phases, P1 in short and medium term, P2 in medium term, and P3 in long term. One deliberate split: ambiguity rejection is immediate (see "Generated diagnostics"), while route ranking moves to medium term because optional segments and splats — the patterns that need ranking — do not exist before then.

### Immediate

1. Define the nested declaration format, generated module signatures, packed runtime types, and path/search codec laws.
2. Define matching, miss, parse-error, redirect, and boundary selection semantics.
3. Specify the history reducer and partial navigation protocol, including revisions and deployment mismatch.
4. Add deterministic conformance tests for matching, codecs, races, and reducer transitions.
5. Remove page-level parameter parsing and make unknown routes and parse failures return visible boundaries with correct status.

### Short term

1. Replace the global mounted-layouts registry with router-scoped committed match state.
2. Implement typed `Link`, `NavLink`, destination builders, and navigation with standard modified-click behavior.
3. Add request cancellation, response validation, route errors, retry, redirects, and nested not-found boundaries.
4. Preserve search and hash through hydration, push, replace, pop, and restoration.
5. Add focus and scroll behavior to the navigation commit.

### Medium term

1. Add typed loaders, actions, inherited route context, and separate cache layers.
2. Add index routes, pathless layouts, optional segments, splats, ranking, and ambiguity diagnostics.
3. Add blockers, metadata, headers, and prefetching.
4. Add development match and cache inspection after the behavior contract is stable.

### Long term

1. Consider file-based route generation after the code-based typed API is stable.
2. Consider route masking and custom search serialization after canonical URL semantics are proven.
3. Turn the demo into an inspection tool that shows active matches, decoded inputs, loader state, cache decisions, and the exact partial RSC request.

## Conformance strategy

The router needs:

- Pure matcher and canonicalization vectors shared by native and Melange tests
- Codec round-trip and malformed-input tests
- PPX or generator compile-pass and compile-fail fixtures
- Navigation reducer model tests with fake history, fetch, clock, and cancellation adapters
- Deterministic latest-navigation-wins race tests
- Paired direct-load and client-navigation assertions for every route outcome
- Browser tests for links, hydration, query and hash preservation, push, replace, pop, focus, scroll, errors, and mobile reflow
- Streaming tests that distinguish failures before and after HTTP headers commit
- Transport degradation tests: each navigation header stripped, malformed, or oversized must yield a correct `Full` response, never a wrong patch
- Shared-prefix tests asserting definition-and-param equality, including the `/note/1` to `/note/2` case sharing nothing below the common static ancestor
- Deployment-skew tests that require a reload on registry mismatch

## Definition of done for a credible v1

The router library and its demo application have separate completion criteria. Demo quality must not block a library release, and library claims must not rest on demo behavior.

### Library

A v1 of the router should not be called type-safe or production-ready until all of these statements are true:

- Every application navigation uses a typed route handle or destination.
- Path and search values are decoded before a page can render.
- The compiler rejects links with missing or invalid params.
- URL, match, params, data, and content commit atomically.
- Superseded navigation cannot update UI or history.
- A partial response cannot apply to the wrong committed tree revision.
- Direct load, client navigation, and back/forward produce the same match.
- Search and hash survive hydration and restoration.
- Unknown routes, parse failures, loader failures, and render failures reach typed boundaries with the specified status behavior.
- Nested layouts preserve state without global render-time mutation or stale route inputs.
- Links work with standard browser behavior and without JavaScript where applicable.
- Old clients reload rather than applying incompatible route registries or RSC payloads.
- A recorded conformance fixture shows that a leaf navigation patch response is smaller than the equivalent full response, since payload reduction is the justification for the patch protocol.
- Deterministic native, Melange, and browser tests cover the behavior contract.

### Demo

The demo is done when:

- Mobile layout reflows without horizontal scrolling at 320 px and 200 percent zoom.
- Keyboard and screen-reader users can operate every control.
- A production-profile bundle baseline is recorded, with transferred and parsed sizes attributed to shared chunks, before any budget is set.

## Open decisions

- PPX versus standalone code generation
- Exact declaration grammar and generated module naming
- Existential or GADT representation for packed routes and matches
- Which route inputs participate in layout instance identity and therefore in `layoutInstanceKey`
- Eager versus deferred URL updates for push and replace
- Loader execution graph and cache ownership
- Exact malformed-path and codec-failure status policy

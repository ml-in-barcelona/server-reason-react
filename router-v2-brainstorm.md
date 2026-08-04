# Typed router v2 brainstorm

Status: Brainstorm, not committed scope

Date: 2026-08-03

V2 begins only after [`router-v1-plan.md`](router-v1-plan.md) is implemented, measured, and used by the monorepo. This document records likely pressure points so v1 does not accidentally prevent them. It is not a promise to implement every item.

## Promotion rule

A candidate moves into a v2 plan only when it has:

- A concrete monorepo use case that v1 cannot express cleanly
- A measured correctness, latency, payload, or developer-experience problem
- A type sketch that preserves generated labeled destinations and the single route tree
- Defined cache, cancellation, error, and server/client ownership where applicable
- A migration path that does not invalidate v1 destinations unnecessarily

## Likely v2 candidates

### Typed actions

Integrate route-aware mutations with existing server functions instead of creating a parallel RPC mechanism. A candidate design would provide typed input validation, application errors, redirects through generated destinations, progressive enhancement, CSRF/origin policy, and explicit loader invalidation.

Evidence required: at least one mutation that cannot be expressed cleanly by a server function plus generated redirect and invalidation helpers.

### Loader caching and revalidation

Add a data cache only after loader identity and mutation pressure are visible in production. The design must define authentication scope, cache keys, freshness, invalidation, cancellation, memory limits, and deployment revision behavior. It must cache loader data, never React elements.

Evidence required: repeated loader work with measured latency or load impact that request-local caching does not solve.

### Prefetching

Allow links to prefetch by intent or viewport. Prefetch must reuse the same authorization, loader, fingerprint, and response-validation path as navigation. Cache entries must be scoped to the exact destination, user, and registry revision.

Evidence required: measured navigation latency where payload prefetch materially improves interaction without excessive network or server work.

### Navigation-pending UI

Add a declaration distinct from render-phase `~loading`. A possible `~pending` attachment would render while a navigation request and its loaders are outstanding. Its available inputs must be defined separately because target loader values do not exist yet.

Evidence required: product flows where retaining current content plus global pending state is insufficient.

### Optional segments and splats

Extend path syntax only together with deterministic precedence and ambiguity diagnostics. Generated destination signatures must make optional values and splat encoding explicit.

Evidence required: real routes whose duplication or catch-all handling is materially worse without these patterns.

### Relative destinations

Generate destinations relative to route identity rather than string path prefixes. Relative navigation must still produce an opaque fully resolved destination before it reaches the runtime.

Evidence required: reusable nested features that otherwise need knowledge of application-level parents.

### `NavLink` and active matching

Build active and pending link behavior over route IDs, canonical params, and search dependencies. Avoid path-prefix string comparisons.

Evidence required: navigation surfaces needing route-aware styling or accessibility state beyond ordinary links.

### Navigation blockers

Support dirty-form and workflow confirmation without corrupting browser history. The reducer needs explicit blocked, resumed, and canceled transitions for push, replace, and pop.

Evidence required: an unsaved-work flow in the monorepo.

### Lazy route modules

Make route module boundaries explicit for server and client code splitting. Generated APIs must remain available without eagerly importing page implementations into the client bundle.

Evidence required: a production bundle trace identifying route declarations or references as meaningful eager cost.

### Composable feature subtrees

Allow large monorepo features to define reusable route fragments while preserving one visible application tree and deterministic generated names. Composition must not become implicit registration or filesystem discovery.

Evidence required: the central `Router.re` manifest becoming a measurable ownership or review bottleneck.

### Multiple mounts

Parameterize one generated route tree by multiple base paths. This likely requires a mounted router value or generated functor and would change the instance-free `Router.Note.href(...)` shape.

Evidence required: the same compiled route tree being mounted more than once in one application or process.

### Development inspection

Expose active matches, decoded inputs, loader timings, cache decisions, metadata composition, response kind, base revision, and patch boundaries. Tooling should consume stable runtime inspection data rather than private mutable state.

Evidence required: recurring debugging cost after v1 behavior stabilizes.

## Unlikely to make v2

### File-based routing

The code-based API must prove its semantics first. Filesystem conventions would add another declaration language and generation pipeline before the core contract has enough usage evidence.

### Route masks

Displayed and matched URLs should remain identical until canonical navigation, history, and cache behavior are mature.

### Exhaustive destination variants

The requirement is type-safe construction, not closed-world pattern matching. Generated route modules and opaque destinations already satisfy that requirement with less machinery.

### Implicit global registration

Routes remain visible in one tree. Import side effects, process-global registries, and automatic discovery would reintroduce hidden ownership and nondeterministic ordering.

### Raw string navigation

Application navigation, redirects, and links continue to require generated destinations. An explicit external-URL API is separate from internal route navigation.

### Multiple loaders per node

One loader can return an application record. Multiple independently named loaders would complicate ordering, error selection, and generated props without adding expressive power.

### Automatic sync/async detection

Loaders, metadata, and headers remain async-only. `Lwt.return` handles immediate values without untyped generator inference or runtime promise inspection.

### Generated page-input records

Direct labeled props avoid generated-type dependency cycles and keep component contracts readable. Records remain appropriate inside application loader data.

### React element caching

History restoration and prefetch caches store location, matches, loader data, and protocol payloads according to explicit ownership. They never retain rendered React element trees as durable data.

### Automatic route-name suffix stripping

Page module names remain the default route names, with explicit overrides. Naming conventions such as removing `Page` are too implicit for stable public modules.

### Arbitrary custom search serialization

The standard schema and canonical URL contract should accumulate production evidence before allowing per-route serialization semantics that can break equality, caching, and hydration.

### Framework abstraction without demand

Dream remains the first server integration. Generalizing request, response, streaming, and cancellation interfaces requires another concrete adapter rather than speculative indirection.

## Questions v1 should leave answerable

- Can generated route modules be parameterized by a mount without changing path/search safety?
- Can feature subtrees compose while preserving one deterministic registry and public namespace?
- Which loader dependencies are stable enough to key caches and run independent loaders concurrently?
- Can pending UI be selected without moving matching authority to the client?
- Can actions reuse server-function transport while participating in loader invalidation and typed redirects?
- Which optional path forms can be ranked and diagnosed statically?
- What inspection data can be public without freezing runtime internals prematurely?

These are compatibility questions for v1, not reasons to implement v2 machinery early.

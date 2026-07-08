# Investigation — `React.memo` (Q6) and the react-client fork (Q7)

## Q6 — `React.memo` / `memoCustomCompareProps` incompatibility

### Evidence
- reason-react (`_opam/lib/reason-react/React.rei:420`):
  ```reason
  external memo: component('props) => component('props) = "memo";
  external memoCustomCompareProps:
    (component('props), ('props, 'props) => bool) => component('props) = "memo";
  ```
  `memo` takes **one** argument (a component) and returns a component.
- server-reason-react (`packages/react/src/React.ml:611-612`, `.mli:666-667`):
  ```ocaml
  let memo f _component = f
  let memoCustomCompareProps f _compare _component = f
  val memo : ('props * 'props -> bool) -> 'a -> 'props * 'props -> bool
  val memoCustomCompareProps :
    ('props * 'props -> bool) -> ('props * 'props -> bool) -> 'a -> 'props * 'props -> bool
  ```
  `memo` takes **two** arguments and returns its first argument (the "compare fn"), which is then treated as the component.

### Why it's incompatible
`React.memo(MyComponent)` — the reason-react shape — does not type-check against srr's two-argument `memo`. The srr signature also has the arguments in a nonsensical order (a compare predicate first, the component discarded), so even adapting call sites can't recover reason-react semantics. On the server, memoization is a no-op anyway (there's no re-render), so the *behavior* target is simply "identity that passes the component through."

### Fix direction
Match reason-react's shapes so universal code compiles unchanged, keeping the server behavior as pass-through:
```ocaml
(* React.ml *)
let memo component = component
let memoCustomCompareProps component _compare = component
```
```ocaml
(* React.mli *)
val memo : 'component -> 'component
val memoCustomCompareProps : 'component -> ('props * 'props -> bool) -> 'component
```
Then confirm against the server-reason-react-ppx `[@react.component]` lowering (the cram at `packages/server-reason-react-ppx/cram/component-definition.t` references `React.memo((~a) => …)` and `React.memoCustomCompareProps((~prop) => …, (a,b) => true)`) — the ppx emits `let make = React.memo(makeInner)` style, so the one-arg shape is what it needs. Add a test that a `[@react.component] [@react.memo]`-style component renders identically to the un-memoized one.

## Q7 — Removing the `@pedrobslisboa/react-client` dependency (keep the custom esbuild plugin)

### Constraint from the maintainer
**Keep the custom esbuild `$$$config`. No webpack shim.** (An earlier draft of this doc suggested adapting `react-server-dom-webpack/client` behind a `__webpack_require__` shim — that is explicitly rejected, because it throws away the whole point of a first-class esbuild integration and pretends to be webpack.)

### What is actually the fork, and what isn't
`packages/react-server-dom-esbuild/ReactServerDOMEsbuild.js` is a **genuine, hand-written esbuild integration** — it *is* the custom plugin. Its `$$$config` (`ReactFlightClientConfigBundlerEsbuild`, lines 169-278) implements `resolveClientReference`/`resolveServerReference`/`preloadModule`/`requireModule` natively against `window.__client_manifest_map` / `window.__server_functions_manifest_map`. There is no webpack anywhere. **This file stays.**

The *only* external dependency is line 30:
```js
import ReactClientFlight from "@pedrobslisboa/react-client/flight";
```
i.e. the generic Flight-client **factory** — the function that takes a `$$$config` and returns `{ createResponse, processReply, getRoot, processBinaryChunk, close, … }`. The file's own docblock (lines 18-27) and the `TODO` at line 286 ("Can we use the real thing, instead of mocks/vendored code here?") already frame the problem. So the task is narrow: **source that factory from React proper instead of a third-party republish** — without touching the esbuild config.

### Why you can't just import it from an official npm package
React does not publish `react-client` standalone. Every official bundler package (`react-server-dom-webpack`, `-parcel`, `-turbopack`, `-fb`) is built by React as `react-client/flight` **already specialized with that bundler's config baked in at build time** — you cannot cleanly extract the un-configured factory from `react-server-dom-webpack`. That specialization is exactly what a webpack shim would drag in, and exactly what we're refusing. The un-specialized factory only exists in React's *source* (`packages/react-client/src/ReactFlightClient.js` + the `ReactFlightClientConfig` seam). This is precisely why the `@pedrobslisboa` fork exists.

### Options that preserve the custom esbuild plugin

1. **Own the build (recommended).** Produce the `react-client/flight` factory (or a full `react-server-dom-esbuild`) yourself from a **pinned React commit**, and ship it *inside* this project's `server-reason-react-server-dom-esbuild` package at release time (or under the project's own npm scope). This is exactly what `@pedrobslisboa` did — the only change is that *the project owns it*, pins the exact React SHA, and controls releases. `ReactServerDOMEsbuild.js` keeps importing "the factory", now sourced from your own build. No fork, no shim, no protocol drift.
   - React's build (`scripts/rollup`) already emits per-bundler flavors; adding an `esbuild`/generic-client flavor that outputs just the factory is a build-config change, and can be automated in CI so bumping React is one pinned-SHA change.

2. **Vendor the factory source.** Copy React's `ReactFlightClient.js` (+ the config seam) into `packages/react-server-dom-esbuild/vendor/` pinned to a React SHA, and have `ReactServerDOMEsbuild.js` call it directly. Fully self-contained, no npm dependency on react-client at all. React's flight client is *designed* as a factory for exactly this injection pattern — the esbuild config you already have is the intended extension point. Cost: you re-vendor on each React bump (a diffable, reviewable step).

3. **Upstream a `react-server-dom-esbuild` package to React.** The "right" long-term fix given React keeps adding bundler integrations; slow, and you'd still want option 1/2 in the meantime.

### Recommendation
1. **Immediately:** pin exact versions — `@pedrobslisboa/react-client` `19.1.0` (not `^`) and `esbuild` to a tested version — so the Flight protocol can't float underneath you (this alone removes the acute risk of Q9's 7-tuple-vs-4-tuple mismatch appearing on a silent minor bump).
2. **Then:** replace the fork import with an **owned build of `react-client/flight`** (option 1) — build it from a pinned React SHA in CI and bundle it into `server-reason-react-server-dom-esbuild`. `ReactServerDOMEsbuild.js` — the custom esbuild plugin — is unchanged; only line 30's provenance changes from "someone's fork" to "our pinned build of React's own factory."
3. **Guardrail:** add a round-trip test (OCaml `ReactServerDOM` encoder → this esbuild client decoder) pinned to the known React version, so wire-format drift (Q9) is caught in CI rather than in production. Align the OCaml encoder's prod rows with what the pinned client expects (4-tuple vs 7-tuple) as part of that test.

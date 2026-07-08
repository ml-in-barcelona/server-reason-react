# Design tensions

The deepest issues, where the approach — not a single line — is the problem.

---

## T1 — `useId` uses process-global mutable state inside a concurrent (Lwt) renderer

**Problem.** The four render-id refs (`React.ml:747-750`) are module globals. The save/restore-around-recursion discipline only holds within a synchronous slice; it does not survive an Lwt suspension. This is the root of finding 2.1 and is structurally at odds with the project's headline feature — streaming/async SSR with `useId` hydration parity.

The maintainer's current position ("single process is fine") makes this a **constraint, not a live bug**, but the constraint is undocumented and easy to violate: two overlapping `renderToStream`/`render_html`/`render_model` calls on one process already interleave at Lwt yields, without multicore.

**Alternative.** Thread the tree context per render:
- Store it in an `Lwt.key` (the codebase already does this for `React.Cache` and `React.Context`), so each Lwt execution has its own; or
- Pass `Tree_context.t` explicitly through the renderer functions (they already pass `buf`/`stream_context` positionally for exactly this "no shared state" reason — see the perf comment at ReactDOM.ml:135-140).

Either removes the concurrency hazard and lets the "in production at scale" claim hold under real concurrency. Until then: document the single-render-at-a-time constraint in `React.mli` and the SSR docs.

---

## T2 — Two divergent stream lifecycle models that both have close/backpressure bugs

**Problem.** `renderToStream` and `render_html` implement the same idea (shell + async boundaries + close-when-done) twice, differently:
- `renderToStream` guards pushes with `closed` (ReactDOM.ml:561) but **miscounts pending** (root not counted → 2.2).
- `render_html` **counts the root** (`pending:1`, ReactServerDOM.ml:1104) but has **no `closed` guard** on async pushes (→ 2.3, process crash on timeout).

Neither has backpressure: `Push_stream` wraps an unbounded `Lwt_stream` (Push_stream.ml), so a fast producer + slow/absent consumer grows memory without bound; abort is a no-op (2.12).

**Alternative.** One shared streaming core with:
1. the root walk counted as a pending unit from the start (fixes 2.2),
2. every `push`/`close` idempotent and guarded by a single `closed` flag (fixes 2.3),
3. abort/timeout that flushes fallbacks + `$RX` client-retry markers then closes (fixes 2.12; spec in [`investigations/react-abort-timeout.md`](investigations/react-abort-timeout.md)),
4. consumer-driven backpressure (the subscriber already `iter_s`; make production await it).

The duplication is why these two engines keep drifting (they already disagree on error gating — 2.9 — and on the `hidden` vs `hidden="true"` boundary markup).

---

## T3 — "Universal" (0-divergence) is asserted and shipped, but not verified in CI

**Problem.** The core promise is "same source, identical behavior on server and client." The maintainer confirms the contract is **0 divergences** and that a quickjs update was shipped to fix number semantics. But:
- The quickjs fix reaches `Js.Float`/`Js.Number` formatting only; **`Belt.Float.toString`, `Belt.Int/Float.fromString`, `Js.Float.fromString`'s error path, and `Js.Global.parseInt` still use `Stdlib` or the wrong quickjs variant** (2.16, [`investigations/quickjs-divergence-status.md`](investigations/quickjs-divergence-status.md)).
- The most dangerous divergences aren't number-related at all: `Belt.HashMap` data loss (2.4), `Js.String` byte-vs-UTF16 (2.14), `Js.Date` local-time (2.15), `url` WHATWG gaps (2.22).
- The test suites assert **native self-consistency** (unordered comparisons, ±2.0 float epsilon, commented-out failing cases, a tautological `assert_raises`), not JS-equivalence — so they cannot defend the contract.

**Alternative.** A differential harness: run identical inputs through Melange-compiled JS (the `arch/server` bun scripts already do this for useId/head-ordering) and native, asserting byte-equality, wired into PR CI. Without it, "0 divergences" is a goal the test suite is structurally unable to enforce, and regressions like 2.16 ship silently.

---

## T4 — DOM attribute knowledge is triplicated and drifting

**Problem.** React's attribute tables are hand-transcribed into (a) the PPX's `DomProps.ml` (~1690 lines), (b) the runtime `ReactDOM.domProps` (~1000 lines), and (c) `ReactDOMStyle`. (a) and (b) have already drifted (2.6 xlink/xmlns), share the `defaultChecked`/`defaultValue` bug (2.7), and are riddled with `(* Does it exist? *)` comments and typos (2.30). There are also four HTML serializers (2.25).

**Alternative.** Single source of truth: a typed attribute table from which both `DomProps.ml` and `ReactDOM.domProps` are generated, and one HTML serializer parameterized by mode that the sync/stream/RSC/PPX-`Writer` paths all share. Makes the JSX path and the variadic path incapable of disagreeing and kills the serializer drift.

---

## T5 — Transparent core types + exported render internals = no enforceable invariants

**Problem.** `React.element`, `React.Model.t`, and the render-id refs are public and transparent (`React.mli:583-614,695-700`). This is convenient for the PPX but means:
- the library can't enforce escaping or well-formed trees — a user can build `Lower_case_element {tag = "<script>…"}` (tag never validated) or `Static {prerendered}` (an undocumented raw-HTML injection point) — 2.33;
- the render-id lifecycle can be called out of order;
- the representation can't evolve without breaking every consumer.

**Alternative.** Abstract `element`/`Model.t` behind the `.mli`, expose smart constructors (`createElement`, `text`, `dangerouslyInnerHtml`), and move the render-id internals into a private module the PPX reaches via a documented internal path (`-open` / `Private` submodule). Keeps PPX ergonomics while restoring an abstraction boundary.

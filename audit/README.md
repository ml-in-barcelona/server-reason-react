# server-reason-react — Adversarial Audit

Audit of the repository at commit `a8e5e43` (`main`). Scope: the full codebase — core runtime (`React`, `ReactDOM`, `ReactServerDOM`), the RSC pipeline, the universal libraries (Belt, Js, webapi, Dom, url, fetch, promise), the three ppxes, docs, demo, and tests.

Method: the core rendering path was read line-by-line; peripheral packages were deep-read by dedicated agents and spot-verified. Every finding carries a `file:line`, a concrete failure/surprise scenario, and a confidence tag:

- **CONFIRMED** — traced in code (and, where noted, reproduced against the built artifacts or React 19.1.0).
- **PLAUSIBLE** — strong code-level inference, not executed end-to-end.

## How to read this folder

| File | Contents |
|------|----------|
| [`00-system-map.md`](00-system-map.md) | Architecture, real execution paths, key invariants |
| [`01-critical.md`](01-critical.md) | Data loss, crashes, silent corruption |
| [`02-high.md`](02-high.md) | Wrong output, dropped props, leaks |
| [`03-medium.md`](03-medium.md) | Divergences, footguns, missing behavior |
| [`04-low.md`](04-low.md) | Nits, typos, cosmetic drift |
| [`05-design-tensions.md`](05-design-tensions.md) | Structural issues where the approach is the problem |
| [`06-expectation-gaps.md`](06-expectation-gaps.md) | "I expected X, found Y" |
| [`07-open-questions.md`](07-open-questions.md) | Questions + maintainer answers + follow-ups |
| [`areas/`](areas/) | Per-package detail (Belt/Js, ppx, webapi, url/fetch/promise, html/runtime/styles, tests, docs/DX) |
| [`investigations/`](investigations/) | Follow-up research: React abort/timeout, quickjs status, memo, react-client fork |

## Maintainer answers folded into this audit

The following answers from the maintainer reshape severity:

1. **Concurrency** — "for now, it's fine to be running on a single process." → Finding 2.1 (global `useId` state corruption under concurrent renders) is **downgraded from a live bug to a documented constraint** that must be written down and guarded before multi-domain/multi-request-in-flight is enabled. See [`investigations/react-abort-timeout.md`](investigations/react-abort-timeout.md) and 01-critical.md §2.1.
2. **`Lwt.async_exception_hook`** — "Nop, why is it needed?" → It is *not* the right fix, but its absence means finding 2.3 (push-after-close on timeout) currently **terminates the process**. The real fix is guarding pushes with the `closed` flag. Explained in 01-critical.md §2.3.
3. **Abort/timeout semantics** — reproduced against React 19.1.0; React flushes fallbacks + `$RX` client-retry markers. Full output and the required fix in [`investigations/react-abort-timeout.md`](investigations/react-abort-timeout.md).
4. **Error gating** — "It should be both gated on env." → Finding 2.9 confirmed as a bug: `renderToStream` leaks errors unconditionally; must gate on `env` like `ReactServerDOM` does.
5. **Universal divergence contract** — "should be 0 divergences; we shipped a quickjs update." → Verified: quickjs fixed the *number primitives* and `Js.Float`/`Js.Number` now route through them, but divergences remain because Belt and some Js paths still use `Stdlib`, and the string/date/hash bugs are unrelated to quickjs. See [`investigations/quickjs-divergence-status.md`](investigations/quickjs-divergence-status.md).
6. **`memo`** — "is it incompatible? Let's fix it." → Confirmed incompatible with reason-react. Fix direction in [`investigations/memo-and-react-client.md`](investigations/memo-and-react-client.md).
7. **react-client fork** — "we want our custom esbuild plugin, not a webpack shim." → Correct. `ReactServerDOMEsbuild.js` **is** the custom esbuild plugin and stays as-is; only line 30's `@pedrobslisboa/react-client/flight` factory import should be replaced with an **owned build/vendor of React's own `react-client/flight`** pinned to an exact React SHA. No shimming. Analysis in [`investigations/memo-and-react-client.md`](investigations/memo-and-react-client.md).

## Severity summary

Statuses last synced against the 2026-07-09 worktree (after `53f8893`). Per-finding `Sync` lines in the severity files carry the evidence.

| # | Severity | One-line | Status |
|---|----------|----------|--------|
| 2.1 | Critical→Constraint | Global `useId` state corrupts across concurrent renders | **Constraint, documented** (React.ml/.mli); request-scoped state still TODO |
| 2.2 | Critical | `renderToStream` closes stream before shell push → `Lwt_stream.Closed` | **Fixed** (root walk counts as pending; guarded shell push) + test |
| 2.3 | Critical | `render_html` timeout → push-after-close → process exit | **Fixed** by #373 (bcbc9ac) |
| 2.4 | Critical | `Belt.HashMap.Int/String` lose data (FFI misuse) | **Fixed** (pure Int32 hash) + tests |
| 2.5 | Critical | `Belt.Option.getUnsafe` unsound `%identity` (segfault) | **Fixed** (pattern match, raises on None) + tests |
| 2.6 | Critical | Runtime `domProps` xlink/xmlns names drifted from PPX | **Fixed** (3 mappings) + test; single-table generation (T4) still open |
| 2.7 | Critical | `defaultChecked`/`defaultValue` rendered as literal attrs | **Fixed** (map to `checked`/`value`) + test |
| 2.8 | High | `cloneElement` drops style/event/ref/innerHTML/action props | **Fixed** (spread semantics over all prop kinds) + tests |
| 2.9 | High | Error+backtrace leaked into prod HTML (`renderToStream`) | **Fixed** (`env` threaded; bare template in Prod) + test |
| 2.10 | High | `render_html ~debug` silently ignored | **Fixed** (debug/filter_stack_frame threaded via Fiber; model-path row format) + tests |
| 2.11 | High | Head-hoisted resources dropped when root isn't `<html>` | **Fixed** (hoistables stream before the root, react-dom preamble order) + tests |
| 2.12 | High | `renderToStream` abort is a no-op | **Fixed** by #373 (bcbc9ac), tests enabled |
| 2.13 | High | Errors swallowed in `client_to_html` Suspense | **Fixed** (re-raise without boundary; `<!--$!-->` pre-flush; `$RX` post-flush; env-gated) + tests |
| 2.14 | High | `Js.String` byte-vs-UTF16: crashes, corruption, infinite loops | **Fixed** (UTF-16 semantics via Quickjs.String; Str removed) + tests, node-differential |
| 2.15 | High | `Js.Date` local/UTC parse wrong | **Fixed** (ECMA-262 parsing, LocalTZA DST, mutating setters, round-trips) + tests |
| 2.16 | Medium | Numeric parse/format divergences | **Fixed** by #372 (7cb72d0) + #374 (b04951c) |
| 2.17–2.25, 2.27–2.28 | Medium | See `03-medium.md` | Open |
| 2.26 | Medium | `bootstrapScriptContent` injected raw (`</script>` breakout) | **Fixed** (`Html.escape_entire_inline_script`) + test |
| 2.29 | Low | `memo`/`memoCustomCompareProps` signatures | **Fixed** by #371 (054a7e7) |
| 2.30 | Low | API typos (`onEncrypetd`, `fomat`) | Open |
| 2.31 | Low | `ReactDOMStyle` empty-value physical equality | **Fixed** by 39e64ce (+ regression test); one comment nit left |
| 2.32–2.33 | Low | See `04-low.md` | Open |

Full detail per severity file. Design-level issues in `05-design-tensions.md`.

## Sync log

| Date | Verified at | Changes |
|------|-------------|---------|
| 2026-07-08 | `39e22a6` | Re-verified 2.1–2.33 against #371–#374 + style fix. Fixed: 2.3, 2.12, 2.16, 2.29, 2.31. Partial: 2.9. All other findings re-confirmed open at current line numbers. |
| 2026-07-08 | `4dc1fbb..f6b59ae` | Fix batch: 2.2, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9 (completed), 2.26 all fixed with regression tests; 2.1 constraint documented. Remaining open: 2.10, 2.11, 2.13, 2.14, 2.15, 2.17–2.25, 2.27, 2.28, 2.30, 2.32, 2.33. |
| 2026-07-09 | worktree after `53f8893` | Fix batch: 2.10, 2.11, 2.13, 2.14, 2.15 all fixed with regression tests (details in per-finding Sync lines in 02-high.md). Remaining open: 2.17–2.25, 2.27, 2.28, 2.30, 2.32, 2.33. |

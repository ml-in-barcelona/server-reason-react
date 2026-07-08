# Open questions & maintainer answers

The seven questions raised by the audit, with the maintainer's answers and the resulting follow-up work.

---

### Q1 — Is concurrent rendering in one process supported (given `useId` globals)?
**Answer:** "For now, it's fine to be running on a single process."
**Follow-up:**
- Downgrade finding 2.1 from live bug to **documented constraint**.
- Action: add an explicit note to `React.mli` / SSR docs — "one async render in flight per process until render-id state is request-scoped."
- Before enabling multi-request-in-flight or multicore: implement design tension T1 (move id state into an `Lwt.key` or explicit parameter).

---

### Q2 — Is there a global `Lwt.async_exception_hook` override?
**Answer:** "Nop, why is it needed?"
**Follow-up:** It is **not** the right fix. Its absence is *why* finding 2.3 currently terminates the process: a push-after-close inside `Lwt.async` escapes to the default hook, which prints and `exit 2`. Installing a hook would only *mask* the bug. The correct fix (01-critical.md §2.3): give `ReactServerDOM.Stream.t` a `closed` flag, no-op pushes after close, make `close` idempotent — never raise in the first place. `renderToStream` already does this (ReactDOM.ml:561); `render_html`/`Stream.push_async` do not.

---

### Q3 — How does React handle abort/timeout with pending boundaries?
**Answer:** "Check how reactjs does it; maybe create a repro."
**Follow-up:** Done — reproduced against React 19.1.0 in `arch/server/render-html-to-stream-abort.js`. Full captured output + the required server-reason-react behavior in [`investigations/react-abort-timeout.md`](investigations/react-abort-timeout.md). Summary: React flushes the fallbacks (already in the shell) and emits a `$RX` instruction-set script that flips each pending boundary's marker to `$!` and triggers `_reactRetry()`, telling the client to render those boundaries itself; error detail (`msg`/`stck`/`cstck`) is dev-only. This is the spec for fixing 2.12 and the `render_html` timeout path (2.3).

---

### Q4 — `renderToStream` error leak vs `ReactServerDOM` env-gating — which is intended?
**Answer:** "It should be both gated on env."
**Follow-up:** Finding 2.9 confirmed as a bug. Action: add `?env:[\`Dev|\`Prod]` to `renderToStream`, thread it into `render_to_buffer`, and in `\`Prod` emit no `data-msg`/`data-stck` (or only a digest), matching `ReactServerDOM.Model.make_error_json` (ReactServerDOM.ml:177-186) and react-dom.

---

### Q5 — Which universal divergences are known/accepted vs bugs? (0-divergence contract)
**Answer:** "The contract is 0 divergences. We shipped an update into quickjs to fix all of them."
**Follow-up:** Verified in [`investigations/quickjs-divergence-status.md`](investigations/quickjs-divergence-status.md). The quickjs update fixed the number *primitives* and `Js.Float`/`Js.Number` now route through them — but divergences remain because:
1. `Belt.Float.toString`, `Belt.Int/Float.fromString` still use `Stdlib` (don't call quickjs).
2. `Js.Float.fromString`'s error path falls back to `Stdlib.float_of_string`.
3. `Js.Global.parseInt` uses `Quickjs.Global.parse_int` (int-capped), not `parse_int_float`.
4. Non-number divergences (Belt.HashMap 2.4, Js.String 2.14, Js.Date 2.15, url 2.22) are unrelated to quickjs.
Recommended: route the Belt/Js paths above through quickjs, and add a differential (native-vs-Melange) CI harness (design tension T3) so the 0-divergence contract is enforced, not hoped for.

---

### Q6 — Is `React.memo` incompatible? Fix it.
**Answer:** "Is it incompatible? Let's fix it."
**Follow-up:** Confirmed incompatible (reason-react `memo: component => component`, 1 arg; srr `memo f _component = f`, 2 args). Fix direction in [`investigations/memo-and-react-client.md`](investigations/memo-and-react-client.md).

---

### Q7 — Can we drop `@pedrobslisboa/react-client` and depend on React internals?
**Answer:** "Yes, that's a stability risk." + "We want our custom esbuild plugin, not shimming."
**Follow-up:** Confirmed direction. `packages/react-server-dom-esbuild/ReactServerDOMEsbuild.js` **is** the custom esbuild plugin (a genuine esbuild `$$$config`, not a webpack shim) and stays. The only fork dependency is the generic `react-client/flight` **factory** at line 30. Replace its provenance — build or vendor React's own `react-client/flight` pinned to an exact React SHA and ship it inside `server-reason-react-server-dom-esbuild` — without touching the esbuild config. No `react-server-dom-webpack`, no `__webpack_require__` shim (explicitly rejected). Pin exact versions immediately; add an encoder→decoder round-trip test in CI. Full analysis in [`investigations/memo-and-react-client.md`](investigations/memo-and-react-client.md).

---

## Still-open (no maintainer answer yet)

- **Q8** — Is dropping hoisted `<title>`/stylesheets for non-`<html>` roots intended (partial/`skipRoot` renders) or a bug? (2.11)
- **Q9** — RSC element rows are 7-tuples even in `env:\`Prod` (tests bless `["$",t,k,p,null,null,1]`); React prod emits 4-tuples. Is the client fork pinned to tolerate this, and is the `^19.1.0` caret (floats to 19.2+) a wire-format risk? (relates to Q7)
- **Q10** — Should `renderToStaticMarkup` emit Suspense comment markers? React's doesn't. (E2/2.x)
- **Q11** — Is `createPortal` meant to be inert server-side or render inline? (2.20)

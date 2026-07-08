# High findings

Wrong output, dropped data, information leaks, broken public APIs.

---

## 2.8 — `React.cloneElement` silently drops Style / Event / Ref / DangerouslyInnerHtml / Action props

- **Where:** `packages/react/src/React.ml:455-481`.
- **Status:** CONFIRMED.
- **Sync (2026-07-08, 4dc1fbb..4c0e871):** FIXED. `clone_attributes` now merges over all prop kinds with JS spread semantics (base order preserved, overridden in place, new appended); `compare_attribute`/`attributes_to_map`/sorting removed. Tests in test_cloneElement.ml (style/event/innerHTML survival, override position, order).
- **Issue:** `attributes_to_map` (455-466) only inserts `Bool`/`String` props into the merge map; `Style`, `Event`, `Ref`, `DangerouslyInnerHtml`, `Action` all fall through to `acc` unchanged and are never re-added. `clone_attributes` rebuilds only from the map, so those props vanish from the clone. The result is also re-sorted by `compare_attribute`, reordering vs React's insertion order.
- **Scenario:** `React.cloneElement(<div style=... onClick=... />, [extraProp])` → a `div` with the extra prop but **no style and no onClick**.
- **Secondary bug:** `compare_attribute` (436-445) Style branch: `Int.compare (String.compare a b) (String.compare c d)` — comparing two comparison results is meaningless (works by accident, produces an arbitrary but stable order).
- **Action:** Merge over *all* prop constructors (or, since only `Bool`/`String` are keyed by name, pass through non-keyed props unchanged into the output instead of dropping them). Preserve order.

---

## 2.9 — Error message + backtrace leaked into production HTML (`renderToStream`)

- **Where:** `packages/reactDom/src/ReactDOM.ml:436-442` (`write_suspense_fallback_error`).
- **Status:** CONFIRMED bug. Maintainer: "It should be both gated on env."
- **Sync (2026-07-08, HEAD 39e22a6):** PARTIALLY FIXED by #373 (bcbc9ac). `renderToStream` now takes `?env` (ReactDOM.ml:674) but it only gates the abort `$RX` message (:456-461). The original leak is untouched: `write_suspense_fallback_error` (:484-490) still writes `Printexc.to_string exn ^ backtrace` into `data-msg` unconditionally (called at :594, :629); `env` is not threaded into `render_to_buffer`. Finishing the fix is now trivial since `env` is in scope.
- **Sync (2026-07-08, 4dc1fbb..4c0e871):** FIXED. `env` threaded through `render_to_buffer`; `write_suspense_fallback_error` emits a bare `<template></template>` in `Prod` (no `data-msg`). Regression test `suspense_with_always_throwing_in_prod`.
- **Issue:** On a Suspense child error, the renderer writes `Printexc.to_string exn ^ "\n" ^ backtrace` into `data-msg="..."` unconditionally. There is no `env` parameter on `renderToStream` at all. React only emits error detail in dev builds. Contrast `ReactServerDOM.Model.make_error_json` (ReactServerDOM.ml:177-186) which correctly gates on `env` and emits only a digest in prod.
- **Scenario:** Any exception thrown inside a `<Suspense>` on a public page ships the OCaml exception string + full server backtrace to every visitor's HTML.
- **Action:** Add `?env` to `renderToStream` (and thread it into `render_to_buffer`); in `\`Prod`, emit no `data-msg`/`data-stck` (or only a digest), matching both React and the RSC path.

---

## 2.10 — `render_html`'s `?debug` parameter is silently ignored; no `filter_stack_frame`

- **Where:** `packages/reactDom/src/ReactServerDOM.ml:1088` (`?debug:(_ = false)`).
- **Status:** CONFIRMED.
- **Issue:** `render_html` binds `debug` to `_` and never uses it, and does not accept `filter_stack_frame`. `render_model` honours both. So `render_html ~debug:true` produces no debug info, contradicting the shared `~debug` convention.
- **Scenario:** A user turns on `~debug:true` for `render_html` to get owner/stack info in the RSC rows and gets nothing, with no error.
- **Action:** Thread `debug`/`filter_stack_frame` into `render_element_to_html`'s model emission, or drop the parameter from the signature so it can't be called with a false promise.

---

## 2.11 — Head-hoisted resources dropped when the root element is not `<html>`

- **Where:** `packages/reactDom/src/ReactServerDOM.ml:858-862` + `:884` (hoist + replace with `Html.null`), `:1017-1037` (`reconstruct_document`).
- **Status:** CONFIRMED.
- **Issue:** `<title>`/`<meta>`/`<link>`/async-`<script>` are pushed into `fiber.resources`/`extra_head_children` and replaced by `Html.null` in place. But `reconstruct_document` only re-emits those collections when `root_tag = Some "html"`. For any other root it returns `Html.list (root_html :: user_scripts)` (line 1037), and the hoisted content is silently discarded.
- **Scenario:** An RSC fragment (no `<html>` wrapper) containing `<title>New title</title>` or `<link rel="stylesheet" precedence="high" …>` → the title/stylesheet disappears from the output. The test suite even blesses a "deduplicated resources" case where two stylesheets vanish (test_RSC_html.ml:571-606).
- **Action:** When the root isn't `<html>`, still inject `resources`/`extra_head_children` (React streams late `<link>`/`<style>`/`<title>` inline for non-document renders). At minimum, don't silently drop them.

---

## 2.12 — `renderToStream` abort is a no-op

- **Where:** `packages/reactDom/src/ReactDOM.ml:640-643`.
- **Status:** CONFIRMED. Only test is commented out (test_renderToStream.ml:800).
- **Sync (2026-07-08, HEAD 39e22a6):** FIXED by #373 (bcbc9ac). `abort ()` now emits `$RX("B:<id>", …)` per pending boundary (tracked via `stream_context.pending_boundaries`, ReactDOM.ml:428, :603, :610-611) then closes idempotently; message is env-gated (:456-461); late completions guarded by `closed` (:612). Tests enabled: `abort_with_pending_boundaries`, prod variant, idempotency, noop-after-complete (test_renderToStream.ml:460-515). `render_html ?timeout` got matching behavior in the same commit.
- **Issue:** `abort ()` does `Lwt_stream.closed stream |> Lwt.ignore_result` — reads a promise and discards it. It neither closes the stream nor flushes fallbacks nor signals the client. The TODO admits it.
- **Scenario:** Client disconnects mid-stream → server keeps resolving suspended boundaries into a stream nobody reads; no cancellation, wasted work, and (with 2.2/2.3) potential push-after-close.
- **Action:** Implement React's abort semantics: flush remaining fallbacks (already in the shell) and emit `$RX(...)` client-retry markers per pending boundary, then close. Exact required output captured in [`../investigations/react-abort-timeout.md`](../investigations/react-abort-timeout.md).

---

## 2.13 — Errors swallowed in `client_to_html` Suspense → blank regions, no diagnostics

- **Where:** `packages/reactDom/src/ReactServerDOM.ml:637-639`, `:674`, `:679-682`.
- **Status:** CONFIRMED.
- **Issue:** `client_to_html` catches `_exn` and returns `Html.null` or an empty boundary chunk. A throwing client subtree under Suspense yields blank HTML with no error row and no error-boundary behavior.
- **Scenario:** An exception in a client-rendered child under `<Suspense>` → silently empty region; no error surfaced to the client or logs.
- **Action:** Emit an error boundary chunk (`$!` / error row) so the client can retry or show an error boundary, matching React; at minimum log/propagate.

---

## 2.14 — `Js.String` is byte-oriented against a UTF-16-indexed regex engine

- **Where:** `packages/Js/lib/Js_string.ml` — infinite loops `:182-286`; UTF-8 corruption `:191-281`; byte length/indexing `:19-84`; `Str`-based `replace` `:120-122`.
- **Status:** CONFIRMED (agent probes). Partially in scope of the quickjs work — see [`../investigations/quickjs-divergence-status.md`](../investigations/quickjs-divergence-status.md).
- **Issue (multiple):**
  - `replaceByRe`/`splitByRe` with an empty-matching regex (`/x*/g`) infinite-loop.
  - quickjs returns UTF-16 indices but the code uses them as UTF-8 byte offsets → `replaceByRe /b/ "éb"` → `"\195Xb"` (corrupt).
  - `length "é"`=2 (JS 1); `charCodeAt "é"`=195 (JS 233); `codePointAt`, `get`, `charAt` all byte-based.
  - Negative-index `startsWith`/`endsWith`/`includes`/`indexOf`/`slice`/`substr` raise `Invalid_argument` or clamp wrong, where JS returns benignly.
  - `replace` uses `Str.replace_first` → a replacement containing `\1` raises `Failure`; `$&` is not interpreted as in JS.
- **Scenario:** Any non-ASCII text through these functions diverges or crashes on the server while working in the browser.
- **Action:** Make index-taking/-returning functions operate on UTF-16 code units to match JS (or route through quickjs consistently), fix empty-match loops, clamp negative indices, and reimplement `replace` with JS `$`-semantics.

---

## 2.15 — `Js.Date` local/UTC parsing wrong for the two most common formats

- **Where:** `packages/Js/lib/Js_date.ml:386` (ISO no-TZ as UTC), `:460` (legacy as UTC), `:384` (trailing garbage accepted), `:131-143` (DST-wrong local offset), setters immutable `:471`.
- **Status:** CONFIRMED (agent probes with `TZ=Europe/Madrid`).
- **Issue:** ES2015+ treats ISO datetimes *without* a timezone designator, and all legacy formats, as **local** time; this code computes them as **UTC**. `Js.Date.fromString (Js.Date.toUTCString d)` returns NaN (can't round-trip its own output). Setters don't mutate (Melange mutates).
- **Scenario:** `Js.Date.parseAsFloat "2024-06-15T10:00:00"` differs from the browser by the local UTC offset → any rendered date is a hydration mismatch.
- **Action:** Follow ECMA-262 date parsing (local unless TZ present), validate the whole string, fix the local-offset computation around DST.

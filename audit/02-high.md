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
- **Sync (2026-07-09, worktree):** FIXED. `debug`/`filter_stack_frame` threaded via `Fiber.t`; `continue_with_debug_html` mirrors `Model.attach_debug_info`/`outline_with_debug_ref` (first component attaches to root row, nested components outlined with `D` refs, `~owner` threaded through every `Model.node` in the HTML path); `?filter_stack_frame` added to the `.mli`. Tests `debug_adds_debug_info`, `debug_nested_owner_chain`, `debug_async_component_owner_chain`, `debug_not_emitted_without_flag` (test_RSC_html.ml) pin the same wire format as the render_model debug tests; the stale disabled test was replaced.
- **Issue:** `render_html` binds `debug` to `_` and never uses it, and does not accept `filter_stack_frame`. `render_model` honours both. So `render_html ~debug:true` produces no debug info, contradicting the shared `~debug` convention.
- **Scenario:** A user turns on `~debug:true` for `render_html` to get owner/stack info in the RSC rows and gets nothing, with no error.
- **Action:** Thread `debug`/`filter_stack_frame` into `render_element_to_html`'s model emission, or drop the parameter from the signature so it can't be called with a false promise.

---

## 2.11 — Head-hoisted resources dropped when the root element is not `<html>`

- **Where:** `packages/reactDom/src/ReactServerDOM.ml:858-862` + `:884` (hoist + replace with `Html.null`), `:1017-1037` (`reconstruct_document`).
- **Status:** CONFIRMED.
- **Sync (2026-07-09, worktree):** FIXED. `reconstruct_document`'s non-`<html>` branch now emits `sort_head_children (resources @ extra_head_children)` before the root (no `<head>` wrapper), matching react-dom 19.1.0's unconditional preamble for non-document renders (verified against the vendored react-dom: stylesheets → async scripts → title/meta in discovery order, deduped). A literal `<head>` under a fragment root keeps its wrapper; `skipRoot` also emits hoistables. Tests: `fragment_root_hoists_resources`, `fragment_root_dedupes_stylesheets`, `fragment_root_with_skip_root_keeps_hoistables`; `input_and_bootstrap_scripts` updated (modulepreload links no longer dropped). Note: the audit's "blessed dedup-drop test" (`page_with_duplicate_resources`) was dead code, never registered. Follow-up (both root kinds): hoistables discovered after the shell (inside pending Suspense boundaries) are still lost; React streams them with the boundary.
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
- **Sync (2026-07-09, worktree):** FIXED. `client_to_html`'s `Upper_case_component` catch re-raises (a throw with no Suspense above now rejects the render, matching every other branch; a server-side Suspense above still yields the `E`-row path). Under a client-side Suspense: pre-flush errors emit `<!--$!--><template>` errored-boundary markup (`html_suspense_client_render`, env-gated like 2.9 — bare template in Prod); post-flush async failures stream `$RX("B:<id>", …)` via the generalized `client_render_boundary_to_chunk ~message` (dev-only message, digest-only in Prod); the `$RX` definition is deduplicated once per stream (`Stream.take_rx_definition`, shared with the timeout path). Tests: `client_with_sync_error_under_client_suspense(_in_prod)`, `client_with_async_error_under_client_suspense(_in_prod)`, `client_with_error_without_suspense`, `client_with_error_under_server_suspense`.
- **Issue:** `client_to_html` catches `_exn` and returns `Html.null` or an empty boundary chunk. A throwing client subtree under Suspense yields blank HTML with no error row and no error-boundary behavior.
- **Scenario:** An exception in a client-rendered child under `<Suspense>` → silently empty region; no error surfaced to the client or logs.
- **Action:** Emit an error boundary chunk (`$!` / error row) so the client can retry or show an error boundary, matching React; at minimum log/propagate.

---

## 2.14 — `Js.String` is byte-oriented against a UTF-16-indexed regex engine

- **Where:** `packages/Js/lib/Js_string.ml` — infinite loops `:182-286`; UTF-8 corruption `:191-281`; byte length/indexing `:19-84`; `Str`-based `replace` `:120-122`.
- **Status:** CONFIRMED (agent probes). Partially in scope of the quickjs work — see [`../investigations/quickjs-divergence-status.md`](../investigations/quickjs-divergence-status.md).
- **Sync (2026-07-09, worktree):** FIXED, one pass. Representation stays `t = string` (UTF-8); every index-taking/-returning function now operates on UTF-16 code units via `Quickjs.String.Prototype` (the pinned quickjs exposes `utf16_index_of_byte`/`byte_index_of_utf16` boundary converters). `replaceByRe` rewritten as an exec loop on the original string with spec `AdvanceStringIndex` (empty-match advance, unicode-aware over surrogate pairs) and UTF-16→byte slicing; `splitByRe` follows `Symbol.split` (capture splicing, ToUint32 `~limit` honored — previously ignored); `match_` global returns all matches (was capped at 2); `replace`/`split` no longer use `Str` (thread-unsafety removed; `str` and `uucp` dropped from the package deps); `fromCharCode(Many)`/`fromCodePoint(Many)` implemented with surrogate pairing; `trim` uses the ECMA whitespace set; `toLowerCase`/`toUpperCase` context-sensitive. Verified against node v22 on a 38-probe differential corpus (byte-identical). Known inherent divergence: lone surrogates surface as U+FFFD (UTF-8 can't encode them); UTF-16 indices remain correct. Js test suite 896 → 914.
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
- **Sync (2026-07-09, worktree):** FIXED. ISO datetimes without a designator and legacy formats parse as local per ECMA-262 (date-only forms stay UTC); every parse path requires full-string consumption (trailing garbage → NaN; malformed offsets fail instead of defaulting to 0); `local_to_utc` implements `LocalTZA(t, false)` (spring gap and fall ambiguity resolve to the pre-transition offset); `fromString (toUTCString d)` and `fromString (toString d)` round-trip (weekday comma stripped, both `Mon DD YYYY` and RFC-1123 `DD Mon YYYY` orders). Setters mutate: `t` is now an abstract mutable record (maintainer decision), matching Melange's receiver-mutating setters that return the new timestamp. Differential-tested against node (70/71 identical; the one divergence — `"2000-"` → NaN vs V8's lenient year-2000 — is deliberate and documented in code). New TZ-pinned tests incl. all six DST probes (`date_tests/local_time.ml`); Js suite green under six timezones.
- **Issue:** ES2015+ treats ISO datetimes *without* a timezone designator, and all legacy formats, as **local** time; this code computes them as **UTC**. `Js.Date.fromString (Js.Date.toUTCString d)` returns NaN (can't round-trip its own output). Setters don't mutate (Melange mutates).
- **Scenario:** `Js.Date.parseAsFloat "2024-06-15T10:00:00"` differs from the browser by the local UTC offset → any rendered date is a hydration mismatch.
- **Action:** Follow ECMA-262 date parsing (local unless TZ present), validate the whole string, fix the local-offset computation around DST.

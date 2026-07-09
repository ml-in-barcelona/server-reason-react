# Medium findings

Divergences, footguns, missing behavior.

---

## 2.16 — Numeric parse/format divergences (silent hydration-mismatch fuel)

- **`Belt.Float.toString`** — `packages/Belt/src/Belt_Float.ml:5-8` uses `Stdlib.string_of_float` (`%.12g`): `0.30000000000000004`→`"0.3"`, `nan`→`"nan"` (JS `"NaN"`), `infinity`→`"inf"` (JS `"Infinity"`). Does **not** route through quickjs. CONFIRMED.
- **`Belt.Int.fromString`** — `Belt_Int.ml:4-7` uses `int_of_string_opt`/`float_of_string`: `"10px"`→`None` (Melange `Some 10`), `"0x10"`→`Some 16` (Melange `Some 0`), `" 42 "`→`None`. CONFIRMED.
- **`Belt.Float.fromString`** — `Belt_Float.ml:3`: `"3.5px"`→`None` (Melange `Some 3.5`). CONFIRMED.
- **`Js.Float.fromString`** — `Js_float.ml:45` falls back to `Stdlib.float_of_string` on the error path: `"abc"` raises `Failure` (JS `NaN`), `"1_0"`→`10.` (JS `NaN`). CONFIRMED.
- **`Js.Global.parseInt`** — `Js_global.ml:205` uses `Quickjs.Global.parse_int` (int-capped) instead of `parse_int_float`: `parseInt "99999999999999999999999999"`→`nan` (JS `1e26`). CONFIRMED.
- **`Js.Math._SQRT2`** — `Js_math.ml:25` = `1.41421356237` (truncated; JS `1.4142135623730951`). CONFIRMED.
- **`React.float`** — `React.ml:539` = `Text (string_of_float f)`: `1.0`→`"1."` (JS `"1"`). Code comment admits it. CONFIRMED.
- **Action:** Route `Belt.Float.toString` through `Quickjs.Number.to_string`; `Belt.Int/Float.fromString` and `Js.Float.fromString` and `Js.Global.parseInt` through the quickjs `parse_*`/`parse_int_float` primitives. Fix `_SQRT2`. Decide `React.float`/`React.int` formatting to match React's `Number.prototype.toString`. See [`../investigations/quickjs-divergence-status.md`](../investigations/quickjs-divergence-status.md).
- **Sync (2026-07-08, HEAD 39e22a6):** FIXED. #372 (7cb72d0) routed `Belt_Float.ml:7,12`, `Belt_Int.ml:9`, `Js_float.ml:26-31,61-66`, `Js_global.ml:141` through quickjs and fixed `_SQRT2` (Js_math.ml:25). #374 (b04951c) fixed `React.float` — now a `Float` element variant rendered via `Js.Float.toString` (React.ml:552, ReactDOM.ml:47,159).

---

## 2.17 — ~200 universal-lib functions raise `Impossible_in_ssr` at runtime with no compile-time signal

- **Where:** `Js.Math` (all but sin/cos + constants, `Js_math.ml:28-79`), all of `Js.Json`, `Js.Global` timers, `Js.Exn` accessors, most `Js.Array` mutators, `Fetch.fetch` and the whole `Fetch` surface, `Fetch.AbortController` (a silent no-op, `Fetch.ml:20-31`), and nearly all of `webapi`. Runtime raise from `packages/runtime/Runtime.ml:3-16`.
- **Status:** CONFIRMED (agent).
- **Issue:** The `melange_ppx`-generated raising stubs carry **no `[@alert]`** (unlike `browser_ppx`'s `let%browser_only`), so server-side misuse compiles clean and only fails at runtime. Each failure prints two banners to **stdout** first (Runtime.ml:6-15), which can corrupt stdout-based output.
- **Action:** Attach `[@alert browser_only]` to the melange_ppx-generated arrow stubs so misuse is a compile-time warning; print the banner to **stderr**, not stdout. See [`areas/webapi-dom.md`](areas/webapi-dom.md), [`areas/belt-js.md`](areas/belt-js.md).

---

## 2.18 — `melange_ppx` destroys native externals and mis-orders `mel.send.pipe` types

- **Where:** `packages/melange.ppx/ppx.ml` — `[@platform native]` not in pass-through (`:455-462`); zero-arg `send.pipe` reversal (`:692-694`); `[@mel.as]` phantom arg (`:657-668`).
- **Status:** CONFIRMED (agent, verified against `.cmi`).
- **Issue:** A genuine native external inside universal code (or a `[@platform native]` include) is rewritten into a raising stub on the platform it targets. Zero-arg `[@mel.send.pipe]` externals get reversed types (`ret -> t` instead of `t -> ret`), breaking `event |> Event.preventDefault` — the most common webapi call — at native compile time. `[@mel.as]` constant args become phantom `'a` params (arity drift).
- **Action:** Add `[@platform native]` / no-attribute externals to the pass-through path; fix the `send.pipe` arg insertion for the zero-arg and non-`Ptyp_constr` cases. See [`areas/ppx.md`](areas/ppx.md).

---

## 2.19 — `browser_ppx` footguns: `Obj.magic ()` segfault, arity collapse, silent keep

- **Where:** `packages/browser-ppx/ppx.ml:220-222` (`Obj.magic ()`), `:53-65` (arity collapse), `:227` (silent keep), `:15-45` (`switch%platform` drops guards/scrutinee).
- **Status:** CONFIRMED (agent, `Obj.magic` path reproduced as SIGSEGV).
- **Issue:** `let%browser_only x = <ident>` compiles to `let x = Obj.magic ()` typed `'a` — unifies with anything, calling it segfaults. Multi-param `let%browser_only f a b = …` collapses to arity 1 (partial application raises during SSR even though the closure is never invoked). Unmatched shapes silently keep the browser body on native. `switch%platform` drops `when` guards and discards the scrutinee's side effects.
- **Action:** Replace the `Obj.magic ()` path with a raising stub carrying `[@alert]`; preserve arity; error (don't silently keep) on unhandled shapes. See [`areas/ppx.md`](areas/ppx.md).

---

## 2.20 — `createPortal` renders children inline instead of nothing

- **Where:** `packages/reactDom/src/ReactDOM.ml:655`; docstring `ReactDOM.mli:48-49`.
- **Status:** CONFIRMED.
- **Issue:** `createPortal reactElement _ = reactElement` renders the portal's children inline at the current position; the `.mli` says "Does nothing on the server."
- **Scenario:** A modal in a portal renders inside the current node server-side, then React relocates it on hydration → mismatch + wrong initial paint.
- **Action:** Decide the contract. If portals should be inert server-side, return `Empty` and document it; otherwise document that it renders inline and note the hydration implication.

---

## 2.21 — `.mli` docstrings lie about failure mode for `querySelector`/`render`/`hydrate`

- **Where:** `packages/reactDom/src/ReactDOM.mli:39-46` vs `ReactDOM.ml:650-652`.
- **Status:** CONFIRMED.
- **Issue:** Documented "Does nothing on the server" / "always returns None", but they call `Runtime.fail_impossible_action_in_ssr` → **raise** + stdout spew.
- **Action:** Either make them actually inert (return `None`/`()`), or fix the docstrings to say they raise. Given they're "compatibility with reason-react" stubs, inert is probably intended.

---

## 2.22 — `url` native diverges pervasively from WHATWG; `makeWith` is broken

- **Where:** `packages/url/native/URL.re` — `makeExn` only rejects empty (`:125-135`), no normalization (`:273`), default ports kept (`:197-202`), IPv6 brackets lost (`:150-158`), `getAll` returns first only (`:75-91`), commas re-joined with `""` (`:5`), `setHref` no-op (`:178-181`), `setPort ""` raises (`:204-206`), `makeWith` resolution broken (`:144-148`).
- **Status:** CONFIRMED (agent, probed against `ocaml-uri`).
- **Issue:** Native uses RFC3986 `ocaml-uri`, not WHATWG. `makeWith("https://other.com/x", ~base="https://a.com")` → `"https://a.com/https://other.com/x"` instead of the absolute URL. Same `.rei` for both platforms (via `copy_files#`), so it compiles then behaves differently. The `js/URL.re` wrapper independently has inverted `append`/`delete`/`set` (mutates input, returns stale copy, `:21-53`).
- **Action:** Move native to a WHATWG-conformant implementation (or document the RFC3986 subset as the contract, contradicting the 0-divergence goal). See [`areas/url-fetch-promise.md`](areas/url-fetch-promise.md).

---

## 2.23 — Native `promise` callbacks never run; `Promise.all([])` hangs

- **Where:** `packages/promise/native/promise.re:216-239` (`ReadyCallbacks` with no driver), `:397-469` (`all []` never resolves).
- **Status:** CONFIRMED (agent).
- **Issue:** The vendored aantron/promise on native pushes settled-promise callbacks into a global `ReadyCallbacks` queue that nothing drains (no driver anywhere in the repo), so `Promise.get`/`then` callbacks never fire and the queue grows unbounded; `all []` never resolves. The codebase actually uses Lwt-backed `Js.Promise` instead — a separate, unbridged async world.
- **Action:** Either wire a driver / bridge to Lwt, or remove the vendored native promise if unused, to avoid a live trap. See [`areas/url-fetch-promise.md`](areas/url-fetch-promise.md).

---

## 2.24 — Self-closing tag list & serialization diverge from react-dom (byte-level)

- **Where:** `packages/html/Html.ml:4-5` (tag list incl. non-void `image`/`basefont`/`bgsound`/`command`/`frame`), `:98` + `ReactDOM.ml:249` (`" />"` with space), `:26` (`'`→`&apos;`) vs `:194` (`'`→`&#x27;`).
- **Status:** CONFIRMED.
- **Issue:** react-dom emits void tags as `/>` (no space) and escapes `'` as `&#x27;` everywhere; here text/attribute escaping uses `&apos;` but the RSC attribute escaper uses `&#x27;`. `image` etc. aren't void in React's list.
- **Scenario:** Byte-level hydration divergences; `image` treated as self-closing wrongly.
- **Action:** Align the void-tag list with React's, drop the space, and unify on `&#x27;`.

---

## 2.25 — Four HTML serializers with drifting rules

- **Where:** `Html.to_string` (`Html.ml:74-135`), `Html.pp` (`:138-179`), `ReactDOM.render_to_buffer` (`ReactDOM.ml:141-265`), `ReactDOM.write_to_buffer` (`ReactDOM.ml:267-358`, public via `.mli:30`, used by PPX `Writer` tier `server_reason_react_ppx.ml:510`).
- **Status:** CONFIRMED.
- **Issue:** Doctype logic lives in three of the four; `write_to_buffer` omits doctype, text separators, and Suspense markers. A subtree emitted via the PPX `Writer` tier follows different rules than a variant subtree in the same document.
- **Scenario:** A `Writer`-tier subtree at document root won't emit `<!DOCTYPE html>`; text-node comment separators differ between paths.
- **Action:** Collapse to one serializer parameterized by mode; have the PPX `Writer` tier and RSC reuse it. See design tension T4/T5.
- **Sync (2026-07-09, worktree):** Two concrete manifestations fixed in the RSC HTML path (found live in the demo — `/demo/singlePageRSC` crashed at HEAD): (1) `Writer` subtrees containing client components crashed `render_html` (`write_to_buffer` raises on `Client_component`; it also renders Suspense without boundary markers) — the RSC path now renders `Writer` via the regular walk (which it already performed for the model) instead of the prerendered emit, in both `render_element_to_html` and `client_to_html`; regression test `writer_subtree_with_client_component`. (2) `Static` prerendered bytes still contained hoistables that the model walk had hoisted, duplicating them in the shell — the `Static` branch now uses the walked HTML when the walk hoisted anything (`Fiber.hoisted_count`); regression test `static_subtree_hoistables_not_duplicated`. The structural four-serializers problem remains open.

---

## 2.26 — `bootstrapScriptContent` injected raw (`</script>` breakout)

- **Where:** `packages/reactDom/src/ReactServerDOM.ml:1058`.
- **Status:** PLAUSIBLE (caller-controlled, but the API invites dynamic strings).
- **Issue:** User content is wrapped in `<script>` via `Html.raw` with no escaping. React escapes `<`/`/` (e.g. `\u003c`). Content containing `</script>` or `<!--` breaks out. The RSC *payload* itself is safe (single-quoted attribute + `escape_attribute_value`).
- **Action:** Escape `bootstrapScriptContent` for the script-data context (`</` → `<\/`, `<!--` → `<\!--`) as react-dom does.
- **Sync (2026-07-08, 4dc1fbb..4c0e871):** FIXED. Added `Html.escape_entire_inline_script` (exact port of react-dom's `escapeEntireInlineScriptContent`: unicode-escapes the `s` of `<script`/`</script`, case-insensitive) and applied it at the `bootstrapScriptContent` injection site. Test `bootstrap_script_content_cannot_break_out_of_script` (test_RSC_html_shell.ml).

---

## 2.27 — `useState` runs the updater eagerly during init

- **Where:** `packages/react/src/React.ml:645-651`.
- **Status:** CONFIRMED.
- **Issue:** `setState fn = let _ = fn initial_value in ()` — ignores the result but *executes* `fn`, running any side effects. React's server setter is a no-op.
- **Scenario:** `setState (fun s -> log s; s+1)` runs `log` synchronously on the server.
- **Action:** Make the setter a true no-op: `let setState _ = ()`.

---

## 2.28 — `Children.only` / `Children.toArray` diverge from React

- **Where:** `packages/react/src/React.ml:852-862`.
- **Status:** CONFIRMED.
- **Issue:** `only` returns the first child of a multi-child list instead of raising (React throws when not exactly one child); `toArray` wraps in a 1-element array without flattening/keying.
- **Action:** Match React semantics (`only` raises unless exactly one; `toArray` flattens and assigns keys).

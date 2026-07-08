# Critical findings

Data loss, process crashes, silent corruption, memory-unsafety.

---

## 2.1 — Concurrent streaming renders corrupt each other's `useId` via global state

- **Where:** `packages/react/src/React.ml:747-750` (globals), used across `packages/reactDom/src/ReactDOM.ml:626` and `packages/reactDom/src/ReactServerDOM.ml:1091`, mutated across `let%lwt` points throughout both.
- **Status:** CONFIRMED (traced). **Severity downgraded to a documented constraint** per maintainer: "for now it's fine to be running on a single process."
- **Sync (2026-07-08, HEAD 39e22a6):** CONSTRAINT in intent, OPEN in execution — the constraint was never written into docs/`.mli` (no note exists anywhere), and the globals are unchanged (React.ml:761-764, exposed at React.mli:704).
- **Sync (2026-07-08, 4dc1fbb..4c0e871):** CONSTRAINT, now documented — comment + TODO on the globals in React.ml, doc notes on `useId` and `current_tree_context` in React.mli. The real fix (request-scoped state) remains TODO before enabling concurrent renders.
- **Issue:** `current_tree_context`, `local_id_counter`, `did_render_id_hook`, `identifier_prefix` are process-global refs. The save/restore discipline around recursion only protects a synchronous slice. When a render suspends on Lwt (async component, suspended boundary) and another render runs, they clobber each other's tree context.
- **Scenario:** Two concurrent `renderToStream` requests, each with an async component that calls `useId`. Request A suspends; request B calls `reset_id_rendering`/`reset_component_id_state`, overwriting the globals; A resumes and computes IDs from B's tree position → server-emitted `id`/`for`/`aria-*` differ from what the client's single-threaded hydration computes → React discards the server tree and re-renders (hydration mismatch), silently and load-dependently.
- **Why it's invisible today:** All tests are sequential; single-process deployment serializes renders in practice as long as only one render is ever in flight *and yielding* at a time. But two overlapping `renderToStream`/`render_html`/`render_model` calls on one process already interleave at Lwt yields even without multicore.
- **Action:**
  1. Write down the constraint explicitly (docs + `.mli` note): "Do not run two async renders concurrently in one process until useId state is request-scoped."
  2. Real fix (before enabling concurrency): move tree-context state out of module globals into either an `Lwt.key` (like `React.Cache`/`Context` already do) or an explicit parameter threaded through the renderer, so each render has its own.
- See also: [`../investigations/react-abort-timeout.md`](../investigations/react-abort-timeout.md) is unrelated but in the same engine; design tension T1.

---

## 2.2 — `renderToStream` closes the stream before the shell is pushed → `Lwt_stream.Closed`

- **Where:** `packages/reactDom/src/ReactDOM.ml:396-404` (`stream_context`), `:554` / `:571-573` (counter + close), `:646` (shell push).
- **Status:** CONFIRMED (traced). `Lwt_stream.push`-after-`close` raises `Lwt_stream.Closed` (`_opam/lib/lwt/lwt_stream.mli:39,88`).
- **Sync (2026-07-08, HEAD 39e22a6):** STILL OPEN. #373 (bcbc9ac) added an idempotent `close_stream` (ReactDOM.ml:431-434) and moved the boundary close-check inside the `closed` guard (:612-622), but `waiting` still starts at 0 (:683) and the shell push (:710) is unguarded — the prescribed fix (count the root walk as a pending unit, like `render_html`'s `~pending:1`) was not applied. Note: this rejects the `renderToStream` promise, it does not kill the process.
- **Sync (2026-07-08, 4dc1fbb..4c0e871):** FIXED. The root walk now counts as a pending unit ([waiting = 1] seed, decremented after the shell push), and the shell push is guarded by [closed]. Regression test `boundary_resolves_while_shell_is_suspended` (test_renderToStream.ml) reproduces the race with a once-pausing boundary and fails on the old code.
- **Issue:** `stream_context.waiting` counts only spawned Suspense boundaries, not the root walk. A boundary's `Lwt.async` block decrements `waiting` and calls `close ()` when it hits 0 (ReactDOM.ml:571-573). If the sole boundary's promise resolves before the main walk reaches line 646, the stream is already closed and the shell push raises.
- **Scenario:** `<html><body><Suspense fallback><AsyncResolvesImmediately/></Suspense></body></html>` where rendering the fallback awaits (it goes through `render_to_buffer` which is Lwt). The boundary's async runs, `waiting` → 0, `close()`. Back in the main walk, `push_to_stream (Buffer.contents buf)` (646) raises `Lwt_stream.Closed`; `renderToStream`'s returned promise rejects with an opaque exception after partial content already streamed.
- **Contrast:** `render_html` gets this right by seeding `pending:1` for the root and decrementing it only after the shell is built (ReactServerDOM.ml:1104, 1122-1124). `renderToStream` should do the same.
- **Action:** Count the root walk as a pending unit from the start; decrement it after `push_to_stream (Buffer.contents buf)`; only `close` when the counter (including root) is 0.

---

## 2.3 — `render_html` timeout closes the stream, then in-flight boundaries push into it → process exit

- **Where:** `packages/reactDom/src/ReactServerDOM.ml:1159-1163` (timeout closes stream), `:84-94` (`push_async` pushes unconditionally, no `closed` guard).
- **Status:** CONFIRMED (traced). Maintainer confirmed no `Lwt.async_exception_hook` override exists.
- **Sync (2026-07-08, HEAD 39e22a6):** FIXED by #373 (bcbc9ac). `Stream.t` gained `mutable closed` (ReactServerDOM.ml:91), `close` is idempotent (:126-129), every push is guarded by `if not context.closed` (:134, :218-223), root seeded as `~pending:1` (:1549), and timeout now rejects pending rows with error rows and emits `$RX` per pending boundary before closing (:1613-1637). A boundary resolving after timeout drops its chunk instead of raising into `Lwt.async_exception_hook`.
- **Issue:** On timeout the code sets `context.pending <- 0; context.close ()`. But `Stream.push_async` blocks spawned earlier resolve later and call `context.push (...)` with no check that the stream is closed. Push-after-close raises `Lwt_stream.Closed` inside an `Lwt.async` with no surrounding `try`, so it escapes to `Lwt.async_exception_hook`. Lwt's **default hook prints the exception and calls `exit 2`** — the whole server process dies.
- **Why an `async_exception_hook` is "needed" (answer to the maintainer's question):** It isn't the correct fix — installing one would only *mask* the crash by swallowing a real bug. The correct fix is to make `push`/`close` idempotent and guard every async push with the `closed` flag (exactly as `renderToStream` already does at ReactDOM.ml:561). The reason the process currently dies is precisely that there is no hook to swallow it; the fix is to never raise, not to catch.
- **Scenario:** A page with a boundary that takes 6s, rendered with `~timeout:5.`. At t=5s the stream closes; at t=6s the boundary resolves and `context.push` raises `Lwt_stream.Closed` → uncaught in `Lwt.async` → process exits. A single slow render can take down the server.
- **Action:**
  1. Add a `mutable closed : bool` to `ReactServerDOM.Stream.t` (mirror `ReactDOM.stream_context.closed`).
  2. In `push`/`push_async`, no-op if `closed`.
  3. Make `close` idempotent.
  4. Additionally implement the correct timeout behavior (flush pending fallbacks + `$RX` markers) — see [`../investigations/react-abort-timeout.md`](../investigations/react-abort-timeout.md).

---

## 2.4 — `Belt.HashMap.Int` / `Belt.HashMap.String` lose data nondeterministically (FFI misuse)

- **Where:** `packages/Belt/src/caml_hash.ml:9-10`; consumed by `Belt_HashMapInt.ml:8`, `Belt_HashMapString.ml:8`.
- **Status:** CONFIRMED (agent reproduced against the built `belt.cmxa`).
- **Sync (2026-07-08, 4dc1fbb..4c0e871):** FIXED. caml_hash.ml rewritten on pure `Int32` arithmetic (no externals, no nativeint); both hashmap consumers updated. Regression tests with interleaved allocations in Test_Belt_HashMap_Int.ml/Test_Belt_HashMap_String.ml.
- **Issue:** `external ( *~ ) : nativeint -> nativeint -> nativeint = "caml_int32_mul"` (and `+~` = `caml_int32_add`) apply the **int32** C primitives to **nativeint** boxes. `caml_copy_int32` allocates a 4-byte payload; the `Nativeint.*` operations then read a full 8-byte word, folding uninitialized heap memory into the hash. `rotl32`'s `x >>> (32-n)` mixes that garbage into the low bits. Result: hashing the same key twice, with unrelated allocation in between, yields different buckets ~73–79% of the time.
- **Scenario:** `Belt.HashMap.String.set h "hello" 1; <allocate>; Belt.HashMap.String.get h "hello"` → `None` (key lost). Setting key `42` twice can produce `size = 2` (duplicate). `Belt.HashSet.Int/String` are *not* affected (they use `Stdlib.Hashtbl`); generic `Belt.HashMap` with a user `~id` hash is safe.
- **Why undetected:** The tests are single-key smoke tests with no allocation between `set` and `get`.
- **Action:** Reimplement the MurmurHash mixing in pure `Int32`/`int` arithmetic (no int32-primitive-on-nativeint), or route through a correct native hash. This is universal-code poison: works on the client, corrupts on the server.

---

## 2.5 — `Belt.Option.getUnsafe` is a memory-unsafe `%identity`

- **Where:** `packages/Belt/src/Belt_Option.ml:26`, `.mli:70`.
- **Status:** CONFIRMED (agent probe).
- **Sync (2026-07-08, 4dc1fbb..4c0e871):** FIXED. Real pattern match; `None` raises `Invalid_argument`. Tests in Test_Belt_Option.ml.
- **Issue:** `external getUnsafe : 'a option -> 'a = "%identity"` is a valid unboxing trick in Melange (JS `Some x` is `x`) but type-unsound in native OCaml where `Some x` is a boxed block. It returns the block pointer reinterpreted as `'a`. For `'a = string` this reads block-header bytes as string data → potential segfault. The `.mli` docstring "returns x" is false.
- **Scenario:** `Belt.Option.getUnsafe (Some 42)` returns a heap address, not `42`.
- **Action:** Implement natively as `function Some x -> x | None -> <undefined behavior sentinel / raise>` (it's "unsafe" by contract; matching Melange's *observable* behavior for `Some x` is what matters — return `x`).

---

## 2.6 — Runtime `domProps` attribute names drifted from the PPX's `DomProps.ml`

- **Where:** `packages/reactDom/src/ReactDOM.ml:1624-1632` vs `packages/server-reason-react-ppx/DomProps.ml:1381-1391`.
- **Status:** CONFIRMED.
- **Sync (2026-07-08, 4dc1fbb..4c0e871):** FIXED. All three mappings corrected in ReactDOM.ml and DomProps.ml (`xlink:actuate`/`xlink:arcrole`/`xmlns:xlink`); svg_2 ppx test expectation updated, renderToString regression test added. The single-table generation (T4) remains open.
- **Issue:** The hand-written `ReactDOM.domProps` (used by `createDOMElementVariadic` and non-JSX callers) has copy-paste bugs that the PPX source does not:
  - `xlinkActuate` → `"xlink:arcrole"` (ReactDOM.ml:1624). Should be `"xlink:actuate"`. DomProps.ml:1381 is correct (`xlink:actuate`).
  - `xlinkArcrole` → literal `"xlinkArcrole"` (ReactDOM.ml:1625). Should be `"xlink:arcrole"`. DomProps.ml:1382 is correct.
  - `xmlnsXlink` → literal `"xmlnsXlink"` in **both** ReactDOM.ml:1632 and DomProps.ml:1391. Should be `"xmlns:xlink"`.
- **Scenario:** SVG built via `ReactDOM.domProps ~xlinkActuate:"onLoad"` emits `xlink:arcrole="onLoad"` — silently wrong attribute.
- **Action:** Fix the three mappings; better, generate both `DomProps.ml` and `ReactDOM.domProps` from a single table (design tension T4).

---

## 2.7 — `defaultChecked` / `defaultValue` render as literal HTML attributes

- **Where:** `packages/server-reason-react-ppx/DomProps.ml:481-482`, `packages/reactDom/src/ReactDOM.ml:1206-1207`.
- **Status:** CONFIRMED.
- **Sync (2026-07-08, 4dc1fbb..4c0e871):** FIXED. Both the PPX table and runtime `domProps` now map `defaultChecked`→`checked` (bool) and `defaultValue`→`value` (string). renderToString regression test added.
- **Issue:** Both paths map `defaultChecked`→attribute `"defaultChecked"` and `defaultValue`→attribute `"defaultValue"`. React maps these to the *DOM* attributes `checked`/`value` on server output (that's the entire point of `defaultChecked` — it sets the initial rendered state).
- **Scenario:** `<input defaultChecked=true />` → server emits `<input defaultChecked />` (a meaningless boolean attribute; the checkbox renders **unchecked**). Client hydrates to checked → visible flash + controlled/uncontrolled mismatch.
- **Action:** Map `defaultChecked` → `checked` (bool) and `defaultValue` → `value` (string) in both the PPX table and the runtime `domProps`.

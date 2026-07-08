# Area — Core rendering (React, ReactDOM, ReactServerDOM)

Cross-references the numbered findings; this file records the render-path specifics.

## React.ml
- Global render-id state (`:747-750`) — design tension T1 / finding 2.1.
- `cloneElement` drops non-`Bool`/`String` props (`:455-481`) — 2.8; `compare_attribute` Style branch is nonsense (`:440-444`).
- `useState` setter executes the updater (`:645-651`) — 2.27.
- `Children.only`/`toArray` diverge (`:852-862`) — 2.28.
- `useSyncExternalStore` calls `getSnapshot()` on the server (`:655`) — React throws "Missing getServerSnapshot"; can expose browser-only stores during SSR. PLAUSIBLE divergence.
- `float f = Text (string_of_float f)` (`:539`) — `1.0`→`"1."` — 2.16.
- `cache` keys on `Obj.repr arg` (`:629`) — crashes on functional args — 2.32.
- `with_request_cache` and `with_request_cache_async` are identical (`:602-608`) — harmless duplication.
- Transparent `element`/`Model.t` + exported id internals in `.mli` — 2.33 / design tension T5.

## ReactDOM.ml
- `renderToString`/`renderToStaticMarkup` don't wrap `with_request_cache` → `React.cache` is a passthrough there (`:380-394`) — expectation gap E1.
- Suspense markers emitted in both String and Markup modes (`:181-191`) — E2.
- `renderToStream` counter miscount → push-after-close (`:396-404,554,571-573,646`) — **critical 2.2**.
- `write_suspense_fallback_error` leaks exn+backtrace, no env gate (`:436-442`) — **high 2.9** (maintainer: gate on env).
- `abort` is a no-op (`:640-643`) — 2.12 (fix spec in investigations/react-abort-timeout.md).
- `createPortal` renders inline (`:655`) — 2.20; `render`/`hydrate`/`querySelector` raise despite docstrings (`:650-652`) — 2.21.
- `domProps` xlink/xmlns drift (`:1624-1632`) — **critical 2.6**; `defaultChecked`/`defaultValue` literals (`:1206-1207`) — **critical 2.7**; typos `onEncrypetd`/`fomat` — 2.30.
- `write_to_buffer` (public, PPX `Writer` tier) omits doctype/separators/Suspense markers — 2.25.
- Boundary markup `<div hidden id="S:n">` here vs `<div hidden="true">` in ReactServerDOM — 2.24 inconsistency.

## ReactServerDOM.ml
- `render_html ~debug` ignored; no `filter_stack_frame` (`:1088`) — **high 2.10**.
- Head-hoisted resources dropped for non-`<html>` roots (`:858-884,1017-1037`) — **high 2.11**.
- `client_to_html` Suspense swallows errors → blank + no diagnostics (`:637-682`) — **high 2.13**.
- Timeout closes stream; `Stream.push_async` has no `closed` guard → process crash (`:84-94,1159-1163`) — **critical 2.3** (maintainer: no async hook; fix = guard pushes).
- `render_html` correctly seeds `pending:1` for the root (`:1104`) — the pattern `renderToStream` is missing (contrast for 2.2).
- Payload delivery is XSS-safe (single-quoted attr + `escape_attribute_value`); `bootstrapScriptContent` is raw (`:1058`) — 2.26.
- RSC element rows are 7-tuples even in `env:\`Prod` — open question Q9 (React prod = 4-tuples).
- `Model.render`/`create_action_response` are synchronous until `Lwt.async`, so the root-vs-async ordering hazard of `renderToStream` doesn't apply to the model path. Reply decoders (`decode_value`, `decodeFormDataReply`, `decodeAction`) look sound; `resolve_from_formdata` returns `Null` on missing/invalid keys silently.

## Push_stream.ml
- Thin wrapper over `Lwt_stream.create`; `push`-after-`close` raises `Lwt_stream.Closed` — the mechanism behind 2.2/2.3. Unbounded (no backpressure) — design tension T2.

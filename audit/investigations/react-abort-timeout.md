# Investigation — React's abort/timeout behavior (Q3)

**Goal:** determine exactly what react-dom emits when a streaming render is aborted with pending Suspense boundaries, so `renderToStream`'s no-op `abort` (finding 2.12) and `render_html`'s crashing timeout (finding 2.3) can be fixed to match.

**Repro:** `arch/server/render-html-to-stream-abort.js` (added by this audit), run with `bun render-html-to-stream-abort.js` against `react@19.1.0` / `react-dom@19.1.0`.

## Setup

```jsx
const App = () => (
  <html><body>
    <div>shell content</div>
    <Suspense fallback={<div>Loading A...</div>}><DeferredComponent by={10}>A</DeferredComponent></Suspense>
    <Suspense fallback={<div>Loading B...</div>}><DeferredComponent by={10}>B</DeferredComponent></Suspense>
  </body></html>
);
const controller = new AbortController();
const stream = await ReactDOM.renderToReadableStream(<App/>, { signal: controller.signal, onError });
setTimeout(() => controller.abort(new Error("aborted by server")), 100); // abort while both boundaries pending
```

## Captured output (React 19.1.0, dev build)

```html
<!DOCTYPE html><html><head></head><body><div>shell content</div>
<!--$?--><template id="B:0"></template><div>Loading A...</div><!--/$-->
<!--$?--><template id="B:1"></template><div>Loading B...</div><!--/$-->
<script>
$RX=function(b,c,d,e,f){var a=document.getElementById(b);a&&(b=a.previousSibling,b.data="$!",
a=a.dataset,c&&(a.dgst=c),d&&(a.msg=d),e&&(a.stck=e),f&&(a.cstck=f),b._reactRetry&&b._reactRetry())};
;$RX("B:0","","Switched to client rendering because the server rendering aborted due to:\n\naborted by server",
"…stack…","…component stack…")
</script>
<script>$RX("B:1","","Switched to client rendering because the server rendering aborted due to:\n\naborted by server","…","…")</script>
</body></html>
```

`onError` fired once per pending boundary (2×).

## What React does on abort

1. **Shell + fallbacks already flushed** — the pending boundaries appear as `<!--$?--><template id="B:n"></template><fallback><!--/$-->` (exactly what server-reason-react already writes via `write_suspense_fallback` / `html_suspense_placeholder`).
2. **Emit the `$RX` instruction set once**, then call `$RX("B:n", digest, msg, stack, componentStack)` for each still-pending boundary. `$RX` flips the boundary's opening comment from `$?` to `$!` (errored/aborted) and calls `_reactRetry()`, which tells the hydrating client to **render that boundary on the client** instead of waiting for server HTML.
3. **Error detail is dev-only.** `msg`/`stck`/`cstck` args are populated here because this is a dev build; in production React passes only the digest (empty strings for the rest). This matches the maintainer's "gate on env" answer (Q4/2.9).
4. **Close the stream.**

## Required fix for server-reason-react

`renderToStream`'s `abort` (ReactDOM.ml:640-643) and `render_html`'s timeout branch (ReactServerDOM.ml:1159-1163) should, for each boundary still counted as pending:

1. Emit the `$RX` function definition once (analogous to the existing `$RC` injection at ReactDOM.ml:407-420 / ReactServerDOM.ml:521-524), then a `$RX('B:n', digest, ...)` call per pending boundary.
2. Include error detail **only when `env = \`Dev`** (ties into 2.9 — `renderToStream` needs an `?env` first).
3. Then close the stream — **idempotently and after guarding all further async pushes** (fixes 2.3; without the guard, the boundary promises that resolve after abort still `push` into the closed stream and crash the process).

The `$RX` minified source to vendor (from React 19.1.0), analogous to the existing `$RC`:

```js
$RX=function(b,c,d,e,f){var a=document.getElementById(b);a&&(b=a.previousSibling,b.data="$!",a=a.dataset,c&&(a.dgst=c),d&&(a.msg=d),e&&(a.stck=e),f&&(a.cstck=f),b._reactRetry&&b._reactRetry())};
```

## Note on the two boundary markups

React uses a bare `hidden` attribute and `id="S:n"` on the resolved segment. server-reason-react is inconsistent internally: `ReactDOM.write_suspense_resolved_element` emits `<div hidden id="S:n">` (correct, ReactDOM.ml:423) while `ReactServerDOM.boundary_to_chunk` emits `<div hidden="true" id="S:x">` (ReactServerDOM.ml:535). Align both on bare `hidden` to match react-dom (relates to 2.24).

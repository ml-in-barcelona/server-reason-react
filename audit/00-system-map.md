# System Map

## Overview

server-reason-react renders React component trees to HTML (and to the React Server Components wire format) natively in OCaml, so the same Reason/React source compiles both to native (server, via this library) and to JavaScript (browser, via Melange + reason-react).

## The element tree

`React.element` (`packages/react/src/React.ml:402-428`) is a **transparent** variant. The important constructors:

- `Lower_case_element { key; tag; attributes; children }` — a DOM element.
- `Upper_case_component of string * (unit -> element)` — a synchronous component.
- `Async_component of string * (unit -> element Lwt.t)` — an async component.
- `Client_component { key; props; client; import_module; import_name }` — an RSC client component boundary.
- `Suspense { key; children; fallback }`.
- `Provider { children; push; async_key; async_value }` / `Consumer of element` — context.
- `List` / `Array` / `Text` / `Empty` / `Fragment`.
- `Static { prerendered; original }` — a fully-static subtree pre-rendered to an HTML string by the PPX.
- `Writer { emit : Buffer.t -> unit; original : unit -> element }` — a static-skeleton-with-holes subtree; `emit` writes straight into the caller's buffer. `original` lazily rebuilds the variant form for `cloneElement`/RSC.

The PPX (`packages/server-reason-react-ppx`) compiles JSX into these constructors and picks the tier (`Static`/`Writer`/variant) via static analysis (`static_analysis.ml`).

## Three render engines

All three consume the same `React.element`:

1. **Synchronous string renderers** — `ReactDOM.render_to_buffer ~mode` (`packages/reactDom/src/ReactDOM.ml:141-265`) drives `renderToString` (`mode=String`, inserts `<!-- -->` between adjacent text nodes) and `renderToStaticMarkup` (`mode=Markup`). Raises on `Async_component` (ReactDOM.ml:169-173) and `Client_component` (155-159). A second, simpler synchronous serializer `write_to_buffer` (ReactDOM.ml:267-358) is public and used by the PPX `Writer` tier.

2. **Streaming HTML renderer** — `renderToStream` (ReactDOM.ml:625-648) → `render_to_buffer ~stream_context` (444-623). Fizz-style: renders the shell synchronously, emits `<!--$?--><template id="B:n">` + fallback for each suspended boundary, spawns an `Lwt.async` per boundary that on resolution pushes `<div hidden id="S:n">…</div>` + a `$RC('B:n','S:n')` script. A `stream_context.waiting` counter tracks in-flight boundaries; reaching 0 closes the stream.

3. **RSC renderer** — `packages/reactDom/src/ReactServerDOM.ml`:
   - `render_model` / `render_model_value` — emits only the RSC wire model (rows `id:payload`, with `$L`, `$@`, `I[...]`, `E{...}`, `D` framing; `Model.to_chunk`, ReactServerDOM.ml:246-281).
   - `render_html` — emits an HTML shell *and* the RSC model in parallel, with head-hoisting (title/meta/link/async-script promoted to `<head>`), a `<script data-payload='…'>` bootstrap, and progressive chunking.
   - `create_action_response` — serializes a server-action result (or error) into the RSC stream.
   - Reply decoders (`decodeReply`, `decodeFormDataReply`, `decodeAction`) — deserialize React's `$`-prefixed client-to-server encoding.

## useId — shared global render state

`useId` (React.ml:770-780) produces React-compatible base-32 tree IDs (`«Rxyz»`). Correctness depends on four **process-global** mutable refs (React.ml:747-750):

- `current_tree_context : Tree_context.t ref`
- `local_id_counter : int ref`
- `did_render_id_hook : bool ref`
- `identifier_prefix : string option ref`

Every renderer calls `reset_id_rendering` once at the top, then, at each component, `reset_component_id_state` before invoking it and `Tree_context.push`/restore around its children (e.g. ReactDOM.ml:192-206, 307-321; ReactServerDOM.ml:348-412). The save/restore pattern is correct **within a synchronous slice**; it does **not** survive Lwt suspension points (see design tension T1 / finding 2.1).

## Request-scoped caches & context

`React.cache` (React.ml:614-640) and `React.createContext`/`useContext` (562-643) use `Lwt.with_value` keys so cache entries and context values are per-Lwt-execution. `renderToStream`, `render_html`, `render_model*`, and `create_action_response` wrap their work in `React.Cache.with_request_cache_async`. **The synchronous `renderToString`/`renderToStaticMarkup` do not**, so `React.cache` is a passthrough there (see 06-expectation-gaps.md).

## HTML serialization

`packages/html/Html.ml` provides an `Html.element` tree + `to_string`, plus two escapers:
- `Html.escape` — escapes `& < > ' "` (used for text nodes and double-quoted attribute values). `'`→`&apos;`.
- `Html.escape_attribute_value` (`add_attribute_escaped`) — escapes only `'`→`&#x27;` and `&`, for single-quoted attributes (the RSC `data-payload='…'`).

`ReactDOM` has its *own* buffer-based attribute/element serializers (`write_attribute_to_buffer`, `render_lower_case`) that duplicate parts of `Html` (see design tension T4/T5).

## RSC round-trip

1. Server streams `application/react.component` rows via `render_model` (Dream middleware `DreamRSC.stream_model`, `demo/dream-rsc/DreamRSC.re:283-311`).
2. For SSR, `render_html` emits an HTML shell + an inline bootstrap script that builds `window.srr_stream` as a `ReadableStream` (ReactServerDOM.ml:504-519), plus `<script data-payload='…'>window.srr_stream.push()</script>` rows.
3. In the browser, the forked `ReactServerDOMEsbuild` client (`@pedrobslisboa/react-client/flight`, `packages/react-server-dom-esbuild/ReactServerDOMEsbuild.js`) decodes the payload; client components are resolved via `window.__client_manifest_map`.
4. The manifest is generated by the esbuild plugin (`packages/esbuild-plugin/plugin.mjs`) shelling out to `server-reason-react.extract_client_components` (`packages/esbuild-plugin/extract_client_components.ml`), which scans compiled `.js` for `// extract-client` / `// extract-server-function` marker comments emitted by the RSC ppx.

## Key invariants (and whether they hold)

| Invariant | Where | Holds? |
|-----------|-------|--------|
| One renderer per logical thread at a time (useId globals) | React.ml:747-750 | Only single-process; **not** across concurrent Lwt renders (2.1) |
| `waiting`/`pending` = 0 ⟺ safe to close | ReactDOM.ml:571, ReactServerDOM.ml:1104 | `render_html` counts root; `renderToStream` does not (2.2). No `closed` guard on RSC async push (2.3) |
| PPX `DomProps.ml` ≡ runtime `ReactDOM.domProps` | DomProps.ml / ReactDOM.ml | **Drifted** (2.6) |
| Universal libs behave identically native vs JS | Belt/Js/url/… | **Contract is 0 divergence; not yet met** (2.4, 2.14–2.16, 2.22; see quickjs investigation) |
| Text/attribute output byte-equal to react-dom | Html.ml, ReactDOM.ml | Several byte divergences (2.24) |

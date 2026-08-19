# Plan: timeout and client-disconnect abort for Flight model streams

Status: proposed. Written 2026-08-19 for the Admin Site Inspector RSC
migration (monorepo `docs/admin-site-inspector-rsc-plan.md`, task 17).

Related code in this repository:

- `packages/reactDom/src/ReactServerDOM.ml`
  - `render_html` (`?timeout` already implemented)
  - `Model.run_stream`, `Model.render`, `render_model`,
    `render_model_value`, `Model.create_action_response`
  - `Stream.make`, `context.pending`, `context.pending_rows`,
    `Stream.close`

## Problem

`render_html` accepts `?timeout`. On timeout it settles every pending row
and Suspense boundary as an error and closes the stream, so a slow data
resource cannot hang the connection.

The Flight model renderers have no equivalent:

1. **No timeout.** `render_model`, `render_model_value`, and
   `create_action_response` stream until every pending row resolves. A
   hung resource promise keeps the HTTP response open forever. Downstream,
   every router navigation (full model and patch) uses this path, so
   navigation responses are unbounded while document responses are not.
2. **No abort on client disconnect.** When the client goes away, the
   subscriber callback stops consuming, but the render keeps evaluating:
   pending `push_async` retries still run their resource promises
   (ClickHouse queries, endpoint actions) to completion, and their chunks
   are then dropped by the `closed` guard. The work is wasted and there is
   no hook for the host server to stop it.

## Current mechanics (what the design builds on)

- `Stream.make` returns a `context` with a `pending` counter and
  `pending_rows : (int * [ `Boundary | `Model_row ]) list`. Pushes are
  guarded on `context.closed` and `Stream.close` is idempotent, so late
  async completions after an abort are already safe.
- `render_html`'s timeout is an `Lwt.pick` between the subscription and a
  sleep. On timeout it writes an error row per pending model row, a `$RX`
  client-render instruction per pending boundary, sets `pending <- 0`, and
  closes. `timeout_error` mirrors React Flight's abort reason; production
  output carries only the digest.
- `Model.run_stream` drives the subscriber with
  `Lwt_stream.iter_s subscribe stream`; there is no branch that can settle
  pending rows early.

## Design

### 1. One abort primitive, two triggers

Add an abort signal to the model renderers instead of only a timer:

```ocaml
val render_model_value :
  ?env:[ `Dev | `Prod ] ->
  ?debug:bool ->
  ?filter_stack_frame:(string -> string -> bool) ->
  ?subscribe:(string -> unit Lwt.t) ->
  ?timeout:float ->                    (* sugar: abort after N seconds *)
  ?abort:unit Lwt.t ->                 (* resolves => abort the stream *)
  React.model_value ->
  unit Lwt.t
```

- `?timeout` is implemented as `abort = Lwt_unix.sleep seconds`, matching
  `render_html`.
- `?abort` is a promise supplied by the host server. The adapter resolves
  it when the client disconnects (or on its own deadline policy). This is
  the OCaml equivalent of React's `abort(reason)` on the Flight stream.
- When both are given, whichever resolves first aborts. Omitting both
  keeps today's behavior.
- `render_html` gains the same `?abort` parameter for symmetry; its
  timeout branch becomes the same code path.

### 2. Abort semantics for model streams

Extract the settlement block from `render_html`'s timeout branch into a
shared `Stream.abort ~reason context` that:

1. Takes the current `pending_rows`, clears the list, and emits one error
   row (`timeout_error`-style reason, digest-only in `Prod`) per pending
   row **through the normal push path**, before closing. Model streams
   have no HTML `$RX` instructions; every pending entry settles as a
   Flight error row so client-side `$L`/`$@` references reject instead of
   hanging.
2. Sets `pending <- 0` and calls `Stream.close`.

Difference from the `render_html` implementation: the HTML path writes the
error chunks straight into the subscriber's buffer because `Lwt.pick` is
about to cancel the subscription. For the model path, `run_stream` must
push the rows into the stream *before* closing it, so
`Lwt_stream.iter_s` delivers them and then terminates normally — no
`Lwt.pick` race with a buffered writer. Shape:

```ocaml
let run_stream ~env ~debug ?filter_stack_frame ?subscribe ?abort model =
  let stream, context = Stream.make () in
  Option.iter
    (fun abort ->
      Lwt.async (fun () ->
        let%lwt () = abort in
        if not context.closed then Stream.abort ~reason:timeout_error ~env context;
        Lwt.return ()))
    abort;
  ...
```

`Stream.abort` reuses the push/close guards, so a race between a resolving
row and the abort is benign: whichever runs first wins, the other is
dropped by the `closed` check.

### 3. Cancel pending resource work on abort

Settling the rows fixes the protocol; the server work must stop too:

- Track the in-flight task promises: `push_async` (and the
  `Upper_case_component` retry path) currently registers only the row
  index. Extend the registration to keep the `unit Lwt.t` of the running
  task in the context.
- On `Stream.abort`, call `Lwt.cancel` on each tracked promise after the
  error rows are written. Cancellation propagates into `Lwt_unix` I/O and
  typical database client promises, releasing the connection instead of
  running the query to completion.
- Best-effort caveat: `Lwt.cancel` is a no-op for promises created without
  cancellation support (e.g. `Lwt.wait`-based). Document this; the guard
  on `closed` already makes their late completion harmless.
- The React request cache (`React.Cache`) is request-scoped, so cancelled
  entries die with the request; no cache poisoning is possible across
  requests.

### 4. Host integration (downstream, for reference)

The Ahrefs monorepo adapter (`backend/api/src/lib/admin_rsc_router_adapter.ml`)
will:

- pass `~timeout:stream_timeout` to `render_model_value` (same default as
  its document path, currently 30s), and
- create `let disconnected, resolve_disconnected = Lwt.wait ()` per
  response, resolve it from the HTTP server's connection-teardown hook
  (or on the first failed write in the subscriber callback), and pass it
  as `~abort`.

A Dream integration does the same from `Dream.request` disconnect
detection in `demo/dream-router/DreamRouter.ml`.

## Tests

Extend the existing Flight test suite (the `suspense_with_use_promise`
family):

1. **Model timeout settles pending rows**: a model with one resolved and
   one never-resolving `usePromise` row; `~timeout:0.01`; assert the
   subscription terminates, the resolved row streamed, and the pending row
   streamed as an error row with the timeout digest.
2. **Abort signal**: same tree with `~abort` resolved manually mid-stream;
   assert identical settlement.
3. **Late completion after abort**: a promise that resolves after the
   abort; assert no chunk is emitted after the close chunk (guarded push).
4. **Cancellation**: a cancelable task (e.g. `Lwt_unix.sleep`) tracked by
   the stream; on abort assert the promise ends in `Lwt.Canceled`.
5. **`create_action_response`** with `~timeout`: the wrapper promise is
   also bounded.
6. **No-regression**: `render_html ~timeout` behavior unchanged when
   expressed through the shared `Stream.abort`.
7. **Prod redaction**: with `~env:\`Prod`, abort error rows contain only
   the digest, no message or stack.

## Non-goals

- Per-resource timeouts. Resources that need their own deadline wrap their
  promise before handing it to `usePromise`.
- Partial abort (aborting one boundary but continuing the stream). React
  Flight aborts the whole response; this plan matches that.
- Backpressure changes. `Lwt_stream.iter_s` semantics stay as they are.

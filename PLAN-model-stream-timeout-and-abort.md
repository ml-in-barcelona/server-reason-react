# Plan: timeout and abort for Flight model streams

Status: implemented on 2026-08-20 after code and Lwt lifecycle review.

This work supports the Admin Site Inspector RSC migration in the Ahrefs
monorepo (`docs/admin-site-inspector-rsc-plan.md`, task 17).

Related code:

- `packages/reactDom/src/ReactServerDOM.ml`: `Stream.make`,
  `Stream.push_task`, `Stream.close`, `Model.push_root_task`,
  `Model.run_stream`, `Model.render`, `Model.create_action_response`, and the
  public render functions
- `packages/reactDom/src/ReactServerDOM.mli`
- `packages/reactDom/test/test_RSC_model.ml`
- `packages/reactDom/test/test_RSC_html.ml`
- `demo/dream-router/DreamRouter.ml`

## Goal

Bound Flight model responses and stop request work when the caller no longer
needs the response.

The public model renderers support:

- a timeout in seconds;
- an external abort promise supplied by the host server;
- Flight error rows for references that were pending when the render stopped;
- best-effort cancellation of pending Lwt work; and
- cleanup when the subscriber fails or the caller cancels the render promise.

`render_html` accepts the same external abort input. Its existing timeout wire
output is unchanged.

## Problems addressed

### Unbounded model renders

`render_model`, `render_model_value`, and `create_action_response` previously
waited without a deadline until every pending row resolved.

### Work outliving the response

`Stream.close` previously left tasks running, and some output paths could still
allocate rows or try to write after close.

### Action execution outside the stream

`Model.create_action_response` previously awaited the action promise before it
called `run_stream`, so the stream deadline could not bound a hung action.

### Subscriber failures leaving tasks running

`Model.run_stream` previously returned the subscription directly. A failed
write did not cancel pending resource tasks.

## Constraints found during review

### Lwt cancellation is best effort

`Lwt.cancel` propagates through normal bind chains and cancelable I/O promises.
It does not stop work behind `Lwt.wait`, `Lwt.no_cancel`, or
`Lwt.protected`. The stream must remain safe when canceled work later resumes.

Cancellation can run callbacks immediately. Abort code must detach pending
tasks and close output before it calls `Lwt.cancel`.

An uncaught `Lwt.Canceled` from a promise passed to `Lwt.async` reaches
`Lwt.async_exception_hook`. The task driver must consume cancellation.

### An abort watcher must have a bounded lifetime

A detached watcher on an unresolved host promise retains the stream context
after a normal render. The watcher must be canceled when the stream completes.
Canceling the watcher must not cancel the host-owned abort promise, so the
watcher must use `Lwt.protected`.

### Model and HTML settlement need different writers

Model abort rows must enter the internal `Lwt_stream` before it closes so
`Lwt_stream.iter_s` can deliver them.

The HTML timeout branch writes into the subscriber buffer because its current
`Lwt.pick` cancels the stream subscription. HTML also emits `$RX` instructions
for pending Suspense boundaries. A single output-producing `Stream.abort`
function does not fit both paths.

Share the state transition and task snapshot. Keep the two output emitters
separate.

### Dream cannot report every disconnect immediately

The installed Dream API has no high-level request-disconnect promise. A failed
`Dream.write` or `Dream.flush` detects a disconnected client when a write is in
progress. It cannot detect an idle disconnect while the renderer waits on a
hung resource.

The timeout is the reliable backstop for Dream. Full immediate disconnect
detection needs a Dream or httpaf transport hook. HTTP/2 needs a per-stream
reset hook rather than a connection-wide signal.

### The existing HTML timeout starts after shell rendering

`render_html` creates its timer inside the returned `subscribe` function. It
does not bound initial shell rendering. The implementation preserves that behavior.
Changing the two-stage HTML API or timing the shell render is separate work.

## Public API

All model renderers accept `?timeout` and `?abort`:

```ocaml
val render_model_value :
  ?env:[ `Dev | `Prod ] ->
  ?debug:bool ->
  ?filter_stack_frame:(string -> string -> bool) ->
  ?subscribe:(string -> unit Lwt.t) ->
  ?timeout:float ->
  ?abort:unit Lwt.t ->
  React.model_value ->
  unit Lwt.t
```

`render_model` and `create_action_response` accept the same additions.
`render_html` adds `?abort` to its existing `?timeout` parameter.

Semantics:

- `timeout` starts when the model renderer starts.
- A fulfilled `abort` promise requests an external abort.
- A rejected or canceled `abort` promise also requests an external abort. This
  keeps a bad host signal from leaking through `Lwt.async_exception_hook`.
- When both inputs exist, the first one to settle wins.
- Timeout and external abort use different development messages.
- Production error rows contain only the digest.
- Omitting both inputs preserves current successful render output.

With `subscribe = None` and no timeout or abort, `render_model` and
`render_model_value` preserve their fire-and-return behavior.
`create_action_response` first waits for the action to settle, then preserves
the same fire-and-return serialization behavior. When a timeout or abort is
supplied, the renderer drains through an internal no-op subscriber so the
returned promise waits for completion or the trigger.

## Implementation

### Root task and action compatibility

The model driver accepts a root model promise. `render_model` and
`render_model_value` supply an already-resolved model, while
`create_action_response` supplies the action promise. The driver registers row
`0` before it starts the abort monitor, so an already-settled abort signal
cannot miss the root task.

A normal rejected action still produces a root model that references an
outlined error row:

```text
0:"$Z1"
1:E{...}
```

The action wrapper catches ordinary rejection and serializes a
`React.Model.Error` with the generated digest. A timeout or abort instead
settles the still-pending root as `0:E` and attempts to cancel the action.

### Stream lifecycle

Each active task record contains its row ID, its `Model_row` or `Boundary`
kind, and its running promise. The stream has three lifecycle states:

```ocaml
type lifecycle = Open | Aborting | Closed
```

Task registration happens before task execution can yield. Normal completion
removes an active task once and closes the stream when no work remains.
`render_html` tracks its root shell separately because it has no task promise
or row to settle.

### Output guards

Lifecycle-aware helpers enforce these rules:

- regular pushes work only in `Open`;
- abort settlement pushes work only in `Aborting`;
- task registration works only in `Open`;
- import, hint, deferred, debug, and existing-ID row writes cannot reach the
  closed `Lwt_stream`.

The guards remain necessary after cancellation because `Lwt.wait` and other
non-cancelable promises can resume later. Refused registration still allocates
an inert row index, which keeps late serialization total while write guards
drop its output. A resource canceled by its owner while the stream remains open
settles its row as an error.

### Abort transition

For an open stream, `Stream.begin_abort` performs one non-yielding transition:

1. Change the lifecycle from `Open` to `Aborting`.
2. Take a stable snapshot of active task records.
3. Clear the active task collection.
4. Return the snapshot to the caller.

For an aborting or closed stream, it returns no snapshot. The transition does
not serialize rows or call `Lwt.cancel`, so repeated aborts are harmless.

### Model settlement

The model abort emitter receives the task snapshot and:

1. Sort pending row IDs in ascending order.
2. Push one `E` row for each existing ID without allocating new row IDs.
3. Close the internal stream after the last error row.
4. Cancel the captured task promises after close.

Rows already queued remain before abort rows. Model streams emit no `$RX`
instructions and have no close chunk. Closing is the out-of-band `None` from
`Lwt_stream`.

Use these development messages:

- timeout: `The render timed out.`
- external abort: `The render was aborted.`

Production serialization redacts both messages and stacks.

### Monitor and subscription

`Lwt.pick` selects the first timeout or external abort trigger. The renderer
protects the abort promise so cleanup can detach the watcher without canceling
the host-owned signal. When a trigger wins, the renderer queues settlement
rows, closes and cancels tasks, then waits for the subscription to drain the
queued rows. Normal completion cancels the watcher.

If the subscriber raises or the caller cancels the returned render promise,
the renderer closes output and cancels active tasks without writing settlement
rows to the failed subscriber.

An external abort can still wait on a subscriber callback that is already
blocked. Host adapters should make failed writes reject promptly. The renderer
cannot force an arbitrary callback to return.

### HTML settlement

`render_html` combines `?abort` with its existing timeout. The trigger starts
when the caller invokes `subscribe`, after shell rendering. The HTML emitter
uses the same abort transition, then:

1. Writes one model error row per pending task into the subscriber buffer.
2. Writes one `$RX` instruction per pending `Boundary` task.
3. Writes the `$RX` function definition once.
4. Writes the stream end script once.
5. Closes the internal stream.
6. Cancels the captured tasks.

It keeps this ordering:

- error rows in ascending row-ID order;
- boundary instructions in registration order; and
- the end script after all settlement output.

`$RX` messages wrap the reason the same way the timeout path does:

```text
Switched to client rendering because the server rendering aborted due to:

<reason>
```

Timeout keeps its existing wrapped message. External abort uses the wrapped
form of `The render was aborted.` in development. Production emits a
digest-only `$RX` call in both cases.

## Host integration

### Ahrefs adapter

The monorepo adapter can pass the existing document timeout to
`render_model_value` and `create_action_response`.

If its HTTP layer exposes a response teardown or per-request cancellation
promise, pass that promise as `~abort`. The subscriber should also resolve the
abort signal or fail when its first write fails.

### Dream demo

`demo/dream-router/DreamRouter.ml` is a repository-only reference adapter, not
an installed package. It applies a timeout to model and action responses. The
action timer starts before handler dispatch, and the remaining time is passed
to `create_action_response`, so action execution and serialization share one
deadline. A failed `Dream.write` or `Dream.flush` becomes a subscriber failure,
which cancels pending tasks.

The Dream demo does not claim immediate client-disconnect cancellation because
Dream and its exposed transport provide no suitable hook.

## Tests

`packages/reactDom/test/test_RSC_model.ml` covers pending roots and promise
rows, production redaction, row order, cancelable and non-cancelable work,
subscriber failure, canceled render promises, subscriber-less model and action
calls, action success and rejection compatibility, action timeout, and action
abort.

`packages/reactDom/test/test_RSC_html.ml` covers timeout and external-abort
settlement, `$RX` output, production redaction, late completion, and a single
end script. `demo/dream-router/test_dream_router.ml` verifies that the Dream
deadline includes action execution and preserves successful and rejected
action responses.

## Validation

1. Run `make format` and inspect the diff.
2. Run `make format-check`.
3. Run `make build`.
4. Run `make test`.
5. Run `make spec-check` when the Flight fixture dependencies are installed.
   Existing non-aborted Flight output must remain unchanged.
6. Run `make bench` and compare model-render results. Lifecycle checks affect
   every async row, so measure their cost.

## Final guarantees

- Every model renderer accepts timeout and external abort inputs.
- The timeout covers a pending action response from API entry.
- Pending Flight references receive one error row each before model stream
  close.
- Normal action success and failure output remain unchanged.
- Cancelable pending work receives `Lwt.Canceled` after abort or subscriber
  failure.
- Non-cancelable late work cannot write, register effective work, decrement
  stale counters, or raise through `Lwt.async_exception_hook`.
- Abort monitors do not retain completed render contexts.
- Existing HTML timeout output remains unchanged.
- Dream integration uses timeout as its disconnect backstop.

## Non-goals

- Per-resource timeouts. Resources can wrap their own promises.
- Partial boundary abort. Abort stops the whole response.
- Backpressure changes to `Lwt_stream.iter_s`.
- A new Dream or httpaf disconnect API.
- Changing when the `render_html` shell timeout starts.
- Guaranteeing cancellation for libraries that return non-cancelable promises.

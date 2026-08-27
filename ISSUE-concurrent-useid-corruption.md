# useId corruption in concurrent and async renders

Status: open. Found on 2026-08-19 during the Admin Site Inspector RSC
migration (monorepo task 6, `docs/admin-site-inspector-rsc-plan.md`).

Tested against:

- Pinned package: `server-reason-react 0.5.1+ahrefs.20260817.8`
- This checkout: branch `nested-router-header-protocol`,
  commit `eb721d4c2ffcd636701e0400a385394fb88ccbca`
  (the relevant code is identical to the pinned package).

## Summary

`React.useId` render state is process-global. Two problems follow:

1. **Cross-render corruption.** Two concurrent renders
   (`ReactServerDOM.render_model` or `render_html`) interleave at `Lwt`
   yields. Each render mutates the same three globals, so a render that
   resumes after a yield reads the other render's tree context. The
   resumed render emits useId values from the wrong tree.
2. **Single-render duplicate ids.** Even one render alone produces
   duplicate useId values when an `Async_component` resolves late. The
   async continuation reads whatever `React.current_tree_context`
   contains at wake-up time, not the context that was current when the
   async subtree was reached. Sibling components that render after the
   suspension have already advanced and restored the global, so the
   continuation re-renders from a stale position.

## Where the state lives

`packages/react/src/React.ml`:

```ocaml
(* This state is process-global: two async renders (renderToStream/render_html)
   must not be in flight concurrently in one process, or their useId state
   interleaves at Lwt yields and produces hydration mismatches.
   TODO: scope per render (Lwt.key, as React.Cache/Context do, or thread through
   the renderer) before enabling concurrent renders. *)
let current_tree_context : Tree_context.t Stdlib.ref = Stdlib.ref Tree_context.empty
let local_id_counter : int Stdlib.ref = Stdlib.ref 0
let did_render_id_hook : bool Stdlib.ref = Stdlib.ref false
let identifier_prefix : string option Stdlib.ref = Stdlib.ref None
```

The code comment already documents the risk. This issue confirms it with a
reproduction and adds the single-render duplicate-id finding, which the
comment does not cover.

## Corruption paths in the renderer

`packages/reactDom/src/ReactServerDOM.ml`, `turn_element_into_payload`:

- `Upper_case_component` retry: after `React.Suspend`, the retry callback
  runs `React.reset_component_id_state saved_ctx` when the awaited promise
  resolves. This write clobbers the tree context of any other render that
  is mid-walk at that moment.
- `Async_component`, `Sleep` branch: the continuation runs
  `turn_element_into_payload element` when the promise wakes. That walk
  reads the **current** global `React.current_tree_context`, which by then
  belongs to another render, or to a later sibling of the same render.
  There is no save of the context that was current when the async node was
  reached, apart from `saved_ctx` which is only restored *after* the walk.

`render_html` has the same pattern in `packages/reactDom/src/ReactDOM.ml`
(`reset_id_rendering` at render start, `reset_component_id_state` in
retries).

## Reproduction

Monorepo test `backend/api/src/lib/tests/tests_concurrent_render.ml`
(temporarily pointed at the raw renderer). Two element trees with different
shapes; each has an `Async_component` that awaits `Lwt.pause` a few times
before rendering children that call `useId`:

```text
tree A: <main> IdA0 <Suspense><AsyncA(3 pauses)> IdA1 IdA2 </></> IdA3 </main>
tree B: <article> <div> IdB0 IdB1 </div> <Suspense><AsyncB(2 pauses)> <div>IdB2</div> IdB3 IdB4 </></> </article>
```

Procedure:

1. Render each tree alone with `render_model`; collect the useId values
   from the Flight payload (sorted). These are the baselines.
2. Render both trees concurrently with `Lwt.both` (and 8-way with
   `Lwt.all`); collect and compare.

## Observed output

```text
render A ids survive a concurrent render B
expected: «R1», «R1», «R2», «R3» but got: «R1», «R3», «R6», «Ra»

render 1 (B) ids are uncorrupted
expected: «R1», «R2», «R3», «R5», «R9» but got: «R5», «R6», «R9», «Ra», «Re»
```

Full OUnit log: `concurrent-render-failure.log` next to this file
(untracked; `*.log` is gitignored).

Two independent observations:

1. Concurrent ids differ from sequential ids for the same tree. This is
   the cross-render corruption.
2. The sequential baseline for tree A is `«R1», «R1», «R2», «R3»`, with
   a duplicate `«R1»`. Tree A has four `useId` call sites at four
   distinct tree positions, so four distinct ids are expected. This is the
   single-render async-continuation bug. It reproduces with one render and
   no concurrency.

## Suggested fix

Scope the four globals per render, as the TODO in `React.ml` says:

- Thread a render-task record through the renderer (mirror of React's
  `currentlyRenderingTask` in `ReactFizzHooks.js`), or
- use an `Lwt.key` so each render's Lwt promise chain carries its own
  id state, the same mechanism `React.Cache` and async context providers
  already use.

For the `Async_component` `Sleep` branch, the continuation must capture the
tree context (after the `did_use_id` push) at suspension time and restore it
before walking the resolved element, instead of reading the global at
wake-up time. The `Upper_case_component` retry path needs the same
treatment.

## Downstream mitigation

Until this is fixed upstream, the monorepo Admin RSC adapter
(`backend/api/src/lib/admin_rsc_router_adapter.ml`) serializes React
renders per process with a global `Lwt_mutex` held from render start to
stream completion. The monorepo test above runs through that lock and
passes. The lock caps admin render concurrency at 1 per process, so it must
be removed once the upstream fix lands.

The single-render duplicate-id bug is not covered by the mitigation: it needs the upstream continuation-context fix. Downstream
impact today is limited because the admin pages that stream do not yet rely
on unique server-generated ids across an async boundary.

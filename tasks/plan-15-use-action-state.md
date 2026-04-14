# Implement `useActionState` and `decodeFormState`

**Priority**: Lower
**Depends on**: plan-12-bound-server-references (partially — `$F` resolution needed for some patterns)
**Last in sequence** — this is the least actionable plan; all others can proceed independently
**Origin**: Phase E from plan-03-rethink-server-actions-architecture.md (Layer 2.2)

## Problem

`useActionState` is currently a stub in `packages/react/src/React.ml`. The companion `decodeFormState` is not implemented in ReactServerDOM. Together, these enable the server to know which `useActionState` hook to update after a no-JS form submission.

React's model: after a no-JS form submission, the server calls `decodeFormState(result, formData, action)` to check if the submitted `$ACTION_KEY` matches the expected key. If so, the result is passed back to `useActionState` as the new state.

## Tasks

### Implement `decodeFormState` in ReactServerDOM

**File**: `packages/reactDom/` — new function in the ReactServerDOM module

React's `decodeFormState`:
1. Reads `$ACTION_KEY` from the FormData
2. Computes expected key as a hash of `[componentKeyPath, null, hookIndex]`
3. If the keys match, returns the action result as the new state for `useActionState`

- [ ] Implement `decodeFormState` function: `(result, formData, action) => option(state)`
- [ ] Implement the `$ACTION_KEY` hashing algorithm (hash of `[componentKeyPath, null, hookIndex]`)
- [ ] Integrate with the tree context system (component key paths)

### Implement `useActionState` in React.ml (server-side rendering)

**File**: `packages/react/src/React.ml`

**Current**: Stub or not implemented.

The server-side `useActionState` needs to:
1. Return the current state and a dispatch function
2. During SSR, render the form with `$ACTION_KEY` hidden field
3. After a no-JS form submission, use `decodeFormState` to recover the new state

- [ ] Implement the server-side `useActionState` hook
- [ ] Emit `$ACTION_KEY` hidden field during SSR
- [ ] Wire `decodeFormState` into the form state recovery flow

### Add tests

- [ ] Add unit tests for `decodeFormState` with matching and non-matching keys
- [ ] Add unit tests for `useActionState` server-side rendering output
- [ ] Add cram tests for PPX output if `useActionState` affects generated code

## Verification

- [ ] Run `make build` — both native and Melange compilation must succeed
- [ ] Run `make test` — all existing tests pass (including new tests)
- [ ] Run `make ppx-test` — PPX snapshot tests pass
- [ ] Run `make demo-serve` — demo app builds and serves without errors
- [ ] Add a demo component using `useActionState`:
  - A form with `useActionState` that shows a counter or status message
  - Submit with JS enabled — verify state updates via RSC stream
  - Submit with JS disabled — verify state recovers via `decodeFormState` / `$ACTION_KEY`
  - Verify the `$ACTION_KEY` hidden field is present in the rendered HTML

## Dependencies

- Partially depends on plan-12-bound-server-references (some `useActionState` patterns use bound server refs)
- Benefits from plan-11-no-js-response-handling (no-JS form submission path)
- The tree context / component key path system must support key derivation for `$ACTION_KEY` hashing

# Fix client binding types in ReactServerDOMEsbuild

**Priority**: High
**Prerequisite for**: plan-10-encode-form-action
**Origin**: Phase A from plan-03-rethink-server-actions-architecture.md (Layer 4.1-4.3)
**Status**: DONE

## Problem

The Reason bindings in `packages/react-server-dom-esbuild/ReactServerDOMEsbuild.re` have incorrect types that don't match the actual JS implementation in `ReactServerDOMEsbuild.js`. No behavior change needed — just type correctness.

## Tasks

### 4.1 Fix `callServer` type

**File**: `packages/react-server-dom-esbuild/ReactServerDOMEsbuild.re:1-7`

**Was**:
```reason
type arg;
type callServer = (string, list(arg)) => Js.Promise.t(React.element);
```

**Now**:
```reason
type serverFunctionArgs;
type callServer = (string, serverFunctionArgs) => Js.Promise.t(React.element);
```

Note: The plan originally proposed `encodedArgs`, but the args React passes to `callServer` are raw JS arrays (not encoded). `serverFunctionArgs` is more accurate. The user's `callServer` implementation is responsible for calling `encodeReply` to produce the encoded body.

- [x] Update the type aliases in `ReactServerDOMEsbuild.re`

### 4.2 Add `temporaryReferences` to `options`

**File**: `packages/react-server-dom-esbuild/ReactServerDOMEsbuild.re:9-14`

**Now**:
```reason
type temporaryReferences;
type options = {
  callServer,
  temporaryReferences: option(temporaryReferences),
};
```

- [x] Add `temporaryReferences` type and update `options` record
- [x] Update `createFromReadableStream` and `createFromFetch` wrappers to thread `temporaryReferences` through

### 4.3 Fix `encodeReply` signature

**File**: `packages/react-server-dom-esbuild/ReactServerDOMEsbuild.re:16-57`

**Was**:
```reason
external encodeReply: list('arg) => Js.Promise.t(string) = "encodeReply";
```

**Now**:
```reason
type encodedBody;
type encodeReplyOptions = {
  temporaryReferences: option(temporaryReferences),
  signal: option(Fetch.AbortSignal.t),
};

external encodeReply:
  ('a, ~options: encodeReplyOptions=?, unit) => Js.Promise.t(encodedBody) =
  "encodeReply";

external encodedBodyToBodyInit: encodedBody => Fetch.BodyInit.t = "%identity";
```

Design decisions:
- `encodedBody` is separate from `serverFunctionArgs` — they represent different stages (raw args vs encoded body)
- `encodedBodyToBodyInit` uses `%identity` following the same pattern as `Fetch.BodyInit.make` (which is also `%identity`)
- `signal` uses `Fetch.AbortSignal.t` (from `melange-fetch`, already a dependency)

- [x] Update `encodeReply` external binding with correct input/output types
- [x] Add `encodeReplyOptions` type

### Update demo consumers

- [x] Update `demo/client/SinglePageRSC.re` to match the new types
- [x] Update `demo/client/DummyRouterRSC.re` to match the new types
- [x] Update `demo/client/NestedRouterRSC.re` to match the new types

Consumer changes: `encodeReply(args)` → `encodeReply(args, ())` (unit sealer for optional options arg), `Fetch.BodyInit.make(body)` → `ReactServerDOMEsbuild.encodedBodyToBodyInit(body)`.

`demo/client/ServerOnlyRSC.re` and `demo/dream-nested-router/native/shared/Router.re` only use `createFromFetch`/`createFromReadableStream` without `encodeReply` — no changes needed.

## Verification

- [x] Run `make build` — both native and Melange compilation succeed (zero warnings)
- [x] Run `make test` — all 323 tests pass
- [x] Run `make ppx-test` — all PPX cram tests pass
- [x] Run `make format-check` — formatting clean
- [ ] Run `make demo-serve` — demo app builds and serves without errors
- [ ] Manually verify the demo's RSC page loads and server actions still work (click a server action button, confirm response)

## Dependencies

- This is a **breaking API change** for any external consumers of `ReactServerDOMEsbuild.re`
- Item 4.2 (temporaryReferences in options) connects to plan-04-temporary-references
- This plan is a **prerequisite** for plan-10-encode-form-action

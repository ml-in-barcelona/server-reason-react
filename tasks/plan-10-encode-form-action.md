# Implement encodeFormAction for client-side progressive enhancement

**Priority**: High
**Depends on**: plan-09-fix-client-binding-types
**Origin**: Phase B from plan-03-rethink-server-actions-architecture.md (Layer 4.4-4.5)

## Problem

When a `<form action={serverFn}>` is hydrated on the client, React calls `fn.$$FORM_ACTION(prefix)` to generate hidden inputs for progressive enhancement. Currently, the client-side server references don't have `$$FORM_ACTION` because `encodeFormAction` is not implemented — it's passed as `undefined` in `ReactServerDOMEsbuild.js:219` and `None` in `ReactServerDOMEsbuild.re:79`.

This means that even though the server now renders `$ACTION_ID_<hash>` hidden inputs (plan-08), client-side re-renders after hydration lose them.

## Tasks

### 4.4 Implement `encodeFormAction` in the JS layer

**File**: `packages/react-server-dom-esbuild/ReactServerDOMEsbuild.js`

React's model: when React sees `<form action={serverFn}>` during hydration, it calls `encodeFormAction` to convert the server reference into hidden form field data. The callback receives a server reference and returns:
```typescript
{
  name: string,      // hidden input name (e.g. "$ACTION_ID_<hash>")
  method: string,    // form method
  encType: string,   // form enctype
  data: FormData,    // additional hidden field data (null for unbound)
}
```

For unbound actions, `name = "$ACTION_ID_" + id`. For bound actions, `name = "$ACTION_REF_" + prefix` and `data` contains serialized bound args.

**Proposed**: Implement `defaultEncodeFormAction` in `ReactServerDOMEsbuild.js`:
```javascript
function encodeFormAction(id, bound) {
  if (bound === null) {
    return {
      name: "$ACTION_ID_" + id,
      method: "POST",
      encType: "multipart/form-data",
      data: null,
    };
  }
  // For bound actions, serialize bound args into FormData
  // ... (more complex, involves processReply)
}
```

Then pass it to `createResponse` at the line currently passing `undefined` for `encodeFormAction`.

- [ ] Implement `defaultEncodeFormAction` function in `ReactServerDOMEsbuild.js`
- [ ] Wire it into `createResponseFromOptions` (replace the `undefined` for encodeFormAction)
- [ ] Export it so it can be referenced from Reason if needed

### 4.5 Wire `encodeFormAction` through `createServerReference`

**File**: `packages/react-server-dom-esbuild/ReactServerDOMEsbuild.re:79`

**Current**:
```reason
createServerReferenceImpl(serverReferenceId, callServer, None, None, None);
```

The three `None`s correspond to: `encodeFormActionCallback`, `findSourceMapURLCallback`, and `functionName`. At minimum, `encodeFormActionCallback` should be wired once 4.4 is implemented.

**Proposed**:
```reason
createServerReferenceImpl(serverReferenceId, callServer, Some(encodeFormAction), None, None);
```

This requires exposing `encodeFormAction` as a value from the JS file and binding it in Reason.

- [ ] Add a Reason external binding for the `encodeFormAction` function exported from the JS file
- [ ] Update `createServerReference` to pass `Some(encodeFormAction)` instead of `None`

## Verification

- [ ] Run `make build` — both native and Melange compilation must succeed
- [ ] Run `make test` — all existing tests pass
- [ ] Run `make demo-serve` — demo app builds and serves without errors
- [ ] Test progressive enhancement manually:
  - Load a page with a `<form action={serverFn}>` in the demo
  - Inspect the HTML: hidden `$ACTION_ID_*` inputs should be present after server render
  - Disable JavaScript in the browser
  - Submit the form — it should still POST correctly with the hidden fields
  - Re-enable JavaScript, reload, trigger a client-side re-render — hidden inputs should persist after hydration

## Dependencies

- Requires plan-09-fix-client-binding-types to be completed first (correct types for `callServer`, `encodeReply`, etc.)
- Connects to plan-08-action-formdata-protocol-progressive-ench (server-side `$ACTION_*` protocol)
- Bound action support (`$ACTION_REF_*`) depends on plan-12-bound-server-references

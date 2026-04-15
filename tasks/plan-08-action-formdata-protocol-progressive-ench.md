# Adopt React's `$ACTION_*` FormData protocol

## Problem

The current server function dispatch uses a custom `ACTION_ID` HTTP header to identify which server function to call. This works for JS-enabled clients but **breaks progressive enhancement**: when JavaScript is disabled, a `<form action={serverFn}>` submits as a standard browser form POST with no custom headers. The browser sends only the form fields as `multipart/form-data` or `application/x-www-form-urlencoded`.

React's solution is to embed the server function ID **inside the form submission itself** using hidden `$ACTION_*` fields, so the server can dispatch the correct handler without relying on custom HTTP headers. This enables:

1. **No-JS form submissions** - forms work without JavaScript.
2. **Progressive enhancement** - the same endpoint handles both JS-enhanced and no-JS submissions.
3. **Bound arguments** - server functions can have pre-filled (closed-over) arguments via `$ACTION_REF_`.

The current codebase already has the route structure for this pattern. In `demo/server/server.re:3-4`, there is a comment: *"Allow GET and POST from the same handler enables progressive enhancement."* But the actual protocol relies on the `ACTION_ID` header, defeating that goal.

## Current architecture

### Client side (`demo/client/SinglePageRSC.re:1-19`)

```reason
let callServer = (path: string, args) => {
  let headers = Fetch.HeadersInit.make({
    "Accept": "application/react.action",
    "ACTION_ID": path,     // <-- custom header
  });
  ReactServerDOMEsbuild.encodeReply(args) |> ...
};
```

### Server side (`demo/dream-rsc/DreamRSC.re:184-199`)

```reason
let handleRequest = (~lookup, request) => {
  let actionId = Dream.header(request, "ACTION_ID");  // <-- reads custom header
  ...
};
```

### ReactServerDOMEsbuild.js (line 219)

```javascript
undefined, // encodeFormAction   <-- disabled
```

### ReactServerDOMEsbuild.re (line 22-23)

```reason
// EncodeFormActionCallback (optional) (We're not using this right now)
option('encodeFormActionCallback),
```

## Target architecture (React's `$ACTION_*` protocol)

### How it works in React

When React renders `<form action={serverFn}>` on the server:

1. The server-rendered HTML includes hidden form fields:
   - `$ACTION_ID_<hash>` = `""` (for unbound actions) — the field name contains the ID
   - OR `$ACTION_REF_<hash>` with encoded bound argument metadata

2. On form submission (no-JS), the browser sends these fields as part of the FormData.

3. The server's `decodeAction` function:
   - Iterates FormData entries looking for `$ACTION_*` keys
   - `$ACTION_ID_<hash>` → loads the server function by ID with no bound args
   - `$ACTION_REF_<hash>` → decodes bound argument metadata, loads the function with bound args
   - Non-`$ACTION_*` fields are collected into a new FormData (the user's form data)
   - Returns `fn.bind(null, formData)` — the form data becomes the first argument

4. When JS is enabled, React intercepts form submission and uses the `callServer` callback instead, sending arguments via `encodeReply` + the `$F` reference protocol. The `$ACTION_*` hidden fields are ignored.

### What `encodeFormAction` does

React's client-side `encodeFormAction` callback converts a server reference into hidden form field data. It is called during hydration to inject the `$ACTION_*` fields into the form's submission data. This is passed as a parameter to `createResponse` (currently `undefined` in our code at `ReactServerDOMEsbuild.js:219`).

## Tasks

### Phase 1: Server-side `decodeAction`

- [ ] Implement `decodeAction` in `packages/reactDom/src/ReactServerDOM.ml`: parse `$ACTION_*` keys from FormData, extract the action ID, separate user form fields from protocol fields.
- [ ] Add `decodeAction` to `packages/reactDom/src/ReactServerDOM.mli`.
- [ ] Add unit tests for `decodeAction` in `packages/reactDom/test/test_RSC_decoders.ml`:
  - `$ACTION_ID_<hash>` with form fields
  - `$ACTION_ID_<hash>` with no extra form fields
  - FormData with no `$ACTION_*` keys (returns `None`)
  - Multiple `$ACTION_*` keys (error or last-wins)

### Phase 2: Server-side dispatch refactor

- [ ] Refactor `DreamRSC.handleRequest` to support both protocols:
  1. Check for `ACTION_ID` header (existing JS-enabled path)
  2. If no header, check FormData for `$ACTION_*` keys (new no-JS path)
  3. Dispatch to the same handler registry either way
- [ ] Update `DreamRSC.handleFormRequest` to call `decodeAction` when no `ACTION_ID` header is present.
- [ ] Keep backward compatibility: the `ACTION_ID` header path continues to work for JS-enabled clients.

### Phase 3: Server-side HTML rendering of action forms

- [ ] When rendering `<form action={serverFn}>` to HTML, emit a hidden `<input type="hidden" name="$ACTION_ID_<hash>" value="" />` inside the form.
- [ ] This happens in `packages/reactDom/src/ReactServerDOM.ml` in the HTML rendering path, where `Action` props on `<form>` elements are serialized. Currently `action_value` (line 197) only produces the RSC `$F` reference; the HTML output needs the hidden input for no-JS submissions.

### Phase 4: Client-side `encodeFormAction`

- [ ] Implement the `encodeFormAction` callback in `packages/react-server-dom-esbuild/ReactServerDOMEsbuild.js` (replacing `undefined` at line 219).
- [ ] This callback receives a server reference and returns `{ name, value, action, enctype, method, target }` that React uses to configure the form's submission attributes during hydration.
- [ ] Wire it through `createResponseFromOptions`.

### Phase 5: `useActionState` / `decodeFormState` (optional, future)

- [ ] Implement `decodeFormState` in `packages/reactDom/src/ReactServerDOM.ml` to support `$ACTION_KEY`-based form state recovery.
- [ ] Replace the `useActionState` stub in `packages/react/src/React.ml:878` with a real implementation that works with the form state protocol.
- [ ] This enables progressive enhancement for stateful form actions (showing optimistic updates, handling errors).

### Phase 6: Bound server references (optional, future)

- [ ] Support `$ACTION_REF_` for bound server references (server functions with pre-filled arguments via `.bind()`).
- [ ] This requires changes to `Runtime.server_function` to carry a `bound` field and to the PPX to support partial application of server functions.
- [ ] The `action_to_json` function in `ReactServerDOM.ml:198` currently always emits `"bound": null`; this would need to emit the bound arguments when present.

## Design

### `decodeAction` signature

```ocaml
(** Decode a form submission that may contain $ACTION_* protocol fields.
    Returns [Some (action_id, user_form_data)] if an action was found,
    or [None] if no $ACTION_* keys are present (not a server action form). *)
val decodeAction :
  Js.FormData.t ->
  lookup:(string -> server_function option) ->
  (string * Js.FormData.t) option
```

### `decodeAction` implementation

```ocaml
let decodeAction formData ~lookup =
  let action_id = ref None in
  let user_entries = ref [] in
  Js.FormData.entries formData
  |> List.iter (fun (key, value) ->
    if String.starts_with ~prefix:"$ACTION_ID_" key then
      action_id := Some (String.sub key 11 (String.length key - 11))
    else if not (String.starts_with ~prefix:"$ACTION_" key) then
      user_entries := (key, value) :: !user_entries);
  match !action_id with
  | None -> None
  | Some id ->
    let user_fd = Js.FormData.make () in
    List.rev !user_entries |> List.iter (fun (k, v) -> Js.FormData.append user_fd k v);
    Some (id, user_fd)
```

### Updated `handleRequest` in DreamRSC.re

```reason
let handleRequest = (~lookup, request) => {
  let actionId = Dream.header(request, "ACTION_ID");
  let contentType = Dream.header(request, "Content-Type");

  switch (actionId, contentType) {
  // JS-enabled path: ACTION_ID header present
  | (Some(_), Some(ct)) when String.starts_with(ct, ~prefix="multipart/form-data") =>
    // existing handleFormRequest path
  | (Some(_), _) =>
    // existing handleRequestBody path

  // No-JS path: no ACTION_ID header, check FormData for $ACTION_* keys
  | (None, Some(ct)) when String.starts_with(ct, ~prefix="multipart/form-data") =>
    switch%lwt (Dream.multipart(request, ~csrf=false)) {
    | `Ok(formData) =>
      let formDataJs = /* convert Dream formData to Js.FormData.t */ in
      switch (ReactServerDOM.decodeAction(formDataJs, ~lookup)) {
      | Some((actionId, userFormData)) =>
        // dispatch to the FormData handler with userFormData
      | None =>
        // not a server action form, return 400 or handle as regular POST
      }
    }

  // No-JS path: url-encoded form
  | (None, Some(ct)) when String.starts_with(ct, ~prefix="application/x-www-form-urlencoded") =>
    // similar to above but read body as url-encoded form
  };
};
```

### HTML rendering of action forms

In the HTML rendering path where `Action` props on `<form>` are handled (around `packages/reactDom/src/ReactServerDOM.ml:330-333`), in addition to emitting the RSC `$F` reference, inject a hidden input into the form's children:

```html
<form action="" method="POST">
  <input type="hidden" name="$ACTION_ID_244965410" value="" />
  <!-- user's form content -->
</form>
```

The `action=""` makes the form POST to the same URL. The hidden input carries the server function ID. The `method="POST"` ensures the browser sends a POST request.

This needs careful handling because the current JSX prop processing for `action` produces either a string URL or an RSC `$F` reference, but for HTML output it needs to produce the form attributes plus the hidden input.

## Open questions

1. **Form `action` attribute value**: Should the rendered `action=""` (same URL) or should it be configurable? React uses `action` with a special URI scheme or empty string.

2. **CSRF protection**: Dream's `Dream.multipart(~csrf=false)` is currently used. With no-JS form submissions hitting the same endpoint, CSRF protection needs consideration. Dream has built-in CSRF middleware that could be re-enabled.

3. **Response format for no-JS**: When JS is disabled, the server can't return an RSC stream (there is no JS to parse it). The response should be a full HTML page (redirect + re-render). This requires the `streamFunctionResponse` handler to detect no-JS submissions and return HTML instead of RSC.

4. **`enctype`**: Standard form submissions use `application/x-www-form-urlencoded` by default. File uploads need `multipart/form-data`. The rendered form needs the correct `enctype` based on whether the server function accepts `Js.FormData.t`.

## Verification

- `make build`
- `make test`
- `make ppx-test`
- `make format-check`
- Manual testing: submit a form with JS disabled and verify the server dispatches correctly

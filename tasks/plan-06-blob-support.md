# Add `$B` (Blob) support to `decode_value`

## Problem

React's `processReply` on the client can encode `Blob` objects as `$B<hex_id>` references. The blob data is stored as a binary entry in the FormData, keyed by the decimal representation of the part ID. The current `decode_value` in `packages/reactDom/src/ReactServerDOM.ml:1179` returns `unsupported "Blob ($B)"`.

### When would this be used?

A server function receives a `Blob` argument that is NOT wrapped in a `Js.FormData.t`. For example:

```reason
[@react.server.function]
let uploadFile = (~blob: Blob.t): Js.Promise.t(string) => {
  // process the blob
};
```

The client calls `uploadFile(~blob=someBlob)`, and React's `processReply` encodes it as `$B<id>` with the binary data in FormData.

### Current alternative

The existing `Js.FormData.t` argument type already handles file uploads. A server function like:

```reason
[@react.server.function]
let uploadForm = (formData: Js.FormData.t): Js.Promise.t(string) => {
  let file = Js.FormData.get(formData, "file");
  // ...
};
```

The user wraps their file in a FormData on the client. This works today.

## Assessment

This is **low priority** because:

1. The `Js.FormData.t` path covers the primary file upload use case.
2. There is no `Blob.t` type in the native OCaml implementation (`packages/Js/` has no blob module).
3. Dream's multipart handling gives us strings, not binary blobs. Supporting `$B` would require either a new `Blob.t` type or mapping to `string`/`bytes`.

## Tasks (if pursued)

- [ ] Define what OCaml type `$B` should decode to: `string` (raw bytes), `bytes`, or a new `Blob.t` type.
- [ ] Add a `Blob` module to `packages/Js/` or `packages/webapi/` with at least `type t` and basic accessors.
- [ ] Handle `$B` in `decode_value`: resolve from FormData by hex ID, return the binary content.
- [ ] Add a `blob` case to `make_json_decoder` or decide that blobs are only supported via `Js.FormData.t`.
- [ ] Add unit tests in `test_RSC_decoders.ml`.

## Design sketch

```ocaml
| 'B' -> (
    match formData with
    | Some fd ->
        let key = string_of_int (int_of_string ("0x" ^ rest)) in
        (try
          let (`String data) = Js.FormData.get fd key in
          Ok (`String data)  (* return blob content as string *)
        with Not_found -> Error "decodeReply: Blob ($B) FormData entry not found")
    | None -> Error "decodeReply: Blob ($B) requires FormData")
```

The blob data arrives as a binary FormData entry. On the native side it would be received as a string (since Dream represents all multipart values as strings). The question is what OCaml type this maps to in the server function signature.

## Depends on

- A clear use case beyond what `Js.FormData.t` already provides
- A `Blob.t` type decision

## Verification

- `make build`
- `make test`
- `make format-check`

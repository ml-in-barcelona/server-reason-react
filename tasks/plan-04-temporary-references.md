# Add `$T` (Temporary Reference) support to `decode_value`

## Problem

React's wire protocol supports `$T<id>` (Temporary References) for round-tripping opaque server-side values through client components back to server functions. The current `decode_value` in `packages/reactDom/src/ReactServerDOM.ml:1175` returns `unsupported "Temporary Reference ($T)"`.

### When is `$T` needed?

1. Server renders a component, passing a complex value (e.g. a database record, a closure, a non-serializable object) as a prop to a client component.
2. The client component receives it as an opaque reference (it cannot inspect it).
3. The client passes the value back to a server function as an argument.
4. React's `processReply` on the client encodes it as `$T<id>` using a `temporaryReferences` map.
5. The server needs to resolve `$T<id>` back to the original value.

The client-side infrastructure already passes `temporaryReferences` through: `packages/react-server-dom-esbuild/ReactServerDOMEsbuild.js:221-223` threads it to `createResponse`, and `encodeReply` at line 257 threads it to `processReply`.

What is missing is the server-side decode path and the registry that maps reference IDs back to original values.

## Tasks

- [ ] Add a `temporary_references` parameter to `decode_value` in `packages/reactDom/src/ReactServerDOM.ml`.
- [ ] Handle `$T` in `decode_value`: look up the reference ID, return the resolved value or error.
- [ ] Thread `temporary_references` through `decodeReply` and `decodeFormDataReply`.
- [ ] Update `packages/reactDom/src/ReactServerDOM.mli` with the new signatures.
- [ ] Design the server-side `TemporaryReferences` module type and registration API.
- [ ] Update `demo/dream-rsc/DreamRSC.re` to create and pass temporary references during the render-then-action cycle.
- [ ] Add unit tests in `packages/reactDom/test/test_RSC_decoders.ml`.
- [ ] Run `make build && make test`.

## Design

### decode_value changes

Add an optional `?temporaryReferences` parameter (alongside the existing `?formData`):

```ocaml
type temporary_references = string -> Yojson.Basic.t option

let rec decode_value ?formData ?temporaryReferences json =
  match json with
  | `String value when ... ->
    match String.get value 1 with
    | ...
    | 'T' -> (
        match temporaryReferences with
        | Some lookup -> (
            match lookup rest with
            | Some resolved -> Ok resolved
            | None -> Error (Printf.sprintf "decodeReply: Temporary Reference $T%s not found" rest))
        | None -> Error "decodeReply: Temporary Reference ($T) requires a temporaryReferences resolver")
    | ...
```

### Updated signatures

```ocaml
val decodeReply :
  ?temporaryReferences:(string -> Yojson.Basic.t option) ->
  string ->
  (Yojson.Basic.t array, string) result

val decodeFormDataReply :
  ?temporaryReferences:(string -> Yojson.Basic.t option) ->
  Js.FormData.t ->
  (Yojson.Basic.t array * Js.FormData.t, string) result
```

### Server-side lifecycle

The render phase needs to produce a `TemporaryReferences` map. When rendering props for client components, any non-serializable value gets assigned a temporary ID and stored in the map. The subsequent action request receives this map and uses it to decode `$T` references.

This requires coordination between the render pass and the action dispatch, which `DreamRSC.re` already partially supports via `with_render_context` / `with_action_context` using `Lwt.key`.

### Open questions

- What is the scope of a temporary reference? Per-request? Per-session? React uses a WeakMap on the client, suggesting per-page-lifecycle. On the server, per-request-pair (render + subsequent action) is the natural boundary.
- Should the `TemporaryReferences` API be a module type in `ReactServerDOM` or a simpler function parameter? A function parameter (`string -> Yojson.Basic.t option`) is simpler and more flexible.
- How are temporary reference IDs assigned during render? This is a separate concern from decoding - it requires changes to the RSC model serialization path, not covered in this plan.

## Verification

- `make build`
- `make test`
- `make format-check`

# Fix `char` bug and add `result` to `make_json_decoder`

## Problem

The `make_json_decoder` function in `packages/server-reason-react-ppx/server_reason_react_ppx.ml:977-1025` maps OCaml types to `Melange_json.Primitives.*_of_json` decoders for server function argument deserialization. Two issues:

1. **Bug:** Line 984 emits `Melange_json.Primitives.char_of_json`, but this function does not exist in `melange-json-native`. Any server function with a `char` argument will produce a compile error. The `Melange_json.Primitives` module only exposes: `string`, `bool`, `float`, `int`, `int64`, `option`, `unit`, `result`, `list`, `array`.

2. **Gap:** `result` has no explicit match arm in `make_json_decoder`. It falls through to the `[%of_json: ...]` fallback (line 1025), which requires the type to have `[@@deriving json]`. Meanwhile, `Melange_json.Primitives.result_of_json` exists and takes two decoder arguments `(ok_of_json, err_of_json)`, and the RSC codec system already has built-in `result_to_rsc`/`result_of_rsc` in `packages/rsc/ppx_common/ppx_deriving_tools.ml:68`.

## Tasks

- [ ] Fix the `char` decoder in `make_json_decoder` by inlining a decoder (matching the RSC codec approach from `packages/rsc/native/RSC.ml:87-90`).
- [ ] Add an explicit `result` match arm to `make_json_decoder`, using `Melange_json.Primitives.result_of_json` with two recursive decoder arguments.
- [ ] Add cram test inputs for both types in `packages/server-reason-react-ppx/cram/server-function-on-server.t/input.re`.
- [ ] Run `make ppx-test-promote` to capture snapshots, then `make ppx-test` to verify.
- [ ] Run `make build` and `make test` to verify nothing breaks.

## Design

### Fix `char` (line 984)

Replace:
```ocaml
| [%type: char] -> [%expr Melange_json.Primitives.char_of_json]
```

With an inline decoder that reads a string and extracts the first character, mirroring `packages/rsc/native/RSC.ml:87-90`:
```ocaml
| [%type: char] ->
    [%expr fun json ->
      let s = Melange_json.Primitives.string_of_json json in
      if String.length s = 1 then String.get s 0
      else Melange_json.of_json_error ~json "expected a single-character string"]
```

### Add `result` (between the `array` arm at line 994 and the tuple arm at line 995)

```ocaml
| { ptyp_desc = Ptyp_constr ({ txt = Lident "result"; _ }, [ ok_type; err_type ]); _ } ->
    let decode_ok = make_json_decoder ~loc ok_type in
    let decode_err = make_json_decoder ~loc err_type in
    [%expr Melange_json.Primitives.result_of_json [%e decode_ok] [%e decode_err]]
```

This follows the exact same pattern as `option`, `list`, and `array` but with two type parameters. The wire format is `["Ok", value]` or `["Error", value]` (matching the RSC codec format in `packages/rsc/native/RSC.ml:48-50`).

## Verification

- `make build`
- `make ppx-test`
- `make test`
- `make format-check`

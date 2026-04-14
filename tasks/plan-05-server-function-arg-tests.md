# Expand test coverage for server function argument types

## Problem

The server function cram tests in `packages/server-reason-react-ppx/cram/server-function-on-server.t/input.re` and `server-function-on-client.t/input.re` only exercise `string`, `int`, `option(string)`, and `Js.FormData.t` arguments. No other types are tested.

This means there is zero PPX snapshot coverage for `bool`, `float`, `int64`, `list`, `array`, tuples, `result` (after plan-01), or nested parameterized types like `list(option(string))`.

Additionally, the `decodeReply` unit tests in `packages/reactDom/test/test_RSC_decoders.ml` comprehensively test `decode_value` but there are no end-to-end tests that verify the full path: JSON -> `decode_value` -> `make_json_decoder`-generated code -> typed OCaml value.

## Tasks

### PPX cram tests (server side)

- [ ] Add a server function with `bool` argument to `server-function-on-server.t/input.re`.
- [ ] Add a server function with `float` argument.
- [ ] Add a server function with `int64` argument.
- [ ] Add a server function with `list(string)` argument.
- [ ] Add a server function with `array(int)` argument.
- [ ] Add a server function with `(string, int)` tuple argument.
- [ ] Add a server function with `(int, string, bool)` triple argument.
- [ ] Add a server function with `result(string, string)` argument (depends on plan-01).
- [ ] Add a server function with `option(int)` argument (tests non-string inner type for option).
- [ ] Add a server function with nested `list(option(string))` argument.
- [ ] Add a server function with nested `result(list(int), string)` argument.

### PPX cram tests (client side)

- [ ] Mirror a representative subset of the above in `server-function-on-client.t/input.re` to verify the RSC response decoding path generates correct `[%of_rsc: ...]` calls for these types.

### Snapshot promotion

- [ ] Run `make ppx-test-promote` to generate new snapshots.
- [ ] Review the generated decoder code in `run.t` to verify correctness manually.
- [ ] Run `make ppx-test` to confirm stability.

### Build verification

- [ ] Run `make build` to confirm the generated code compiles (cram tests use `dune describe pp` which only checks PPX output, not compilation).
- [ ] Run `make test` for full test suite.

## Design

Each new test case follows the existing pattern in the input files:

```reason
[@react.server.function]
let withBoolArg = (~flag: bool): Js.Promise.t(string) => {
  Js.Promise.resolve(flag ? "yes" : "no");
};
```

The cram test snapshots will show the generated `FunctionReferences.register` call with the appropriate `Melange_json.Primitives.*_of_json` decoder for each type, which serves as documentation of the decoder mapping.

## Expected decoder output per type

| Argument type | Expected generated decoder |
|---|---|
| `bool` | `Melange_json.Primitives.bool_of_json` |
| `float` | `Melange_json.Primitives.float_of_json` |
| `int64` | `Melange_json.Primitives.int64_of_json` |
| `list(string)` | `Melange_json.Primitives.list_of_json Melange_json.Primitives.string_of_json` |
| `array(int)` | `Melange_json.Primitives.array_of_json Melange_json.Primitives.int_of_json` |
| `(string, int)` | Inline `match json with \| \`List [a;b] -> (string_of_json a, int_of_json b)` |
| `result(string, string)` | `Melange_json.Primitives.result_of_json string_of_json string_of_json` (after plan-01) |
| `option(int)` | `Melange_json.Primitives.option_of_json Melange_json.Primitives.int_of_json` |
| `list(option(string))` | `list_of_json (option_of_json string_of_json)` |

## Verification

- `make ppx-test-promote && make ppx-test`
- `make build`
- `make test`
- `make format-check`

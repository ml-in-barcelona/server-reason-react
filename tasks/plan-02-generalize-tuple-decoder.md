# Generalize tuple handling in `make_json_decoder`

## Problem

`make_json_decoder` in `packages/server-reason-react-ppx/server_reason_react_ppx.ml:995-1021` has three nearly identical hard-coded arms for 2-tuples, 3-tuples, and 4-tuples. Each generates:

```ocaml
fun json -> match json with
| `List [ a; b; ... ] -> (decode_a a, decode_b b, ...)
| _ -> Melange_json.of_json_error ~json "expected a JSON array of length N"
```

5+ element tuples silently fall through to `[%of_json: ...]` (line 1025), which may or may not work depending on whether the user has derivers set up. This is inconsistent: if 4-tuples work out of the box, 5-tuples should too.

The RSC codec system has a similar limitation: `packages/rsc/native/RSC.ml` only has `tuple2_to_rsc` through `tuple4_to_rsc` (lines 54-58), and `packages/rsc/ppx_common/ppx_deriving_tools.ml` generates tuple codecs inline via AST generation for arbitrary-length tuples.

## Tasks

- [ ] Extract a helper function `make_tuple_json_decoder ~loc types` that takes a list of `core_type` and generates the inline decoder for N elements.
- [ ] Replace the three hard-coded arms (lines 995-1021) with a single `Ptyp_tuple` match that delegates to the helper.
- [ ] Verify existing cram snapshots are byte-identical for 2/3/4-tuples after the refactor (run `make ppx-test` without promoting first).
- [ ] Add cram test cases for a 5-tuple and 6-tuple server function argument.
- [ ] Promote and verify snapshots.

## Design

The helper generates AST nodes programmatically:

```ocaml
let make_tuple_json_decoder ~loc types =
  let n = List.length types in
  (* Generate fresh variable names: a, b, c, ... *)
  let vars = List.mapi (fun i _ -> Printf.sprintf "t%d" i) types in
  (* Generate decoders for each element *)
  let decoders = List.map (make_json_decoder ~loc) types in
  (* Build the pattern: `List [ t0; t1; t2; ... ] *)
  let list_pat = (* ppat_construct for each var *) in
  (* Build the tuple expression: (decode_0 t0, decode_1 t1, ...) *)
  let tuple_expr = pexp_tuple ~loc (List.map2 (fun decode var -> [%expr [%e decode] [%e evar ~loc var]]) decoders vars) in
  let error_msg = Printf.sprintf "expected a JSON array of length %d" n in
  [%expr fun json -> match json with
    | [%p list_pat] -> [%e tuple_expr]
    | _ -> Melange_json.of_json_error ~json [%e estring ~loc error_msg]]
```

Then the match arm becomes:

```ocaml
| { ptyp_desc = Ptyp_tuple elements; _ } when List.length elements >= 2 ->
    make_tuple_json_decoder ~loc elements
```

This handles all tuple arities uniformly.

Note: single-element "tuples" `Ptyp_tuple [a]` are not valid OCaml (the compiler prevents them), so the `>= 2` guard is just defensive.

## Verification

- `make build`
- `make ppx-test` (should pass without promotion for existing 2/3/4-tuple tests)
- `make ppx-test-promote` (for new 5/6-tuple tests)
- `make ppx-test`
- `make format-check`

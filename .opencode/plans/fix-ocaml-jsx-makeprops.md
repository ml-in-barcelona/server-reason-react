# Fix OCaml syntax JSX expansion generating incorrect `makeProps` calls

## Problem

In OCaml/mlx syntax, the PPX generates an extra `()` before labeled arguments in `makeProps` calls:

```ocaml
(* BUG: *)    Note_header.makeProps () ~title ~preview ~updated_at ()
(* CORRECT: *) Note_header.makeProps ~title ~preview ~updated_at ()
```

Root cause: `strip_final_unit_arg` (line 85-88) only strips `(Nolabel, ())` from the END of the arg list. mlx places `()` at the BEGINNING.

## Changes

### 1. Fix `strip_final_unit_arg` → `strip_unit_args`

**File**: `packages/server-reason-react-ppx/server_reason_react_ppx.ml`

**Lines 85-88** — Change from:
```ocaml
let strip_final_unit_arg args =
  match List.rev args with
  | (Nolabel, { pexp_desc = Pexp_construct ({ txt = Lident "()"; _ }, None); _ }) :: rest -> List.rev rest
  | _ -> args
```

To:
```ocaml
let strip_unit_args args =
  List.filter args ~f:(fun (label, expr) ->
      match (label, expr.pexp_desc) with
      | Nolabel, Pexp_construct ({ txt = Lident "()"; _ }, None) -> false
      | _ -> true)
```

**Line 108** — Update reference from `strip_final_unit_arg` to `strip_unit_args`:
```ocaml
  let non_key_args = strip_unit_args non_key_args in
```

### 2. Add OCaml-syntax cram test for uppercase JSX calls

Create `packages/server-reason-react-ppx/cram/upper-calls-ocaml.t/` with:

**`input.ml`** — OCaml-syntax JSX with unit before labeled args (mlx style):
```ocaml
(* Simulates mlx desugaring: <Upper /> *)
let upper = (Upper.createElement () [@JSX])

(* Simulates mlx desugaring: <Upper count /> *)
let upper_prop = (Upper.createElement () ~count [@JSX])

(* Simulates mlx desugaring: <Upper> foo </Upper> *)
let upper_children_single = fun foo -> (Upper.createElement () ~children:[foo] [@JSX])

(* Simulates mlx desugaring: <Foo.Bar a=1 b="1" /> *)
let upper_nested_module = (Foo.Bar.createElement () ~a:1 ~b:"1" [@JSX])
```

**`run.t`** — Cram test verifying correct expansion (no extra `()`):
```
  $ ../../standalone.exe --impl input.ml -o output.ml
  $ ocamlformat --enable-outside-detected-project --impl output.ml
  <expected output showing makeProps ~arg1 ~arg2 () without extra ()>
```

### 3. Run tests

```bash
make build    # Rebuild with the fix
make test     # All existing tests
make ppx-test # PPX cram tests specifically
```

### 4. Promote snapshots if needed

If existing test output changes (it shouldn't), review diffs:
```bash
make ppx-test-promote
```

## Verification

- All existing Reason-syntax cram tests must still pass unchanged
- New OCaml-syntax test must show `makeProps ~arg ()` (no extra `()`)
- `make build` must succeed

## Issue 2 (Event target types) — No action needed

The `.mli` already defines `target_like` with proper fields (`value`, `checked`, etc.). The bug report's claim of `< >` doesn't match the current code.

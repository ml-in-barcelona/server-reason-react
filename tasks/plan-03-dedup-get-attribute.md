# Deduplicate `Resources.get_attribute` and `get_html_attr`

## Problem

`ReactServerDOM.ml` has two identical functions that look up an attribute value by key from an `Html.attribute_list`:

1. **`Resources.get_attribute`** (line 98) — labeled `~key` argument, used inside the `Resources` nested module by `resource_key` (lines 105-106).
2. **`get_html_attr`** (line 932) — positional `key` argument, used by `classify_head_element` (lines 947, 950).

Both do the same thing: `List.find_map` over the attribute list matching `` `Value (k, v) `` where `k` equals the given key, returning `Some v` or `None`.

Neither function is exposed in the `.mli`. The `Resources` module is purely internal (no external callers). `get_html_attr` is also file-internal.

## Design

Move `get_html_attr` (and its companion `has_html_attr`) above the `Resources` module (before line 97), then replace `Resources.get_attribute` with calls to `get_html_attr`. This eliminates the duplicate without changing any signatures or behavior.

The positional-argument style (`get_html_attr key attrs`) is preferred over the labeled style (`get_attribute ~key attrs`) since it's simpler and matches the existing `has_html_attr` convention.

## Tasks

- [ ] Move `get_html_attr` and `has_html_attr` definitions (currently at lines 932-939) to just before the `Resources` module (before line 97).
- [ ] Inside `Resources`, delete `get_attribute` and update `resource_key` to call `get_html_attr` instead:
  ```ocaml
  let resource_key item =
    match (item : Html.node) with
    | { tag = "script"; attributes; _ } -> get_html_attr "src" attributes
    | { tag = "link"; attributes; _ } -> get_html_attr "href" attributes
    | _ -> None
  ```
- [ ] Remove the now-duplicate `get_html_attr` and `has_html_attr` definitions from their original location (around line 932).
- [ ] Run `make build` to verify compilation.
- [ ] Run `make test` to verify all 323 tests pass.
- [ ] Run `make format-check` to verify formatting.

## Verification

- `make build`
- `make test`
- `make format-check`

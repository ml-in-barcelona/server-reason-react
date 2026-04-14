# Plan: Simplify Head & Resource Management in ReactServerDOM.ml

## Goal
Make head management and resource management easier to reason about, without changing behavior.

## Steps

### Step 1: Extract `create_initial_resources`, `create_user_scripts` from render_html (lines 889-987)

Extract three helpers:
- `create_preload_link href` - single preload `<link>` node (deduplicates the two identical `List.map` blocks)
- `create_initial_resources ~bootstrap_scripts ~bootstrap_modules` - preload links for bootstrap resources
- `create_user_scripts ~root_data_payload ?bootstrapScriptContent ?bootstrapScripts ?bootstrapModules ()` - the `user_scripts` list

Then `render_html` calls these instead of building everything inline.

### Step 2: Rename Fiber fields for clarity

| Current | New | Rationale |
|---------|-----|-----------|
| `visited_first_lower_case` | `root_tag` | Communicates purpose: tracking root HTML tag |
| `hoisted_head` | `head_element` | Stores the `<head>` element |
| `hoisted_head_childrens` | `extra_head_children` | Elements promoted into `<head>` (fixes grammar) |
| `html_tag_attributes` | `html_attributes` | Simpler |

Also rename the Fiber setter/getter functions to match.

### Step 3: Extract `reconstruct_document` from render_html (lines 989-1011)

Move the post-render HTML document assembly into:
```ocaml
let reconstruct_document ~fiber ~root_html ~user_scripts ~skip_root = ...
```

This is the single place to understand (or modify) how the final document is assembled, including any future head reordering (issue #303).

### Step 4: Introduce `element_role` classification type

Replace the nested if/match cascade in `render_lower_case_element` with an explicit classification:

```ocaml
type element_role =
  | Html_root          (* <html> at document root *)
  | Head_section       (* <head> element *)
  | Body_section       (* <body> element *)
  | Hoistable_resource (* async <script>, <link rel=stylesheet precedence=...> *)
  | Hoistable_meta     (* <title>, <meta>, <link> outside head *)
  | Regular            (* everything else *)

let classify_element ~fiber ~tag ~attributes = ...
```

Then `render_lower_case_element` becomes a clean match on this type.

### Verification
Run `make test` after each step. No behavior changes expected.
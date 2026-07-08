# Area — html, runtime, styles-attribute, ReactDOMStyle

## Html (`packages/html/Html.ml`)
- **Escapers (both correct for their context):**
  - `escape` (`:9-30`) escapes `& < > ' "` for text nodes and double-quoted attribute values; `'`→`&apos;`.
  - `escape_attribute_value` / `add_attribute_escaped` (`:181-206`) escapes only `'`→`&#x27;` and `&`, for single-quoted attributes (RSC `data-payload='…'`). Safe: inside a quoted attribute the HTML tokenizer is in attribute-value state, so `</script>` in the payload cannot break out. CONFIRMED.
  - **Inconsistency:** `'`→`&apos;` in `escape` but `&#x27;` in the attribute escaper — two entity spellings for the same char, diverging from react-dom's uniform `&#x27;`. Finding 2.24.
- **`is_self_closing_tag` (`:1-7`)** includes non-void `image`, `basefont`, `bgsound`, `command`, `frame`; react-dom's list doesn't. `image` treated as void is wrong. Finding 2.24.
- **`" />"` with a space** on void tags (`:98`) — react-dom emits `/>`/`>`. Byte divergence.
- **Two serializers here** (`to_string` adds doctype + text separators; `pp` neither) plus ReactDOM's two — four total, drifting (finding 2.25, design tension T4/T5).

## Runtime (`packages/runtime/Runtime.ml`)
- `exception Impossible_in_ssr of string` (`:1`).
- `fail_impossible_action_in_ssr` (`:3-16`) prints a message + 8-frame callstack to **stdout** (should be stderr — corrupts stdout-based output streams), then raises. Used by every raising stub in webapi/fetch/Js/browser_ppx. Finding 2.17.
- `type 'callback server_function = { id : string; call : 'callback }` with a `QUESTION` comment admitting the callback's uncurried-ness is unenforced.

## ReactDOMStyle (`packages/reactDom/src/ReactDOMStyle.ml`)
- Fixed parameter order in `make` → serialization order follows the record definition, not JS object insertion order (tests literally named "order matters" bless this divergence from react-dom). Later-prop-wins overrides can't be expressed.
- `write_to_buffer` uses `v == ""` (physical equality) to skip empty values — a computed empty string isn't skipped, emitting `key:` with no value. Finding 2.31.
- `unsafeAddProp` comment says "last position" but prepends (so it's overridden, not overriding). `combine` TODO suggests `List.combine` which would zip, not append. Finding 2.31.
- `camelcaseToKebabcase` correctly preserves `--custom-props`.

## styles-attribute (`packages/styles-attribute`)
- Not deeply covered here; the primary style path in the render pipeline is `ReactDOMStyle`. A focused pass on `styles_attribute.ml` CSS serialization/escaping is recommended to close the gap (the earlier agent run for this package returned empty and was not repeated).

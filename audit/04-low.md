# Low findings — nits, typos, cosmetic drift

## 2.29 — `memo` / `memoCustomCompareProps` signatures incompatible with reason-react
- **Where:** `packages/react/src/React.ml:611-612`, `.mli:666-667`.
- **Status:** CONFIRMED. Maintainer: "Let's fix it."
- **Sync (2026-07-08, HEAD 39e22a6):** FIXED by #371 (054a7e7). `memo : 'component -> 'component` and `memoCustomCompareProps : 'component -> ('props -> 'props -> bool) -> 'component` (React.ml:625-626, .mli:675-676) — matches reason-react.
- **Issue:** reason-react: `memo: component('props) => component('props)` (1 arg). srr: `let memo f _component = f` (2 args), `.mli` `('props*'props->bool) -> 'a -> 'props*'props->bool`. Incompatible arity and shape.
- **Action & analysis:** [`investigations/memo-and-react-client.md`](investigations/memo-and-react-client.md).

## 2.30 — Public API typos frozen into signatures
- **Where:** `onEncrypetd` (should be `onEncrypted`) — `ReactDOM.ml:884,1378`, `.mli:274`; `fomat` (should be `format`) — `ReactDOM.ml:979,1468`, `.mli:364`.
- **Status:** CONFIRMED.
- **Issue:** Misspelled optional labels are part of the public `domProps` signature; `onEncrypetd` also means the real `onEncrypted` media event is unavailable.
- **Action:** Rename (breaking) or add correct aliases.

## 2.31 — `ReactDOMStyle` empty-value skip uses physical equality; misleading comments
- **Where:** `packages/reactDom/src/ReactDOMStyle.ml` — `write_to_buffer` `if v == ""`; `unsafeAddProp` "last position" comment but prepends; `combine` TODO suggests `List.combine` (which would zip, not append).
- **Status:** CONFIRMED.
- **Sync (2026-07-08, HEAD 39e22a6):** FIXED by 39e64ce (with regression test in test_renderToString.ml). Skip is now structural (`String.length v = 0`, ReactDOMStyle.ml:716-718); `unsafeAddProp` comment corrected. Remaining nit: the misleading `combine` TODO comment is still at :733.
- **Issue:** `v == ""` is physical equality — a computed empty string isn't skipped, emitting `key:` with no value.
- **Action:** Use `String.equal v ""`; fix comments.

## 2.32 — `React.cache` keys on `Obj.repr arg` → crashes on functional args
- **Where:** `packages/react/src/React.ml:629`.
- **Status:** PLAUSIBLE.
- **Issue:** `Hashtbl.find_opt fn_cache (Obj.repr arg)` uses structural hash/equality; if `arg` contains a closure, `Hashtbl` comparison raises `Invalid_argument "compare: functional value"` on a bucket collision.
- **Action:** Document that cached functions must take comparable args, or use physical-identity keying.

## 2.33 — Transparent core types + exported render internals (leaky abstraction / injection surface)
- **Where:** `packages/react/src/React.mli:583-614` (transparent `element`), `:695-700` (exported `current_tree_context`, `reset_component_id_state`, `check_did_render_id_hook`), `Model.t` transparent.
- **Status:** CONFIRMED.
- **Issue:** Users can hand-craft `Lower_case_element {tag="<script>…"}` (tag is never validated/escaped) or `Static {prerendered}` (an undocumented `dangerouslySetInnerHTML`), and can call render-id internals out of order.
- **Action:** See design tension T5 — abstract the type, provide smart constructors, hide id-state internals behind the renderer.

## Misc confirmed nits (from area audits)
- `Runtime.fail_impossible_action_in_ssr` prints to **stdout** (should be stderr) — `Runtime.ml:6-15`.
- `Belt` `*Exn` functions raise `Js.Exn.Error "File …"` instead of Melange's `Not_found` — `Belt_List.ml`, `Belt_Option.ml`, etc. Universal `try … with Not_found` catches on client, crashes on server. (agent)
- `Belt.Array.push` is a silent no-op sentinel on native — `Belt_Array.ml:408`. (agent)
- `Js.Array.isArray` is `fun _ -> true` — `Js_array.ml:10`. (agent)
- `Js.Dict` backed by `Hashtbl.add` keeps duplicate keys; iteration order is bucket order, not insertion order — `Js_dict.ml`. (agent)
- `Fetch.ml:155` typo `"sharedworder"`. (agent)
- CHANGES.md `0.5.0` section contains commits made *after* the `0.5.0` tag; tag isn't an ancestor of `main`. (agent)
- Two README doc links 404 (`browser_only.html`, `belt_native/…`); `React.use` referenced (renamed to `Experimental.usePromise`). (agent — see [`areas/docs-dx.md`](areas/docs-dx.md))
- `make lib-test` targets a nonexistent `test/`; docs examples use invalid dune and non-existent APIs; `dune-project` declares mdx but no mdx stanza compiles the doc snippets. (agent)
- webapi test dir is `tests/_dune` (invisible to dune), zero assertions. (agent)

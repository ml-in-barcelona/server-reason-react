# Area — PPX layer

Four ppxes: `browser-ppx` (platform code elimination), `melange.ppx` (native `@mel.*` handling), `server-reason-react-ppx` (JSX + RSC client-component transform), `rsc/ppx_*` (RSC prop serialization).

## browser-ppx (`packages/browser-ppx/ppx.ml`)
- **`:220-222`** — `let%browser_only x = <ident>` → `let x = Obj.magic ()` typed `'a`; unifies with anything; **calling it segfaults** (no exception). CONFIRMED (SIGSEGV). Finding 2.19.
- **`:53-65`** — multi-param `let%browser_only f a b = …` collapses arity to 1 (matches `Pexp_function(param::_rest)`, discards `_rest`); partial application then raises during SSR even though the closure is never called. Syntax-dependent (Reason nested `fun`s keep params; OCaml/coalesced collapse). CONFIRMED, blessed in cram.
- **`:227`** — unmatched shapes (e.g. first param is `Pparam_newtype`) fall through to `do_nothing` → the browser body (with `Js.typeof` etc.) is kept verbatim on native, no raise, no alert. CONFIRMED, blessed.
- **`:167-170`** — drops `pval_constraint`/`Pexp_constraint` → platform-divergent typechecking (native infers `'a -> 'b`). CONFIRMED.
- **`:79-124`** — inconsistent raise messages: constraint path stringifies the whole function body into the exception; expression path uses the *parameter* name; `()` patterns yield `"<unkwnown>"` (sic), blessed 4×.
- **`:15-45`** — `switch%platform` drops `when` guards and discards the scrutinee's side effects. Multi-binding `let … and …` with `[@platform]` silently ignored. CONFIRMED.
- Eliminated code raises `Runtime.Impossible_in_ssr` after printing an 8-frame callstack to **stdout** (`packages/runtime/Runtime.ml`).

## melange.ppx (`packages/melange.ppx/ppx.ml`)
- Every arrow-typed `external` — regardless of `@mel.*` attribute — becomes a curried raising function (`:888-895`). No `[@alert]` attached, so server misuse is invisible at compile time (unlike browser_ppx). Finding 2.17/2.18.
- **`:455-462`** — `[@platform native]` not in the pass-through list → a genuine native external (or `include struct … end [@@platform native]`) is turned into a raising stub on the platform it targets. Also plain `external id : 'a -> 'a = "%identity"` with no attributes. CONFIRMED. High-severity footgun.
- **`:692-694`** — zero-arg `[@mel.send.pipe]` externals get **reversed** types: `external f : ret [@@mel.send.pipe: t]` → native `ret -> t` (Melange `t -> ret`). Breaks `event |> Event.preventDefault`. Non-`Ptyp_constr` first arg → arg inserted in wrong position. CONFIRMED via `.cmi`, blessed in cram.
- **`:657-668`** — `[@mel.as]` constant args become phantom `'a` params (arity drift); if the `mel.as` arg is first, zero params collected → module raises at load time. CONFIRMED.
- **`:643-647`** — `[@mel.send.pipe]` only honored if it's the *first* attribute (`List.hd`). CONFIRMED.
- Derivers: `js_converter.ml:4` `[@bs.as]` silently ignored (native `B→1`, Melange `B→5`) — cross-platform wire divergence, blessed. `[@mel.as N]` value continuation diverges from Melange (`N+1` vs "skip used"). CONFIRMED.
- Failure message printed to **stdout**; outer `raise` wraps a function that itself raises (dead code).

## server-reason-react-ppx
- JSX transform picks tiers: `Static {prerendered}` (`:531`), `Writer` via `ReactDOM.write_to_buffer` (`:510`), or variant. `Writer`/`Static` follow different serialization rules than the variant path (design tension T4/T5, finding 2.25).
- `DomProps.ml` shares the `defaultChecked`/`defaultValue`-as-literal bug (`:481-482`, finding 2.7) and the `xmlnsXlink` mistake (`:1391`, finding 2.6); but has the *correct* `xlink:actuate`/`xlink:arcrole` that the runtime `domProps` got wrong (2.6).
- Cram tests largely snapshot the transform output, including the browser_ppx bugs above (they're blessed). Two cram "typecheck" steps are no-ops: `sed … output.ml > output.ml` truncates before reading; another compiles a nonexistent `output.ml`. CONFIRMED.
- The location-correctness cram (`cram/locations/run`) is disabled (`.t` extension dropped) — "slow and fragile."

## rsc ppx
- Emits `// extract-client` / `// extract-server-function` marker comments consumed by `extract_client_components.ml`; module IDs derive from paths + hashing (xxhash/base32). Parity of that hash between the OCaml emit side and any JS side must be verified (see [`reactserverdom-rsc.md`](reactserverdom-rsc.md)).

> Note: the ppx agent report was truncated mid-`js_converter` section; the items above are the confirmed subset. A re-run focused solely on `rsc/ppx_common/ppx_deriving_tools.ml` prop-serialization type coverage (which types are supported / compile-error vs runtime-fail on unsupported) is recommended to close that gap.

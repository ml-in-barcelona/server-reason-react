# Area — Belt & Js (universal stdlib reimplementations)

Native reimplementations of Melange's `Belt` and `Js`. Contract: behavior-identical to the same code compiled with Melange (Q5 — "0 divergences"). See [`../investigations/quickjs-divergence-status.md`](../investigations/quickjs-divergence-status.md).

## Critical
- **`caml_hash.ml:9-10`** — int32 C primitives applied to `nativeint`; reads uninitialized memory → **`Belt.HashMap.Int/String` lose data nondeterministically** (~73–79% unstable). `HashMap.String.set;<alloc>;get`→`None`. CONFIRMED (probed). Finding 2.4.
- **`Belt_Option.ml:26`** — `getUnsafe = "%identity"` unsound on native (boxed `Some`); returns heap address; `string` case → possible segfault. CONFIRMED. Finding 2.5.

## Number formatting/parsing (partly quickjs — see investigation)
- `Belt_Float.ml:5-8` `toString` uses `%.12g`: `0.1+.0.2`→`"0.3"`, `nan`→`"nan"`, `inf`→`"inf"`. CONFIRMED.
- `Belt_Int.ml:4-7` `fromString`: `"10px"`→None, `"0x10"`→`Some 16`, `" 42 "`→None. CONFIRMED.
- `Js_float.ml:45` `fromString` error path → `Stdlib.float_of_string`: `"abc"` raises, `"1_0"`→`10.`. CONFIRMED.
- `Js_global.ml:205` `parseInt` uses int-capped `parse_int`: huge values → `nan`. CONFIRMED.
- `Js_math.ml:25` `_SQRT2 = 1.41421356237` (truncated). CONFIRMED.

## `Js.String` — byte vs UTF-16 (finding 2.14)
- Empty-match `replaceByRe`/`splitByRe` infinite-loop (`Js_string.ml:182-286`). CONFIRMED.
- quickjs UTF-16 indices used as UTF-8 byte offsets → corruption (`replaceByRe /b/ "éb"`→`"\195Xb"`). CONFIRMED.
- `length "é"`=2, `charCodeAt "é"`=195, `codePointAt`/`get`/`charAt` byte-based. CONFIRMED.
- Negative-index `startsWith`/`endsWith`/`includes`/`indexOf`/`slice`/`substr` raise or clamp wrong. CONFIRMED.
- `replace` uses `Str` (`:120-122`): `\1` in replacement raises `Failure`; `$&` not JS-interpreted. CONFIRMED.
- `split` with no separator defaults to the whole string; `limit` ignored in `splitByRe`. CONFIRMED.
- `trim` only strips `" \t\n\r"` (JS strips more); `toLowerCase` lacks Final_Sigma context. CONFIRMED.

## `Js.Date` — finding 2.15
- ISO no-TZ and legacy formats computed as UTC, not local (`Js_date.ml:386,460`). CONFIRMED.
- Trailing garbage accepted (`:384`). DST-wrong local offset (`:131-143`). Setters immutable (Melange mutates). `fromString(toUTCString d)`=NaN. CONFIRMED.
- `toLocaleString` etc. aliased to non-locale versions; `toString` lacks TZ name. CONFIRMED.

## Other `Js.*`
- `Js_array.ml:10` `isArray = fun _ -> true`. `includes` uses structural `=` (NaN≠NaN in JS is inverted). Negative-`start` `indexOf`/`lastIndexOfFrom` diverge. CONFIRMED.
- `Js_dict.ml` backed by `Hashtbl.add`: duplicate keys retained; iteration is bucket order, not insertion order. CONFIRMED.
- `Js_console.ml` all log fns are silent no-ops; `.mli` narrows to `string` so `Js.log 42` won't compile. CONFIRMED.
- `Js_promise.ml:50` `race [||]` raises (JS: forever-pending). CONFIRMED.
- `Js_nullable.ml:10` `bind : 'b t -> ('b -> 'b) -> 'b t` (Melange `'a -> ('a -> 'b) -> 'b t`). CONFIRMED.
- `Js_bigint.ml:55-56` hex literals with `e`/`E` digits parse to 0. CONFIRMED.
- `Js.Set`/`Map`/`WeakSet`/`WeakMap`/`Typed_array` are type-only stubs. `Js.FormData` semantics differ (get returns last/raises). CONFIRMED.

## ~200 raising stubs, no `[@alert]` (finding 2.17)
- Entire `Js.Math` (except sin/cos + constants), all `Js.Json`, `Js.Global` timers, `Js.Exn` accessors, most `Js.Array` mutators, `Js.Vector`, `Js.Types` raise `Impossible_in_ssr` at runtime with no compile-time signal, printing to stdout first. CONFIRMED.

## Belt exceptions
- All `*Exn` raise `Js.Exn.Error "File …"` where Melange raises `Not_found`/`Assert_failure` → universal `try … with Not_found` catches on client, crashes on server. Several hardcode a fake path `"../others/internal_map.cppo.ml"`. CONFIRMED.
- `Belt_Array.push` silent no-op sentinel on native. CONFIRMED.

## Tests
- Zero tests: `Js.Array`, `Js.Math`, `Js.Int`, `Js.Json`, `Js.Null`, `Js.Nullable`, `Js.Exn`, `Js.Console`, `Js.Vector`, `Js.Types`, `Js.Set/Map/…`, `Js.Typed_array`, `Js.FormData`. `Belt.Range`, generic `Belt.HashSet`.
- Tests assert native self-consistency, not JS-equivalence: dict duplicate-key/order tests bless divergent output; `assert_raises`/`helpers.ml:29-32` is tautological (any exception passes); `Alcotest.float 2.` gives ±2.0 tolerance; known-broken cases commented out (negative slice/substr, non-ASCII char funcs, big-int parseInt).

## `Obj.magic`/`%identity` audit
- Unsound: `Belt_Option.getUnsafe` (2.5), `caml_hash` FFI (2.4).
- Sound: `Js` null/undefined/nullable `= 'a option` identities; `Belt_List` C-stub tail mutation; `Belt_Id` magic (identity natively).

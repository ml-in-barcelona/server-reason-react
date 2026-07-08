# Investigation — quickjs divergence status (Q5)

**Maintainer contract:** "0 divergences. We shipped an update into quickjs to fix all of them."

**Installed:** `quickjs 0.4.2`, pinned to `git+https://github.com/ml-in-barcelona/quickjs.ml.git`. It exposes JS-correct primitives: `Quickjs.Global.parse_int`, `Quickjs.Global.parse_float`, `Quickjs.Number.to_string`/`to_fixed`/`to_precision`/`to_exponential`/`to_radix`, and `Quickjs.RegExp` (UTF-16-indexed).

**Verdict:** the quickjs update is real and correct, and `Js.Float`/`Js.Number` formatting now routes through it. But several OCaml call sites **still bypass quickjs** or use the wrong variant, and the most dangerous divergences are unrelated to quickjs. So the 0-divergence contract is **not yet met**, not because quickjs is wrong, but because the OCaml layer doesn't fully use it.

## Routes correctly through quickjs (fixed)

- `Js.Float.toString` / `toFixed` / `toPrecision` / `toExponential` — `packages/Js/lib/Js_float.ml:22-43` → `Quickjs.Number.Prototype.*`. ✅
- `Js.Global.parseFloat` — `Js_global.ml:179` → `Quickjs.Global.parse_float`. ✅
- `Js.String` regex *compilation/execution* — via `Quickjs.RegExp`. ✅ (but index handling around it is still byte-based — see below.)

## Still bypasses quickjs (live divergences)

| Site | Current | Divergence | Fix |
|------|---------|------------|-----|
| `Belt.Float.toString` | `Belt_Float.ml:5-8` `Stdlib.string_of_float` (`%.12g`) | `0.1+.0.2`→`"0.3"`; `nan`→`"nan"`; `inf`→`"inf"` | route to `Quickjs.Number.to_string` |
| `Belt.Int.fromString` | `Belt_Int.ml:4-7` `int_of_string_opt`/`float_of_string` | `"10px"`→None; `"0x10"`→`Some 16`; `" 42 "`→None | `Quickjs.Global.parse_int ~radix:10` |
| `Belt.Float.fromString` | `Belt_Float.ml:3` `float_of_string` | `"3.5px"`→None; `"0x10"`→`Some 16.` | `Quickjs.Global.parse_float` |
| `Js.Float.fromString` | `Js_float.ml:45` falls back to `Stdlib.float_of_string` on error | `"abc"` raises `Failure` (JS NaN); `"1_0"`→`10.` | catch → NaN, or `Quickjs.Global.parse_float` |
| `Js.Global.parseInt` | `Js_global.ml:205` `Quickjs.Global.parse_int` (int-capped) | `"9999…(26 digits)"`→`nan` (JS `1e26`) | use `parse_int_float` variant |
| `Js.Math._SQRT2` | `Js_math.ml:25` literal `1.41421356237` | truncated vs `1.4142135623730951` | correct the constant |

## Divergences unrelated to quickjs (won't be fixed by any quickjs update)

- **`Belt.HashMap.Int/String` data loss** — `caml_hash.ml:9-10` FFI misuse (finding 2.4). Pure OCaml/C-binding bug.
- **`Belt.Option.getUnsafe`** — unsound `%identity` (2.5).
- **`Js.String` byte-vs-UTF-16** — `length`/`charCodeAt`/`indexOf`/`slice`/`replace`/empty-match loops (2.14). The regex engine is UTF-16, but the surrounding index arithmetic is UTF-8-byte-based; and `replace` uses `Str`, not quickjs.
- **`Js.Date` local/UTC parsing** — `Js_date.ml:386,460` treat no-TZ/legacy as UTC (2.15).
- **`Belt` `*Exn` raise `Js.Exn.Error` not `Not_found`** — catch-site divergence.
- **`Js.Dict` duplicate keys / bucket-order iteration**, **`Js.Array.isArray = true`**, **`url` WHATWG gaps** (2.22).

## Recommendation

1. Route the six "still bypasses" sites through quickjs (mechanical).
2. Treat the "unrelated" list as separate correctness work (2.4, 2.5, 2.14, 2.15, 2.22).
3. **Enforce the contract in CI** (design tension T3): the `arch/server` bun scripts already run real Melange/JS; extend them into a differential harness that feeds a fixed input corpus through both native and Melange-compiled JS and asserts byte-equality on `Belt`/`Js`/`url`/date/string outputs. Otherwise regressions like the Belt bypasses reappear silently — they're exactly the class of bug a "0 divergences" contract exists to catch.

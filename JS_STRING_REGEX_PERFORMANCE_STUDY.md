# `Js.String` regular-expression scaling study

Date: 2026-07-22

Suggested issue title: `Make Js.String global regular-expression operations scale linearly`

## Summary

The released server-reason-react 0.5.0 does not improve this behavior. The old Ahrefs pin at
`1a32b96`, the 0.5.0 tag at `902ca32`, and `main` at the start of this study (`e5e1bbf`) contain identical
`packages/Js/lib/Js_string.ml` and `packages/Js/lib/Js_re.ml` implementations.
The implementation first landed in `e6aa297` on 2026-07-10 and has not changed
since.

In that baseline, both `Js.String.replaceByRe` and `Js.String.splitByRe` take quadratic time when
the number of global matches grows with the input size. On a 16 KB ASCII string
with one match every ten bytes, each operation takes roughly 0.4 seconds and
allocates about 3 GB.

The main baseline cost is below `Js.String`: every `Quickjs.RegExp.exec` invocation copies
the complete input into a new C buffer. A global replacement or split calls
`exec` once per match, so `m` matches over an `n`-byte input cost `O(n * m)`.
Non-ASCII input does more work because each `exec` also rebuilds the UTF-16 map
and converted buffer.

Two additional quadratic paths exist in `Js_string.ml`:

1. UTF-16 indices are converted to UTF-8 byte offsets by scanning from byte zero
   for each match or output segment.
2. `replaceByRe` creates complete prefix and suffix strings for every match,
   even when the replacement contains neither the JavaScript prefix token
   (dollar-backtick) nor the suffix token (`$'`).

The fix is implemented in quickjs.ml 0.5.1 and server-reason-react 0.5.1.
quickjs 0.5.1 adds a prepared-input API;
the `Js.String` global replacement and split drivers use it, consume exact byte
ranges, and write replacements directly. The 16 KB dense ASCII cases now take
about 0.8-1.1 ms and allocate 3.9-4.8 MB instead of taking 0.4-0.5 seconds and
allocating roughly 3 GB.

## Version comparison

| Version | Commit | `Js_string.ml` versus prior Ahrefs pin |
| --- | --- | --- |
| Prior Ahrefs pin | `1a32b96` | baseline |
| server-reason-react 0.5.0 | `902ca32` | identical |
| Current `main` during this study | `e5e1bbf` | identical to 0.5.0 |

Commands used to verify this:

```sh
git diff --quiet 1a32b96 902ca32 -- \
  packages/Js/lib/Js_string.ml packages/Js/lib/Js_re.ml
git diff --quiet 902ca32 e5e1bbf -- \
  packages/Js/lib/Js_string.ml packages/Js/lib/Js_re.ml
```

Both commands exit with status 0.

The quickjs dependency is `quickjs 0.5.0` in both tested setups.

## Reproduction

The benchmark source is in `benchmark/regex-study/`.

Run it from the repository root:

```sh
opam exec --switch=. -- dune exec benchmark/regex-study/regex_scaling.exe
```

Environment:

```text
Linux 6.12.86+deb12-amd64 x86_64
AMD EPYC 9755
OCaml 5.4.0
quickjs 0.5.1
server-reason-react 0.5.1 release candidate
```

The dense input is ASCII. Every tenth byte is `x`. The benchmarks use `/x/g`
for replacement and `/(x)/g` for splitting. Pattern compilation occurs inside
each measured operation, matching inline `[%re]` use. Compilation takes about
2 microseconds and does not explain the scaling.

## Baseline results

### Dense global matches

| Bytes | Matches | `replaceByRe` us/op | `Js.Re.exec` loop us/op | UTF-16 offset loop us/op | `splitByRe` us/op |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1,000 | 100 | 1,488 | 1,313 | 154 | 1,543 |
| 2,000 | 200 | 6,176 | 5,290 | 613 | 6,329 |
| 4,000 | 400 | 25,139 | 21,678 | 2,529 | 26,618 |
| 8,000 | 800 | 107,195 | 81,407 | 10,079 | 110,597 |
| 16,000 | 1,600 | 378,628 | 322,137 | 39,592 | 498,318 |

Doubling both input size and match count costs about four times as much. The
plain `Js.Re.exec` loop has the same curve, which shows that the dominant cost
is already present before `replaceByRe` or `splitByRe` builds its result.

### Allocation

| Bytes | Matches | `replaceByRe` allocated/op | `Js.Re.exec` loop allocated/op | `splitByRe` allocated/op |
| ---: | ---: | ---: | ---: | ---: |
| 1,000 | 100 | 12.4 MB | 12.2 MB | 12.3 MB |
| 2,000 | 200 | 48.9 MB | 48.5 MB | 48.6 MB |
| 4,000 | 400 | 194.7 MB | 193.0 MB | 193.3 MB |
| 8,000 | 800 | 776.5 MB | 769.9 MB | 770.5 MB |
| 16,000 | 1,600 | 3.10 GB | 3.08 GB | 3.08 GB |

The `Js.Re.exec` loop accounts for nearly all allocations. This agrees with the
source: each match recreates Ctypes arrays and copies the complete input.

### No matches

`replaceByRe /x/g` over strings containing no `x` scales linearly because it
calls `exec` once:

| Bytes | us/op |
| ---: | ---: |
| 1,000 | 23 |
| 2,000 | 46 |
| 4,000 | 104 |
| 8,000 | 170 |
| 16,000 | 410 |

Match count, rather than regex compilation, triggers the quadratic behavior.

## Post-fix results

The same benchmark against the prepared-input implementation produces linear
time and allocation growth.

### Dense ASCII matches

| Bytes | Matches | `replaceByRe` us/op | prepared `Js.Re` loop us/op | `splitByRe` us/op |
| ---: | ---: | ---: | ---: | ---: |
| 1,000 | 100 | 46 | 40 | 64 |
| 2,000 | 200 | 94 | 82 | 137 |
| 4,000 | 400 | 189 | 163 | 272 |
| 8,000 | 800 | 380 | 319 | 544 |
| 16,000 | 1,600 | 794 | 624 | 1,085 |

| Bytes | `replaceByRe` allocated/op | prepared `Js.Re` loop allocated/op | `splitByRe` allocated/op |
| ---: | ---: | ---: | ---: |
| 1,000 | 247 KB | 236 KB | 309 KB |
| 2,000 | 489 KB | 467 KB | 608 KB |
| 4,000 | 973 KB | 929 KB | 1.20 MB |
| 8,000 | 1.94 MB | 1.85 MB | 2.40 MB |
| 16,000 | 3.88 MB | 3.70 MB | 4.79 MB |

At 16 KB, replacement is about 477 times faster and allocates about 800 times
less memory than the baseline. Split is about 459 times faster and allocates
about 644 times less memory. Allocation approximately doubles when both input
size and match count double.

### Dense UTF-8 matches

The UTF-8 fixture repeats `ééééx`, so each match exercises the prepared UTF-16
buffer and index map.

| Bytes | Matches | `replaceByRe` us/op | `replaceByRe` allocated/op | `splitByRe` us/op | `splitByRe` allocated/op |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1,000 | 111 | 58 | 292 KB | 76 | 365 KB |
| 2,000 | 222 | 119 | 579 KB | 161 | 718 KB |
| 4,000 | 444 | 238 | 1.15 MB | 322 | 1.42 MB |
| 8,000 | 888 | 476 | 2.30 MB | 622 | 2.84 MB |
| 16,000 | 1,777 | 1,045 | 4.60 MB | 1,267 | 5.66 MB |

### One-shot `Js.Re.exec`

`Js.Re.exec ~str` remains a one-shot API and prepares the supplied string on
each call. Repeated callers that own the iteration must use `Js.Re.Prepared`;
the benchmark's original `Js.Re.exec` loop remains quadratic by design. The
public `Js.String` global operations no longer use that path.

## Baseline source analysis

### 1. `Quickjs.RegExp.exec` rebuilds the input for every match

`quickjs/lib/RegExp.ml` creates fresh capture storage on every call. For ASCII
input it calls `fill_carray_of_string input`. For non-ASCII input it additionally
calls `build_utf16_map input`, `utf8_to_utf16_bytes input`, and then
`fill_carray_of_string` on the converted string.

Simplified from `Quickjs.RegExp.exec`:

```ocaml
let exec regexp input =
  let capture = Ctypes.CArray.make ... in
  let use_utf16 = not (is_ascii input) in
  let bufp, matching_length, buffer_type, utf16_map =
    if use_utf16 then
      let map = build_utf16_map input in
      let utf16_str = utf8_to_utf16_bytes input in
      (fill_carray_of_string utf16_str, ..., Some map)
    else
      (fill_carray_of_string input, ..., None)
  in
  Libregexp.exec ...
```

`Js_string.replace_driver` and `splitByRe` repeatedly call this function with the
same input while advancing `lastIndex`. The C buffer and map are discarded after
each match.

For `m` global matches, this path copies or converts the `n`-byte input `m + 1`
times. The final failed `exec` also rebuilds the input.

### 2. UTF-16 to byte conversion restarts at byte zero

`Quickjs.String.byte_index_of_utf16` starts with `(byte = 0, utf16 = 0)` on every
call:

```ocaml
let byte_index_of_utf16 s utf16_index =
  let rec loop i u16 =
    if u16 >= utf16_index || i >= String.length s then i
    else
      let d = String.get_utf_8_uchar s i in
      ...
      loop next_byte next_utf16
  in
  loop 0 0
```

`replace_driver` calls it twice per match. `splitByRe.substring_between` calls it
twice per output segment. Global match offsets are monotonically increasing, but
the implementation does not reuse the previous byte and UTF-16 positions.

The isolated conversion loop is also quadratic, reaching 39.6 ms for the 16 KB
fixture. It is smaller than the repeated `RegExp.exec` cost but still needs a
fix.

### 3. `replaceByRe` eagerly copies prefix and suffix strings

For each match, `replaceByRe` allocates the complete source prefix and suffix:

```ocaml
let prefix = String.sub str 0 match_start_byte in
let suffix = String.sub str match_end_byte (str_byte_length - match_end_byte) in
process_replacement ~replacement ~matches ~prefix ~suffix
```

These strings are only needed for the JavaScript prefix and suffix replacement
tokens. Literal replacements, `$&`, `$$`, and numeric capture references do not
need them. The current implementation pays the copying cost for every match
regardless.

Some quadratic output is unavoidable when a replacement deliberately contains
the prefix or suffix token, because JavaScript semantics require inserting a
growing prefix or suffix for each match. Literal replacements should remain
linear.

## Guest-site trigger

The issue appeared while checking the Ahrefs guest site's `TextHighlight` SSR
change. That component uses `splitByRe` once on a short newsletter string:

```text
plain span SSR                         0.1 us
TextHighlight, one match             22.4 us
TextHighlight, 50 matches           943.8 us
```

The production newsletter case is small enough that the cost is harmless. The
50-match case exposes the curve.

The more serious existing caller is `ServerPageLayout.encodeForScriptJson`. It
runs five global replacements over `initialData`, `commonData`, and JSON schemas
on every SSR page. A synthetic JSON payload containing frequent `<`, `>`, and
`&` characters produced these measurements under the monorepo's OCaml 5.5.0
switch with server-reason-react 0.5.0:

| Payload | Dense matches | Sparse or no matches |
| ---: | ---: | ---: |
| 1 KB | 1.7 ms | not measured |
| 10 KB | 114 ms | 1.2 ms |
| 100 KB | 10.8 s | 11.5 ms |

The dense fixture is deliberately adversarial and is not a production latency
measurement. It demonstrates the complexity problem. Measuring saved production
payloads is needed to quantify current guest-site impact.

The guest site can remove its immediate risk with a single-pass JSON script
escaping function. Five literal characters do not require regular expressions.
That local change does not solve the public `Js.String` APIs.

## Implemented fix

### quickjs.ml 0.5.1

`Quickjs.RegExp` now exposes an immutable prepared input and a ranged match:

```ocaml
type prepared_input
type source_range = {
  utf16 : int * int;
  bytes : (int * int) option;
}
type prepared_match = {
  result : match_result;
  range : source_range;
}

val prepare_input : string -> prepared_input
val exec_prepared :
  ?timeout_ms:float -> t -> prepared_input -> prepared_match option
```

The prepared value owns the C matching buffer, matching length and buffer type,
UTF-16 map, and original OCaml string. `exec_prepared` preserves the existing
global, sticky, `lastIndex`, timeout, and failure semantics. The one-shot `exec`
function is implemented by preparing once and delegating to `exec_prepared`.

Exact UTF-8 ranges are optional because a non-Unicode regexp can match one half
of an astral surrogate pair. `prepared_substring` reconstructs such a UTF-16
range in linear time and emits U+FFFD for an unpaired surrogate, which is the
documented native representation. `prepared_advance_index` implements
AdvanceStringIndex without rescanning the source.

### server-reason-react

`Js.Re.Prepared` wraps the quickjs API for the string implementation.
`replace_driver` prepares once and collects global matches before evaluating
replacement callbacks, matching JavaScript when a callback mutates the regexp's
`lastIndex`. Rendering then writes unmatched source ranges and substitutions
directly into one `Buffer`.

`process_replacement` no longer allocates complete prefix and suffix strings for
every match. It uses `Buffer.add_substring` for exact source ranges and the
prepared UTF-16 fallback only when a range splits a surrogate pair or the input
contains malformed UTF-8.

`splitByRe` streams matches from the same prepared input, stops early at its
limit, and slices each output segment without rescanning from byte zero.

## Verification

- quickjs test262 suite: 571 tests pass;
- server-reason-react `Js` suite: 1,409 tests pass;
- new tests cover prepared-input lifetime, ASCII and Unicode byte ranges,
  surrogate-half captures, multibyte prefix/suffix replacement, split at a
  surrogate boundary, and callback `lastIndex` mutation;
- the benchmark reports near-2x allocation growth when input size and match
  count double for both ASCII and UTF-8 fixtures;
- `git diff --check` passes in both repositories.

For ordinary literal replacements and regex splits, runtime is now
`O(input bytes + regex work + output bytes)`. A replacement containing the
prefix or suffix token can still produce quadratic-size output by definition;
its runtime remains proportional to that output.

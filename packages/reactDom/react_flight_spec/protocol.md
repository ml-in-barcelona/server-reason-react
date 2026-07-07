# React Flight wire protocol notes

Observed from `react-server-dom-webpack@19.1.0` with `NODE_ENV=production`
(the prod wire format is the contract; dev adds debug rows and stacks on top).
This file is kept honest by the fixtures: if a statement here disagrees with a
committed `.flight` file, the fixture wins.

## Stream framing

The Flight payload is a stream of **rows**. In the text protocol each row is

```
<id>:<tag?><value>\n
```

- `<id>` is the row id in lowercase hexadecimal.
- `<tag>` is an optional single uppercase letter describing the row kind.
  No tag means the row value is a plain JSON *model*.
- `<value>` is JSON (UTF-8, no trailing spaces), except for a few tags with raw
  bodies (e.g. `T` text rows, which are also length-prefixed: `<id>:T<hex-size>,<text>`).

Row ids are referenced from models with `$`-prefixed strings (see below).
Chunking is a transport detail: consumers must join the stream and split on `\n`.
The spec therefore compares **rows**, never chunks.

## Row tags seen so far

| tag | meaning |
| --- | ------- |
| *(none)* | model row: JSON value, possibly containing `$` references |
| `I` | module import (client reference): `[id, chunks[], exportName]` as resolved through the client manifest |
| `E` | error: prod emits `{"digest": "..."}` only; dev adds `message`, `stack`, `env` |
| `T` | raw text row, `<id>:T<hex-length>,<utf8 bytes>` (large/binary-ish strings) |
| `D` | debug info (dev only) |
| `W` | console/warn replay (dev only) |

## `$` string prefixes inside models

Strings in a model position are special-cased when they start with `$`:

| prefix | meaning |
| ------ | ------- |
| `$` alone / `$<hex>` | reference to another row by id |
| `$$` | escape: the literal string starts with `$` (`"$$10"` means `"$10"`) |
| `$L<hex>` | *lazy* reference: row not ready yet, will stream later (e.g. Suspense content) |
| `$@<hex>` | promise reference |
| `$S<name>` | well-known symbol, e.g. `$Sreact.suspense` |
| `$F<hex>` | server function reference |
| `$T...` | temporary reference |
| `$D`, `$n`, `$i`, `$-0`, `$NaN`, `$Infinity`, `$-Infinity`, `$u` | typed scalars (date, bigint, undefined, negative zero, non-finite floats) |

## Elements

React prod encodes an element as a 4-tuple:

```json
["$", type, key, props]
```

- `type` is a tag name string, a `$<hex>` reference (client component), or a
  symbol reference like `"$Sreact.suspense"`.
- `key` is `null` or a string.
- `props` is a JSON object; `children` is a prop like any other.

Dev mode appends owner/debug fields, producing wider tuples.

> **Known divergence:** server-reason-react currently emits 7-tuples
> `["$",tag,key,props,null,null,1]` unconditionally, even with `~env:\`Prod`.
> All fixtures record React's 4-tuple form; the affected cases are xfail in the
> conformance suite.

## Normalization rules

Applied identically by `generate.mjs` (fixture side) and the OCaml conformance
runner (srr side) before comparison:

1. Join the whole stream, split on `\n`, drop the final empty segment
   (every row ends with a newline). Compare the resulting row lists.
2. Replace `"stack":<json array or string>` contents with `"stack":"<stack>"`
   (platform/dev dependent; prod rows normally carry no stacks).
3. Replace `"digest":"<anything>"` with `"digest":"<digest>"` in `E` rows
   (digests are implementation-defined).
4. Everything else is byte-exact — including row ids, row order, JSON key
   order, and number formatting.

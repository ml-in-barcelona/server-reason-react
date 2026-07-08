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
| `H` | resource hint (see below); the only row kind with **no id**: `:H<kind><json>` |
| `D` | debug info (dev only) |
| `W` | console/warn replay (dev only) |

## Hint rows

Calling react-dom's resource APIs (`preload`, `preconnect`, `prefetchDNS`,
`preinit`) while a flight request is active emits a **hint row**. Hint rows
are id-less — the row is literally `:H<kind><json>\n` — and never consume a
row id, so they don't shift the ids of surrounding model rows.

The letter after `H` encodes the hint kind, and the JSON payload depends on
which optional arguments survive React's `trimOptions` (absent options
collapse to the shortest form):

| kind | source call | payload (shortest form) |
| ---- | ----------- | ----------------------- |
| `L` | `preload(href, {as})` | `["<href>","<as>"]` (`[href, as, options]` with options) |
| `C` | `preconnect(href)` | `"<href>"` (`[href, crossOrigin]` with a string crossOrigin) |
| `D` | `prefetchDNS(href)` | `"<href>"` |
| `X` | `preinit(src, {as:"script"})` | `"<src>"` (`[src, options]` with options) |
| `S` | `preinit(href, {as:"style"})` | `"<href>"`, `[href, precedence]`, or `[href, precedence, options]` |
| `m` | `preloadModule(href)` | `"<href>"` (`[href, options]` with options) |
| `M` | `preinitModule(src)` | `"<src>"` (`[src, options]` with options) |

The payload is plain `JSON.stringify` output: hrefs starting with `$` are
**not** escaped (hints never pass through the model serializer).

Hints are deduplicated per request, keyed on the call kind and its
identifying arguments (`"L[<as>]<href>"`, `"C|<crossorigin-or-null>|<href>"`,
`"D|<href>"`, `"X|<src>"`; `preload` with `as: "image"` folds
`imageSrcSet`/`imageSizes` into the key). The same call twice emits one row
(`hint_dedup.flight`); the same href with a different `as` is a new key.

Within a flush cycle React writes rows in bucket order: import (`I`) rows,
then hint rows, then regular model rows, then error rows. A hint issued
*before* a client reference is encountered therefore still streams *after*
the `I` row (`hint_before_client_ref.flight`), and a hint issued inside a
suspended task streams right before that task's model row.

server-reason-react exposes `ReactDOM.preload`/`preconnect`/`prefetchDNS`/
`preinitScript` covering the `L`/`C`/`D`/`X` kinds without options. The calls
dispatch to the current flight request (installed by
`ReactServerDOM.render_model` and `create_action_response` via Lwt's implicit
storage) and are safe no-ops when no flight render is active — including
under `render_html`, where turning hints into head tags (react-dom's fizz
behavior) is out of scope for now.

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

- `type` is a tag name string, a `$L<hex>` lazy reference (client component),
  or a `$<hex>` reference to an outlined row (e.g. the suspense symbol row
  `"$Sreact.suspense"`, emitted once per stream and deduplicated).
- `key` is `null` or a string.
- `props` is a JSON object; `children` is a prop like any other. Suspense
  props serialize in `{children, fallback}` order. Numeric props serialize as
  JSON numbers. User string values beginning with `$` are escaped by
  prefixing another `$` (`"$foo"` → `"$$foo"`); internally generated
  references are never escaped.

Prod emits the 4-tuple form. Dev appends the debug fields
`[debugOwner, debugStack, validated]`, producing 7-tuples. server-reason-react
follows the same gate on `~env`.

A prop whose value is absent (e.g. a `<Suspense>` without `fallback`) is
omitted from the props object entirely, not serialized as `null`
(`suspense_no_fallback.flight`).

## Errors

Observed from the `error_*` fixtures:

- A React node that throws — synchronously or as a rejected async component —
  is replaced in its model position by a **lazy** reference `$L<id>`, and the
  error itself streams as `<id>:E{...}`. The reference is `$L<hex>`, not
  `$Z<hex>` (`error_row_reference.flight`).
- Prod `E` rows carry `{"digest": ...}` only; the digest is the return value
  of the `onError` render option (`""` when it returns undefined). Digests are
  implementation-defined and normalized to `<digest>`.
- Within a flush, React emits `E` rows **after** the model rows, even when the
  throw happened synchronously while rendering the model
  (`error_in_suspense_sync.flight`).
- A throw while rendering the **root** model errors row 0 itself: the whole
  stream is a single `0:E{...}` row (`error_component.flight`).
- Suspense does not catch errors at the Flight layer: the boundary serializes
  normally with its `children` as the errored `$L` reference and the fallback
  untouched; fallback handling is the client's job.

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

# Area — Test suites

## Style
- Predominantly golden/snapshot string assertions (`renderToString`, `renderToStaticMarkup`, `renderToStream` chunk lists, RSC rows) + cram snapshots of ppx output. `test_RSC_decoders.ml` is the best-designed (semantic pattern-matches).

## Tests that bless React-divergent output
- `test_RSC_html.ml:233` vs `test_renderToStream.ml:110` — `<div hidden="true">` vs `<div hidden>` for the same boundary; React emits bare `hidden`. CONFIRMED inconsistency (2.24).
- 7-tuple RSC element rows even with `env:\`Prod` / `debug:false` (`test_RSC_html.ml:376-383,1276`); React prod = 4-tuples. CONFIRMED (Q9).
- `test_RSC_html.ml:571-606` "deduplicated resources" — user `<head>` + 2 stylesheets **vanish** from output; blessed under a dedup name. CONFIRMED (relates to 2.11).
- `test_RSC_html_shell.ml:78-80,182-183` — payload/bootstrap `<script>` emitted **after `</body>`** as direct children of `<html>`; React writes them inside `<body>`. Blessed. CONFIRMED.
- `test_RSC_html_shell.ml:424-428` — blesses a known head-ordering bug + duplicate `<title>`s.
- `Html.ml:26`/tests — `'`→`&apos;` vs React `&#x27;`; style order "order matters" blessed (2.24, 2.31).
- `DomProps.ml:1391`/`test.re:318` — `xmlnsXlink` literal blessed (2.6).
- `test_native.re` (url) — comma-splitting `getAll`, no trailing-slash normalization, base-less relative `makeExn` blessed; correct-behavior cases commented out (2.22).

## Skipped/disabled tests hiding bugs
- `test_renderToStream.ml:800` — `abort_streaming` commented out → hides that abort is a no-op (2.12).
- `packages/webapi/tests/_dune` empty + underscore → whole webapi suite never built, zero assertions (2.17 area).
- `ppx/cram/locations/run` — disabled (dropped `.t`), so ppx location correctness is unverified.
- Several RSC debug-info tests commented out; all active debug tests pass `~filter_stack_frame:drop_all_frames`, so `stack:[]` is the only shape asserted.

## Weak/tautological helpers
- `assert_raises` (`test_renderToStream.ml:117-120`, `test_RSC_html.ml:12-15`, `helpers.ml:29-32`) — `exception exn` shadows the expected param and compares the caught exception to itself → **any** exception passes. Weakens all error-path tests.
- `Alcotest.float 2.` — ±2.0 tolerance makes float assertions nearly meaningless.
- `test_cloneElement.ml` uses physical `==` on strings.
- `ppx/test/test.re:571-592` server-function error test `ignore`s the Lwt result with no fail path.

## Concurrency/streaming coverage
- Good: multi-boundary resolution order incl. reversed completion, nested Suspense, mid-stream errors, timeout-closes-stream.
- Missing: abort (disabled), backpressure, **concurrent renders** (the 2.1 hazard is structurally untested — all tests sequential), client-disconnect, hanging-boundary fate, `identifier_prefix` in streams.
- Order-determinism tests depend on real `Lwt_unix.sleep` deltas under a 20ms `Lwt.pick` — flaky under CI load.

## Reference fixtures
- `arch/server/*.js` generate React reference output via `bun` against `react@^19.1.0` (caret) — **not wired into dune/CI**; expected values hand-transcribed. Only useId/head-ordering were ever cross-checked. Staleness risk; enables the T3 differential harness recommendation.

## Zero-coverage public API (grep-confirmed)
- React.mli: `createRef`, `forwardRef`, `memo`, `memoCustomCompareProps`, `useReducer*`, `useTransition`, `useDeferredValue`, `useSyncExternalStore`, most `useMemo*`/`useCallback*`/`useEffect*`/`useLayoutEffect*`, `Children.*` (most), `Experimental.useActionState`, JSX helper fns, most `Event.*`.
- ReactDOM.mli: `querySelector`, `render`, `hydrate`, `createPortal`, `attribute_to_html`, `escape_to_buffer`, and `renderToStream`'s abort.
- ReactServerDOM.mli: `render_html ~identifier_prefix`, `~filter_stack_frame` (only tested as drop-all).

## Broken harness plumbing
- `make lib-test` → nonexistent `test/test.exe`.
- CI builds dev but runs `@runtest` under release profile; the nested-router RSC test is `enabled_if (= %{profile} dev)` → **skipped in CI**.

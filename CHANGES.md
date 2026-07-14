# Changes

## 0.5.0

* Require `quickjs >= 0.5.0 & < 0.6.0`: `Js.Re` and `Js.String` are built on quickjs 0.5.0's breaking API (`RegExp.exec` returns `match_result option`, captures are `string option array`, indices are UTF-16 code units) by @davesnx
* Complete `Js.Bigint`'s Melange-named API: `asIntN`/`asUintN` (labeled wrappers over `as_int_n`/`as_uint_n`), `toLocaleString` (plain decimal, no ICU) and `make` (unsupported: needs JS runtime coercion) by @davesnx
* Fix `Belt` `*Exn` exception types to match Melange: `Belt.Option/List/Result/Map*/Set*/MutableMap*/MutableSet*/MutableQueue` `getExn`/`headExn`/`tailExn`/`peekExn`/`popExn` now raise `Not_found` and `Belt.Array.getExn`/`setExn` raise `Assert_failure` (previously all raised `Js.Exn.Error` with a fake file path, so universal `try ... with Not_found` handlers caught on the client but crashed on the server). `Belt.Array.push` now raises (with a compile-time alert) instead of silently returning a sentinel by @davesnx
* Rewrite `Js.Dict` to preserve JS object key order: iteration (`entries`/`keys`/`values`) follows insertion order, duplicate keys in `fromList`/`fromArray` collapse (first position, last value) like JS object literals, and `Js.Json.stringify` consequently serializes objects in insertion order (previously Hashtbl bucket order with duplicates retained) by @davesnx
* Implement `Js.Map` and `Js.Set` natively (previously type-only stubs): full Melange 6 API with JS semantics — mutable, insertion-ordered iteration, `fromArray` dedup, chainable `set`/`add`. Key equality is structural instead of SameValueZero (documented) by @davesnx
* Add `Js.Iterator` and the modern `Js.Array` methods: `at`, `findLast`/`findLasti`/`findLastIndex`/`findLastIndexi`, `flat`, `toReversed`, `toSortedWith`, `toSpliced`, `removeFrom`, `removeCount`, and `entries`/`keys`/`values` iterators. `toSorted` (comparator-less) stays unsupported: JS's default comparator string-coerces elements by @davesnx
* Fix `Js.Float.toExponential`/`Js.Int.toExponential` without `~digits` to return exponential notation with the shortest round-trip digits (`(123456).toExponential()` is now `"1.23456e+5"`, previously `"123456"`), and `Js.Float.toFixed` of values ≥ 1e21 to fall back to exponential form like JS by @davesnx
* Fix `Js.Bigint.of_string`/`of_string_exn` rejecting hex literals containing `e`/`E` digits (`BigInt("0xE0")` is 224) by @davesnx
* Fix `Js.Promise.race [||]` to return a forever-pending promise like JS (previously raised) by @davesnx
* Widen `Js.Console` signatures to Melange's polymorphic API (`'a -> unit`); the functions remain silent no-ops on the server by @davesnx
* Port Melange's `Js.*` test suites to native (`js_array`/`js_dict`/`js_obj`/`js_global`/`js_int`/`js_float`/`js_promise_basic`/`js_re`/`js_string`/`js_date` from melange 6.0.1-54 `jscomp/test`, ~280 cases): every expectation is Melange's own JS-verified value. Three divergences were found and documented instead of blessed: `Js.Int.toExponential`/`Js.Float.toExponential` without `~digits` return `Number.prototype.toString` output instead of exponential form, and `Js.Float.toFixed` of values ≥ 1e21 prints positionally where JS switches to exponential by @davesnx
* Port Melange's `Belt` test suites to native (`bs_array`/`bs_list`/`bs_map`/`bs_map_set_dict`/`bs_set_int`/`bs_mutable_set`/`bs_queue`/`bs_stack`/`bs_sort`/`bs_hashmap`/`bs_hashset_int`/`bs_float`/`bs_int` from melange 6.0.1-54, ~120 cases incl. the 1M-element map/set/sort stress blocks): zero behavioral divergences — the only deltas are the already-documented `*Exn` exception types and `Belt.Array.push` no-op by @davesnx
* Remove `Js.Vector` and `Js.TypedArray2` (removed upstream in Melange 6; both were raising stubs natively) by @davesnx
* Implement `Js.Json` natively (all 25 functions were raising stubs): a strict ECMA-404 parser (`parseExn` raises `Js.Exn.SyntaxError`, duplicate keys keep the last, surrogate-pair `\u` escapes decode to UTF-8) and an ECMA-262 `JSON.stringify` serializer (numbers formatted via quickjs `Number::toString`, NaN/Infinity as `null`, `stringifyWithSpace` clamps indentation to 10). `test` narrows its first argument to `Js.Json.t` (no runtime type info natively); `stringifyAny`/`serializeExn`/`deserializeUnsafe` remain unsupported. Melange's `js_json_test.ml` suite is ported by @davesnx
* Implement `Js.Math` natively (45 of 59 members were raising stubs) with ECMA-262 semantics where they diverge from IEEE 754/OCaml defaults: `max_float`/`min_float` propagate NaN and order ±0, `pow_float` returns NaN for NaN exponents and `±1 ** ±Infinity`, `round` rounds half towards +Infinity preserving -0, `sign_float` preserves signed zeros, `fround` rounds through binary32, `clz32`/`imul` wrap through int32, and `random` uses a lazily self-initialized PRNG state. Melange's `js_math_test.ml` suite is ported by @davesnx
* Implement `Js.Global` timers on Lwt: `setTimeout`/`setInterval` (+`Float` variants) schedule on the running Lwt event loop and `clearTimeout`/`clearInterval` cancel, WHATWG/node-style. Callbacks only fire while an Lwt main loop is running (Dream, `Lwt_main.run`) by @davesnx
* Implement `Js.Exn` accessors: `asJsExn` maps the `Js.Exn.Error`/`EvalError`/…/`UriError` exceptions to a `Js.Exn.t` carrying `name` and `message` (`stack`/`fileName` are `None` natively); `Js.Exn.t` is now a concrete record instead of an empty abstract type by @davesnx
* Implement `Js.Null` `getExn`/`map`/`bind`/`iter` (labeled `~f`, raising `Js.Exn.Error "Js.Null.getExn"` like Melange). The legacy `Js.Null.test` (removed upstream in Melange 6) is gone. Melange's `js_null_test.ml` suite is ported by @davesnx
* Implement `Js.Undefined` `getExn`/`map`/`bind`/`iter` (labeled `~f`, raising `Js.Exn.Error "Js.Undefined.getExn"` like Melange). The legacy `Js.Undefined.test` (removed upstream in Melange 6) is gone; `testAny` stays unsupported (needs runtime type tags). Melange's `js_undefined_test.ml` suite is ported by @davesnx
* Align `Js.Nullable` with Melange 6: `map`/`bind`/`iter` take a labeled `~f` — the previous `bind` had a divergent `'b t -> ('b -> 'b) -> 'b t` signature vs Melange's `f:('a -> 'b t) -> 'a t -> 'b t` — plus `isNullable`/`null`/`undefined` (both represented as `None` natively). Melange's `js_nullable_test.ml` suite is ported by @davesnx
* Implement the remaining `Js.String` stubs: `unsafeReplaceBy0`-`3` (function-based regex replacement on the shared UTF-16 replace driver; non-participating capture groups are passed as `""` where JS passes `undefined`), `anchor`/`link` (ECMA-262 CreateHTML, `&quot;`-escaping), `localeCompare` (byte-wise, no ICU collation), and `toLocaleLowerCase`/`toLocaleUpperCase` (aliased to the locale-insensitive versions). Only `Js.String.make` still raises (needs JS `String()` coercion) by @davesnx
* Add generated per-function compatibility READMEs for `Js` and `Belt` (`packages/Js/README.md`, `packages/Belt/README.md`): a dune rule merges Melange 6's API surface, a mechanical scan for raising stubs, and hand-maintained divergence annotations, and fails the build when the annotations contradict the code. Statuses: verified-by-JS-sourced-tests / implemented-unverified / divergent / stub / missing by @davesnx
* Fix `ReactServerDOM.render_html` crashing on PPX-prerendered (`Writer`) subtrees that contain client components ("Client components can't be rendered via write_to_buffer") and duplicating hoistable elements (`<title>`/`<meta>`/`<link>`) contained in `Static` prerendered subtrees: the RSC HTML path now renders `Writer` subtrees via the regular walk (already performed for the model) and falls back to the walked HTML for `Static` subtrees whose walk hoisted something by @davesnx
* [esbuild-plugin] Fix client components failing to load in the browser when their chunk wasn't eagerly imported ("Lazy element type must resolve to a class or function"): the manifest registered components as `React.lazy`, which the Flight client wrapped in a second lazy. The manifest now stores loader records and `ReactServerDOMEsbuild` implements the Flight `preloadModule`/`requireModule` contract (preload starts the import and blocks the module chunk; require returns the component synchronously) by @davesnx
* Demo: add JavaScript-identical `Js.String`/`Js.Date` output sections and a client component that errors during SSR and recovers in the browser (`ThrowingClient`) to `/demo/singlePageRSC`, and wire `DEMO_ENV=development` into `render_html`'s `~debug` by @davesnx
* Fix `ReactServerDOM.render_html` dropping head-hoisted resources (`<title>`, `<meta>`, `<link>`, async `<script>`, bootstrap modulepreload links) when the root element is not `<html>`: they now stream at the start of the shell, before the root HTML, in react-dom's priority-bucket order (matching react-dom 19.1's preamble for non-document renders) by @davesnx
* Fix errors inside client components being silently swallowed by `render_html` (blank regions, no diagnostics): a sync throw with no Suspense above now rejects the render like every other path; under a client-side Suspense boundary the error becomes a client-rendered boundary — `<!--$!--><template>` when it happens before the placeholder flushes, a `$RX("B:<id>", ...)` retry instruction when it happens after. Error detail is dev-only (production emits a bare template / digest-only `$RX`), and the `$RX` function definition is emitted once per stream by @davesnx
* Fix `ReactServerDOM.render_html`'s `?debug` parameter being silently ignored: `~debug:true` now emits the same debug-info rows as `render_model` (component name/owner/stack `D` rows, owner refs in dev element tuples), and `render_html` gains the `?filter_stack_frame` parameter matching `render_model` by @davesnx
* Fix `Js.Date` parsing: ISO datetimes without a timezone designator and legacy formats are now parsed as local time per ECMA-262 (previously UTC — every rendered date diverged from the browser by the UTC offset), strings with trailing garbage return NaN instead of being accepted, `fromString (toUTCString d)` round-trips (previously NaN), and local-time conversion follows `LocalTZA(t, false)` around DST transitions (spring-forward gaps and fall-back ambiguities use the pre-transition offset, matching V8). `Js.Date` setters now mutate the receiver and return the new timestamp, matching Melange (`Js.Date.t` is now abstract) by @davesnx
* Rewrite `Js.String` to be UTF-16-correct through quickjs, matching JavaScript on non-ASCII input: `length`/`charAt`/`charCodeAt`/`codePointAt`/`indexOf`/`slice`/`substring`/`substr`/`includes`/`startsWith`/`endsWith` now operate on UTF-16 code units (previously bytes: `length "é"` was 2, `charCodeAt "é" 0` was 195), negative indices clamp like JS instead of raising, `fromCharCode`/`fromCodePoint` handle the full code-point range with surrogate pairing (previously broke above 255), `replaceByRe`/`splitByRe` no longer infinite-loop on empty-match global regexes nor corrupt multibyte strings (UTF-16 match indices were used as byte offsets), `splitByRe` honors `~limit` and splices captures per spec, `match_` with `/g` returns all matches (previously capped at 2), `replace`/`split` drop the thread-unsafe `Str` module and follow JS `$&`/`$$`/`` $` ``/`$'` replacement semantics, `trim` uses the full ECMA whitespace set, and `toLowerCase`/`toUpperCase` handle context-sensitive mappings (final sigma). Verified against node v22 on a differential corpus by @davesnx
* Fix `Belt.HashMap.Int`/`Belt.HashMap.String` losing keys nondeterministically: the MurmurHash mixing misused int32 C primitives on `nativeint` boxes, folding uninitialized memory into the hash. Now pure `Int32` arithmetic by @davesnx
* Fix `Belt.Option.getUnsafe` memory-unsafety: it was `%identity` (valid in Melange where `Some x` is `x`, unsound in native where `Some x` is a boxed block). Now a real pattern match; raises `Invalid_argument` on `None` by @davesnx
* Fix `React.cloneElement` silently dropping `style`, event, `ref`, `dangerouslySetInnerHTML` and action props: attribute merging now follows JS spread semantics over all prop kinds, preserving order (base first, overridden in place, new appended) instead of sorting by @davesnx
* Fix `defaultChecked`/`defaultValue` rendering as literal attributes: they now emit the `checked`/`value` DOM attributes, matching React's server output by @davesnx
* Fix `ReactDOM.domProps` SVG attribute names: `xlinkActuate` emitted `xlink:arcrole`, `xlinkArcrole` and `xmlnsXlink` emitted their camelCase JSX names; now `xlink:actuate`/`xlink:arcrole`/`xmlns:xlink` by @davesnx
* Gate Suspense error detail in `renderToStream` on `?env`: with `` `Prod `` the `<template>` marker carries no exception message or backtrace (previously leaked unconditionally into HTML) by @davesnx
* Fix `renderToStream` closing the stream before the shell is pushed when a Suspense boundary completes while the main render is parked on an Lwt yield: the root walk now counts as a pending unit by @davesnx
* Escape `bootstrapScriptContent` for the inline-script context (`<script`/`</script` neutralized by unicode-escaping the `s`), mirroring react-dom's `escapeEntireInlineScriptContent` by @davesnx
* Document the single-in-flight-render constraint on `useId`'s process-global state (`React.useId`, `React.current_tree_context`) by @davesnx
* Fix empty inline `style` values not being skipped at runtime: the skip used physical equality (`v == ""`), which misses empty strings from other compilation units, diverging from the PPX static fold (e.g. `style="color:;padding:8px"` vs `style="padding:8px"`) by @davesnx
* Match react-dom's abort behavior in streaming renders: `ReactDOM.renderToStream`'s `abort` (previously a no-op) and `ReactServerDOM.render_html`'s `timeout` now emit a `$RX` client-render instruction per still-pending Suspense boundary before closing the stream, so the client flips those boundaries to errored and retries them there. Error detail is dev-only (gated on the new `?env` parameter of `renderToStream`; production passes only the digest), the close is idempotent, and boundary promises that resolve after the abort no longer push into the closed stream (which crashed the process). Also aligns `ReactServerDOM`'s resolved-segment markup on a bare `hidden` attribute (`<div hidden id="S:x">`) matching react-dom
* Add `ReactDOM.preload`, `ReactDOM.preconnect`, `ReactDOM.prefetchDNS` and `ReactDOM.preinitScript`, following react-dom's flight-side resource hint API. Called during a `ReactServerDOM.render_model` (or `create_action_response`) render they emit id-less `:H<kind><json>` rows into the Flight stream with React's per-request dedup and flush order (imports, hints, model rows) — verified byte-for-byte against react-server-dom-webpack 19.1.0 by six new flight spec cases. Outside a flight render the calls are no-ops by @davesnx

* Add a verifiable React Flight protocol spec (`packages/reactDom/react_flight_spec`): single-source cases rendered by both `ReactServerDOM.render_model` and real `react-server-dom-webpack` (pinned to 19.1.0) with committed golden fixtures, a conformance suite in `dune runtest`, and `make spec-generate`/`spec-check` targets. Bumping React regenerates the fixtures, making the diff the protocol changelog by @davesnx
* Align the Flight wire format with react-server-dom-webpack 19.1.0 (all verified byte-for-byte by the flight spec): escape user strings starting with `$` (`"$foo"` → `"$$foo"`), serialize numeric JSX props as JSON numbers instead of strings, reference client components lazily with `$L<id>`, outline the suspense symbol as a deduplicated row, and emit prod element rows as 4-tuples `["$",type,key,props]` (dev keeps the 7-tuple debug form). Also align the serializer's task/row model with React's: dedup a promise shared across props/components into a single `$@<id>` row (mirroring `writtenObjects`, keyed on the promise's physical identity), render the task root destructively (an async component at the root resolves into the task's own row instead of outlining a `$L` reference, and a throw on the root chain errors the root row itself as `0:E{...}`), and flush outlined error rows and already-resolved promise rows after the model rows that reference them (React's `completedErrorChunks`/`pingedTasks` ordering). Print Flight numbers the way `JSON.stringify` does (integral doubles in full digits up to 1e21, e.g. `9e18` as `9000000000000000000`) and encode NaN/Infinity/-0 as React's `$NaN`/`$Infinity`/`$-Infinity`/`$-0` special strings. The spec has zero known divergences left by @davesnx
* Fix `React.memo` and `React.memoCustomCompareProps` signatures to match reason-react (`memo: 'component -> 'component`, `memoCustomCompareProps: 'component -> ('props -> 'props -> bool) -> 'component`), so universal code written against reason-react type-checks unchanged. On the server both are pass-through since there's no re-render
* [server-reason-react.ppx] Fix expected-type propagation for optional host-element props in the Writer fast path: the lowered `match` now annotates the scrutinee with its concrete option type (e.g. `string option`), so a bare `None`/`Some` in a value like `href=?{disabled ? None : Some(href)}` disambiguates to `option` even when a user type in scope shadows `None` (e.g. `type roundness = … | None`). Previously this only affected the variant-tree path; the fast path resolved `None` by lexical scope and failed to type-check
* Fix unescaped inline `style` attribute in SSR, which truncated the attribute when a CSS value contained a double quote (e.g. a quoted font-family)
* Improve SSR rendering performance (geomean 1.39x, props-heavy scenarios up to 1.9x, 25-52% less allocation per render) with byte-identical HTML output: lazy/deferred `Js.t` object registration (no more per-`makeProps` Hashtbl and per-field entry allocation), widen the PPX Writer fast path to `style` attributes (literal styles fold to compile-time strings) and skip SSR-ignored attributes (events, `suppress*Warning`), eliminate closure-per-node allocation in the sync render paths, and seed render buffers with the previous render's size. Also fixes literal `suppressHydrationWarning` leaking into prerendered HTML by @davesnx
* Support Promise caching in react.client.components by @davesnx
* Reorder head content exactly like react-dom/server by @davesnx
* Implement hydration-compatible `useId` using React's tree-position-based algorithm, matching React 19 output. Adds `?identifier_prefix` to `renderToString`, `renderToStaticMarkup`, `renderToStream` and `render_html`. Fixes https://github.com/ml-in-barcelona/server-reason-react/issues/93
* Fix `renderToString` rendering Suspense children twice (once as trial, once with markers) due to side-effectful match expression. Children are now rendered into a separate buffer
* Change shape for React.Event.* since Js.t is now supported. All methods fail at runtime with `Runtime.fail_impossible_action_in_ssr`
* [server-reason-react.ppx] Strip units at any position (supporting mlx difference with [@JSX] transformations)
* Add runtime error with clear message when `React.cloneElement` is used with uppercase components by @davesnx
* Allow `[@platform js]` and `[@browser_only]` on externals to conditionally exclude them from native builds. Fixes https://github.com/ml-in-barcelona/server-reason-react/issues/170 by @davesnx
* Generate `makeProps` in the PPX by @davesnx in https://github.com/ml-in-barcelona/server-reason-react/pull/364
* Implement `Js.t` natively with `Js.Internal` and a type registry by @davesnx in https://github.com/ml-in-barcelona/server-reason-react/pull/363
* Add `React.useActionState` by @davesnx
* Add `key` into client components by @davesnx
* Fix several functions in Belt to match specification (`Belt.Array.setExn`, `Belt.Array.concat`, `Belt.MutableMap.remove`, `Belt.HashMap.keepMapInPlace`, and avoid double callback evaluation) by @yasunariw in https://github.com/ml-in-barcelona/server-reason-react/pull/362
* Implement `Belt.Array.getUndefined` and annotate `Belt.Array.push` as not implemented by @davesnx
* Remove deprecated folder from Belt and reorganise Belt tests by @davesnx
* Fix leaking `was_previous` when node was closing by @davesnx in https://github.com/ml-in-barcelona/server-reason-react/pull/361
* Fix `React.cloneElement` on `Static {}` components by @davesnx in https://github.com/ml-in-barcelona/server-reason-react/pull/359
* Require ppxlib >= 0.36 by @davesnx

## 0.4.1

* Use OCaml 5.4.0 by @davesnx in https://github.com/ml-in-barcelona/server-reason-react/pull/335
* Use latest ppxlib by @davesnx in https://github.com/ml-in-barcelona/server-reason-react/pull/334
* Update to latest quickjs by @davesnx
* Update dependency and usage by @davesnx in https://github.com/ml-in-barcelona/server-reason-react/pull/333
* Add filter to esbuild plugin to scope entrypoint by @pedrobslisboa in https://github.com/ml-in-barcelona/server-reason-react/pull/330
* Add back and forward navigation to nested router by @pedrobslisboa in https://github.com/ml-in-barcelona/server-reason-react/pull/329
* Implement memo and memoCustomCompareProps by @davesnx
* Move Date, BigInt and modularise Js by @davesnx in https://github.com/ml-in-barcelona/server-reason-react/pull/327
* Create complex navigation at RSC demo by @pedrobslisboa in https://github.com/ml-in-barcelona/server-reason-react/pull/307

## 0.4.0

* Add upper bound to quickjs 0.2.0
* Bump lwt to 5.9.2
* Expand styles prop into className and style props with optional handling by @pedrobslisboa in https://github.com/ml-in-barcelona/server-reason-react/pull/324
* Lowercase components have ?key:string by @davesnx in https://github.com/ml-in-barcelona/server-reason-react/pull/323
* Wrap client value on React.Upper_case_component by @pedrobslisboa in https://github.com/ml-in-barcelona/server-reason-react/pull/322
* Fix remove last element on nested_modules by @pedrobslisboa in https://github.com/ml-in-barcelona/server-reason-react/pull/321
* Add searchParams function to native URL by @pedrobslisboa in https://github.com/ml-in-barcelona/server-reason-react/pull/320
* Add URL construct function and improve lib build by @EmileTrotignon in https://github.com/ml-in-barcelona/server-reason-react/pull/317
* Specify model values at React by @pedrobslisboa in https://github.com/ml-in-barcelona/server-reason-react/pull/309
* Allow async in client props by @pedrobslisboa in https://github.com/ml-in-barcelona/server-reason-react/pull/315
* Improve the Fiber and Model stream context by @pedrobslisboa in https://github.com/ml-in-barcelona/server-reason-react/pull/312
* Align Suspense with reason-react by @pedrobslisboa in https://github.com/ml-in-barcelona/server-reason-react/pull/311
* Make client component to execute in runtime by @pedrobslisboa in https://github.com/ml-in-barcelona/server-reason-react/pull/306
* Fix mismatch of the model and html on render_html by @pedrobslisboa in https://github.com/ml-in-barcelona/server-reason-react/pull/305
* Fix createFromFetch interface and avoid transition on navigation by @davesnx in https://github.com/ml-in-barcelona/server-reason-react/pull/299
* Change ppx execution order (styles expansion in server-reason-react) by @davesnx in https://github.com/ml-in-barcelona/server-reason-react/pull/297
* Rename use function to usePromise in Experimental module by @pedrobslisboa in https://github.com/ml-in-barcelona/server-reason-react/pull/298
* Add shared-folder-prefix arg to ppx by @davesnx in https://github.com/ml-in-barcelona/server-reason-react/pull/294

## 0.3.1

* Update quickjs dependency to 0.1.2 by @davesnx

## 0.3.0

* browser-ppx: process stritems by @jchavarri in https://github.com/ml-in-barcelona/server-reason-react/pull/127
* Make React.Children.* APIs work as expected by @davesnx in https://github.com/ml-in-barcelona/server-reason-react/pull/130
* Improve global crashes by @davesnx in https://github.com/ml-in-barcelona/server-reason-react/pull/132
* Support assets in `mel.module` by @jchavarri in https://github.com/ml-in-barcelona/server-reason-react/pull/134
* browser_only: don't convert to runtime errors on identifiers or function application by @jchavarri in https://github.com/ml-in-barcelona/server-reason-react/pull/138
* Port `j` quoted strings interpolation from Melange by @jchavarri in https://github.com/ml-in-barcelona/server-reason-react/pull/139
* mel.module: handle asset prefix by @jchavarri in https://github.com/ml-in-barcelona/server-reason-react/pull/140
* Add browser_only transformation to useEffect automatically by @davesnx in https://github.com/ml-in-barcelona/server-reason-react/pull/145
* Append doctype tag on html lowercase by @davesnx in https://github.com/ml-in-barcelona/server-reason-react/pull/136
* Transform Pexp_function with browser_only by @davesnx in https://github.com/ml-in-barcelona/server-reason-react/pull/146

## 0.2.0

- Remove data-reactroot attr from ReactDOM.renderToString #129 by @pedrobslisboa
- Make useUrl return the provided serverUrl #125 by @purefunctor
- Replace Js.Re implemenation from `pcre` to quickjs b1a3e225cdad1298d705fbbd9618e15b0427ef0f by @davesnx
- Remove Belt.Array.push #122 by @davesnx

## 0.1.0

Initial release of server-reason-react, includes:

- Server-side rendering of ReasonReact components (renderToString, renderToStaticMarkup & renderToLwtStream)
- `server-reason-react.browser_ppx` for skipping code from the server
- `server-reason-react.melange_ppx` for enabling melange bindings and extensions which run on the server
- `server-reason-react.belt` a native Belt implementation
- `server-reason-react.js` a native Js implementation (unsafe and limited)
- `server-reason-react.url` and `server-reason-react.url-native` a universal library with both implementations to work with URLs on the server and the client
- `server-reason-react.promise` and `server-reason-react.promise-native` a universal library with both implementations to work with Promises on the server and the client. Based on https://github.com/aantron/promise
- `server-reason-react.melange-fetch` a fork of melange-fetch which is a melange library to fetch data on the client via the Fetch API. This fork is to be able to compile it on the server (not running).
- `server-reason-react.webapi` a fork of melange-webapi which is a melange library to work with the Web API on the client. This fork is to be able to compile it on the server (not running).

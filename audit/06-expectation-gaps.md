# Expectation gaps — "I expected X, found Y"

Affordance, docs, and DX mismatches. Each is a place where the code/docs *invite* one thing and *do* another.

| # | I expected… | …found | Evidence |
|---|-------------|--------|----------|
| E1 | `renderToString`/`renderToStaticMarkup` to memoize `React.cache` | Only the streaming/RSC paths wrap `with_request_cache_async`; the sync renderers don't wrap at all, so `React.cache` is a passthrough during `renderToString` | `ReactDOM.ml:380-394` vs `:627`, `ReactServerDOM.ml:1092` |
| E2 | `renderToStaticMarkup` to omit Suspense comment markers (React does) | Emits `<!--$-->…<!--/$-->` in both `String` and `Markup` modes; no test covers Suspense under `renderToStaticMarkup` | `ReactDOM.ml:181-191` |
| E3 | `ReactDOM.render`/`hydrate`/`querySelector` to no-op server-side (per docstrings) | They raise + print to stdout | `ReactDOM.mli:39-46` vs `ReactDOM.ml:650-652` |
| E4 | `createPortal` to render nothing server-side (per docstring) | Renders children inline | `ReactDOM.mli:48-49` vs `ReactDOM.ml:655` |
| E5 | `render_html ~debug:true` to add debug info like `render_model` | Parameter discarded | `ReactServerDOM.ml:1088` |
| E6 | `React.memo(component)` to compile like reason-react | `memo` needs 2 args and returns the compare fn | `React.mli:666`; [`investigations/memo-and-react-client.md`](investigations/memo-and-react-client.md) |
| E7 | `cloneElement(el, [p])` to keep `el`'s style/onClick | Those props are dropped | `React.ml:455-481` |
| E8 | An error in a `<Suspense>` child on a public page to stay server-side | Exception string + backtrace shipped in `data-msg` | `ReactDOM.ml:436-442` |
| E9 | `Belt.Float.toString 0.1 +. 0.2` to match JS | `"0.3"` (12-digit truncation), `nan`/`inf` spellings differ | `Belt_Float.ml:5-8` |
| E10 | `event |> Event.preventDefault` (webapi) to compile natively | Type error — `send.pipe` reversal makes it `unit -> event` | `melange.ppx/ppx.ml:692-694` |
| E11 | The get-started dune snippet to be valid | `(libraries (a b))` is a dune parse error; first snippet a newcomer copies | `documentation/get-started.mld:30` |
| E12 | Doc library names to match `public_name` | `server-reason-react.promise` (real: `.promise-js`/`.promise-native`), `server-reason-react-ppx` (real: `.ppx`) | README/`index.mld`; agent |
| E13 | `React.use()` (advertised in README) to exist | Renamed to `React.Experimental.usePromise` | `React.mli:766`; README:11 |
| E14 | `npm install` "from the root" (demo README) to work | No root `package.json`; leaves a fossil `node_modules/` | `demo/README.md:3`; agent |
| E15 | `make lib-test` to run the tests | Targets a nonexistent `test/test.exe` | `Makefile:88-90` |
| E16 | Doc code examples to be compile-checked | `dune-project` declares `(using mdx 0.4)` but no mdx stanza exists — nothing compiles them | `dune-project:4`; agent |
| E17 | The webapi test suite to run | `tests/_dune` (underscore → invisible to dune), zero assertions | agent |
| E18 | `renderToStream` `abort()` to stop the render | No-op; keeps resolving boundaries into an unread stream | `ReactDOM.ml:640-643` |
| E19 | A `<title>` in a non-`<html>` RSC fragment to appear in output | Hoisted then dropped | `ReactServerDOM.ml:858-884,1017-1037` |
| E20 | Universal `Belt.HashMap.String` to round-trip a set/get | Returns `None` after intervening allocation | `caml_hash.ml:9-10` |

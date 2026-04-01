# Changes

## unreleased

* Implement hydration-compatible `useId` using React's tree-position-based algorithm, matching React 19 output. Adds `?identifier_prefix` to `renderToString`, `renderToStaticMarkup`, `renderToStream` and `render_html`. Fixes https://github.com/ml-in-barcelona/server-reason-react/issues/93
* Fix `renderToString` rendering Suspense children twice (once as trial, once with markers) due to side-effectful match expression. Children are now rendered into a separate buffer
* Change shape for React.Event.* since Js.t is now supported. All methods fail at runtime with `Runtime.fail_impossible_action_in_ssr`
* [server-reason-react.ppx] Strip units at any position (supporting mlx difference with [@JSX] transformations)

## 0.5.0

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

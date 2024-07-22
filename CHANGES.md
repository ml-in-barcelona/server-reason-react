# Changes

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

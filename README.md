# server-reason-react

Native React's server-side rendering (SSR) and React Server Components (RSC) architecture for Reason.

Designed to be used with [reason-react](https://github.com/reasonml/reason-react) and [Melange](https://github.com/melange-re/melange). Together it enables developers to write efficient React components using a single language, while target both native executable and JavaScript.

## Features

- **Server-side rendering HTML** with `ReactDOM.renderToString`/`ReactDOM.renderToStaticMarkup`
- Server-side rendering **streaming HTML** with `ReactDOM.renderToStream` (similar to react@18 `renderToReadableStream`)
- Includes **`React.Suspense`** and **`React.use()`** implementations
- **server-reason-react-ppx** - A ppx transformation to support JSX on native
- All reason-react interface is either implemented or stubbed (some of the methods, like React.useState need to be stubbed because they aren't used on the server!)
- **React Server Components** - A ReactServerDOM module for streaming RSC payload, an esbuild plugin to enhance the bundle with client-components mappings, a Dream middleware to serve the RSC endpoint and a dummy implementation of a router (still [work in progress](https://github.com/ml-in-barcelona/server-reason-react/issues/204))

> Warning: This repo contains a few parts that are considered experimental and there's no guarantee of stability. Most of the stable parts are used in production at ahrefs.com, app.ahrefs.com and wordcount.com. Check each module's documentation for more details.

## Why

There are plenty of motives for it, the main one is that [ahrefs](https://ahrefs.com) (the company I work for) needs it. We use OCaml for the backend and Reason (with React) for the frontend. We wanted to take advantage of the same features from React.js in the server as well.

Currently 100% of the public site ([ahrefs.com](https://ahrefs.com)), the shell part of the dashboard ([app.ahrefs.com](https://app.ahrefs.com)) and [wordcount.com](https://wordcount.com) are rendered on the server with `server-reason-react`.

What made us create this library was mostly:

- Use the same language (Reason) for both server and client
- Embrace server-client integrations such as type-safe routing, JSON decoding/encoding, sharing types and logic, while keep enjoying functional programming patterns
- Native performance is better than JavaScript performance (Node.js, Bun, Deno)
- Writing React from a different language than JavaScript, but still using the brilliant pieces from the ecosystem
- Exploration of OCaml effects and React
- Further exploration with OCaml multicore, direct-style and concurrency with React features such as async components, React.use or Suspense

Explained more about the motivation in [this blog post](https://sancho.dev/blog/server-side-rendering-react-in-ocaml) and also in my talk about [**Universal react in OCaml** at fun-ocaml 2024](https://www.youtube.com/watch?v=Oy3lZl2kE-0&t=92s&ab_channel=FUNOCaml) and [**Server side rendering React natively with Reason** at ReactAlicante 2023](https://www.youtube.com/watch?v=e3qY-Eg9zRY&ab_channel=ReactAlicante)

## Other libraries inside this repo

Aside from the core (`React`, `ReactDOM` and `ReactServerDOM`), server-reason-react repo contains some common melange libraries to ensure components are universal. Some of them are reimplementations in native of those libraries, and others are new implementations. Currently they are part of the repository, but eventually will be moved out to their own opam packages and repositories.

| Name | Description | Melange equivalent library |
|---------|-------------|---------|
| [`server-reason-react.browser_ppx`](https://ml-in-barcelona.github.io/server-reason-react/server-reason-react/browser_only.html) | A ppx to discard code for each platform with different attributes: `let%browser_only`, `switch%platform` and `@platform` |
| [`server-reason-react.url_js` and `server-reason-react.url_native`](https://ml-in-barcelona.github.io/server-reason-react/server-reason-react/server-reason-react.url_native/URL/index.html) | Universal URL module: binds to `window.URL` in browser, implemented with [`opam-uri`](https://github.com/mirage/ocaml-uri) in native |
| [`server-reason-react.melange_ppx`](https://ml-in-barcelona.github.io/server-reason-react/server-reason-react/externals-melange-attributes.html) | A ppx to add the melange attributes to native code | [melange.ppx](https://melange.re/v4.0.0/) |
| `server-reason-react.promise` | Vendored version of [aantron/promise](https://github.com/aantron/promise) with melange support [PR#80](https://github.com/aantron/promise/pull/80) | [promise](https://github.com/aantron/promise) |
| `server-reason-react.belt` | Implementation of Belt for native [API reference](https://ml-in-barcelona.github.io/server-reason-react/server-reason-react/server-reason-react.belt_native/Belt/index.html) | [melange.belt](https://melange.re/v4.0.0/api/ml/melange/Belt) |
| `server-reason-react.js` | Implementation of `Js` library for native (unsafe/incomplete) | [melange.js](https://melange.re/v4.0.0/api/ml/melange/Js) |
| `server-reason-react.fetch` | Stub of fetch with browser_ppx to compile in native | [melange.fetch](https://github.com/melange-community/melange-fetch) |
| `server-reason-react.webapi` | Stub version of Webapi library for native code compilation | [melange-webapi](https://github.com/melange-community/melange-webapi) |
| `server-reason-react.dom` | Stub version of Dom library for native code compilation | [melange-dom](https://melange.re/v4.0.0/) |

## [Documentation](https://ml-in-barcelona.github.io/server-reason-react/server-reason-react/index.html)

The [documentation site](https://ml-in-barcelona.github.io/server-reason-react/server-reason-react/index.html) is generated with odoc and hosted on GitHub Pages.

## Demo

The `demo` folder contains a simple server to showcases the usages of `server-reason-react. Check the [README](demo/README.md) for how to setup and run it.

## Want to contribute to the future?

[Follow me](https://x.com/davesnx) or [message me](https://x.com/davesnx)

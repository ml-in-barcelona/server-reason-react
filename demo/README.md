# server-reason-react demo

The app consist of 3 folders: `shared`, `server` and `client`, which encapsulates each compilation target defined by dune.

## `client/`

A folder that contains the code executed in the client only. It's defined in dune as a `melange.emit` to emit JavaScript from Reason via Melange. It uses all the ReScript goodies: Belt, Js, etc. Currently is tiny: client only renders the `Shared_js.App` component:

```re
switch (ReactDOM.querySelector("#root")) {
| Some(el) => ReactDOM.render(<Shared_js.App />, el)
| None => ()
};
```

## `server/`

An executable that expose a dream app with a home route which serves an HTML page. Written in [server-reason-react](https://github.com/ml-in-barcelona/server-reason-react) and send it as a string with `ReactDOM.renderToString`

## `universal/`

The folder contains the library for shared code between `client` and `server`. dune generates two libraries `Shared_js` and `Shared_native` (by using `copy_files#`) with separate dependencies for each:

```dune
; universal/js/dune
(library
 (name shared_js)
 (modes melange)
 (libraries reason-react)
 (preprocess (pps reason-react-ppx)))

(copy_files# "../*.re")
```

```dune
; universal/native/dune
(library
 (name shared_native)
 (modes native)
 (libraries
  server-reason-react.react
  server-reason-react.reactDom)
 (preprocess
  (pps server-reason-react.ppx)))

(copy_files# "../*.re")
```

`Shared_js` is compiled by Melange to JavaScript while `Shared_native` compiled by OCaml to native.

<!-- Link to documentation -->

## Requirements

- npm (and run `npm install` from the root of the project)
- [watchexec](https://github.com/watchexec/watchexec)

# Usage

From the root of the project, run

```bash
# 1 terminal to compile the code
make demo-build-watch
# 2 terminal to run the server
make demo-serve-watch
```

# Folder explanation

The app consist of 3 folders: `universal`, `server` and `client`, which contains each compilation target defined by dune.

## `client/`

A folder that contains the code executed in the client only. It's defined in dune as a `melange.emit` to emit JavaScript from Reason via Melange. It's a a tiny entrypoint to render `Shared_js.App` component.

```re
switch (ReactDOM.querySelector("#root")) {
| Some(el) => ReactDOM.render(<Shared_js.App />, el)
| None => ()
};
```

## `server/`

An executable that expose a HTTP server using [dream](https://aantron.github.io/dream). It serves a different routes, all of them written in React and send it as a string with `ReactDOM.renderToString` or as an `application/octet-stream` with [`Dream.stream`](https://aantron.github.io/dream/#streams).

## `universal/`

This folder contains a library for shared code between `client` and `server`. dune generates two sub-libraries `Shared_js` and `Shared_native` (by using `copy_files#`) with separate dependencies and preprocessors for each:

```dune
; demo/universal/js/dune
(library
 (name shared_js)
 (modes melange)
 (libraries reason-react)
 (preprocess (pps reason-react-ppx)))

(copy_files# "../*.re")
```

```dune
; demo/universal/native/dune
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

`shared_js` is used on the `client/dune` melange.emit to be compiled by Melange while `shared_native` is used in the `server/dune` executable compiled by OCaml

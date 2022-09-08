# jsoo-react

[![Actions Status](https://github.com/ml-in-barcelona/jsoo-react/workflows/CI/badge.svg?branch=main)](https://github.com/ml-in-barcelona/jsoo-react/actions?query=branch%3Amain)

Bindings to [React](https://reactjs.org/) for [js_of_ocaml](https://ocsigen.org/js_of_ocaml/), including JSX ppx.

Adapted from [ReasonReact](https://github.com/reasonml/reason-react/).

`jsoo-react` allows to use React from OCaml, but it is still at the **experimental** phase: there is no published version in [opam](opam.ocaml.org/) yet, and the library is expected to break backwards compatibility often.

Bug reports and contributions are welcome!

## Getting started

### New project

For new projects, the best way to start is by using [the jsoo-react template](https://github.com/ml-in-barcelona/jsoo-react-template).

### Existing project

1. Install the `jsoo-react` package:

    ```bash
    opam pin add -y jsoo-react https://github.com/ml-in-barcelona/jsoo-react.git
    ```

2. Add `jsoo-react` library and ppx to [dune](https://dune.readthedocs.io/en/stable/) file of your executable JavaScript app:

    ```
    (executables
    (names index)
    (modes js)
    (libraries jsoo-react.lib)
    (preprocess
      (pps jsoo-react.ppx)))
    ```

3. Provision React.js library
    
    `jsoo-react` uses `require` to import React and ReactDOM. This means that you will likely need to use a bundler such as Webpack or rollup.js.

    Note that at this moment, `jsoo-react` is compatible with **React 16**, so be sure to have the appropriate constraints in your `package.json`.

## Contributing

Take a look at our [Contributing Guide](CONTRIBUTING.md).

## Acknowledgements

Thanks to the authors and maintainers of ReasonReact, in particular [@rickyvetter](https://github.com/rickyvetter) for his work on the v3 of the JSX ppx.

Thanks to the authors and maintainers of Js_of_ocaml, in particular [@hhugo](https://github.com/hhugo) who has been answering many many questions in GitHub threads.

Thanks to the Lexifi team for creating and maintaining [gen_js_api](https://github.com/LexiFi/gen_js_api).

Thanks to [@tmattio](https://github.com/tmattio/) for creating Spin and the jsoo-react template :raised_hands:

And thanks to the team behind React.js! What an amazing library :)

# melange-basic-template

A simple project template using [Melange](https://github.com/melange-re/melange).

## Quick Start

```shell
npm install

# In separate terminals:
npm run build:watch
npm run serve
```

### React

React support is provided by
[`@rescript/react`](https://github.com/rescript-lang/rescript-react). The entry
point of the sample React app is [`src/Index.re`](src/Index.re).

## Commands

- `npm install` - installs the npm/JavaScript dependencies, including the `esy`
  package manager (see below)
- `npm run build:watch` - uses `esy` to:
  - Install OCaml-based dependencies (e.g. OCaml and Melange)
  - Symlink Melange's JavaScript runtime into `node_modules/melange`, so that
    JavaScript bundlers like Webpack can find the files when they're imported
  - Compile the project's ReasonML/OCaml/ReScript source files to JavaScript
  - Rebuild files when changed (via Melange's built-in watch mode)
- `npm run serve` - starts a dev server to serve the frontend app

## JavaScript output

Since Melange just compiles source files into JavaScript files, it can be used
for projects on any JavaScript platform - not just the browser.

All ReasonML/OCaml/ReScript source files under `src/` will be compiled to
JavaScript and written to `_build/default/src/*` (along with some other build
artifacts).

For example, [`src/Hello.ml`](src/Hello.ml) (using OCaml syntax) and
[`src/Main.re`](src/Main.re) (using ReasonML syntax) can each be run with
`node`:

```bash
node _build/default/src/Hello.bs.js
node _build/default/src/Main.bs.js
```

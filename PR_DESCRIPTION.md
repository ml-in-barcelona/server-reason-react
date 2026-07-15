# Build `react-client` from a pinned React submodule (drop the npm fork)

## Why

`react-server-dom-esbuild` needs React's Flight client (`react-client/flight`), which
React **does not publish to npm** — it's consumed only internally by React's own bundler
integrations. Until now we depended on a personally-scoped republished fork
(`@pedrobslisboa/react-client`), built from a hand-maintained fork of `facebook/react`.

This PR builds it from source in this repo, from a pinned `facebook/react` submodule, and ships
it through opam like the esbuild plugin. No unofficial npm package, no React fork to rebase, and
the React commit it was built from is recorded as the submodule pin in this repo's history.

## What changed

- **New package `packages/react-client`.** It pins `facebook/react` as a submodule
  (`c260b38d`, React 19.1.0) and runs React's own rollup build for its `react-client` package.
  - The `flight` entry is redirected to our `flight-entry.js` so the output re-exports both
    the response client (`ReactFlightClient`) and the reply client (`ReactFlightReplyClient`),
    which upstream's `flight` entry doesn't expose.
- **`dist/` is committed** — React's build output copied verbatim (`flight.js`, `LICENSE`, and
  the development and production `cjs/` builds) plus a generated `package.json`. Its version is
  derived from the submodule's `ReactVersion.js`, and `peerDependencies.react` is pinned to
  match, so the manifest can't drift from the React it was built against.
- **dune installs `dist/` as a package directory** —
  `lib/server-reason-react/react-client/…` — the same delivery mechanism as
  `esbuild-plugin/plugin.mjs`.
- **`react-server-dom-esbuild` imports it as a bare specifier**, and consumers declare a path
  dependency on the installed directory, so their resolver dedupes it:
  ```json
  "@ml-in-barcelona/react-client": "file:<switch>/lib/server-reason-react/react-client"
  ```
  In-repo, `demo/client` points at `packages/react-client/dist`, since server-reason-react
  isn't installed into its own switch.
- **`react` is a peer dependency** and stays a plain `require`, so the app resolves exactly one
  React instance — the Flight client shares it via
  `React.__CLIENT_INTERNALS_DO_NOT_USE_OR_WARN_USERS_THEY_CANNOT_UPGRADE`.

## Why the package is shipped unbundled

An earlier iteration bundled the build output into one self-contained `react-client.js`. That was
wrong: React's `flight.js` selects between the development and production builds at
`process.env.NODE_ENV`, and bundling resolved that condition at *generation* time. esbuild
substitutes `"development"` for `platform: "browser"`, so the committed artifact ended up as

```js
if (false) { module.exports = null; } else { module.exports = require_..._development(); }
```

— the production build eliminated as dead code, and every consumer shipping React's 158KB
development Flight client in production. Shipping the package as React emits it leaves the choice
to the consumer's bundler. Measured on the demo's esbuild config:

| `NODE_ENV` | output | build included |
| --- | --- | --- |
| `production` | 85 KB | production only |
| `development` | 196 KB | development only |

## Why a package directory rather than a bare file

Importing the file relatively works, but it leaves the same file reachable at more than one path
in a consumer's build. Two copies of the Flight client means two module instances with separate
`knownServerReferences`/`boundCache` state, and server actions then fail with
`Could not find module of type ServerFunction`. Routing it through a package name makes dedupe the
resolver's job: one entry in `node_modules`, one instance — verified by bundling both the bare
specifier and a direct path and confirming a single copy.

This must stay the only resolvable copy, which is why `dist/` is *not* also a
`melange.runtime_deps` of `react-server-dom-esbuild`.

## Resolving `react`

`npm install` materialises a `file:` dependency as a symlink, and esbuild resolves symlinks to
their real path — so it looks for `react` next to `packages/react-client` and fails. Inside a dune
build this doesn't arise: `(source_tree node_modules)` copies the dependency into `_build` as a
real directory, so `react` resolves from the app's own `node_modules`. Consumers bundling outside
such a tree need `--preserve-symlinks` or a `react` alias.

## Setup

Normal development needs nothing special — the committed `dist/` is used as-is. Only bumping
React needs the submodule:

```
make react-client-generate     # checks out the submodule, rebuilds dist/
```

🤖 Generated with [Claude Code](https://claude.com/claude-code)

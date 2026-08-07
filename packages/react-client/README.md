# @ml-in-barcelona/react-client

React's Flight client (`react-client/flight`), built from React's source.

React does not publish `react-client` to npm — it is consumed only internally by React's own
bundler integrations (webpack, parcel, …). This directory builds it from React at a pinned commit
so that [server-reason-react](https://github.com/ml-in-barcelona/server-reason-react)'s esbuild
integration can use it. **It is not part of React's public API** and its shape may change between
React releases.

`react` is a peer dependency and stays a plain `require`, so there is exactly one React instance
at runtime — the consumer's.

## What is generated

`dist/` is React's own build output for its `react-client` package, copied verbatim, plus a
manifest we write:

```
dist/
├── package.json                              (generated: name, version, exports, peer range)
├── flight.js                                 (React's: switches on process.env.NODE_ENV)
├── LICENSE
└── cjs/
    ├── react-client-flight.development.js    158 KB
    └── react-client-flight.production.js      63 KB
```

It is deliberately **not** bundled into a single file. `flight.js` picks the development or the
production build at `process.env.NODE_ENV`, so bundling it here would resolve that condition at
generation time — which is exactly the bug this replaced: the previous single-file artifact had
the production build eliminated as dead code and shipped the development client to every
consumer, in production. Shipping the package unbundled leaves the choice to the consumer's
bundler, which keeps one build and drops the other.

The version in `dist/package.json` is derived from the submodule's `ReactVersion.js`, so it always
names the React the client was built from, and `peerDependencies.react` is pinned to match.

## How it's delivered

Not published to npm. dune installs `dist/` into the opam switch as a package directory, the same
way `esbuild-plugin/plugin.mjs` is installed:

```
lib/server-reason-react/react-client/{package.json,flight.js,LICENSE,cjs/…}
```

Consumers depend on that directory by path, so their bundler resolves the bare specifier in
`ReactServerDOMEsbuild.js` to exactly one copy:

```json
"@ml-in-barcelona/react-client": "file:<switch>/lib/server-reason-react/react-client"
```

In this repo the demo points at `file:../../packages/react-client/dist` instead, since
server-reason-react isn't installed into its own switch.

This must remain the **only** resolvable copy. Two copies means two Flight client instances with
separate `knownServerReferences`/`boundCache` state, and server actions then fail with
`Could not find module of type ServerFunction`.

### Resolving `react`

`npm install` materialises a `file:` dependency as a **symlink**. Bundlers that resolve symlinks
to their real path (esbuild does, by default) then look for `react` from `packages/react-client/`
rather than from the app, and fail with `Could not resolve "react"`. Two ways out:

- Build in a tree where the dependency is a real directory — dune's `(source_tree node_modules)`
  copies it into `_build`, which is why the demo needs no extra configuration.
- Otherwise pass `--preserve-symlinks`, or alias `react` to the app's copy.

## Regenerating

The source is the `packages/react-client/react` submodule, pinned to a `facebook/react` commit.
To bump React:

```sh
git -C packages/react-client/react fetch --depth 1 origin <sha>
git -C packages/react-client/react checkout --detach <sha>
git add packages/react-client/react
make react-client-generate
```

That checks out the submodule, runs React's own rollup build (with the `react-client/flight` entry
redirected to `flight-entry.js`, so the output re-exports the reply client too, which upstream's
entry doesn't expose), and rewrites `dist/`. Commit `dist/` along with the new submodule pin.

The generator needs no npm dependencies of its own — it only copies files and writes a manifest —
but React's build needs its toolchain, which it installs into the submodule with `yarn` on first
run.

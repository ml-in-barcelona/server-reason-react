# Build `react-client` from a vendored React submodule (drop the npm fork)

## Why

`react-server-dom-esbuild` needs React's Flight client (`react-client/flight`), which
React **does not publish to npm** — it's consumed only internally by React's own bundler
integrations. Until now we depended on a republished fork (`@pedrobslisboa/react-client`).

This PR removes that dependency and builds `react-client` from source, from a pinned
`facebook/react` submodule, so there's no reliance on an unofficial package and the version
is explicit and reproducible.

## What changed

- **New package `packages/react-client`.** It vendors `facebook/react` as a submodule
  (pinned to `c260b38d`, React 19.2), builds React's Flight client from it, and bundles it
  (with esbuild, `react` left external) into a single self-contained file, `react-client.js`.
  - The `flight` entry is redirected to our `flight-entry.js` so the bundle re-exports both
    the response client (`ReactFlightClient`) and the reply client (`ReactFlightReplyClient`),
    which upstream's `flight` entry doesn't expose.
- **`react-client.js` is committed**, with a `// Do not edit by hand.` banner. Regenerate it
  only when bumping the React submodule:
  ```
  make react-client-generate     # or: npm run react-client-generate (in packages/react-client)
  ```
- **`react-server-dom-esbuild` just consumes the committed file** — its dune copies
  `react-client.js` in as a melange runtime dep and imports it relatively. No submodule, no
  Node build, no npm dependency in this package.

## Why commit the generated file

Building `react-client` requires React's full Node toolchain (yarn + rollup) and the
submodule — none of which exist in a hermetic, from-git `opam install` (no `node_modules`,
no submodule, no network). Committing the bundle keeps **building `server-reason-react`
hermetic**: `dune build`, `@install`, and `@demo` use the committed artifact and need
neither Node nor the submodule. Only *regenerating* it does.

## Setup / regenerating

Normal development needs nothing special — the committed `react-client.js` is used as-is.
To regenerate after bumping React:

```
make react-client-generate
```

🤖 Generated with [Claude Code](https://claude.com/claude-code)

# React Flight protocol spec

A verifiable specification of the React Flight (RSC) wire protocol, used to keep
`ReactServerDOM.render_model` byte-compatible with the real React implementation.

## How it works

Every case under `cases/shared/` is a single-source Reason file that compiles **twice**:

1. **natively** (via `server-reason-react.ppx`) and is rendered by
   `ReactServerDOM.render_model ~env:\`Prod` — this is the implementation under test.
2. **to JavaScript** (via melange + `reason-react-ppx`) and is rendered by the *real*
   `react-server-dom-webpack/server` running under `bun --conditions react-server`
   with `NODE_ENV=production` — this is the reference implementation.

React's output is committed under `fixtures/*.flight` (one Flight row per line,
normalized as described in [protocol.md](./protocol.md)). An OCaml conformance runner
(`conformance/`) renders the same cases natively and byte-compares each row against the
committed fixture. Fixture diffs across React version bumps *are* the protocol changelog.

## Layout

```
package.json      exact React pins (no ^). bun.lock is committed.
generate.mjs      renders every case with react-server-dom-webpack → fixtures/.
                  --check re-renders and diffs against committed fixtures.
harness/          the universal `Spec` seam: native and melange implementations
                  of the same interface (client refs, async components, delay).
cases/shared/     single-source case files + the Cases.re registry.
cases/native/     native library (copy_files from shared).
cases/js/         melange.emit target (copy_files from shared).
fixtures/         committed golden output of the real React.
conformance/      alcotest runner comparing srr output against fixtures.
```

## Running

```sh
# The conformance suite (offline; only reads committed fixtures):
dune build @packages/reactDom/react_flight_spec/runtest

# Regenerate fixtures from the real React (needs bun + `bun install` in this dir):
make spec-generate      # from the repo root
# Verify fixtures are up to date without writing:
make spec-check
```

## Known divergences (xfail)

Cases annotated with `~xfail` in `cases/shared/Cases.re` are **expected** to mismatch;
the conformance runner asserts that they *do* mismatch, so they flip loudly when fixed.
The five divergences the spec caught on day one (`$`-string escaping, numeric
props as strings, `$` instead of `$L` client references, inlined suspense
symbol, unconditional 7-tuple element rows) were fixed on this branch — see
the git history for the wire-format alignment.

Current known divergences (see the `~xfail` reasons in `Cases.re` for the
exact rows):

- `children_numbers` — `React.int`/`React.float` children cross the wire as
  JSON strings (srr stringifies at construction); React emits JSON numbers.
- `props_style_order` — multi-property style objects come out with reversed
  key order (srr's `ReactDOM.Style.make` prepends in declaration order).
- `props_aria_current` — serialized as `"ariaCurrent"` instead of
  `"aria-current"` (camelCase jsxName in srr's DomProps table).
- `props_aria_booleanish` — boolean aria props are stringified to
  `"true"`/`"false"`; React keeps raw JSON booleans.

## Bumping React

1. Edit the exact versions in `package.json`, run `bun install` here.
2. `make spec-generate` — the fixture diff is the protocol change.
3. Review the diff, update `protocol.md` if the grammar changed, adjust xfail
   annotations in `Cases.re`, commit fixtures + lockfile together.

## Compromises / implementation notes

- **Prop constructors**: props for client components go through `Spec.string`,
  `Spec.int`, `Spec.float`, `Spec.bool`, `Spec.json_null`, `Spec.element`,
  `Spec.promise_string` so heterogeneous props stay single-source. Native builds
  `React.Model` values; the melange side builds a raw JS object (bindings-level
  `%identity`/`external` glue lives only in `harness/js/Spec.re`).
- **Host-element float/null props**: typed JSX (both ppxs) cannot express a float or
  null-valued prop on a host element, so that coverage lives in
  `client_component_with_props` via the Spec prop constructors instead of
  `props_primitives`.
- **No `[@react.client.component]`** in cases: its melange output is a browser stub,
  which is the wrong artifact for a JS RSC server. `Spec.client_component` calls
  `registerClientReference` from react-server-dom-webpack directly.
- **Module resolution**: `generate.mjs` copies the melange-emitted JS from `_build`
  into `.melange-out/` (gitignored) so that bare imports (`react`,
  `react/jsx-runtime`, `react-server-dom-webpack/server`) resolve against the
  exact-pinned `node_modules` of this directory rather than whatever is above
  `_build`.

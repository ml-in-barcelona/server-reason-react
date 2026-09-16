# React Flight protocol spec

A verifiable specification of the React Flight (RSC) wire protocol. It checks
`ReactServerDOM.render_model` against React's production bytes, with a separately
checked key-validation extension, and checks
`ReactServerDOM.decodeReply`/`decodeFormDataReply` against `encodeReply`.

## How it works

Every case under `cases/shared/` is a single-source Reason file that compiles **twice**:

1. **natively** (via `server-reason-react.ppx`) and is rendered by
   `ReactServerDOM.render_model ~env:\`Prod` — this is the implementation under test.
2. **to JavaScript** (via melange + `reason-react-ppx`) and is rendered by the *real*
   `react-server-dom-webpack/server` running under `node --conditions react-server`
   with `NODE_ENV=production` — this is the reference implementation.

React's output is committed under `fixtures/*.flight` (one Flight row per line,
normalized as described in [protocol.md](./protocol.md)). An OCaml conformance runner
(`conformance/`) renders the same cases natively. It requires seven-field element
tuples with `null` production debug fields and a validation state of `0`, `1`, or
`2`. It removes only those suffix byte spans, then compares each row against the
committed fixture. It does not reserialize the remaining JSON. Native and browser
tests separately assert the expected validation states and warnings.

The **reply direction** (client → server) works the other way around: `reply/cases.mjs`
declares plain JS argument values, `reply/generate-reply.mjs` encodes them with the real
`encodeReply` from `react-server-dom-webpack/client` (plain `node`, no react-server
condition) into `reply/fixtures/*.reply`, and `conformance/reply_spec_conformance.ml`
feeds those exact bytes to srr's `decodeReply`/`decodeFormDataReply` and compares the
decoded result against an expected Yojson value declared per case.

## Layout

```
package.json      exact React pins (no ^). package-lock.json is committed.
generate.mjs      renders every case with react-server-dom-webpack → fixtures/.
                  --check re-renders and diffs against committed fixtures.
harness/          the universal `Spec` seam: native and melange implementations
                  of the same interface (client refs, async components, delay).
cases/shared/     single-source case files + the Cases.re registry.
cases/native/     native library (copy_files from shared).
cases/js/         melange.emit target (copy_files from shared).
fixtures/         committed golden output of the real React.
conformance/      alcotest runners: flight_spec_conformance (server → client)
                  and reply_spec_conformance (client → server), plus strict
                  element-extension projection tests.
key_validation/   native fixture exporter and development/production browser tests.
reply/            reply-direction spec: cases.mjs (JS argument values),
                  generate-reply.mjs (encodeReply → fixtures), fixtures/.
```

## Running

```sh
# The conformance suite (offline; only reads committed fixtures):
dune build @packages/reactDom/react_flight_spec/runtest

# Regenerate fixtures from the real React (needs `npm ci` in this dir):
make spec-generate        # server → client .flight fixtures, from the repo root
make spec-generate-reply  # client → server .reply fixtures
# Verify fixtures (both directions) are up to date without writing:
make spec-check
```

To test native rows through the shipped Flight client and React DOM in Chromium:

```sh
# In packages/reactDom/react_flight_spec:
npm ci
npx --no-install playwright install chromium

# From the repository root:
make test-flight-key-validation
```

The browser tests use React, React DOM, and the Flight client at 19.1.0. They cover
key warnings, client props, async rows, document mounting, and streamed hydration.
Results and native rows are written to `_build/flight-key-validation/`.

## Known divergences (xfail)

Cases annotated with `~xfail` in `cases/shared/Cases.re` (model direction) or in the
registry of `conformance/reply_spec_conformance.ml` (reply direction) are **expected**
to mismatch; the conformance runners assert that they *do* mismatch, so they flip
loudly when fixed.

Every case matches the React fixtures after the checked element-validation
extension is removed. The reply direction compares the original payloads.
Earlier divergences the spec caught
(including the reply-side `$$`-unescape bug and the missing server-reference
dedup) were fixed on
this branch — see the git history for the alignment work: `$`-string escaping,
numeric props as strings, `$` instead of `$L` client references, inlined
suspense symbol, shared-thenable dedup
(`writtenObjects`), async components at the task root resolving into the
task's own row, sync throws at the root erroring the root row (`0:E`), and
`E`-row flushing after the model rows of the same flush.

## Bumping React

1. Edit the exact versions in `package.json`, run `npm install` here.
2. `make spec-generate && make spec-generate-reply` — the fixture diff is the
   protocol change.
3. Review the diff, update `protocol.md` if the grammar changed, adjust xfail
   annotations in `Cases.re` / `reply_spec_conformance.ml`, commit fixtures +
   lockfile together.

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
- **Resource hints**: `Spec.preload`/`Spec.preconnect`/`Spec.prefetch_dns`/
  `Spec.preinit_script` bind react-dom's flight-side API on the js side and
  `ReactDOM.preload`/`preconnect`/`prefetchDNS`/`preinitScript` natively. The
  calls must happen while a component renders: outside an active request both
  implementations are no-ops (React falls back to the client dispatcher) and
  no `H` row is emitted.
- **No `[@react.client.component]`** in cases: its melange output is a browser stub,
  which is the wrong artifact for a JS RSC server. `Spec.client_component` calls
  `registerClientReference` from react-server-dom-webpack directly.
- **Module resolution**: `generate.mjs` copies the melange-emitted JS from `_build`
  into `.melange-out/` (gitignored) so that bare imports (`react`,
  `react/jsx-runtime`, `react-server-dom-webpack/server`) resolve against the
  exact-pinned `node_modules` of this directory rather than whatever is above
  `_build`.
- **Reply generator runs under plain Node.js**: `encodeReply` is a client API, so
  the generator does not enable the `react-server` condition. Node.js resolves
  `react-server-dom-webpack/client` to `client.node.unbundled`, which does not
  expose `encodeReply`; the generator therefore imports `client.browser`
  explicitly and installs inert `__webpack_require__` shims first.

# Area — Docs, demo, developer experience

All CONFIRMED by the docs/DX agent unless noted; cross-checked against `.mli`s, dune `public_name`s, git, and the live docs site.

## Doc drift — library/API names
- README:44 / index.mld:56 — `server-reason-react.promise` doesn't exist; real: `server-reason-react.promise-js` / `.promise-native`.
- README:12 / index.mld:15 — ppx called `server-reason-react-ppx`; installable name is `server-reason-react.ppx` (get-started.mld:31 uses the right one — inconsistent).
- README:14 / index.mld:17 — "a Dream middleware" advertised as a repo feature, but `DreamRSC` is demo-only (no `public_name`), not shipped with the opam package.
- externals-melange-attributes.mld:35 — `server-reason-react-ppx.melange_ppx` (wrong; real `server-reason-react.melange_ppx`).

## Doc drift — APIs that don't exist / won't compile
- README:11 / index.mld:14 — advertises `React.use()`; renamed to `React.Experimental.usePromise` (React.mli:766).
- how-to-organise-universal-code.mld:87-92 — `ReactDOM.Client.hydrate` + one-arg `hydrateRoot`; reason-react has neither in that form.
- ssr-and-hydration.mld:7 — `ReactDOM.hydrateRoot`/`renderRoot` — nonexistent paths.
- universal-code.mld:29-44, 77 — sealed module hides `async` it then "uses"; `React.Model.Element(string)` uses a type as a value.

## Doc drift — dune snippets that won't parse
- get-started.mld:30 — `(libraries (a b))` — the very first setup snippet is a dune parse error.
- how-to-organise-universal-code.mld:23-36 — unclosed `(library …)`; `(source_only)` isn't a field (real: `only_sources`); `bs_webapi`/`reason_react` don't resolve; `(wrapped false)` library "exposes a `Shared` module" (contradiction).
- **Root cause:** `dune-project:4` declares `(using mdx 0.4)` but no `(mdx)` stanza exists anywhere → doc code blocks are never compile-tested.

## Onboarding
- README "contribution guide" is "DM me"; `make init` (the actual setup) is never mentioned in any doc.
- demo/README:3 — "npm install from the root" but there's no root `package.json` (leaves a fossil root `node_modules/`).
- demo/README:23-30 — describes deleted entrypoints + deprecated `ReactDOM.render`; real setup is six entrypoints, `hydrateRoot`/`createRoot`, libs `demo_shared_js`/`_native`.
- `make docs` needs `odoc-driver`, not in `dune-project` deps; `make docs-open` is macOS-only (`open`) on a Linux repo.

## CI
- Docs (`.mld`) built only post-merge on `main`; PR CI never runs odoc → all the above drift is structurally invisible to CI.
- CI builds dev profile but runs `@runtest` under release; nested-router RSC test `enabled_if (= %{profile} dev)` is skipped in CI.
- `benchmark.yml` triggers on `v*` tags; real tags are `0.5.0` etc. → framework-comparison workflow has never auto-triggered; would fail on a missing `dream` dep if dispatched.

## Links (live-verified)
- README:41 / index.mld:47 → `browser_only.html` = **404** (renamed to `browser_ppx.html`).
- README:45 / index.mld:60 → `…belt_native/Belt/index.html` = **404** (no `belt_native` lib; real `server-reason-react.belt`).
- ssr-and-hydration.mld:17 — markdown `[text](url)` inside `.mld` renders literally (no hyperlink).

## CHANGES.md
- `0.5.0` section contains commits made *after* the `0.5.0` tag; the tag isn't an ancestor of `main` (`git describe` → `0.4.1-109-g…`). If you install `0.5.0` for the advertised style-escaping/perf fixes, you don't get them.

## `arch/` and stray dirs
- `arch/` is the React-parity lab (bun scripts) — referenced nowhere, not in dune `(dirs …)`. Root `dune:1` whitelists `compare`, a directory that doesn't exist. A fossil root `node_modules/` exists with no root `package.json`.

## Newcomer narrative (short)
README sells well then dead-ends (404 links, `React.use`, DM-me); get-started's first dune snippet is a syntax error; demo README is a time capsule ("npm install from root" with no root package.json); universal-code guides teach code that can't compile; CI is green for the wrong reasons (docs never built on PRs, nested-router test skipped). Biggest wins: add mdx/cram checks for doc snippets + build docs in PR CI; rewrite the guides from the working demo; fix the two 404s and the `React.use` claim; add "to set up: `make init`" to the README.

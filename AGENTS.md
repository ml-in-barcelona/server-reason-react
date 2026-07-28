# server-reason-react

Native OCaml/Reason implementation of React SSR and React Server Components.
Stable parts run in production at ahrefs.com.

Package map:

- `packages/react`, `packages/reactDom` — core: React and SSR + RSC rendering
- `packages/server-reason-react-ppx` — JSX ppx
- `packages/rsc` — RSC deriving ppx
- `packages/Belt`, `packages/Js`, `packages/url`, `packages/promise` — vendored universal libraries (native + melange)
- `packages/webapi`, `packages/Dom`, `packages/fetch` — stubs that only need to typecheck natively

See `README.md` for user-facing documentation.

## Commands

| Task | Command |
|------|---------|
| Build | `make build` (dune, dev profile) |
| Test | `make test` (= `dune build @runtest`: alcotest + cram + Flight conformance fixtures) |
| Update snapshots/cram expectations | `make test-promote` |
| Watch mode | `make dev`, `make test-watch` |
| Format | `make format` (ocamlformat `0.28.1`, pinned in `dune-project`; config in `.ocamlformat`) |
| Format check (CI) | `make format-check` |
| Full dep install | `make install` (opam) + `make install-npm` |
| Benchmarks | `make bench` (CI gates regressions on ubuntu + OCaml 5.4.0) |
| Flight fixture check | `make spec-check` (requires bun + `bun install` in `packages/reactDom/react_flight_spec`) |

## Gotchas

- quickjs is pinned from git until 0.5.1 is on opam-repository: `make pin`
  (see the `pin` target in `Makefile` and the constraint comment in
  `dune-project`). quickjs 0.x minors are breaking; keep the `< 0.6.0` bound.
- melange 7.0.0 (exactly) is excluded — see the constraint comment in
  `dune-project`.
- CI builds on macOS + Ubuntu × OCaml 4.14.1 + 5.4.0. Code must stay
  compatible with OCaml 4.14 (no 5.x-only stdlib functions).
- Universal code compiles twice (native + melange). Platform-specific code
  uses `browser-ppx` (`let%browser_only`, `switch%platform`).

## Conventions

- Almost no comments: only non-obvious invariants and "why" that can't be
  expressed in code. Never write comments restating what the code does.
- No `Obj.magic` / `%identity` unless absolutely necessary; prefer type-safe
  alternatives. `Obj.repr` for identity-only keys is acceptable when
  documented (see the `Physical_key` module comment in
  `packages/reactDom/src/ReactServerDOM.ml`).
- Commit messages: short imperative subject line, no prefixes — e.g.
  `Make global regexp string operations linear`, `Fix global timer tests`.
- Snapshot/cram workflow: after an intentional output change, run
  `make test-promote` and review the promoted diff. Never promote to silence
  an unexplained diff.

## Where design decisions live

- `SERVER_FUNCTIONS_DESIGN.md` — design notes for in-flight server-functions work
- `benchmark/perf-work/PERF_NEXT.md` — perf work protocol (measure before changing)
- `documentation/*.mld` — odoc pages (universal code, browser_ppx, SSR/hydration)

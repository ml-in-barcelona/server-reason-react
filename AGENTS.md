# AGENTS.md

## Project Overview

**server-reason-react** is a native OCaml/Reason implementation of React's server-side rendering (SSR) and React Server Components (RSC). It enables writing React components in Reason that compile to both native (server) and JavaScript (client via Melange).

Used in production at ahrefs.com, app.ahrefs.com, and wordcount.com.

## Language & Build System

- **Primary languages**: Reason (`.re`/`.rei`) and OCaml (`.ml`/`.mli`)
- **Build system**: [Dune](https://dune.build/) (version 3.9+)
- **Package manager**: opam (OCaml) + npm (JS tooling)
- **Compiler**: OCaml 5.4.0 (also supports 4.14.1)
- **JS compilation**: [Melange](https://melange.re/) (Reason/OCaml to JavaScript)
- **Formatter**: ocamlformat 0.28.1 (config in `.ocamlformat`, profile=default, margin=120)

## Repository Structure

```
packages/               # Monorepo — all library packages
  react/                # Core React module (server-side impl)
  reactDom/             # ReactDOM: renderToString, renderToStream, RSC
  server-reason-react-ppx/  # JSX PPX transformer for native
  browser-ppx/          # PPX to strip browser-only code on server
  melange.ppx/          # Melange compatibility PPX for native
  Belt/                 # Belt standard library (native impl)
  Js/                   # Js module (native impl, Melange compat)
  Dom/                  # DOM type stubs
  webapi/               # Web API stubs for native compilation
  url/                  # URL module (dual native/js implementations)
  promise/              # Promise module (dual native/js)
  html/                 # HTML generation utilities
  fetch/                # Fetch API stub
  runtime/              # Runtime support module
  expand-styles-attribute/  # Style attribute expansion PPX
  esbuild-plugin/       # Esbuild plugin for client component extraction
  react-server-dom-esbuild/ # React Server DOM esbuild integration
demo/                   # Demo app (Dream server + client hydration)
benchmark/              # Performance benchmarks
documentation/          # odoc documentation source (.mld files)
arch/                   # Architecture reference (browser/server JS)
```

## Essential Commands

```bash
make build              # Build the project (dev profile)
make build-prod         # Build for production
make test               # Run all unit tests (dune build @runtest)
make test-promote       # Update test snapshots
make format             # Format code with ocamlformat
make format-check       # Check formatting (used in CI)
make ppx-test           # Run PPX-specific tests
make ppx-test-promote   # Promote PPX test snapshots
make demo-serve         # Build and serve the demo
make bench              # Run benchmarks
make init               # Full local setup (switch + deps + npm)
```

## Testing

Three testing strategies are used:

1. **Alcotest unit tests** — Located in `test/` directories within each package. Run with `make test`.
2. **Cram tests** (snapshot/golden tests) — Located as `.t` files in `cram/` or `tests/` directories. These test PPX transformations by comparing actual output against expected snapshots. Promote changes with `make test-promote`.
3. **Inline expect tests** — Some packages use inline tests within source files.

Tests should stay explicit and free of test-only logic. Prefer concrete inputs and direct assertions over conditionals, loops, or helpers that hide the behavior being verified.

When modifying PPX code, always run `make ppx-test` and review snapshot diffs carefully before promoting.

## Key Concepts

### Universal Code
Code that compiles for both native (server) and JavaScript (client). The project uses `copy_files` in dune to share `.re` files between Melange and native library targets. See `documentation/universal-code.mld`.

### PPX Transformations
Three PPXes are central to the project:
- **`server-reason-react-ppx`** — Transforms JSX syntax to native React calls
- **`browser-ppx`** — Strips browser-only code on server (`let%browser_only`, `switch%platform`, `@platform`)
- **`melange.ppx`** — Makes Melange attributes (`mel.*`, `##`, `[%re]`, etc.) work in native

### Dual Implementations
Some modules have separate native and JS implementations sharing the same interface:
- `packages/url/native/` vs `packages/url/js/`
- `packages/promise/native/` vs `packages/promise/js/`

### React Server Components (Experimental)
RSC support includes `ReactServerDOM`, an esbuild plugin for client component extraction, and Dream middleware. This is still work in progress.

## Coding Conventions

- Reason (`.re`) is preferred for React components and new application code
- OCaml (`.ml`) is used for library internals, PPX implementations, and Belt/Js modules
- Interface files (`.mli`/`.rei`) are used to define public APIs
- Each package has its own `dune` file defining libraries and test targets
- Follow existing formatting — run `make format` before committing
- PPX transformations use `ppxlib` and follow its visitor pattern

## OCaml

- Do not use `Obj.magic` or `%identity` unless it is absolutely necessary.
- Avoid both at all costs; prefer type-safe alternatives even if they require a slightly larger refactor.
- If either appears to be the only viable option, stop and ask the user before introducing it.

## Do NOT

- Modify `_build/`, `_opam/`, or `node_modules/` directories
- Change `.ocamlformat` settings without discussion
- Skip running tests after modifying PPX code — PPX changes can silently break downstream code
- Introduce new opam dependencies without updating `dune-project`
- Assume browser APIs are available on the server — use `let%browser_only` or `switch%platform`

## CI

GitHub Actions (`.github/workflows/ci.yml`) runs on push to `main` and PRs:
- Matrix: `{macos, ubuntu}` x `{OCaml 4.14.1, OCaml 5.4.0}`
- Steps: build, format check (OCaml 5+ only), tests, docs generation, benchmarks

## Useful Links

- [Documentation](https://ml-in-barcelona.github.io/server-reason-react/server-reason-react/index.html)
- [Reason syntax docs](https://reasonml.github.io/docs/en/what-and-why)
- [Melange docs](https://melange.re/)
- [Dune docs](https://dune.readthedocs.io/)
- [ppxlib docs](https://ocaml.org/p/ppxlib/latest/doc/index.html)

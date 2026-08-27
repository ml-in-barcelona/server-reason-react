# Router: search parameter keys cannot use reserved labels (need aliasing)

Status: open. Found on 2026-08-19 during the Admin Site Inspector RSC
migration (monorepo task 10, `docs/admin-site-inspector-rsc-plan.md`).

Tested against the pinned package `server-reason-react
0.5.1+ahrefs.20260817.8`. The reserved-label list is unchanged in this
checkout (`packages/router/generation/router_declaration.ml`,
`generated_labels`).

## Problem

A search parameter's OCaml record label is also its URL query key. The
generator rejects labels that collide with generated router arguments:

```text
Fatal error: exception router: branch input label target conflicts with a generated router argument
```

`target` is in `generated_labels` because the generated Link component
accepts `~target` (the HTML anchor attribute). So an application cannot
declare a query parameter literally named `target`, which is a very common
query key. Admin Site Inspector's legacy URL surface uses `?target=`.

## Downstream workaround

The monorepo renamed the canonical query key to `site` and redirects legacy
`?target=` URLs at the AA adapter before the router runs. This costs URL
continuity and spreads legacy handling across two layers (the adapter for
`target`, the Overview route loader for the other legacy parameters).

## Suggested fix

Allow the OCaml label and the URL key to differ, for example:

```reason
~search={
  siteTarget: Router.Search.optional(string, ~key="target"),
}
```

- `~key` defaults to the label, so existing declarations stay valid.
- The generated record field, destination argument, and updateSearch
  argument use the label (`siteTarget`); parsing, printing, and canonical
  URL building use the key (`target`).
- Validation: keys must be unique per scope after aliasing; labels keep the
  current reserved-list check; keys need no reserved-list check because
  they never become OCaml identifiers.

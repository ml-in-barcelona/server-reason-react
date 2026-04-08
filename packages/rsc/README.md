`rsc` is a tiny fork of `melange-json` for React Server Component's protocol, with those differences from `melange-json`:

- It supports additional values to plain JSON (for example `React.element`, promises, and server functions) that aligns with `React.Model`.
- Deriving and attributes are renamed from `json` to `rsc` (`[@@deriving rsc]`, `to_rsc`/`of_rsc`, `[@rsc.*]`).

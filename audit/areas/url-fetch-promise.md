# Area — url, fetch, promise

## url (finding 2.22)
Native uses RFC3986 `ocaml-uri`; same `URL.rei` for both platforms (via `copy_files#`), so it compiles then diverges. All CONFIRMED (agent probed against `ocaml-uri`).

- `native/URL.re:125-135` `makeExn` only rejects the empty string; `makeExn "not a url"` succeeds (browser throws).
- `:273` `toString = Uri.to_string` — no WHATWG normalization: no trailing slash (`"https://sancho.dev"` stays, pathname `""` not `"/"`), dot-segments unnormalized.
- `:197-202` default ports kept (`:443` stays); `:150-158` IPv6 brackets lost (`host` = `"::1:8080"`).
- `:144-148` **`makeWith` broken**: the whole relative ref is stuffed into the path and `str` is passed as the scheme. `makeWith("https://other.com/x", ~base="https://a.com")` → `"https://a.com/https://other.com/x"`; `"//cdn.com/x"` → `"https://a.com//cdn.com/x"`.
- SearchParams: `:5` commas re-joined with `""` (`"topic=api,webdev"` → value `"apiwebdev"`); `:75-91` `getAll` returns only the first entry's values; key-without-`=` unreachable; `set` on missing key is a no-op; `:105-107` `sort` not guaranteed stable.
- Setters: `:178-181` `setHref` silent no-op; `:204-206` `setPort ""`/`"80a"` raises `Failure`; `:213-215` `setProtocol` accepts anything.
- `js/URL.re:21-53` — `append`/`delete`/`set` snapshot old state, **mutate the input**, and return the **pre-mutation copy** — inverted vs native and vs the browser's live-linked SearchParams. CONFIRMED.

**Action:** move native to a WHATWG-conformant impl, or document the RFC3986 subset as the contract (contradicts the 0-divergence goal, Q5).

## fetch (finding 2.17)
- `packages/fetch/Fetch.ml` is a native-only stub façade; there is no HTTP client. Every arrow external → `raise (Runtime.Impossible_in_ssr "fetch")` after a stdout banner. Return type is `Js.Promise.t` (= `Lwt.t`), but the failure is a **synchronous raise**, not a rejected promise. CONFIRMED.
- No `[@alert]` — server misuse compiles clean, fails at runtime.
- `AbortController.make()` is fake (`abort = () => ()`, `aborted` stays `false`). `RequestInit.make ?signal` accepts it. CONFIRMED.
- `Fetch.ml:155` typo `"sharedworder"`.

## promise (finding 2.23)
- `native/promise.re:216-239` — settled-promise callbacks are pushed into a global `ReadyCallbacks` queue that **nothing drains** (no driver anywhere in the repo). So `Promise.get`/`then` callbacks never fire on native, and the queue grows unbounded. CONFIRMED.
- `:397-469` `all []` never resolves (JS resolves `[]` immediately). CONFIRMED.
- Deps `lwt`/`belt` are declared but the module never uses Lwt — **no bridge** between this promise world and the Lwt-backed `Js.Promise` the rest of the codebase actually uses. Two disjoint async worlds.
- Rejection handling: uncaught rejections are stored and the promise stays pending forever; no unhandled-rejection detection (Node crashes on those).
- `.rei` covariance differs native vs js (`rejectable(+'a,+'e)` js vs invariant native); covariance-dependent code compiles only on js.

**Action:** either wire a `ReadyCallbacks` driver / Lwt bridge, or remove the vendored native promise if unused, so it isn't a latent trap.

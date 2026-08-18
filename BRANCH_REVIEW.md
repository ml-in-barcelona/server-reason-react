# Branch review: type-safe generated router

Reviewed on 2026-08-18.

## Scope and process

- Target: local `nested-router-header-protocol` at `8a2537f`, compared with `origin/main` at `c988685`.
- PR context: [#392](https://github.com/ml-in-barcelona/server-reason-react/pull/392), including its description, checks, comments, and review threads.
- Scope: all 176 changed files (10,559 additions and 4,352 deletions), with detailed passes over router generation, the native server/protocol, the browser runtime/history, React DOM streaming changes, and Dream/demo integration.
- Review methods: full diff and surrounding-code inspection; protocol and history-state traces; inspection of generated artifacts; existing test and documentation cross-checks.
- Verification:
  - `make test` — passed.
  - `make build` — passed.
  - `make format-check` — passed.
  - `git diff --check origin/main...HEAD` — passed.
  - A temporary manifest confirmed that search fields named `history` or `revalidate` generate duplicate labeled arguments.

The local branch has diverged from the published PR head (`938256b`): it is 42 commits ahead and 46 commits behind `origin/nested-router-header-protocol`. GitHub reports the PR as conflicting. The findings below apply to the local checkout, not necessarily to the currently published PR diff.

## Outcome

**The two critical findings are fixed in the local checkout.** Four warnings and two notes remain. The PR still needs its published branch reconciled with the reviewed local branch before this review can describe what GitHub will merge.

**Open findings:** 0 critical, 4 warnings, 2 notes.

## Resolved critical findings

### 1. Content identities collided across document reloads — resolved

**Location:** `packages/router/react/js/RouterReact.re:154`, `450-457`, `601-605`, `619-646`

Previously, every document initialized its content identity to `content-0`, while later identities derived from request IDs that also restart at 1. Consider a history stack A (`content-0`) → B (`content-1`) → C (`content-2`). After going back to B and reloading, B was rewritten to `content-0`. Going back to A then compared two equal identities and classified the transition as shallow, retaining B's rendered tree at A's URL.

**Resolution:** Each provider now generates a UUID-based document prefix and combines it with its monotonic request ID. Browser regression coverage verifies that generated prefixes are unique.

### 2. A failed `popstate` navigation reloaded the route being left — resolved

**Location:** `packages/router/react/js/RouterReact.re:378-391`, `564-567`

For `Navigation.Pop`, `failNavigation` previously hard-replaced the page with `committed.location`. The browser had already moved to the popped target. If Back from `/b` to `/a` encountered a network or decoding failure, this code replaced `/a` with `/b`, undoing Back and overwriting the target history entry.

**Resolution:** Failed pop requests now hard-replace the document at the popped target rather than the previously committed URL.

## Warnings

### 3. Legal search names generate uncompilable APIs

**Location:** `packages/router/generation/router_declaration.ml:359-387`, `packages/router/generation/router_expansion.ml:418-440`, `511-531`

`generated_labels` does not reserve `history` or `revalidate`, although generated `Link.make` and search-update functions introduce those labels. A manifest using either name emits duplicate labeled arguments such as `?history ... ?history` or `?revalidate ... ?revalidate` and fails to compile.

**Suggestion:** Reserve both labels and add cram cases showing a generation-time diagnostic for each.

### 4. Missing or malformed registry facts can still produce a patch

**Location:** `packages/router/native/RouterServer.ml:741-775`

Only a syntactically valid, unequal `Router-Registry` value is considered a mismatch. `None`, malformed values, and non-numeric versions are treated as acceptable, while `patch_base` does not require an exact registry match. A request retaining `from` and `base_revision` but losing or corrupting only the registry header can therefore receive a patch. This contradicts the documented contract that missing navigation facts degrade to a full response.

**Suggestion:** Distinguish exact match, valid mismatch, and missing/malformed registry facts. Permit patches only for an exact match; return `reload-required` for a valid mismatch and a full response for missing or malformed values. Add tests for each independently dropped fact.

### 5. `Vary: *` is merged into an invalid/non-canonical list

**Location:** `packages/router/runtime/shared/RouterTypes.re:147-196`

The merge treats `*` as an ordinary token. Combining a route's `Vary: *` with the required `Vary: Accept` emits `Vary: *, Accept`; the wildcard must dominate the field value. Caches may handle the combined value inconsistently.

**Suggestion:** If any normalized token is `*`, emit only `Vary: *`; otherwise retain the current case-insensitive deduplication. Add a header-composition test.

### 6. Route headers permit hop-by-hop transport headers

**Location:** `packages/router/runtime/shared/RouterTypes.re:100-106`

The forbidden set covers `Connection`, `Content-Length`, and `Transfer-Encoding`, but still permits `Keep-Alive`, `Proxy-Connection`, `TE`, `Trailer`, and `Upgrade`. Metadata/header callbacks can therefore inject transport-specific headers into framework responses.

**Suggestion:** Reject the complete hop-by-hop set. At the HTTP adapter boundary, also reject names nominated by a `Connection` header if arbitrary framework headers can reach it.

## Notes

### 7. Link interception ignores prior cancellation

**Location:** `packages/router/react/js/RouterReact.re:748-767`

The click handler does not check `event.defaultPrevented`. A child or delegated handler that intentionally cancels navigation can still trigger router navigation when the event bubbles to the anchor.

**Suggestion:** Include `!defaultPrevented(event)` in the interception predicate and add a browser event test.

### 8. The Dream adapter does not expose the renderer's nonce support

**Location:** `demo/dream-router/DreamRouter.ml:182-206`, `DreamRouter.mli:50-59`, `85-94`

The renderer now supports nonces on every streamed script, but the Dream helpers and router route factory cannot accept or forward one. Applications using this adapter cannot use its generated streaming scripts with a strict nonce-based CSP without bypassing the adapter.

**Suggestion:** Thread an optional nonce through `stream_html`, `createFromRequest`, and `routes`, and add an adapter-level streamed-script test.

## Positive observations

- The server recomputes the shared branch from both URLs rather than trusting a client-provided reuse decision.
- Registry mismatches are checked before loaders run.
- Path matching rejects malformed escapes, encoded separators, and dot segments, with focused tests and benchmarks.
- Patch validation checks request identity, base revision, registry fingerprint, protocol version, content type, response kind, and canonical URL before committing.
- Nonce propagation in the renderer itself is covered across initial and streamed scripts.

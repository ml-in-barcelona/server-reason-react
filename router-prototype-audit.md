# Nested router prototype audit

Audit date: 2026-07-30

Scope:

- `demo/server/pages/NestedRouter.re`
- `demo/dream-nested-router/`
- The `NestedRouter_*` components used by the demo
- Browser behavior at `http://localhost:8080/demo/router`

This document audits the current prototype. It does not prescribe compatibility with the existing API, because the router is enabled only in the Dune `dev` profile and the current API has not earned a stable contract yet.

The proposed replacement architecture and draft behavior contract live in [`router-adr-spec.md`](router-adr-spec.md).

## Anti-patterns verdict

**Verdict: fail, but not a severe AI-slop case.** The screen looks like a functional dark-theme demo rather than a deliberately designed notes application. Someone could reasonably believe AI generated the empty states and list treatment, but the interface avoids the most common AI palette and effects.

Specific tells from the frontend-design anti-pattern list:

- The page uses the browser or Tailwind default sans-serif font. There is no typographic point of view.
- Every note is a similar rounded dark card. This creates the repeated-card-grid look even though the cards form a list.
- Empty, loading, and error states center an emoji or plain text in a large unused area. The pattern is generic and does not teach the user what to do beyond one sentence.
- The root view centers its message while the rest of the interface is left-aligned. The composition looks accidental rather than intentionally asymmetric.
- The interface uses one spacing rhythm and one neutral palette almost everywhere.
- The note expansion control is a full-width rounded strip containing `^`. It looks like a placeholder control rather than a designed disclosure affordance.

Anti-patterns not found:

- No cyan-on-dark or purple-to-blue AI palette
- No gradient text
- No glassmorphism or glow effects
- No hero metrics
- No decorative charts
- No bounce or elastic easing
- No nested modal workflow

## Executive summary

### Issue count

| Severity | Count |
| --- | ---: |
| Critical | 3 |
| High | 10 |
| Medium | 7 |
| Low | 2 |
| **Total** | **22** |

### Quality assessment

| Area | Assessment | Basis |
| --- | --- | --- |
| Accessibility | 72/100 | Measured Lighthouse mobile snapshot |
| Router production readiness | Not ready: correctness, failure handling, and coverage gaps at the core | Qualitative review of findings AUD-02 through AUD-09 |
| Overall prototype quality | Prototype-grade: the SSR/RSC foundation is valuable, the edges are unsafe | Audit judgment, not a measurement |

Only the accessibility row is a measured score. The other two rows are judgments and are stated as such rather than as numbers.

### Most important problems

1. User-authored Markdown reaches `dangerouslySetInnerHTML` without escaping or sanitization. A saved note can execute HTML or script-capable markup.
2. Dynamic parameters are untyped strings. `/demo/router/not-an-int` raises `Failure("int_of_string")`, returns HTTP 200, and leaves a blank page.
3. Concurrent navigations share one mutable pending-navigation slot. Responses can commit against the wrong URL and history state.
4. Search navigation is broken. `~shallow=true` exits without changing URL or state, and hydration removes an initial query string from the address bar.
5. The mobile layout has a 400 px sidebar inside a padded two-column row. A 375 px viewport produced a 539 px document and horizontal scrolling.

### Recommended next steps

1. Freeze feature work and define a typed route model before adding more string-based APIs.
2. Fix correctness and security with `/harden`, backed by browser integration tests using `/tdd`.
3. Replace the mounted-layouts registry mutation model with committed match state, request IDs, and cancellation.
4. Repair mobile structure and accessibility with `/adapt`, `/normalize`, and `/clarify`.
5. Re-run `/audit` after the router behavior has tests and the UI has a responsive layout.

## Critical issues

### AUD-01: Stored Markdown can inject executable HTML

- **Location:** `demo/universal/native/Markdown.re:14-206`, `demo/universal/native/shared/NotePreview.re:2-10`, `demo/universal/native/DB.re:213-249`
- **Severity:** Critical
- **Category:** Security / resilience
- **Description:** `Markdown.toHTML` performs regular-expression replacements but never escapes raw HTML or validates generated link URLs. `NotePreview` inserts the result with `dangerouslySetInnerHTML`. Create and edit operations persist user input unchanged.
- **Impact:** A note can inject markup into every reader's browser. Depending on browser parsing and payload shape, this can execute script-capable content, steal data available to the origin, alter navigation, or impersonate application controls.
- **WCAG/standard:** OWASP XSS Prevention Cheat Sheet; React's `dangerouslySetInnerHTML` trust requirement.
- **Recommendation:** Parse Markdown with an allowlisted renderer, sanitize the final HTML, reject unsafe URL schemes, and add malicious fixture tests. Treat stored content as untrusted even in a demo.
- **Suggested command:** `/harden`

### AUD-02: Invalid dynamic parameters crash the route and return a blank 200 response

- **Location:** `demo/server/pages/NestedRouter.re:214-234`, `demo/dream-nested-router/native/shared/PathParams.re:1-17`
- **Severity:** Critical
- **Category:** Router correctness / resilience
- **Description:** The matcher exposes `id` as `option(string)`. Both note pages run `Option.map(int_of_string)` during render. A browser request to `/demo/router/not-an-int` produced an empty accessibility tree, logged `Failure("int_of_string")`, and returned HTTP 200.
- **Impact:** Any malformed or manually edited URL can blank the application. Crawlers and monitoring see a successful status for a failed page, and users get no recovery action.
- **WCAG/standard:** WCAG 3.3.1 Error Identification is relevant to the missing user-facing failure; HTTP semantics require an appropriate 4xx/5xx status before streaming commits.
- **Recommendation:** Put parsing in the route definition through a typed codec such as `int param`. A parse failure should become a typed no-match or 400/404 result before rendering starts. Route error boundaries must render a recovery page and preserve a correct status.
- **Suggested command:** `/harden`, then `/tdd`

### AUD-03: Overlapping navigation responses can commit to the wrong URL

- **Location:** `demo/dream-nested-router/native/shared/Router.re:164-228`, `demo/dream-nested-router/native/shared/Router.re:230-293`
- **Severity:** Critical
- **Category:** Router correctness / performance
- **Description:** Every navigation overwrites `inflightNavigation.current`. Fetches have no request ID or `AbortController`. `commitNavigation` pairs whichever response resolves with whichever pending record is current at that moment.
- **Impact:** If a user starts navigation A and then B, an out-of-order response can render A's content while pushing B's URL and params. This breaks the core invariant that URL, matched route, params, and content describe the same location.
- **WCAG/standard:** Fetch cancellation and React transition correctness; no direct WCAG criterion.
- **Recommendation:** Give every navigation an identity, abort superseded work, and ignore responses that do not match the active navigation. Commit URL, match, params, and rendered model atomically from one response record.
- **Suggested command:** `/harden`, then `/tdd`

## High-severity issues

### AUD-04: Shallow navigation is a no-op, so search does not work

- **Location:** `demo/dream-nested-router/native/shared/Router.re:230-293`, especially `267-269`; `demo/universal/native/shared/NestedRouter_SearchField.re:15-33`
- **Severity:** High
- **Category:** Router correctness
- **Description:** `navigate(~shallow=true, ...)` immediately returns without updating browser history, router URL state, or search params. Typing `Lorem` left all five notes visible and kept the URL at `/demo/router`.
- **Impact:** Search appears interactive but has no effect. Any future feature built on shallow URL state will fail in the same silent way.
- **WCAG/standard:** WCAG 3.2.2 On Input and 4.1.3 Status Messages are relevant to predictable state and feedback.
- **Recommendation:** Define shallow navigation precisely. It should at least update history and the router location atomically without fetching route content. Search-param changes should notify subscribers and preserve unrelated params.
- **Suggested command:** `/harden`

### AUD-05: Hydration removes the initial query string

- **Location:** `demo/dream-nested-router/native/shared/Router.re:295-314`
- **Severity:** High
- **Category:** Router correctness
- **Description:** The hydration effect uses `Location.pathname` as both history path and replacement URL. Directly loading `/demo/router?searchText=Lorem` changed the address bar to `/demo/router` after hydration. The search input retained `Lorem` while the list and router URL reverted, creating contradictory state.
- **Impact:** Bookmarkable state is lost on load. Back/forward cache keys omit the initial search, and UI controls can disagree with the visible URL and rendered data.
- **WCAG/standard:** URL and History API semantics; no direct WCAG criterion.
- **Recommendation:** Preserve the complete relative URL, including search and hash, in initial history state and cache identity. Derive all location state from one parsed `URL.t`.
- **Suggested command:** `/harden`

### AUD-06: Virtual history mutates global state during React render

- **Location:** `demo/dream-nested-router/native/shared/Route.re:76-100`; `demo/dream-nested-router/js/MountedLayouts.re:34-69`
- **Severity:** High
- **Category:** Render performance / correctness
- **Description:** `Route.make` calls `MountedLayouts.push` during render and flips a ref to hide the side effect on later renders. `MountedLayouts.state` is a process-global mutable list of component callbacks. Routes do not unregister on unmount, and cleanup uses string length rather than route ancestry.
- **Impact:** Interrupted, repeated, or strict React renders can register callbacks for trees that never committed. Stale callbacks can target unmounted branches, tests can leak state between roots, and multiple routers on one page share the same registry.
- **WCAG/standard:** React component purity and effect lifecycle rules.
- **Recommendation:** Register committed route instances in an effect with cleanup, scope the registry to a router instance, and represent ancestry with stable route IDs rather than path-length comparisons. Prefer deriving the active branch from router match state so no callback registry is needed.
- **Suggested command:** `/harden`, then `/optimize`

### AUD-07: Unknown URLs bypass the configured `NotFound` component

- **Location:** `demo/dream-nested-router/native/RouterRSC.re:527-642`; `demo/server/pages/NestedRouter.re:180-187`, `240-270`
- **Severity:** High
- **Category:** Router correctness / resilience
- **Description:** The Dream router registers only generated known patterns. An unknown URL such as `/demo/router/does/not/exist` never reaches `renderNotFound`; it receives Dream's empty 404 response instead. The custom `NotFound` component is only used after a registered handler has already matched.
- **Impact:** Users see an empty response rather than an application-level recovery page. Nested route misses cannot render the nearest not-found boundary.
- **WCAG/standard:** Correct HTTP 404 semantics; WCAG 2.4.2 Page Titled and 3.2.3 Consistent Navigation are affected by the empty document.
- **Recommendation:** Add a base-path catch-all after concrete routes, match within the route tree, and render the nearest not-found boundary with status 404. Keep server and client miss behavior identical.
- **Suggested command:** `/harden`

### AUD-08: Navigation fetch failures have no status check, error UI, or retry path

- **Location:** `demo/dream-nested-router/native/shared/Router.re:91-103`, `278-288`
- **Severity:** High
- **Category:** Router correctness / resilience
- **Description:** `fetchComponent` parses every response body without checking `response.ok` or content type. The rejection path resets flags and re-rejects through an ignored promise. No route error boundary receives the failure.
- **Impact:** Network errors and server failures leave stale content on screen, may produce an unhandled rejection, and provide no explanation or retry action. The visible URL may also lag user intent.
- **WCAG/standard:** WCAG 3.3.1 Error Identification and 4.1.3 Status Messages.
- **Recommendation:** Model navigation as `Idle | Pending | Committed | Failed`. Validate the response, surface typed errors to the nearest route boundary, keep a retry operation, and decide explicitly whether the URL commits before or after data succeeds.
- **Suggested command:** `/harden`, then `/clarify`

### AUD-09: The public route API is not type-safe

- **Location:** `demo/dream-nested-router/native/RouterRSC.re:45-80`; `demo/dream-nested-router/native/shared/Router.re:112-122`; `demo/dream-nested-router/native/shared/PathParams.re:1-17`; string concatenation across `NestedRouter_*`
- **Severity:** High
- **Category:** Router architecture
- **Description:** Route paths, navigation destinations, parameter names, and query keys are strings. Params are `array((string, string))`, page modules receive the same untyped bag, and callers build URLs with concatenation. The compiler cannot detect a renamed route, missing param, extra param, bad codec, or misspelled query key.
- **Impact:** OCaml currently adds no route-level safety over a JavaScript router. Refactors fail at runtime, and every page repeats parsing and missing-value policy.
- **WCAG/standard:** API design requirement; no direct WCAG criterion.
- **Recommendation:** Make a generated typed route handle the source of truth for matching, URL construction, page props, search validation, and navigation. See the route declaration and generated API design in [`router-adr-spec.md`](router-adr-spec.md).
- **Suggested command:** `/architect`

### AUD-10: The layout is unusable at mobile widths

- **Location:** `demo/server/pages/NestedRouter.re:102-145`; `demo/universal/native/shared/DemoLayout.re:6-17`
- **Severity:** High
- **Category:** Responsive design
- **Description:** The application always uses `flex-row`, gives the sidebar `min-w-[400px]`, adds a 2 rem gap and page padding, and caps the viewer at 75 percent. At a 375 by 812 viewport, the document measured 539 px wide and displayed a horizontal scrollbar. The viewer was pushed off-screen.
- **Impact:** Mobile users cannot see the selected note without horizontal panning. Text zoom makes the failure worse.
- **WCAG/standard:** WCAG 1.4.10 Reflow, Level AA.
- **Recommendation:** Design a mobile navigation model rather than shrinking the desktop split view. Use one pane at a time or an adaptive drawer, remove fixed minimum widths, and test at 320 px plus 200 percent text zoom.
- **Suggested command:** `/adapt`

### AUD-11: The disclosure control is pointer-only and has no state semantics

- **Location:** `demo/universal/native/shared/NestedRouter_SidebarNoteContent.re:61-65`
- **Severity:** High
- **Category:** Accessibility
- **Description:** The note preview expander is a `div` with `onClick`. It has no keyboard focus, button role, accessible name, `aria-expanded`, or `aria-controls` relationship.
- **Impact:** Keyboard and switch users cannot expand note summaries. Screen-reader users cannot discover the control or its current state.
- **WCAG/standard:** WCAG 2.1.1 Keyboard, Level A; 4.1.2 Name, Role, Value, Level A.
- **Recommendation:** Use a real button with a visible or accessible label, expose expanded state, connect it to the controlled region, and keep the full target at least 44 px high.
- **Suggested command:** `/harden`

### AUD-12: Menu ARIA roles create an invalid accessibility tree

- **Location:** `demo/server/pages/NestedRouter.re:122-139`; `NestedRouter_CreateNoteButton.re:6-12`; `NestedRouter_EditButton.re:6-16`; `NestedRouter_DeleteNoteButton.re:12-42`; `NestedRouter_NoteEditor.re:27-65`
- **Severity:** High
- **Category:** Accessibility
- **Description:** Ordinary toolbars and forms use `role="menubar"`, while buttons use `role="menuitem"` through wrapper elements. The implementation has no menu keyboard model. Lighthouse reported both missing required children and missing required parent failures. The accessibility snapshot also exposed note-selection buttons without names.
- **Impact:** Screen readers announce desktop-application menu semantics that the controls do not implement. Arrow-key expectations fail, and unnamed note buttons do not identify their destination.
- **WCAG/standard:** WCAG 4.1.2 Name, Role, Value, Level A; WAI-ARIA menu pattern.
- **Recommendation:** Remove menu roles from normal forms and action rows. Use native buttons and links with clear names. If a true menu is needed later, implement its complete focus and keyboard behavior.
- **Suggested command:** `/normalize`, then `/harden`

### AUD-13: Note editor fields have no labels, names, or validation contract

- **Location:** `demo/universal/native/shared/NestedRouter_NoteEditor.re:19-26`; `InputText.re:1-15`; `Textarea.re:1-15`
- **Severity:** High
- **Category:** Accessibility / forms
- **Description:** The title input and body textarea are rendered without labels, IDs, names, required state, constraints, or error messages. Chrome reported both controls as missing an `id` or `name`.
- **Impact:** Screen-reader users hear generic "textbox" controls and cannot tell title from body. Browser form features and robust server validation cannot identify fields.
- **WCAG/standard:** WCAG 1.3.1 Info and Relationships, Level A; 3.3.2 Labels or Instructions, Level A.
- **Recommendation:** Add persistent labels and stable names, define validation rules in shared types, show field-specific errors, and move submission onto the form so Enter and no-JavaScript behavior are coherent.
- **Suggested command:** `/clarify`, then `/harden`

## Medium-severity issues

### AUD-14: Secondary text fails AA contrast

- **Location:** `demo/server/pages/NestedRouter.re:110-119`; `demo/universal/native/shared/Theme.re:64-79`
- **Severity:** Medium
- **Category:** Accessibility / theming
- **Description:** `Gray10` (`#6E6E6E`) appears on `Gray2` (`#151515`) at a measured 3.58:1 ratio. The text is 14 px and therefore requires 4.5:1. Lighthouse identified both migration-copy spans.
- **Impact:** Users with low vision or low-quality displays may not be able to read the project attribution.
- **WCAG/standard:** WCAG 1.4.3 Contrast Minimum, Level AA.
- **Recommendation:** Use a semantic muted-text token that meets 4.5:1 on every supported surface. Add automated contrast tests for token pairs.
- **Suggested command:** `/normalize`

### AUD-15: The document lacks basic language, title, and main-content semantics

- **Location:** `demo/server/pages/NestedRouter.re:150-168`
- **Severity:** Medium
- **Category:** Accessibility / SEO
- **Description:** `<html>` has no `lang`, `<head>` has no `<title>`, and the page has no `<main>` landmark. Lighthouse failed all three checks. The root view also has no heading; the application name is a span.
- **Impact:** Screen readers may choose the wrong pronunciation rules, users cannot identify the tab, and landmark navigation cannot jump to the main note view.
- **WCAG/standard:** WCAG 3.1.1 Language of Page, Level A; 2.4.2 Page Titled, Level A; 1.3.1 Info and Relationships.
- **Recommendation:** Add document metadata and route-aware titles. Use one main landmark and a logical heading hierarchy.
- **Suggested command:** `/harden`

### AUD-16: The hidden spinner remains busy and has no accessible name

- **Location:** `demo/universal/native/shared/Spinner.re:1-10`; `NestedRouter_SearchField.re:35-46`
- **Severity:** Medium
- **Category:** Accessibility
- **Description:** The spinner always has `role="progressbar"` and `aria-busy=true`, including while visually hidden with opacity. It has no accessible name. Lighthouse failed `aria-progressbar-name`.
- **Impact:** Screen readers encounter an unnamed busy indicator even when no search is running. Users receive misleading state information.
- **WCAG/standard:** WCAG 4.1.2 Name, Role, Value; 4.1.3 Status Messages.
- **Recommendation:** Remove the progress element from the accessibility tree while inactive. While active, provide a concise label such as "Filtering notes" and put `aria-busy` on the region being updated.
- **Suggested command:** `/clarify`, then `/harden`

### AUD-17: Several primary controls miss the 44 px touch-target goal

- **Location:** `demo/universal/native/shared/Theme.re:134-141`; `InputText.re:3-14`; `DemoLayout.re:32-41`
- **Severity:** Medium
- **Category:** Responsive design / accessibility
- **Description:** Browser measurements at mobile width found the Home link at 24 px high, Create at 36 px, and Search at 40 px. The project target in this audit is 44 by 44 px.
- **Impact:** Users with limited dexterity are more likely to miss controls on touch devices.
- **WCAG/standard:** WCAG 2.5.8 Target Size Minimum requires 24 by 24 px at AA with exceptions; 44 by 44 px is the stronger WCAG 2.5.5 AAA and platform-guidance target.
- **Recommendation:** Increase the interactive box without inflating visual weight. Use padding or pseudo-element hit areas and keep adjacent targets separated.
- **Suggested command:** `/adapt`, then `/polish`

### AUD-18: Theme values are centralized but not semantic or switchable

- **Location:** `demo/universal/native/shared/Theme.re:22-141`; `demo/styles.css:3-24`; `Spinner.re:7-8`
- **Severity:** Medium
- **Category:** Theming
- **Description:** The color scale is centralized in OCaml, which is better than scattered literals, but components choose numbered grays directly. Tailwind emits hard-coded hex classes, `:root` fixes a dark background, and the spinner bypasses the scale with `gray-500` and `white`. There is no light mode or runtime token update path.
- **Impact:** A theme change requires recompilation and component-by-component review. Numbered colors do not encode intent, making invalid contrast combinations easy.
- **WCAG/standard:** WCAG 1.4.3 contrast applies to every theme; no theme switching standard requires a second theme.
- **Recommendation:** Introduce semantic CSS custom properties such as `--surface`, `--surface-raised`, `--text`, `--text-muted`, and `--focus`. Map themes once and keep components on semantic tokens.
- **Suggested command:** `/normalize`, then `/extract`

### AUD-19: Router subscriptions and caches have coarse, stale lifecycle behavior

- **Location:** `demo/dream-nested-router/native/shared/Router.re:149-164`, `366-419`; `demo/dream-nested-router/js/BackForwardCache.re:12-42`
- **Severity:** Medium
- **Category:** Performance / router architecture
- **Description:** One context value contains navigation, params, full URL, search, and pending state, so all consumers rerender for any change. The history cache retains up to ten React element trees with no freshness, invalidation, memory accounting, or loader dependency model. Full-page replacement forces remounts with a timestamp key.
- **Impact:** Larger applications will rerender unrelated consumers, retain stale data and component trees, and lose local state on forced remounts. Cache behavior cannot be reasoned about from data dependencies.
- **WCAG/standard:** React rendering and cache-lifecycle guidance; no direct WCAG criterion.
- **Recommendation:** Store match and loader data rather than opaque React element trees. Add route-scoped selectors or split contexts. Define stale time, garbage collection, invalidation, and mutation effects before calling this a data cache.
- **Suggested command:** `/optimize`

### AUD-20: Matching, navigation, and accessibility lack regression coverage

- **Location:** `demo/dream-nested-router/test_router_rsc.ml:17-98`; `demo/dream-nested-router/native/README.md:247-404`
- **Severity:** Medium
- **Category:** Testing / developer experience
- **Description:** Three native tests cover happy-path param extraction and generated path strings. There are no client tests for search, history, back/forward, races, failed fetches, cache eviction, query/hash preservation, not-found behavior, status codes, focus, or mobile reflow. The README ends with loading and 404 as TODOs even though partial APIs now exist, and several examples use obsolete `Router.use` shapes.
- **Impact:** The current search and query-loss regressions shipped inside the demo undetected. Contributors cannot tell which behavior is intentional.
- **WCAG/standard:** Project test-quality requirement; no direct WCAG criterion.
- **Recommendation:** Write a behavior contract first, then test server matching and browser navigation separately. Keep the README generated from or checked against executable examples where practical.
- **Suggested command:** `/tdd`, then `/clarify`

## Low-severity issues

### AUD-21: Visual hierarchy is generic and wastes the detail pane

- **Location:** `demo/server/pages/NestedRouter.re:89-147`; `NestedRouter_SidebarNoteContent.re:34-66`
- **Severity:** Low
- **Category:** Visual design
- **Description:** The desktop root dedicates roughly three quarters of the screen to a centered emoji and instruction, while the note list repeats large rounded blocks. The interface has little hierarchy beyond font weight and gray surfaces.
- **Impact:** The demo communicates implementation mechanics but does not make the router's nested-layout advantage memorable or easy to inspect.
- **WCAG/standard:** Frontend-design anti-pattern guidance; no WCAG violation by itself.
- **Recommendation:** Use the detail pane to explain route state, pending state, and matched params in the demo. Flatten the note list, strengthen selected-state treatment, and choose a deliberate editorial or developer-tool aesthetic.
- **Suggested command:** `/distill`, then `/bolder`

### AUD-22: The current JavaScript payload needs a production baseline before promotion

- **Location:** Demo build output and browser network trace
- **Severity:** Low
- **Category:** Performance
- **Description:** The dev build loaded 27 JavaScript resources totaling about 1.96 MB decoded, with one shared chunk around 919 KB. The nested router library is dev-profile-only, so this is not a valid production bundle measurement.
- **Impact:** The number is not a release blocker, but promoting the router without a production budget could hide heavy shared-runtime or client-reference costs.
- **WCAG/standard:** Core Web Vitals and project bundle-budget guidance; no direct WCAG criterion.
- **Recommendation:** Add a minified production fixture, record transferred and parsed sizes, and attribute common chunks before setting a budget. Do not optimize from the dev number alone.
- **Suggested command:** `/optimize`

## Features implemented today

| Capability | Status | Notes |
| --- | --- | --- |
| Nested route tree | Implemented | `routeConfig.children` composes layouts and pages. |
| Persistent nested layouts | Prototype | RSC responses update a parent `Route.PageConsumer`; current mounted-layouts registry lifecycle is unsafe. |
| Server rendering | Implemented | Initial route streams HTML and an RSC model. |
| Partial RSC navigation | Implemented | The client asks for a sub-route model with `toSubRoute`. |
| Dynamic path segments | Partial | `:name` segments work through Dream, but values and names are untyped. |
| Search params in pages | Partial | Pages receive `URL.SearchParams.t`; search has no schema and client updates are broken. |
| Per-route loading UI | Implemented | Route `loading` falls back to global loading through Suspense. |
| Root loading UI | Implemented | Main page and child pages can use global loading. |
| Configurable not-found UI | Partial | Rendering helper exists, but unknown HTTP paths bypass it. |
| Push and replace navigation | Implemented | Client history state is written after an RSC response. |
| Back and forward restoration | Prototype | A ten-entry in-memory cache stores React element trees. |
| Revalidation | Partial | `~revalidate=true` requests and remounts the full route tree. There is no data-level invalidation. |
| Shallow navigation | API only | The argument exists; behavior is a no-op. |
| Router hooks | Implemented | `use` exposes navigation; `useRouter` exposes URL, params, and pending state. |
| Trailing-slash canonicalization | Implemented | Registered slash routes redirect with HTTP 303. |

## Missing functionality compared with TanStack Router and React Router

The comparison uses the official TanStack Router overview and React Router framework documentation as of the audit date:

- <https://tanstack.com/router/latest/docs/framework/react/overview>
- <https://reactrouter.com/start/framework/routing>
- <https://reactrouter.com/start/framework/data-loading>
- <https://reactrouter.com/how-to/error-boundary>

Priorities map to the implementation sequence in [`router-adr-spec.md`](router-adr-spec.md): P0 → immediate and short term, P1 → short and medium term, P2 → medium term, P3 → long term.

| Capability | Current router | Priority | Recommendation |
| --- | --- | --- | --- |
| Typed route references | Missing | P0 | Generate route handles used by matching, pages, links, and navigation. |
| Typed path params | Missing | P0 | Parse with route-owned codecs before rendering. |
| Typed and validated search | Missing | P0 | Give each route a search schema, defaults, parse errors, and serializer. |
| Navigation cancellation and race control | Missing | P0 | Abort superseded requests and atomically commit a matched response. |
| Route error boundaries | Missing | P0 | Add nearest-boundary propagation for loader, action, render, and transport errors. |
| Correct not-found boundaries and status | Partial | P0 | Support root and nested 404s before streaming commits. |
| Link and NavLink components | Missing | P0 | Add typed href construction, active state, modified-click behavior, and progressive enhancement. |
| Relative navigation | Missing | P1 | Resolve destinations against route identity rather than string path prefixes. |
| Index routes | Missing | P1 | Model a default child without a new path segment. |
| Pathless layout routes | Missing | P1 | Let layouts group and guard children without changing the URL. |
| Optional params and splats | Missing | P1 | Add these only after deterministic ranking and typed codecs exist. |
| Route ambiguity diagnostics | Missing | P0 | Reject duplicates and ambiguous static/dynamic siblings at startup or compile time. Deterministic ranking lands together with optional params and splats (P1). |
| Route loaders | Missing | P1 | Define route data dependencies separate from render functions. |
| Parallel loader execution | Missing | P1 | Load matched branches concurrently with cancellation. |
| Actions and form integration | Missing | P1 | Route mutations through typed actions with pending and validation states. |
| Redirects | Ad hoc | P1 | Return typed redirects from match, loader, and action phases. |
| Authentication and guards | Missing | P1 | Add typed inherited route context and a pre-load guard phase. |
| Prefetching | Missing | P2 | Let links preload match code and data by intent or viewport. |
| Cache freshness and invalidation | Missing | P1 | Cache data by route and loader dependencies, not React elements. |
| Scroll restoration | Missing | P1 | Restore by history entry and handle hash anchors. |
| Focus restoration and announcements | Missing | P1 | Move focus or announce the new route after client navigation. |
| Navigation blockers | Missing | P2 | Support dirty-form confirmation without corrupting history. |
| Route metadata | Missing | P1 | Compose title, meta, headers, and status from the matched branch. |
| Code splitting and lazy route modules | Partial | P2 | RSC sends client references on demand, but route module boundaries and budgets are not explicit. |
| File-based route generation | Missing | P3 | Optional after the typed code-based API stabilizes. |
| Route masks | Missing | P3 | Defer until core URL semantics are stable. |
| Devtools and match inspection | Missing | P2 | Expose active matches, params, search, pending work, and cache state in development. |

## Patterns and systemic issues

- **Strings cross every boundary.** Route declarations, matches, params, query keys, links, and history entries can disagree without a compiler error.
- **URL state has several owners.** `window.location`, `Router.url`, `inflightNavigation`, history state, `PathParams`, and component-local search state drift independently.
- **Rendering is used as state management.** The router caches React elements and stores component callbacks instead of storing a matched branch and data.
- **Failure states are afterthoughts.** Network errors, parse errors, unknown paths, invalid forms, and route render errors do not share one model.
- **ARIA is added by label rather than behavior.** `menubar`, `menuitem`, and `progressbar` roles do not match the implemented interaction patterns.
- **Desktop dimensions drive the layout.** Fixed widths and row layout have no mobile adaptation.
- **The demo and router are tightly coupled.** Base paths such as `/demo/router` are repeated in consumers rather than supplied by typed route handles or a basename.

## Positive findings

- The route tree is small and understandable. Nested layouts, pages, loading components, and children are visible in one definition.
- Initial SSR and client RSC navigation share server-rendered components. This is a valuable foundation and a real differentiator from a client-only router.
- Partial sub-route responses aim to preserve parent layouts and request only changed UI.
- Loading UI can be configured globally and per route.
- The router already exposes parsed `URL.t` and `URL.SearchParams.t` instead of inventing another URL parser.
- Native buttons are used for primary note selection and actions.
- The search field has a real label and search landmark.
- The note list uses `ul` and `li` semantics.
- The implementation removes `popstate` listeners in effects and caps the history cache.
- Color values are mostly centralized in `Theme.re`, which gives a practical migration path to semantic tokens.
- The three native router tests pass, and the demo build completes.
- The interface avoids gradients, glow effects, glassmorphism, and decorative motion.

## Suggested commands for fixes

| Command | Use it for | Findings addressed |
| --- | --- | --- |
| `/architect` | Design typed route handles, codecs, match state, and response envelopes before implementation | AUD-03, AUD-06, AUD-09, AUD-19 |
| `/harden` | Fix XSS, parse failures, navigation races, history drift, errors, not-found behavior, and ARIA state | AUD-01 through AUD-08, AUD-11 through AUD-13, AUD-15, AUD-16 |
| `/tdd` | Build native matcher tests and browser navigation regression tests | AUD-02 through AUD-08, AUD-20 |
| `/adapt` | Redesign the split view for mobile and text zoom | AUD-10, AUD-17 |
| `/normalize` | Correct ARIA misuse, contrast, and semantic theme tokens | AUD-12, AUD-14, AUD-18 |
| `/clarify` | Write labels, validation messages, loading copy, and route error copy | AUD-08, AUD-13, AUD-16, AUD-20 |
| `/optimize` | Replace element caching, reduce broad subscriptions, and establish bundle budgets | AUD-06, AUD-19, AUD-22 |
| `/extract` | Consolidate semantic tokens and reusable route codecs | AUD-09, AUD-18 |
| `/distill` | Flatten repetitive cards and simplify the empty-state composition | AUD-21 |
| `/bolder` | Give the router demo a deliberate visual concept after usability is fixed | AUD-21 |
| `/polish` | Finish target sizing, focus visibility, spacing, and selected states | AUD-17, AUD-21 |
| `/audit` | Re-run Lighthouse, keyboard, responsive, and anti-pattern checks after fixes | All UI findings |

## Verification evidence

| Check | Result |
| --- | --- |
| `dune exec demo/dream-nested-router/test_router_rsc.exe` | Passed, 3 tests |
| `make demo-build` | Passed |
| Lighthouse mobile snapshot | Accessibility 72, Best Practices 100, SEO 50 |
| Lighthouse accessibility failures | Progressbar name, invalid ARIA parent/children, contrast, title, language, main landmark |
| Mobile viewport | 375 px viewport, 539 px document width, horizontal overflow confirmed |
| Contrast calculation | `#6E6E6E` on `#151515` is 3.58:1 |
| Search interaction | Input changed; URL and five-item list did not change |
| Direct query load | Query disappeared from URL after hydration |
| Invalid ID load | Blank page, `Failure("int_of_string")`, HTTP 200 |
| Unknown path | HTTP 404 with no application not-found UI |
| Dev JS trace | 27 resources, about 1.96 MB decoded; not a production measurement |

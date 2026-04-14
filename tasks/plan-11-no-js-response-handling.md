# No-JS response handling for server actions

**Priority**: Medium
**Independent of**: plan-09, plan-10 (can be done in parallel)
**Origin**: Phase C from plan-03-rethink-server-actions-architecture.md (Layer 3.1-3.2)

## Problem

`streamFunctionResponse` in DreamRSC always returns `Content-Type: application/react.action` with an RSC stream. This works for JS-enabled clients but not for no-JS form submissions — the browser expects HTML, not an RSC stream.

React's model: for no-JS submissions, the server should execute the action, re-render the page with updated state, and return full HTML (or redirect via PRG pattern).

## Tasks

### 3.1 Detect no-JS submissions and return HTML

**File**: `demo/dream-rsc/DreamRSC.re` (or the equivalent middleware)

**Current**: All action responses are RSC streams.

**Proposed**:
- [ ] Detect no-JS submissions by checking for the absence of `Accept: application/react.action` header
- [ ] For no-JS: execute the action, then re-render the page and return HTML
- [ ] For JS: keep the current RSC stream response (no change)
- [ ] Consider using HTTP 303 redirect (POST-Redirect-GET pattern) for no-JS to prevent form resubmission on browser back/refresh

### 3.2 `streamFunctionResponse` should accept a render callback

**Current**: `streamFunctionResponse` only handles the action and streams the RSC response. For no-JS progressive enhancement, it needs to also re-render the page.

**Proposed**:
- [ ] Add an optional `~render` parameter to `streamFunctionResponse` that, when provided, is called after the action completes to produce the full page HTML
- [ ] Or restructure the Dream middleware to combine action handling with page rendering in a single request handler
- [ ] Design the render callback signature: `unit => Lwt.t(React.element)` or `actionResult => Lwt.t(Dream.response)`

### Implementation notes

The no-JS path should:
1. Parse FormData from the multipart body
2. Find `$ACTION_ID_*` or `$ACTION_REF_*` in the FormData keys
3. Look up and execute the server function
4. Call the render callback to produce the page HTML with updated state
5. Return 303 redirect to the same URL (PRG) or return the HTML directly

## Verification

- [ ] Run `make build` — both native and Melange compilation must succeed
- [ ] Run `make test` — all existing tests pass
- [ ] Run `make demo-serve` — demo app builds and serves without errors
- [ ] Test no-JS form submission manually:
  - Load a page with a server action form in the demo
  - Disable JavaScript in the browser
  - Submit the form
  - Verify the browser receives an HTML response (or a 303 redirect followed by HTML)
  - Verify the page reflects the action's effect (e.g., note deleted, counter incremented)
- [ ] Test JS form submission still works:
  - Re-enable JavaScript
  - Submit the same form
  - Verify the RSC stream response is used (no full page reload)

## Dependencies

- No hard dependencies on other plans
- Benefits from plan-08 (`$ACTION_*` hidden fields in forms) being complete
- Benefits from plan-13-csrf-protection for secure no-JS submissions (plan-13 is independent and can be done in parallel)

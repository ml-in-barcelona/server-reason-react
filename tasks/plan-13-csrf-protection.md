# CSRF protection for no-JS form submissions

**Priority**: Lower
**Origin**: Phase F from plan-03-rethink-server-actions-architecture.md (Layer 3.3)

## Problem

`Dream.multipart(~csrf=false)` explicitly disables CSRF. With no-JS form submissions, CSRF tokens become important since the request doesn't have custom headers (which are themselves a CSRF mitigation for JS-enabled requests).

JS-enabled requests include the `Accept: application/react.action` and `ACTION_ID` custom headers, which browsers won't send from cross-origin forms — this provides implicit CSRF protection. No-JS form submissions lack this protection.

## Tasks

### Evaluate Dream's built-in CSRF middleware

- [ ] Research Dream's CSRF middleware: `Dream.csrf_token`, `Dream.verify_csrf_token`, session-based tokens
- [ ] Determine if Dream's CSRF approach is compatible with the server action form submission flow
- [ ] Document the chosen approach and trade-offs

### Render CSRF token in forms

- [ ] During SSR, render a CSRF token as a hidden field alongside `$ACTION_ID_*` in forms with server actions
- [ ] The token should come from Dream's session/CSRF system
- [ ] Ensure the token is present in both server-rendered and client-hydrated forms

### Validate CSRF token in the no-JS dispatch path

- [ ] In the no-JS form submission handler (plan-11), validate the CSRF token from FormData
- [ ] Return 403 or re-render with error if token is invalid/missing
- [ ] Skip CSRF validation for JS-enabled requests (they have custom headers as implicit protection)

## Verification

- [ ] Run `make build` — both native and Melange compilation must succeed
- [ ] Run `make test` — all existing tests pass
- [ ] Run `make demo-serve` — demo app builds and serves without errors
- [ ] Test CSRF protection manually:
  - Load a page with a server action form
  - Disable JavaScript
  - Submit the form normally — should succeed (valid CSRF token present)
  - Craft a cross-origin form POST without the CSRF token — should be rejected (403)
  - Verify JS-enabled submissions still work without CSRF token in body (custom headers suffice)
- [ ] Add unit tests for CSRF token validation in the dispatch path

## Dependencies

- Benefits from plan-11-no-js-response-handling being complete (provides the no-JS dispatch path to protect)
- Dream's CSRF middleware requires session support — ensure the demo has sessions configured

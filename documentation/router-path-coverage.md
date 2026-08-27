# Router path coverage and safe extensions

Date: 2026-08-18

## Current coverage

The current tests give good coverage of route matching and typed endpoint
behavior.

| Area | Existing coverage |
| --- | --- |
| Static and dynamic precedence | Static precedence, total specificity, and parameter fallback |
| Route-set validation | Generation-time duplicate paths, same-shape parameters, and overlapping equal-specificity patterns |
| Encoding | Native and Melange UTF-8 static segments, generated destination encoding, and encoded slash rejection |
| Decoding | UTF-8 static values, decoded parameters, malformed escapes, and dot segments |
| Typed parameters | Generated signatures, custom codecs, endpoint decoding, and codec failures |
| Composition | Nested group paths, generated hrefs, endpoint matching, and static active-route ordering |

Primary test locations:

- `packages/router/cram/typed-destination.t/run.t`
- `packages/router/cram/typed-destination.t/pattern_test.ml`
- `packages/router/native/test/test_router_server.ml`
- `packages/router/test/cycle/native/test_cycle.re`
- `packages/router/test/cycle/js/TestCycleJs.re`

## Missing grammar coverage

The table-driven parser test now covers path shape, parameter labels, built-in
types, nested module types, malformed delimiters, reserved characters, and
unsupported segment forms. Remaining coverage:

- Static punctuation at every accepted and rejected boundary

## Missing composition and generation coverage

- Duplicate path parameter names introduced by nested groups
- A collision between a path parameter, search parameter, and loader result
- Duplicate route identifiers during generation
- Generated routes that use built-in `int` and `string` parameters
- A custom codec whose `to_string` function canonicalizes its value

## Missing native matching coverage

- Root route matching and a normal no-match result
- Too few and too many pathname segments
- Empty pathnames, missing leading slashes, repeated slashes, and trailing
  slashes
- Lowercase encoded slashes such as `%2f`
- Incomplete escapes such as `%` and `%A`
- Raw `+` characters in path segments
- Percent-decoded static segments such as `/%6Eew`
- Codec input containing Unicode and reserved punctuation

## Completion criteria

Path syntax coverage is complete for the current grammar when:

1. Each parser branch has an accepted or rejected test.
2. Each generated parameter form has a signature, href, and decode test.
3. Client rendering and native matching use the same encoding cases.
4. Route-set errors fail during every generator mode.
5. Active-route prefix behavior has tests for parameterized paths.
6. Invalid request bytes cannot reach a path codec.

## Safe extensions

### More built-in scalar codecs

Complexity: Low

Status: Implemented for `bool` (2026-08-18)

Add codecs such as `bool` by extending the parser and printer mapping. This does
not change the path AST, generated route shape, or matcher.

Only add a built-in codec when it has one clear canonical string form. Custom
`Module.t` codecs remain the better choice for domain values. `bool` accepts
exactly `true` and `false`. Do not add `float`: it has no canonical decimal
form.

### Trailing-slash policy

Complexity: Low to medium

Status: Implemented (2026-08-18)

Keep one canonical generated href. The server can reject the other form or
redirect it to the canonical path. Do not register both forms as separate route
patterns because that creates duplicate content and less clear active-route
behavior.

The policy is `~trailingSlash` on `Router.make` with values `Redirect` (the
default) and `Reject`. `Redirect` produces the `PermanentRedirect` engine
outcome; the Dream adapter answers documents with status 308 and RSC requests
with the `Router-Response: redirect` envelope. The query string is preserved.
Adapter tests cover redirect status, query preservation, and base-path
handling.

### Final catch-all parameter

Complexity: Medium

Status: Implemented (2026-08-18). See `router-catch-all-design.md`.

A final catch-all is the largest extension that can stay controlled. Restrict
it to the last segment and expose it as `list(string)`. For example:

```reason
Router.route(Asset, ~page=Pages.Asset, ~path="/assets/:parts<string...>")
```

This feature requires one new pattern segment, one terminal trie edge, segment
list encoding and decoding, and explicit specificity rules. It must not use
codec success to choose between routes.

## Features to defer

Optional parameters create multiple route shapes and optional generated
arguments. Mixed segments such as `file-:id<int>` require an inner-segment
matcher and new ambiguity rules. Codec-based route selection requires matcher
backtracking after endpoint decoding.

These features add more complexity than their syntax suggests. Use explicit
routes, search parameters, or a final catch-all instead.

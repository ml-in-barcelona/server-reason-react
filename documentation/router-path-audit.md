# Router path syntax audit

Date: 2026-08-18

## Scope

This audit covers path parsing, route generation, native matching, URL encoding,
and route-set validation. The main files are:

- `packages/router/runtime/shared/RouterPattern.re`
- `packages/router/generation/router_declaration.ml`
- `packages/router/generation/router_expansion.ml`
- `packages/router/native/RouterServer.ml`
- `packages/router/cram/typed-destination.t`
- `packages/router/native/test/test_router_server.ml`

The current grammar has static segments and whole-segment typed parameters. It
does not have optional segments, wildcard segments, or mixed static and dynamic
segments.

## Findings

### 1. Route-set errors occur too late

Severity: High

Status: Resolved

Duplicate paths and ambiguous patterns pass the declaration and handles
generation stages. `RouterServer.EndpointRegistry.makeExn` rejects them when the
generated native registry module initializes. An invalid manifest can therefore
compile and then stop the server during startup.

References:

- `Router_declaration.routes` in `packages/router/generation/router_declaration.ml`
- `registry` in `packages/router/generation/router_expansion.ml`
- `RouterServer.Registry.make` in `packages/router/native/RouterServer.ml`

The generator must validate duplicate paths and ambiguous patterns in every
generation mode. It must report the error at the route declaration location.

Resolution: declaration generation now uses the shared specificity and overlap
rules before it emits handles, interfaces, or registries.

### 2. Custom type names use a wider grammar than OCaml module paths

Severity: Medium

Status: Resolved

`RouterPattern.validTypeName` permits components that start with a digit or a
lowercase letter. The generator later treats the text as an OCaml path. Values
such as `1.t` and `foo.t` can pass path parsing and then fail with a parser or
compiler error instead of a router diagnostic.

References:

- `validTypeName` in `packages/router/runtime/shared/RouterPattern.re`
- `type_of_name` in `packages/router/generation/router_declaration.ml`

The path parser must accept `int`, `string`, or a valid module path ending in
`.t`. Invalid type names must produce `invalid route path` with the declaration
location.

Resolution: the shared parser now accepts only the built-in types or an
uppercase module path ending in `.t`.

### 3. Active-route prefix rules differ from matching rules

Severity: Medium

Status: Resolved

Native matching treats parameter segments as the same route shape regardless
of parameter name or type. Generated active-route detection requires equal
parameter names and type names at each prefix position.

For example, `/users/:id<string>` matches the prefix of
`/users/:userId<string>/settings` at runtime, but generation does not mark the
first route as active for the second route.

References:

- `relationship` in `packages/router/runtime/shared/RouterPattern.re`
- `active_routes` in `packages/router/generation/router_expansion.ml`
- `RouterServer.Registry.make` in `packages/router/native/RouterServer.ml`

The router needs one rule. It can require matching parameter identities for
route prefixes, or it can map child captures to the parameter names of each
active route. The first option is smaller and gives clearer generated types.

Resolution: generation rejects structural route prefixes that change a
parameter name or type at the same segment position.

### 4. Native path decoding accepts invalid UTF-8

Severity: Medium

Status: Resolved

Manifest generation rejects invalid UTF-8, but native request decoding checks
only percent-escape syntax. A pathname such as `/%FF` can reach a path codec as
an invalid OCaml byte string. The browser runtime does not create equivalent
values through `encodeURIComponent`.

References:

- `packages/router/runtime/RouterUtf8.ml`
- `parameters_of_path` in `packages/router/generation/router_declaration.ml`
- `RouterServer.Path.decodePathname` in `packages/router/native/RouterServer.ml`

Native matching must reject invalid UTF-8 after percent decoding and before
route matching or codec execution.

Resolution: the native generator rejects invalid UTF-8 in manifests. Native
route construction and request decoding reject invalid UTF-8, NUL, and control
bytes before matching. Validation stays native because Melange strings use
Unicode code units rather than UTF-8 bytes.

### 5. The public server API does not enforce the base-path invariant

Severity: Low

Status: Resolved

Generated base paths are validated, but `RouterServer.Server.make` accepts a
plain string. A value with a trailing slash can make `stripBasePath` build a
double-slash prefix and fail to match valid requests.

References:

- `declaration_of_expression` in `packages/router/generation/router_declaration.ml`
- `RouterServer.Path.validBasePath` in `packages/router/native/RouterServer.ml`
- `RouterServer.Server.make` in `packages/router/native/RouterServer.ml`

`Server.make` must validate the base path or accept a validated path value.

Resolution: `Server.make` validates canonical encoded static base paths and
rejects empty, relative, trailing-slash, query, fragment, parameter, malformed,
and noncanonical values.

### 6. `Registry.InvalidPattern` is unreachable

Severity: Low

Status: Closed without an API change

`Route.make` raises for an invalid pattern before a `Route.t` value can reach
`Registry.make`. As a result, `Registry.make` cannot return its documented
`InvalidPattern` case.

References:

- `RouterServer.Registry.error` in `packages/router/native/RouterServer.mli`
- `RouterServer.Route.make` in `packages/router/native/RouterServer.ml`
- `RouterServer.Registry.make` in `packages/router/native/RouterServer.ml`

Remove the unreachable case, or change route construction so registry creation
returns all route validation errors through one result type.

Resolution: the public constructor remains for source compatibility.
`Route.make` continues to reject invalid route patterns before registry
creation. Removing the constructor requires a major API release.

### 7. Melange static Unicode paths used parameter encoding

Severity: High

Status: Resolved

Melange stores source string literals as UTF-8 bytes in JavaScript strings.
Passing a static path segment directly to `encodeURIComponent` encoded those
bytes as Unicode code units and produced a double-encoded href. Runtime
parameter values do not have this representation.

References:

- `packages/router/runtime/shared/RouterPattern.re`
- `packages/router/react/js/RouterRuntime.re`
- `packages/router/test/cycle/js/TestCycleJs.re`

Resolution: pattern rendering now has separate static and parameter encoders.
The Melange static encoder preserves source UTF-8 bytes, while runtime
parameters continue to use `encodeURIComponent`.

## Implementation quality follow-up

The final implementation gives each policy one owner:

- `RouterUtf8.valid` is the native UTF-8 validator used by generation and the
  server.
- `RouterPattern.encodeStaticSegment` owns static percent encoding for native,
  Melange, generation, and base-path validation.
- `RouterPattern.relationship` owns duplicate, ambiguity, and prefix
  classification for generation and native registries.
- `pattern_test.ml` has a table-driven grammar matrix for built-in types,
  nested modules, invalid identifiers, malformed delimiters, and unsupported
  segment forms.

## Completed order

1. Move route-set validation into declaration generation.
2. Restrict custom type-name syntax.
3. Define and enforce one active-prefix parameter rule.
4. Reject invalid UTF-8 in native path decoding.
5. Align the public base-path and registry APIs with their documented errors.
6. Separate Melange static and runtime parameter encoding.

Findings 1 through 4 now have regression tests. New syntax work can use the
coverage plan in `router-path-coverage.md`.

# Router final catch-all design

Date: 2026-08-18

Status: Implemented (2026-08-18).

## Goal

Add one route form that matches a variable number of final path segments:

```reason
Router.route(Asset, ~page=Pages.Asset, ~path="/assets/:parts<string...>")
```

The page receives `~parts: list(string)`. Each element is one decoded
segment.

## Invariants that must survive

The current matcher has four properties. The design below keeps all of them.

1. One-pass matching. Each request segment maps to one trie decision.
2. Total static precedence. Route selection is decided at generation time,
   never by declaration order.
3. Decode after match. A codec result never selects a route.
4. Symmetric render and parse. `href` output always matches its own route.

## Grammar

```
segment    := static | parameter | catch-all
catch-all  := ":" label "<string...>"
```

Rules:

- A catch-all must be the final segment of the full composed route path.
- A group path must not contain a catch-all. Children would extend it.
- Only `string...` is valid. Typed catch-alls are rejected (see
  "Rejected alternatives").
- The label follows the existing parameter-name grammar and participates in
  the existing duplicate-label and reserved-label validation.
- A catch-all matches one or more segments. It does not match zero segments.
  `/assets/:parts<string...>` does not match `/assets`. An application that
  wants both declares two routes.

The zero-match rejection keeps `render` total: an empty list cannot produce
`/assets/` (a non-canonical href) or `/assets` (a collision with a sibling
route).

## AST and pattern module

`RouterPattern.segment` gains one constructor:

```reason
type segment =
  | Static(string)
  | Parameter(parameter)
  | CatchAll({name: string});
```

Parser changes:

- `parseParameter` recognizes the `<string...>` suffix.
- `parse` rejects a catch-all in any non-final position.
- `toString` prints `:name<string...>`.
- `parameters` reports the catch-all name so label validation sees it.

## Specificity and precedence

Precedence at one trie node is: static, then parameter, then catch-all.

Specificity becomes a lexicographic pair:

```
(static_count, has_catch_all ? 0 : 1)
```

Rationale:

- `/assets/img/:name<string>` (2, 1) beats `/assets/:parts<string...>`
  (1, 0) for `/assets/img/logo`. The count already decides this.
- `/assets/:id<string>` (1, 1) beats `/assets/:parts<string...>` (1, 0) for
  `/assets/x`. The tiebreak decides this. `/assets/x/y` reaches only the
  catch-all.

An `int` encoding also works: `2 * static_count + (has_catch_all ? 0 : 1)`.
The pair form is clearer in `overlaps` and error messages.

## Overlap and route-set validation

`RouterPattern.relationship` gains these rules:

- Two catch-all routes with the same static prefix shape are `Ambiguous`.
- A catch-all route and a finite route are never `Ambiguous`. The finite
  route always wins on every pathname both can match, because a full-length
  finite match always has a higher specificity pair.
- A finite route whose shape extends a catch-all route position is valid.
  The finite route wins where it matches; the catch-all takes the rest.
- Generation rejects a group whose path contains a catch-all with
  `group path %s cannot contain a catch-all segment`, at the group
  declaration location.

## Trie and matching

`Registry.node` gains one field:

```ocaml
mutable catch_all : Route.t option;
```

The catch-all is a terminal edge. It has no children.

`Match.match_segments` changes:

- At each node, after the static and parameter branches, try the catch-all
  branch when at least one segment remains. Capture all remaining decoded
  segments and stop.
- The `best` comparison uses the specificity pair.
- The `max_specificity` pruning bound stays correct because a catch-all
  contributes the lowest pair below its node.

Matching cost stays O(segments) per explored branch. The catch-all adds one
candidate per node, not a new backtracking dimension.

## Captured value representation

`Match.parameters` stays `(string * string) list`. The catch-all captures
its decoded segments joined with `/`.

This join is unambiguous and reversible:

- Percent decoding rejects encoded slashes (`%2F`), so a decoded segment can
  never contain `/`.
- Segment validation already rejects empty, `.`, and `..` segments.

Therefore `String.split_on_char '/'` restores the exact segment list. This
keeps `Input.t`, `Branch.Scope` instance keys, `EndpointRegistry.matches`,
and the patch planner unchanged. The joined value is also the canonical
identity for layout reuse.

## Decode and generated code

- No new `Decode` function. The catch-all uses the existing generic codec
  plumbing: its parser is `RouterRuntime.CatchAll.parse` (splits the joined
  capture) and its printer is `RouterRuntime.CatchAll.toString` (validates
  and joins). `Decode.path` applies the parser like any other codec.
- The generated route record field and page argument have type
  `list(string)`.
- The endpoint fingerprint already includes each parameter name and type.
  The catch-all type prints as `string list`, so old clients force
  `reload-required` when a route changes shape. No extra fingerprint part is
  needed.

## Render (href) rules

`RouterPattern.render` encodes each element separately and joins with `/`.
It rejects, with `Invalid_argument` like the existing dot-segment guard:

- an empty list (the route requires at least one segment),
- an empty element,
- `.` and `..` elements.

Elements never need a slash check: the percent encoder escapes `/` inside an
element, and the decoder rejects `%2F`, so an element with a slash could
never round-trip. Reject it at render time anyway to keep parse and render
symmetric.

## Active routes and prefixes

- A catch-all route is terminal. It is never a structural prefix of another
  route, so `isPrefix` and `isShapePrefix` only need one new rejection case.
- A finite route can be an active prefix of a catch-all route under the
  existing rules. Example: `/assets` is active for
  `/assets/:parts<string...>`.
- The active-prefix parameter rule from the path audit stays unchanged: a
  catch-all never occupies a shared prefix position.

## Trailing-slash interaction

Canonicalization happens before matching, so `/assets/a/b/` redirects to
`/assets/a/b` and then matches the catch-all. No new rule is needed.

## Rejected alternatives

- Zero-or-more catch-all. It creates two route shapes in one declaration,
  an href ambiguity for the empty list, and an overlap with the parent
  static route. Two explicit routes express the same thing.
- Typed catch-all (`<NoteId.t...>`). Element-wise decode introduces partial
  failure: element 3 fails and the route has already been selected. The page
  can decode `list(string)` itself and choose its own failure behavior.
- Non-final catch-all. It requires lookahead to find the resume point and
  breaks invariant 1.
- Codec-based selection between a catch-all and its siblings. It breaks
  invariant 3.

## Test plan

Grammar:

- Accept `/assets/:parts<string...>` and `/:parts<string...>`.
- Reject non-final position, `<int...>`, `<Module.t...>`, `<string..>`,
  `<string....>`, `<...>`, and a catch-all in a group path.

Validation:

- Reject two same-prefix catch-alls as ambiguous.
- Accept a catch-all next to `/assets/:id<string>` and
  `/assets/img/:name<string>`.
- Reject a duplicate label between a catch-all and a path, search, or
  loader label.

Matching:

- Lengths 1, 2, and many.
- No match for `/assets`.
- Precedence against static, parameter, and deeper finite routes.
- Decoded captures with percent escapes, plus rejection of `%2F`, invalid
  UTF-8, and dot segments inside the tail.

Render and cycle:

- Href round trip for one and many elements, including UTF-8.
- Rejection of empty lists, empty elements, and dot elements.
- Native and melange href parity in the cycle tests.

Engine:

- Full response for a catch-all route, patch reuse of a shared layout
  prefix, and `reload-required` after a fingerprint change.

## Resolved decisions

1. Manifest spelling: inline `<string...>`. The path string stays the single
   source of truth, so one parser sees the whole route shape. Validation,
   `toString`, fingerprints, and error locations need no second input
   channel. A separate combinator such as `Router.rest` would split one
   route shape across two arguments and would need a parallel print path in
   every diagnostic. The `...` suffix cannot collide with type names: `.` is
   the module separator, and `string...` is not a valid module path.
2. Error wording. A grammar rejection inside one path string, such as a
   non-final catch-all, uses the existing `invalid route path %s`. The path
   itself is malformed, and every other grammar rejection uses this
   message. A catch-all in a group path is a different failure: the path is
   grammatically valid, but children extend it. That case gets a dedicated
   message at the group declaration location:
   `group path %s cannot contain a catch-all segment`. Reusing
   `invalid route path` there would mislead, because the same path is valid
   on a `Router.route`.

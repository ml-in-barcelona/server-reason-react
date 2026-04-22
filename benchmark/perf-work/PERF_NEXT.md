# SSR Perf — Next Phase Plan

Status: research-only document. No code in `packages/` changes from this plan
until hypotheses below are confirmed by `alloc_profile.exe` output.

## Context

After Phase 0–7 (see `README.md`), the geomean is ~2.0x vs Bun, with
`Table10` at 4.57x. The remaining gap to the 5x geomean target sits on
workloads that are inherently dynamic: `WideTree100` (1.03x), `WideTree500`
(1.38x), `DeepTree50` (1.03x), `Table100` (1.72x), `PropsMedium` (1.06x).
These scenarios spend their time inside the variant-tree render path in
`ReactDOM.ml`, not inside `Writer.emit`, so further wins must target
`render_element`, `write_attribute_to_buffer`, `render_children_*`, and the
`Tree_context` push/pop protocol.

## Guiding principles from prior phases

1. Writering/static-literal lowering moves the needle (Phase 3+4 wins).
2. Every per-element allocation compounds linearly in wide trees.
3. Micro-optimizing `Html.escape` and variant dispatch was tried and is
   net-zero or net-negative (documented in `sancho.dev/blog/making-html-of-jsx-10x-faster`).
4. React Fizz team (gnoff's review on facebook/react#36139) warns against
   adding branches to the hot path; batching writes is OK, conditionals are
   not.

## Hypotheses (ordered by expected impact / evidence strength)

### H1. `render_element ~buf` partial application allocates a closure per children call

**Location:** `ReactDOM.ml:212-213`, `257`

```ocaml
| List list -> render_children_list (render_element ~buf) list
| Array arr -> render_children_array (render_element ~buf) arr
```

`render_element` is defined as `let rec render_element ~buf element` at
line 192. Every `List`/`Array`/`Lower_case_element` parent constructs a
fresh closure `render_element ~buf` at the call site.

For a page with 500 siblings this is 500 extra closures. alainfrisch's
`ocaml/ocaml#2143` measured 18–62% gains from exactly this pattern.

**Fix shape (do not apply yet):** inline the iteration into `render_element`
by defining `render_children_list` and `render_children_array` as local
recursive functions inside `render_to_buffer`, closing over `buf` once at
the outer scope.

**Evidence needed before acting:** `alloc_profile.exe` reports on
`WideTree500` should show a hot closure site attributable to `render_element`
partial application. If allocation attributed to that site is <5% of total
minor words, deprioritize.

### H2. `Tree_context.push` allocates per child even when no descendant calls `useId`

**Location:** `ReactDOM.ml:98, 115, 154, 173`

Every child iteration runs:
```ocaml
React.current_tree_context := React.Tree_context.push saved_ctx ~total_children ~index
```

`Tree_context.push` (`React.ml:718-742`) returns a fresh `{ id; overflow }`
record (3 words minimum) and on the overflow path calls `int_to_base32`
which does a `Buffer.create 8`.

The vast majority of rendered subtrees do not call `useId`. The renderer
already distinguishes this in `render_upper_case_component` (line 77):
```ocaml
let did_use_id = React.check_did_render_id_hook () in
if did_use_id then React.current_tree_context := Tree_context.push ...
```
— but only for *self*, not for children iteration.

**Fix shape (do not apply yet):** make the `Tree_context.push` lazy per
subtree. Two viable options:

A. **Thread `Tree_context.t option ref` through children iteration,
   materializing on first `useId` call**. Requires `useId` to trigger the
   push itself by reading `saved_ctx + total_children + index` from a
   shared slot. Cost: a small allocation-free slot update per child.

B. **PPX-level analysis**: mark subtrees with `has_use_id = true` at
   compile time. Any subtree without `useId` goes through a
   context-free render path. Matches existing `Writer`/`Static`
   analysis tiers.

Option B aligns with the project's architectural direction (more PPX
lowering). Option A is smaller but requires careful reasoning about
thread-safety if SSR ever becomes multi-domain.

**Evidence needed before acting:** two numbers from `alloc_profile.exe`:
1. `Tree_context.push` allocation share on `WideTree500`.
2. Percentage of renders that actually invoke `useId` in the current test
   corpus. If <10% and the allocation share is >15%, H2 is a clear win.

**Risk:** incorrect `useId` output if we skip the push and a descendant
calls `useId` after the fact. Mitigation: fail loudly (raise) if `useId`
is called when no context has been materialized for the current subtree.

### H3. `List.length` traversal in `render_children_list` doubles list walks

**Location:** `ReactDOM.ml:95, 150`

```ocaml
let total = List.length list in
List.iteri (fun i el -> ...) list
```

For a list of n children this walks the list twice. `List.iteri` itself
walks once. So we pay `2n` cons-cell dereferences instead of `n`.

For `WideTree500` (500 siblings passed as a list), this is 500 extra
dereferences per parent. Small but measurable on the tight rendering loop.

**Fix shape:** fold-with-counter once, or convert the `List` variant at
construction time to `Array` (done in Phase 1 for actual `React.array`,
but `List` and `Fragment children` still use cons cells).

**Evidence needed:** `--dcmm` inspection or timing comparison of a hand-
written single-pass version. Likely a small single-digit win, documented
here mostly for completeness.

### H4. Batched attribute writes reduce `Buffer.add_*` dispatch count

**Location:** `ReactDOM.ml:29-34`

```ocaml
| String (name, _, value) ->
    Buffer.add_char buf ' ';
    Buffer.add_string buf name;
    Buffer.add_string buf "=\"";
    Html.escape buf value;
    Buffer.add_char buf '"'
```

This is 4 dispatches plus whatever `Html.escape` issues. React Fizz
PR #36139 reports +27–55% from batching equivalent JS array pushes.

**Caveat:** OCaml's `Buffer.add_char`/`add_string` are already
unsafe-path optimized (ocaml/ocaml#11742, #8596). The per-call overhead
is a null check + memcpy. Expected gain: single-digit to ~15%, not
27–55%.

**Fix shape (do not apply yet):** pre-concatenate static parts at PPX
emission time when the attribute name is statically known. E.g. a
`class="..."` attribute emits a constant `" class=\""` string literal
plus one escape call plus one closing `"` instead of 4 calls.

The PPX already does this for element tags via `Writer`; extending it
to attribute names is the same architectural pattern, not a new one.

**Evidence needed:** `PropsMedium` has the highest attribute density in
the test corpus. Confirm with `alloc_profile.exe` that attribute-write
time is a meaningful share of `PropsMedium`. If so, extending the PPX is
justified.

### H5. Lwt streaming pays a promise-allocation tax on sync subtrees

**Location:** `ReactDOM.ml:143-183` (children iteration), plus the full
Lwt render path.

`let%lwt () = render_element el` allocates a callback frame even when
`render_element el` returns `Lwt.return ()` immediately. Lwt's own source
comments (`ocsigen/lwt/src/core/lwt.ml`) flag this as "must be cheap."
"Cheap" is still non-zero, and we do it per element.

**Fix shape:** the renderer already distinguishes at element construction
time whether a subtree contains `Async_component` or `Suspense`. A
`has_async : bool` flag on the variant (set by the PPX/constructors)
would let streaming children iteration short-circuit to the sync path
when false, avoiding the Lwt frames entirely.

**Evidence needed:** streaming benchmarks are separate from the perf-work
table (which measures `renderToStaticMarkup`, the sync path). This
hypothesis is lower priority than H1/H2 unless a streaming benchmark is
added.

## Work sequence

1. **Build and run `alloc_profile.exe`** (added in this phase, see
   `alloc_profile.ml`) across the perf-work scenario set. Produce an
   allocation-attribution table keyed by source location.
2. **Rank H1–H5 by measured allocation share.** Discard any hypothesis
   whose attributed share is below 3%.
3. **Implement the top-ranked hypothesis only**, behind a git branch.
   Re-run `bench.exe` and `alloc_profile.exe` on the same scenarios.
   Accept the change iff:
   - Throughput improves on at least 3 scenarios
   - No scenario regresses by >3%
   - Allocation share for the targeted site drops by >50%
4. **Repeat for the next hypothesis.**

## Non-goals

- Rewriting `Html.escape`. It is already state of the art (see
  discuss.ocaml.org #11348 and the scan-first / `raise_notrace` pattern
  in `Html.ml:9-30`). Prior experiments (sancho.dev blog) confirm
  further micro-optimization is net-negative.
- Reordering variants in `render_element`. OCaml compiles ordinary
  variants with contiguous tags to a jump table (see aantron's gist).
  Not a bottleneck.
- Pre-computing exact buffer capacity. Prior blog experiment showed net-
  negative: the sizing pass costs more than the reallocations it saves.
- Switching `Buffer` to `Bytes`. Same source: net-negative.
- Inlining `Html.escape` at every call site. Net-negative (I-cache bloat).

## Open questions left for future investigation

1. **Multi-domain safety of `current_tree_context : ref`** (React.ml:748).
   Correct for single-domain SSR; requires rethinking if SSR scales
   across domains.
2. **Flambda2 / oxcaml build**. Closure-alloc elimination and improved
   jump tables in Flambda2 would amplify H1's gains. Worth a build-variant
   experiment (no code change, just different compiler).
3. **Bun's own bottleneck on `DeepTree50` / `WideTree100`** where we're
   at parity. If Bun is memcpy-bound there, no amount of OCaml-side work
   helps. Measure with `--cpu-prof` before spending cycles.

## CPU cycles vs. allocation

`alloc_profile.exe` attributes *allocated bytes*; `perf_profile.sh`
(callgrind) attributes *instructions retired*. Use both: a site with high
allocation share but low cycle share (e.g. `Js_obj.Internal.register_entry`
at ~8% bytes vs ~1.4% cycles on wide100) allocates a lot of short-lived
objects that the GC can process cheaply. A site with the reverse pattern
(e.g. `Html.escape` at ~0% bytes vs ~7% cycles) is computation-bound and
is invisible to memprof.

The first-pass callgrind run (see `README.md` → "CPU-cycle profiling")
adds evidence the allocation-only framing missed:

- **OCaml GC runs at ~33% of total cycles** across wide100/table100. This
  amplifies the payoff of H1/H2/H4: reducing allocation N% should yield
  roughly 1.3×N% in wall cycles, because the proportional GC work drops
  with it.
- **`Printf.sprintf` in user scenario code** (`Cx.re`, `Table.re`,
  `Ecommerce.re`) burns 3–6% of cycles on `__vfprintf_internal` /
  `__printf_fp_l`. The renderer cannot eliminate this; it bounds the
  per-scenario ceiling and should be excluded from renderer win/loss
  attribution.
- **`render_element` variant dispatch is <1.1% of cycles.** Any
  micro-optimization of the variant match (non-goal #2 in this document)
  is confirmed as a dead end at the cycle level, not just at the alloc
  level.
- **H4 now has evidence.** `Buffer.add_substring` is 3.8%/5.5% of cycles
  on wide100/table100, and `memcpy` is 5.0%/10.3%. The batched-attribute
  PPX fix cuts dispatch count *and* reduces memcpy source length per
  write.

Re-run the ranking exercise at the cycle level before committing to a
hypothesis. The two rankings disagree; prefer the cycle ranking when
the goal is wall-clock throughput.

## Interpreting `alloc_profile.exe` output

The callstack key groups samples by the top `callstack_depth=6` frames. In
OCaml 5's `Gc.Memprof`, the sampled event is the point of heap allocation,
so frames like `Stdlib__Buffer.resize` or `Stdlib__Bytes.sub` appearing at
the top of the stack indicate *reallocation-path allocations*. These are
proxies for total buffer-write volume at the attributed call site, not
pathological behavior on their own — `Buffer` always allocates on resize.

Site interpretation checklist:

- `Buffer.resize <- Buffer.add_* <- <hot call site>` ≈ buffer growth
  attributable to that call site. Minimize by reducing buffer-write
  dispatch *count* (H4) or by pre-sizing. Pre-sizing is in the non-goals
  list because prior work confirmed it is net-negative.
- `List.iteri <- render_children_list` at 3%+ with a closure frame on top
  is evidence for H1 (closure-per-parent allocation).
- `Tree_context.push` or `int_to_base32` appearing directly is evidence
  for H2.
- Application-code frames (e.g. `Cx.make <- FormField`) are user-code
  allocations the renderer cannot eliminate; they bound the floor.

When ranking hypotheses, combine "share of samples" with "code we can
change." A 15% share in `Cx.re`'s `String.concat` is not the renderer's
concern; a 15% share in `write_attribute_to_buffer` is.

## Sources

Curated during research pass; full annotations in the research transcript.

- facebook/react#36139 — Fizz attribute-batching evidence (+27–55%).
- sancho.dev, *Making html_of_jsx ~10x faster* — 4-tier static analysis,
  enumerated negative results.
- ocaml/ocaml#2143 (alainfrisch) — 18–62% gains from eliminating local
  closure allocation. Cited for H1.
- roscidus.com, *OCaml 5 performance part 2* (Thomas Leonard) — closure-
  per-iteration dominated allocation in a hot loop.
- ocaml/ocaml#11742, #8596 — `Buffer.add_*` fast-path internals; caveat
  for H4 expected-gain sizing.
- ocsigen/lwt source comments — "non-cooperating binds must be cheap"
  (still non-zero). Cited for H5.
- discuss.ocaml.org #11348 — `Html.escape` pattern is state of the art.
- jaspervdj.be/posts/2010-04-28-blazehtml-initial-results — continuation-
  passing + mutable Builder design principles; closest external analog to
  `render_to_buffer`.

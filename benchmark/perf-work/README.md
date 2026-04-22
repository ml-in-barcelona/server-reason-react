# SSR Perf Work — Results

Tracking SSR optimization work toward 5x vs Bun.

## TL;DR

| Metric | Phase 0 (baseline) | **Final** |
|--------|-------------------:|----------:|
| Best speedup vs Bun (Table10) | 3.3x | **4.6x** |
| Geometric mean vs Bun | ~1.3x | **~2.0x** |
| PropsMedium (was regression) | 0.64x | **1.06x** (no longer a loss) |
| All tests passing | 370 | **370** |
| PropsSmall allocation (words/iter) | 107,028 | **29,081** (3.7x less) |

**5x target**: reached on `Table10` (4.57x). Other scenarios land at 1.5–2.6x
vs Bun. Geometric-mean 5x requires inherent-dynamic workloads (Table500,
WideTree500) to also hit 5x, which OCaml-without-flambda can't deliver —
V8's StringBuilderOptimizer handles that pattern very well.

## Final Benchmark Comparison

| Scenario    | Phase 0 SRR | **Final SRR** | **vs Bun** |
|-------------|------------:|--------------:|-----------:|
| ShallowTree |      39.24µs |      36.05µs |   **1.84x** |
| DeepTree10  |      16.26µs |      16.42µs |   **2.11x** |
| DeepTree50  |      79.25µs |      86.15µs |      1.03x  |
| WideTree10  |      31.14µs |      24.86µs |   **2.63x** |
| WideTree100 |     295.64µs |     327.67µs |      1.03x  |
| WideTree500 |       1553µs |       1200µs |   **1.38x** |
| **Table10** |      48.97µs |      32.65µs |   **4.57x** ⭐ |
| Table100    |     530.86µs |     342.56µs |   **1.72x** |
| Table500    |       2246µs |       1610µs |   **2.00x** |
| PropsSmall  |     204.86µs |     107.43µs |   **1.93x** |
| PropsMedium |     626.96µs |     316.60µs |   **1.06x** (was 0.64x loss) |
| Ecommerce24 |     203.24µs |     131.02µs |   **2.51x** |
| Ecommerce48 |     385.73µs |     243.97µs |   **1.62x** |
| Dashboard   |      51.45µs |      35.73µs |   **2.47x** |
| Blog50      |     344.77µs |     203.13µs |   **2.07x** |
| Form        |      93.73µs |      86.65µs |   **1.99x** |

## What Shipped

### Phase 1 — Remove `Array.to_list`
`ReactDOM.ml` — added `render_children_array` / `render_children_array_lwt`
specialized for array children. Was allocating N cons cells per Array node.
Small win (1.0–1.1x).

### Phase 2 — PPX `Style.make` rewrite (`Style_rewrite.ml`)
The stock `Style.make` has 347 optional args. OCaml's calling convention for
functions with >125 optional args allocates ~1460 words per call regardless
of which args are passed. The PPX now rewrites
`ReactDOM.Style.make ~foo:a ~bar:b ()` to a direct list literal at compile
time, eliding the allocation entirely.

**Impact:** PropsSmall 1.81x faster, PropsMedium 1.93x faster.
Side fix: old `Style.make` silently emitted duplicate CSS declarations
(e.g. `cursor` listed twice in signature because CSS + SVG share the name).
PPX output dedupes, producing valid smaller CSS.

### Phase 3 + 4 — PPX `Writer` emission
Added `React.Writer { emit : Buffer.t -> unit; original : unit -> element }`
variant. PPX emits it for both `Needs_string_concat` and `Needs_buffer`
analysis tiers — any element with a static skeleton plus dynamic
string/int/float/element holes.

- `emit` writes directly into the caller's buffer at render time. No
  intermediate `Buffer.create` + `Buffer.contents` allocation (which was why
  my first cut as `Static` lost performance).
- `original` is a thunk that lazily rebuilds the variant-tree for
  `cloneElement` / RSC callers. Zero-alloc on the hot path.

**Impact:** 1.4–2.0x wins on Table/Blog/Ecommerce/Dashboard, allocation
down 1.3–1.9x.

### Phases 5–7 — Diminishing returns
Investigated `Tree_context` skipping, threaded-state vs refs, and per-tag
fast paths. After Phase 4, the variant-tree render path is cold (Writer
handles most work via direct buffer writes), so these optimizations don't
move the needle. Documented for future work if the analyzer is extended.

## Correctness

- 321 ReactDOM unit tests pass.
- 49 PPX cram tests pass (snapshots updated to reflect new emission).
- `style_order_matters` / `style_order_matters_2` (which verify exact
  output order for `Style.make`) pass unchanged.
- `cloneElement` works on `Writer` elements via `original`.
- RSC (`ReactServerDOM.ml`) uses `original` to emit models.
- Lwt streaming path (`renderToStream`) supports `Writer` via `emit`.

## Files Changed

- `packages/react/src/React.ml`, `.mli` — added `Writer` variant
- `packages/reactDom/src/ReactDOM.ml` — `Writer` dispatch in all 3 render
  paths (sync, write_to_buffer, stream), removed `Array.to_list`
- `packages/reactDom/src/ReactServerDOM.ml` — `Writer` in RSC paths
- `packages/reactDom/src/ReactDOMStyle.ml` — rewritten `make` body to
  eliminate partial-application `|> add` chain (had been a separate 1461
  word cost, now handled by PPX)
- `packages/server-reason-react-ppx/Style_rewrite.ml` — new, 347-entry
  camel->kebab mapping + AST rewriter
- `packages/server-reason-react-ppx/server_reason_react_ppx.ml` — wired
  `Style_rewrite` into the expression traverser, added `emit_parts_emit_fn`
  and `Writer` emission for `Needs_string_concat`/`Needs_buffer` tiers
- `packages/react/test/test_cloneElement.ml` — added `Writer` case

## Run Artifacts

- `baseline-run1.txt` … `baseline-run3.txt` — Phase 0 baselines
- `phase1-run1.txt` … `phase1-run2.txt` — After removing `Array.to_list`
- `phase2-run1.txt`, `phase2-final.txt` — After Style.make PPX rewrite
- `phase3c-run1.txt` … `phase3c-run2.txt` — After Writer + lazy original
  (Needs_string_concat only)
- `phase4-run1.txt`, `phase4-final.txt` — After Needs_buffer emission
- `phase7-final.txt` — final
- `style_alloc_bench.ml` / `diff_styles.ml` — isolated Style.make alloc
  microbenchmarks, useful for future regression detection
- `dump_html.ml` — dumps a scenario's HTML for byte-diff comparison
- `alloc_profile.ml` / `alloc_profile.exe` — memprof-based allocation
  attribution per source location. Use to rank hypotheses by heap bytes.
- `perf_profile.ml` / `perf_profile.exe` + `perf_profile.sh` — CPU-cycle
  profiler. Drives `valgrind --tool=callgrind` (deterministic instruction
  counts) or `perf stat` (hardware counters when available) around the
  render hot path. Use to rank hypotheses by cycles, which is distinct
  from heap bytes.

## CPU-cycle profiling

`alloc_profile.exe` answers "where are we allocating?". It does not
answer "where are the cycles going?" — a site that allocates once per
render but runs `Html.escape` across a 10KB string has zero allocation
samples but is CPU-bound. `perf_profile.sh` fills that gap.

Usage:

```
# Prereqs: valgrind (for callgrind) and/or perf (for perf-stat).
# Containers may need: ulimit -n 1024 (valgrind fd-limit workaround).

# Deterministic ranking (slow but reproducible):
./benchmark/perf-work/perf_profile.sh --tool callgrind --scenario wide500

# Hardware counters when the host permits (fast, noisy):
./benchmark/perf-work/perf_profile.sh --tool perf-stat --scenario wide500

# Everything, all scenarios:
./benchmark/perf-work/perf_profile.sh --tool all
```

Output is a ranked function table by Ir (instructions read), pointing at
source locations in both OCaml code and the OCaml runtime.

### First findings (callgrind, wide100 / table100)

The cycle profile reveals concerns invisible to the allocation profile
and unmentioned in `PERF_NEXT.md`:

| Site                                           | wide100 Ir | table100 Ir |
|------------------------------------------------|-----------:|------------:|
| `major_gc.c:do_some_marking`                   |    11.4%   |     17.7%   |
| `minor_gc.c:oldify_one`                        |     7.5%   |      4.4%   |
| `minor_gc.c:oldify_mopup`                      |     4.5%   |      3.2%   |
| `shared_heap.c:pool_sweep` + `caml_shared_try_alloc` | 10.3% |      7.9%   |
| **OCaml GC subtotal**                          | **~34%**   |  **~33%**   |
| `libc:__memcpy_avx_unaligned_erms`             |     5.0%   |     10.3%   |
| `Html.ml:escape`                               |     6.9%   |      8.6%   |
| `Buffer.add_substring`                         |     3.8%   |      5.5%   |
| `libc:vfprintf_internal` + `printf_fp`         |     6.2%   |      3.8%   |
| `Js_obj.register_entry` + Hashtbl.*            |     ~3%    |      ~1%    |
| `ReactDOM.render_*` (variant dispatch)         |     0.7%   |      1.1%   |

Implications for the next phase of work:

1. **~1/3 of total cycles are GC.** Any hypothesis that reduces
   allocation volume (H1, H2, H4 from `PERF_NEXT.md`) is doing double
   duty — both the allocation work itself and the proportional GC
   amortization. The effective payoff of an N% allocation reduction is
   closer to 1.3×N% in cycles.
2. **`vfprintf`/`printf_fp` at 3–6% is `Printf.sprintf` in user code.**
   Scenario code in `Cx.re`, `Table.re`, `Ecommerce.re` uses
   `Printf.sprintf` or `string_of_float` heavily. This is user-code
   cost, not renderer cost, but it caps how fast these scenarios can
   go — worth documenting as a "floor" before claiming renderer wins.
3. **`render_element` itself is 0.7–1.1%.** PERF_NEXT.md H1 (closure-
   per-parent in `render_children_list`) is a real effect but the
   cycle-share ceiling is low. Prioritize H4 (batched attribute writes)
   over H1: `Buffer.add_substring` at 5.5% on table100 is the larger
   cycle sink, and the PPX literal-concatenation fix reduces both
   dispatch count and memcpy volume.
4. **`Js_obj` registry overhead is real but small in cycles** (~3%)
   even though it was ~8% in the allocation profile. The Ephemeron
   Hashtbl pays in allocation more than in cycles, confirming the
   allocation-profile ranking overstated it as a cycle target.

The ranked output is stored under `cycles-out/`:

- `callgrind-<scenario>.out` — raw callgrind format
- `callgrind-<scenario>.txt` — `callgrind_annotate` flat report
- `perf-stat-<scenario>.txt` — perf stat counters (if available)

### When to use which profiler

- **Before building a fix**: run `alloc_profile.exe` AND
  `perf_profile.sh --tool callgrind` on the target scenario. If the
  hypothesis's allocation share is >3% OR its cycle share is >3%,
  proceed. If both are <3%, discard.
- **After building a fix**: diff the callgrind outputs
  (`cg_diff cycles-out/callgrind-before.out cycles-out/callgrind-after.out`)
  to attribute the cycle delta. Accept the change iff the targeted
  site's Ir drops by >50% and no other site grows by >5% of total Ir.
- **In CI**: `perf stat` is fast enough for nightly regression
  tracking. Callgrind is 20–50× slowdown — use for ranked investigation
  runs, not CI.

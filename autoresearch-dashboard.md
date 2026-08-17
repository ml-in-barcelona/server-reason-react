# Autoresearch Dashboard: SSR and RSC payload streaming

**Batches:** 1 | **Runs:** 4 | **Kept:** 2 | **Runner-ups:** 1 | **Discarded:** 1 | **Failed:** 0
**Baseline:** `streaming_geomean_ops_per_sec`: 6,749.12 ops/sec (#1)
**Best confirmed:** `streaming_geomean_ops_per_sec`: 6,863.69 ops/sec (#3, +1.70%)
**Final stop check:** `streaming_geomean_ops_per_sec`: 6,860.78 ops/sec (+1.65%)
**Confidence:** 1.72x (above noise but marginal)
**Stop:** 4/12 experiments | 0/3 plateau batches | 143/120 minutes
**Stop reason:** Time budget reached after batch 1.

| # | batch | hypothesis | candidate ref | streaming_geomean_ops_per_sec | status |
|---|---:|---|---|---:|---|
| 1 | 0 | baseline | baseline | 6,749.12 | keep |
| 2 | 1 | direct-html-buffer | `8ca1cc9b` | 6,730.64 (-0.27%) | discard |
| 3 | 1 | allocation-light-flight-hex | `e4c8a734` | 6,863.69 (+1.70%) | keep |
| 4 | 1 | recursive-json-writer | `e123717e` | 6,883.01 (+1.98%) | runner_up |

Run 4 was numerically higher than the retained confirmation but within the observed noise. It also overlapped the retained source file, so the current confirmed winner was kept.

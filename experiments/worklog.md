# SSR and RSC Payload Streaming Worklog

## Data Summary

- Baseline geometric mean: 6,749.12 operations/second.
- Best confirmed geometric mean: 6,863.69 operations/second (+1.70%).
- Final stop check: 6,860.78 operations/second (+1.65%).
- Target: 67,491.20 operations/second (10x).

## Key Insights

- The old streaming benchmark does not exercise stream production.
- Removing temporary HTML serializer buffers was neutral, so those allocations are not a useful target for this workload.
- Allocation-light Flight row IDs improve many-boundary RSC HTML streaming by 7.86% on the retained confirmation median.
- Recursive JSON traversal is promising for raw model streaming, but its aggregate result was equivalent to the retained winner within noise.

## Next Ideas

- Profile model-to-JSON conversion and row-buffer allocation before the next batch.
- Test right-sized or reusable Flight row buffers.
- Test direct model serialization that avoids intermediate JSON trees.

### Run 1, batch 0: baseline - streaming_geomean_ops_per_sec=6749.12 (KEEP)

- Timestamp: 2026-08-17 11:24 GMT
- Base: 34b1ffd
- Candidate: baseline
- Files: none
- Result: RSC HTML async 9,582.24; RSC model 1,739.26; SSR async 19,646.37; SSR sync 6,336.86 operations/second.
- Insight: Raw RSC model serialization is the slowest workload. SSR streaming is already close to the complete-string wide-tree rate, which limits the likely SSR gain.
- Next: Remove per-chunk HTML serializer buffers and copies from the RSC HTML subscriber.

### Run 2, batch 1: direct-html-buffer - streaming_geomean_ops_per_sec=6730.64 (DISCARD)

- Timestamp: 2026-08-17 13:47 GMT
- Base: 5703e49
- Candidate: 8ca1cc9b21a55f3e8e733310662f7079ce69fa4c951bf38361fdc038e14b7ade
- Files: `packages/html/Html.ml`, `packages/reactDom/src/ReactServerDOM.ml`
- Result: RSC HTML async 9,694.30; RSC model 1,716.54; SSR async 19,430.07; SSR sync 6,347.18 operations/second.
- Insight: A paired rerun was neutral against its adjacent baseline, despite removing temporary strings.
- Next: Do not pursue HTML serializer buffering without allocation-profile evidence.

### Run 3, batch 1: allocation-light-flight-hex - streaming_geomean_ops_per_sec=6863.69 (KEEP)

- Timestamp: 2026-08-17 13:47 GMT
- Base: 5703e49
- Candidate: e4c8a73481e47733a80125e6fc878ca245e4f3680f9ae927fee1db466b35f317
- Files: `packages/reactDom/src/ReactServerDOM.ml`
- Result: RSC HTML async 10,335.35; RSC model 1,746.69; SSR async 19,366.79; SSR sync 6,348.37 operations/second.
- Insight: Replacing `Printf.sprintf` in Flight references and row prefixes improves the RSC boundary-heavy path. The full gate passed on commit d10e516.
- Next: Profile the remaining Flight row construction costs.

### Run 4, batch 1: recursive-json-writer - streaming_geomean_ops_per_sec=6883.01 (RUNNER_UP)

- Timestamp: 2026-08-17 13:47 GMT
- Base: 5703e49
- Candidate: e123717eb91cf0818f235e73eeedb2be313b61d41137f53e820513d46073e9c8
- Files: `packages/reactDom/src/ReactServerDOM.ml`
- Result: RSC HTML async 9,927.47; RSC model 1,785.31; SSR async 19,649.14; SSR sync 6,445.14 operations/second.
- Insight: Direct recursive list traversal improves raw model streaming, but the aggregate difference from the retained winner is below the noise floor and the patches overlap.
- Next: Revisit as an alternative base in a new segment with more samples.

# SSR and RSC Payload Streaming Worklog

## Data Summary

- Baseline geometric mean: 6,749.12 operations/second.
- Target: 67,491.20 operations/second (10x).

## Key Insights

- The old streaming benchmark does not exercise stream production.
- RSC HTML chunks currently pass through `Html.to_string`, which allocates a fresh serializer buffer and an intermediate string for every streamed value.

## Next Ideas

- Test direct HTML serialization into the subscriber's coalescing buffer.

### Run 1, batch 0: baseline - streaming_geomean_ops_per_sec=6749.12 (KEEP)

- Timestamp: 2026-08-17 11:24 GMT
- Base: 34b1ffd
- Candidate: baseline
- Files: none
- Result: RSC HTML async 9,582.24; RSC model 1,739.26; SSR async 19,646.37; SSR sync 6,336.86 operations/second.
- Insight: Raw RSC model serialization is the slowest workload. SSR streaming is already close to the complete-string wide-tree rate, which limits the likely SSR gain.
- Next: Remove per-chunk HTML serializer buffers and copies from the RSC HTML subscriber.

# Autoresearch: SSR and RSC payload streaming

## Objective

Increase server-side rendering and React Server Components payload-streaming throughput without changing emitted HTML, Flight rows, chunk ordering, Suspense behavior, or the public API. A 10x gain is an aspirational target, not an assumed outcome.

## Metrics

- **Primary**: `streaming_geomean_ops_per_sec` (operations/second, higher is better) across synchronous SSR drain, many-boundary SSR streaming, raw RSC model streaming, and many-boundary RSC HTML streaming.
- **Secondary**: each workload's operations/second. No workload may regress by more than 3% after confirmation.

## How to Run

`./autoresearch.sh` outputs `METRIC name=value` lines. It builds once, runs three samples, and reports medians.

## Files in Scope

- `packages/reactDom/src/ReactDOM.ml`: SSR streaming renderer and chunk production.
- `packages/reactDom/src/ReactServerDOM.ml`: Flight serialization and RSC HTML streaming.
- `packages/reactDom/src/Push_stream.ml`: internal stream queue adapter.
- `packages/html/Html.ml`: HTML serialization used by RSC chunks.
- `benchmark/streaming_payload_bench.ml`: focused measurement workload.
- `benchmark/dune`: benchmark executable declaration.
- Autoresearch state and documentation files at the repository root and under `experiments/`.

## Off Limits

- Emitted HTML, Flight protocol rows, ordering, error handling, and timeout behavior.
- Public API changes and new dependencies.
- OCaml 5-only standard library functions; OCaml 4.14 compatibility is required.
- Unrelated router and benchmark work in the original checkout.

## Constraints

- Relevant tests, `make format-check`, `make build`, and `make test` must pass before a winning source change is committed.
- Benchmarks run sequentially to prevent CPU contention.
- A candidate must improve the primary metric and must not regress an individual workload by more than 3% after confirmation.

## Stop Conditions

- Target: 10x the baseline primary metric.
- Maximum experiments: 12.
- Plateau: 3 consecutive batches without improvement.
- Time budget: 120 minutes.
- Parallel experiments: 3 implementations; measurements remain sequential.

## What's Been Tried

- Baseline: 6,749.12 operations/second geometric mean.
- Direct HTML serialization into the subscriber buffer was neutral in a paired rerun and was discarded.
- Allocation-light lowercase hexadecimal formatting for Flight references and row prefixes was kept at a confirmed 6,863.69 operations/second (+1.70%). RSC HTML async streaming improved 7.86% with no confirmed workload regression over 3%.
- Recursive JSON list and association traversal reached 6,883.01 operations/second, but it was equivalent within noise, overlapped the winner, and remains a runner-up.
- The 120-minute time budget expired after batch 1. The 10x target was not reached.

## Initial Evidence

- React's Fizz pipeable-stream optimization attributes poor performance to high chunk counts and replaces per-chunk work with buffering plus direct encoding into the output view.
- React exposes `progressiveChunkSize` because chunk granularity is an explicit performance and delivery tradeoff.
- React's Flight SSR fixture separates bare serialization, stream plumbing, HTTP throughput, synchronous work, and many-boundary asynchronous work.
- Eio's buffered serializer coalesces small writes and exposes vectorized batches, which supports testing fewer temporary buffers and copies in this OCaml implementation.

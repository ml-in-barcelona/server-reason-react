# Server Reason React Benchmark Suite

A comprehensive benchmark suite for measuring and comparing SSR performance of `server-reason-react` against React.js on JavaScript runtimes.

## Performance Summary

Pure rendering performance — `server-reason-react` (release profile, flambda + PPX static analyzer enabled) vs React 19.2.5 on Node 22.22.0 and Bun 1.3.12, both with `NODE_ENV=production`. Numbers are mean of 100 iterations, `renderToString`.

All 17 scenarios the native bench exercises are mirrored in JS, so every row is a like-for-like comparison of the same component tree rendered by three different runtimes.

| Scenario    | SRR         | Node + React | Bun + React | SRR vs Node | SRR vs Bun |
|-------------|------------:|-------------:|------------:|------------:|-----------:|
| Trivial     | **0.29 µs** | 42.10 µs     | 44.54 µs    | **145x**    | **154x**   |
| ShallowTree | **16.78 µs**| 99.97 µs     | 101.17 µs   | **6.0x**    | **6.0x**   |
| DeepTree10  | **13.74 µs**| 35.93 µs     | 35.97 µs    | **2.6x**    | **2.6x**   |
| DeepTree50  | **67.07 µs**| 91.77 µs     | 105.36 µs   | **1.4x**    | **1.6x**   |
| WideTree10  | **14.78 µs**| 66.20 µs     | 96.20 µs    | **4.5x**    | **6.5x**   |
| WideTree100 | **216.24 µs**| 382.75 µs   | 346.96 µs   | **1.8x**    | **1.6x**   |
| WideTree500 | **1.15 ms** | 2.30 ms      | 1.55 ms     | **2.0x**    | **1.3x**   |
| Table10     | **35.95 µs**| 219.12 µs    | 200.06 µs   | **6.1x**    | **5.6x**   |
| Table100    | **301.89 µs**| 714.19 µs   | 628.45 µs   | **2.4x**    | **2.1x**   |
| Table500    | **1.35 ms** | 4.97 ms      | 3.05 ms     | **3.7x**    | **2.3x**   |
| PropsSmall  | **107.42 µs**| 217.50 µs   | 204.00 µs   | **2.0x**    | **1.9x**   |
| PropsMedium | **305.64 µs**| 395.08 µs   | 361.21 µs   | **1.3x**    | **1.2x**   |
| Ecommerce24 | **121.24 µs**| 373.23 µs   | 376.76 µs   | **3.1x**    | **3.1x**   |
| Ecommerce48 | **228.68 µs**| 488.66 µs   | 492.02 µs   | **2.1x**    | **2.2x**   |
| Dashboard   | **31.68 µs**| 85.82 µs     | 94.09 µs    | **2.7x**    | **3.0x**   |
| Blog50      | **182.86 µs**| 565.45 µs   | 587.69 µs   | **3.1x**    | **3.2x**   |
| Form        | **69.39 µs**| 206.54 µs    | 163.92 µs   | **3.0x**    | **2.4x**   |

Throughput (MB/s, higher is better):

| Scenario    | SRR | Node | Bun |
|-------------|----:|-----:|----:|
| Table500    | **505.2** | 137.2 | 223.6 |
| Blog50      | **500.8** | 161.9 | 155.8 |
| Table100    | **455.4** | 192.5 | 218.8 |
| Dashboard   | **440.2** | 162.5 | 148.2 |
| WideTree10  | **439.2** | 98.1  | 67.5  |
| Ecommerce24 | **427.3** | 138.8 | 137.5 |
| Table10     | **421.1** | 69.1  | 75.7  |
| Ecommerce48 | **410.6** | 192.1 | 190.8 |
| Form        | **310.6** | 104.4 | 131.5 |
| PropsMedium | **302.6** | 234.1 | 256.0 |
| WideTree500 | **282.3** | 141.1 | 209.4 |

Notes:
- **SRR wins on every scenario.** Typical margin is 1.3–3.1x on realistic pages; the largest wins are on Table10 (5.6–6.1x), Table500 (2.3–3.7x), ShallowTree (6.0x), and WideTree10 (4.5–6.5x). Trivial's ~145x is measurement floor noise, not a real rendering difference.
- **Bun beats Node** on large wide trees and tables (1.3–1.6x), but loses on attribute-heavy and small-tree scenarios. On most real-page scenarios the two are within 10% of each other.
- React 19 `renderToString` is measurably slower than 18.3.1 on small scenarios (Trivial went from ~19 µs → ~42 µs) because of added server-component machinery that runs on every render. Large scenarios are roughly on par or slightly faster.

> These benchmarks measure pure `renderToStaticMarkup`/`renderToString` performance without HTTP server overhead. JS runs require `NODE_ENV=production`; the harness refuses to run otherwise (React's dev build is 3–7x slower and would give meaningless numbers).

## Quick Start

```bash
# Build everything
make build

# Run all benchmarks
make bench

# Run the render comparision
make bench-render
```

## Optimization Control

By default, benchmarks are built with optimizations enabled (`--profile=release`). You can disable optimizations to compare performance:

```bash
# Build without optimizations
DISABLE_OPTIMIZATIONS=1 make build-native

# Run benchmarks without optimizations
DISABLE_OPTIMIZATIONS=1 make bench-render

# Re-enable optimizations (default)
make build-native
make bench-render
```

This is useful for:
- Comparing optimized vs unoptimized performance
- CI workflows that need to test both configurations
- Debugging performance differences

## Benchmark Categories

### 1. Render Comparison (`bench-render`)

**The official benchmark** — compares pure rendering performance without HTTP overhead:

```bash
make bench-render        # Native vs Bun side-by-side
make bench-render-native # Native only
make bench-render-bun    # Bun only
```

This measures `renderToStaticMarkup` (native) vs `renderToString` (Bun/React) directly, giving the most accurate comparison of SSR performance.

### 2. Memory Benchmarks (`bench-memory`)

Measures allocation and GC behavior:
- Words allocated per render
- Minor/major GC cycles
- Memory efficiency (output bytes per word)

```bash
make bench-memory
make bench-memory-json  # Output JSON for CI
```

### 3. Streaming Benchmarks (`bench-streaming`)

Compares `renderToStaticMarkup` vs `renderToString` on native:
- Time to render
- Throughput (MB/s)
- Overhead comparison

```bash
make bench-streaming
```

### 4. HTTP Load Testing (`bench-http`)

Full end-to-end HTTP benchmarks using wrk:
- Requests/second
- Latency distribution (avg, p99)
- Transfer rate
- Multi-framework comparison

```bash
make bench-http       # Full suite, all frameworks
make bench-http-quick # Quick test (trivial + table100)
make bench-native-http # Native only
make bench-js-http    # JavaScript frameworks only
```

## Test Scenarios

| Scenario | Description | Purpose |
|----------|-------------|---------|
| `trivial` | Hello world | Baseline overhead |
| `shallow` | 5-level component tree | Prop passing |
| `deep10-100` | 10-100 level deep tree | Recursion performance |
| `wide10-1000` | 10-1000 siblings | Array rendering |
| `table10-500` | Data table rows | Real-world tables |
| `props_*` | Many HTML attributes | Attribute serialization |
| `ecommerce24-100` | Product grid | E-commerce SSR |
| `dashboard` | Analytics page | Admin UI |
| `blog10-100` | Article + comments | Content-heavy |
| `form` | Multi-step form | Form rendering |

## Framework Comparison

| Framework | Port | Description |
|-----------|------|-------------|
| `dream-native` | 3000 | OCaml + Dream + server-reason-react |
| `node-express` | 3001 | Node.js + Express + React |
| `node-fastify` | 3002 | Node.js + Fastify + React |
| `hono-node` | 3003 | Hono + Node.js + React |
| `hono-bun` | 3004 | Hono + Bun + React |
| `bun-native` | 3005 | Bun native + React |
| `preact` | 3006 | Node.js + Express + Preact |

## Running Individual Servers

For manual testing or debugging:

```bash
# Start servers individually
make native-server    # Dream on :3000
make node-express     # Express on :3001
make node-fastify     # Fastify on :3002
make hono-node        # Hono on :3003

DISABLE_LOGGER=1 make native-server

# Test with curl
curl "http://localhost:3000/?scenario=table100"
curl "http://localhost:3000/scenarios"  # List available

# Quick wrk test
make wrk-test PORT=3000 SCENARIO=table100
```

## Methodology

### Warmup
- 100 requests before measurement to eliminate cold-start effects
- GC stabilization between benchmark runs

### Measurement
- Multiple iterations with statistical analysis
- Core_bench: 10,000 calls per benchmark
- HTTP: 10-30 seconds with wrk (configurable)

### Environment
- All frameworks run single-threaded for fair comparison
- React runtimes require `NODE_ENV=production` — `render-bench.ts` refuses to run otherwise, and `make bench-render` sets it automatically. React's development build skips a large amount of dev-only validation in production and is 3–7x faster as a result.
- Same React/component tree across frameworks

### Metrics Reported
- **Throughput**: Requests/second
- **Latency**: Average, p50, p99, max
- **Memory**: Words allocated, GC cycles
- **Transfer**: Bytes/second

## Requirements
- OCaml 5.x with opam
- Node.js 20+ (for JS frameworks)
- Bun (optional, for Bun benchmarks)
- wrk (optional, for HTTP load testing)

## Results

Results are saved to `benchmark/results/`:
- `benchmark-TIMESTAMP.json` - Raw data
- `benchmark-TIMESTAMP.md` - Markdown report

View latest results:
```bash
make results
```

## Interpreting Results

### What to look for:

1. **Render time (µs)**: Lower is better. Time to render a component tree.
2. **Throughput (MB/s)**: Higher is better. Data output rate.
3. **Memory (words/iter)**: Lower is better. Memory efficiency.
4. **Requests/sec** (HTTP): Higher is better. End-to-end throughput.

### Typical results pattern:

**Pure rendering** (no HTTP, React runtimes in `NODE_ENV=production`):
- SRR is **1.3–6.1x faster** than Node + React and **1.2–6.5x faster** than Bun + React across all 17 scenarios. The biggest realistic wins are on tables (up to 6.1x on Table10 vs Node) and shallow/wide component trees (4.5–6.5x on WideTree10).
- SRR throughput tops out around **505 MB/s** on tables and **500 MB/s** on content pages (Blog50). Bun is competitive on a handful of scenarios (~225 MB/s on Table500); Node trails at ~100–195 MB/s on large scenarios.
- The "trivial" scenario shows a ~145x gap that's mostly measurement floor noise, not a real rendering difference.
- Node and Bun are roughly at parity on most real-page scenarios. Bun wins on large wide trees and tables; Node wins on attribute-heavy and small-tree scenarios.

**Inline `style` props are expensive in SRR.** `ReactDOM.Style.make` has ~347 optional args and allocates ~1,460 words per call regardless of what's passed. If a component is on a hot render path and uses inline `style`, consider moving the style into a CSS class. Scenarios in this suite use `className` so the measurement reflects the rendering path, not `Style.make` allocation.

**HTTP benchmarks** (with server overhead):
- Bun's HTTP layer is faster for minimal requests (trivial scenario)
- Native wins on real SSR workloads where rendering dominates
- Use `DISABLE_LOGGER=1` for accurate native HTTP benchmarks

## Contributing

To add a new scenario:

1. Create `benchmark/scenarios/NewScenario.re`
2. Add to the scenario list in:
   - `benchmark/native/server.re`
   - `benchmark/micro/micro_bench.re`
   - `benchmark/frameworks/shared/scenarios.jsx`
3. Run benchmarks: `make bench`

# Server Reason React Benchmark Suite

A comprehensive benchmark suite for measuring and comparing SSR performance of `server-reason-react` against React.js with some JavaScript runtimes

## Performance Summary

**Pure rendering performance** — Native + server-reason-rect vs Bun + React:

| Scenario | Native | Bun + React | Speedup |
|----------|--------|-------------|---------|
| Trivial | 0.10µs | 37.16µs | **371x** |
| Table100 | 300.92µs | 3,500µs | **11.6x** |
| Wide100 | 287.40µs | 1,980µs | **6.9x** |
| Deep50 | 140.82µs | 349.37µs | **2.5x** |

**Throughput:**

| Scenario | Native | Bun + React |
|----------|--------|-------------|
| Table100 | 456.9 MB/s | 39.5 MB/s |
| Wide100 | 224.9 MB/s | 33.3 MB/s |

> These benchmarks measure pure `renderToStaticMarkup`/`renderToString` performance without HTTP server overhead, providing an accurate comparison of SSR rendering speed.

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
- Production mode (`NODE_ENV=production`)
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

**Pure rendering** (no HTTP):
- Native is **2.5-12x faster** than Bun + React depending on component complexity
- Throughput: Native achieves **180-510 MB/s** vs Bun's **13-40 MB/s**

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

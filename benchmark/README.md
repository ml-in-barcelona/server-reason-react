# Server Reason React Benchmark Suite

A comprehensive, state-of-the-art benchmark suite for measuring and comparing SSR performance of `server-reason-react` against popular JavaScript frameworks.

## Overview

This benchmark suite provides:

- **Multiple comparison frameworks**: Node.js (Express, Fastify), Hono, Bun, Preact
- **Realistic test scenarios**: E-commerce pages, dashboards, blogs, forms, data tables
- **Multiple benchmark types**: Microbenchmarks, memory profiling, streaming, HTTP load testing
- **Statistical analysis**: Mean, median, p99, standard deviation, throughput
- **Automated runner**: Consistent, reproducible results with warmup and cooldown

## Quick Start

```bash
# Build everything
make build

# Run all benchmarks
make bench

# Quick HTTP comparison
make bench-http-quick
```

## Benchmark Categories

### 1. Microbenchmarks (`bench-micro`)

Precise measurements using Core_bench for:
- Render time per component type
- Scaling characteristics (depth, width)
- React primitive operations

```bash
make bench-micro                    # Run all suites
make bench-micro-suite SUITE=depth  # Run specific suite
```

Available suites: `trivial`, `depth`, `width`, `table`, `props`, `realworld`, `primitives`, `all`

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

Compares `renderToStaticMarkup` vs `renderToString`:
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

## Project Structure

```
benchmark/
├── scenarios/          # Benchmark components (Reason)
│   ├── Trivial.re
│   ├── ShallowTree.re
│   ├── DeepTree.re
│   ├── WideTree.re
│   ├── Table.re
│   ├── PropsHeavy.re
│   ├── Ecommerce.re
│   ├── Dashboard.re
│   ├── Blog.re
│   └── Form.re
├── native/             # Native Dream server
│   └── server.re
├── micro/              # Core_bench microbenchmarks
│   └── micro_bench.re
├── memory/             # Memory profiling
│   └── memory_bench.ml
├── streaming/          # Render comparison
│   └── streaming_bench.ml
├── frameworks/         # JavaScript frameworks
│   ├── shared/scenarios.jsx
│   ├── node-express/
│   ├── node-fastify/
│   ├── hono-node/
│   ├── hono-bun/
│   ├── bun-native/
│   └── preact/
├── runner/             # HTTP benchmark runner
│   └── runner.mjs
├── results/            # Output directory
├── Makefile
└── README.md
```

## Running Individual Servers

For manual testing or debugging:

```bash
# Start servers individually
make native-server    # Dream on :3000
make node-express     # Express on :3001
make node-fastify     # Fastify on :3002
make hono-node        # Hono on :3003

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

Install wrk:
```bash
# macOS
brew install wrk

# Ubuntu
sudo apt install wrk

# Or build from source
git clone https://github.com/wg/wrk.git
cd wrk && make && sudo cp wrk /usr/local/bin/
```

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

1. **Requests/sec**: Higher is better. Shows overall throughput.
2. **Latency (avg)**: Lower is better. Response time per request.
3. **Latency (p99)**: Lower is better. Tail latency, important for real-world use.
4. **Memory (words/iter)**: Lower is better. Memory efficiency.
5. **Throughput (MB/s)**: Higher is better. Data output rate.

### Typical results pattern:
- `dream-native` typically shows 3-5x higher throughput than Node.js
- Latency is typically 5-10x lower for native
- Memory allocation is significantly lower in OCaml

## Contributing

To add a new scenario:

1. Create `benchmark/scenarios/NewScenario.re`
2. Add to the scenario list in:
   - `benchmark/native/server.re`
   - `benchmark/micro/micro_bench.re`
   - `benchmark/frameworks/shared/scenarios.jsx`
3. Run benchmarks: `make bench`

## Running in CI

The benchmark suite includes a GitHub Actions workflow (`.github/workflows/benchmark.yml`) that:

1. **Runs on PRs** - Automatically benchmarks changes to `packages/` or `benchmark/`
2. **Compares branches** - Shows memory allocation differences between PR and base
3. **Weekly tracking** - Scheduled runs every Sunday for long-term performance tracking
4. **Manual triggers** - Run via GitHub Actions UI with suite selection

### CI Outputs

- **Job Summary**: Results appear directly in the GitHub Actions summary
- **Artifacts**: Raw results are uploaded for 30 days
- **Comparison**: PR vs base branch memory comparison

### Local CI Simulation

```bash
# Run what CI runs
make build-native
_build/default/benchmark/memory/memory_bench.exe
_build/default/benchmark/streaming/streaming_bench.exe
_build/default/benchmark/micro/micro_bench.exe table
```

### Adding to Existing CI

If you have an existing CI workflow, add these steps:

```yaml
- name: Build benchmarks
  run: opam exec -- dune build benchmark/memory/memory_bench.exe

- name: Run benchmarks
  run: opam exec -- _build/default/benchmark/memory/memory_bench.exe
```

## License

Same as server-reason-react (MIT)

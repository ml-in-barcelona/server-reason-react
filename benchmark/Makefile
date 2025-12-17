# Server Reason React Benchmark Suite
# ==================================

.PHONY: all build build-native build-js clean help
.PHONY: bench bench-micro bench-memory bench-streaming bench-http
.PHONY: native-server js-servers

# Directories
BENCHMARK_DIR := $(shell pwd)
PROJECT_ROOT := $(shell dirname $(BENCHMARK_DIR))
RESULTS_DIR := $(BENCHMARK_DIR)/results
FRAMEWORKS_DIR := $(BENCHMARK_DIR)/frameworks

BUN := $(shell command -v bun 2>/dev/null || echo "$(HOME)/.bun/bin/bun")

# Optimization control
# Set DISABLE_OPTIMIZATIONS=1 to build without optimizations (--profile=dev)
# Default: optimizations enabled (--profile=release)
ifeq ($(DISABLE_OPTIMIZATIONS),1)
  DUNE_PROFILE := --profile=dev
else
  DUNE_PROFILE := --profile=release
endif

# Default target
all: help

# ============================================================================
# Build Targets
# ============================================================================

build: build-native build-js
	@echo "✓ All builds complete"

build-native:
	@echo "Building native OCaml benchmarks..."
	@if [ "$(DISABLE_OPTIMIZATIONS)" = "1" ]; then \
		echo "  (Optimizations DISABLED)"; \
	else \
		echo "  (Optimizations ENABLED)"; \
	fi
	cd $(PROJECT_ROOT) && opam exec -- dune build $(DUNE_PROFILE) benchmark/scenarios/benchmark_scenarios.a
	cd $(PROJECT_ROOT) && opam exec -- dune build $(DUNE_PROFILE) benchmark/native/server.exe
	cd $(PROJECT_ROOT) && opam exec -- dune build $(DUNE_PROFILE) benchmark/memory/memory_bench.exe
	cd $(PROJECT_ROOT) && opam exec -- dune build $(DUNE_PROFILE) benchmark/streaming/streaming_bench.exe
	@echo "✓ Native builds complete"

build-js:
	@echo "Building JavaScript frameworks..."
	cd $(FRAMEWORKS_DIR) && npm install
	@echo "✓ JavaScript frameworks ready"

clean:
	cd $(PROJECT_ROOT) && opam exec -- dune clean
	rm -rf $(RESULTS_DIR)/*.json $(RESULTS_DIR)/*.md
	rm -rf $(FRAMEWORKS_DIR)/node_modules
	@echo "✓ Cleaned"

# ============================================================================
# Benchmark Targets
# ============================================================================

bench: bench-render bench-memory bench-streaming
	@echo "✓ All benchmarks complete"

bench-memory: build-native
	@echo "\n=== Running Memory Benchmarks ==="
	$(PROJECT_ROOT)/_build/default/benchmark/memory/memory_bench.exe

bench-memory-json: build-native
	@mkdir -p $(RESULTS_DIR)
	$(PROJECT_ROOT)/_build/default/benchmark/memory/memory_bench.exe --json > $(RESULTS_DIR)/memory-$$(date +%Y%m%d-%H%M%S).json

bench-streaming: build-native
	@echo "\n=== Running Streaming Benchmarks ==="
	$(PROJECT_ROOT)/_build/default/benchmark/streaming/streaming_bench.exe

bench-render: build-native build-js
	@echo "\n=== Pure Render Benchmark: Native vs Bun ==="
	@echo "\n--- Native (server-reason-react) ---"
	$(PROJECT_ROOT)/_build/default/benchmark/streaming/streaming_bench.exe
	@echo "\n--- Bun (React) ---"
	@cd $(FRAMEWORKS_DIR) && $(BUN) render-bench.ts

bench-render-native: build-native
	@echo "\n=== Native Render Benchmark ==="
	$(PROJECT_ROOT)/_build/default/benchmark/streaming/streaming_bench.exe

bench-render-bun: build-js
	@echo "\n=== Bun Render Benchmark ==="
	@cd $(FRAMEWORKS_DIR) && $(BUN) render-bench.ts

bench-http: build
	@echo "\n=== Running HTTP Benchmarks ==="
	@mkdir -p $(RESULTS_DIR)
	cd $(BENCHMARK_DIR)/runner && node runner.mjs

bench-http-quick: build
	@echo "\n=== Running Quick HTTP Benchmarks ==="
	cd $(BENCHMARK_DIR)/runner && node runner.mjs --scenarios trivial,table100

bench-native-http: build-native
	@echo "\n=== Running Native HTTP Benchmarks ==="
	cd $(BENCHMARK_DIR)/runner && node runner.mjs --frameworks dream-native

bench-js-http: build-js
	@echo "\n=== Running JavaScript HTTP Benchmarks ==="
	cd $(BENCHMARK_DIR)/runner && node runner.mjs --frameworks node-express,node-fastify,hono-node

# ============================================================================
# Server Targets (for manual testing)
# ============================================================================

native-server: build-native
	@echo "Starting native Dream server on port 3000..."
	PORT=3000 $(PROJECT_ROOT)/_build/default/benchmark/native/server.exe

js-servers: build-js
	@echo "Starting all JavaScript servers..."
	cd $(FRAMEWORKS_DIR) && npm run start:all

node-express: build-js
	cd $(FRAMEWORKS_DIR) && npm run start:node-express

node-fastify: build-js
	cd $(FRAMEWORKS_DIR) && npm run start:node-fastify

hono-node: build-js
	cd $(FRAMEWORKS_DIR) && npm run start:hono-node

# ============================================================================
# Utility Targets
# ============================================================================

wrk-test:
	@if [ -z "$(PORT)" ]; then \
		echo "Usage: make wrk-test PORT=3000 [SCENARIO=table100]"; \
	else \
		wrk -t4 -c100 -d10s "http://localhost:$(PORT)/?scenario=$${SCENARIO:-table100}"; \
	fi

scenarios: build-native
	@$(PROJECT_ROOT)/_build/default/benchmark/native/server.exe &
	@sleep 1
	@curl -s http://localhost:3000/scenarios | jq .
	@pkill -f "server.exe" || true

results:
	@ls -la $(RESULTS_DIR)/*.md $(RESULTS_DIR)/*.json 2>/dev/null || echo "No results yet. Run 'make bench-http'"

# ============================================================================
# Help
# ============================================================================

help:
	@echo "Server Reason React Benchmark Suite"
	@echo "===================================="
	@echo ""
	@echo "Build targets:"
	@echo "  make build          - Build all (native + JS)"
	@echo "  make build-native   - Build native OCaml benchmarks"
	@echo "  make build-js       - Install JS framework dependencies"
	@echo "  make clean          - Clean all build artifacts"
	@echo ""
	@echo "Benchmark targets:"
	@echo "  make bench          - Run all benchmarks"
	@echo "  make bench-render   - Pure render comparison: Native vs Bun (recommended)"
	@echo "  make bench-render-native - Native render only"
	@echo "  make bench-render-bun - Bun render only"
	@echo "  make bench-memory   - Run memory benchmarks"
	@echo "  make bench-streaming - Run streaming benchmarks"
	@echo "  make bench-http     - Run HTTP load testing (all frameworks)"
	@echo "  make bench-http-quick - Quick HTTP test (trivial + table100 only)"
	@echo "  make bench-native-http - HTTP test native only"
	@echo "  make bench-js-http  - HTTP test JS frameworks only"
	@echo ""
	@echo "Server targets (for manual testing):"
	@echo "  make native-server  - Start native Dream server (port 3000)"
	@echo "  make js-servers     - Start all JS servers"
	@echo "  make node-express   - Start Node.js + Express"
	@echo "  make node-fastify   - Start Node.js + Fastify"
	@echo "  make hono-node      - Start Hono + Node.js"
	@echo ""
	@echo "Utility:"
	@echo "  make wrk-test PORT=3000 [SCENARIO=table100]"
	@echo "                      - Quick load test against running server"
	@echo "  make scenarios      - List available scenarios"
	@echo "  make results        - Show benchmark results"
	@echo ""
	@echo "Optimization control:"
	@echo "  DISABLE_OPTIMIZATIONS=1 make build-native"
	@echo "                      - Build without optimizations (--profile=dev)"
	@echo "  make build-native   - Build with optimizations (--profile=release, default)"


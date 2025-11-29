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

# Default target
all: help

# ============================================================================
# Build Targets
# ============================================================================

build: build-native build-js
	@echo "✓ All builds complete"

build-native:
	@echo "Building native OCaml benchmarks..."
	cd $(PROJECT_ROOT) && dune build benchmark/scenarios/benchmark_scenarios.a
	cd $(PROJECT_ROOT) && dune build benchmark/native/server.exe
	cd $(PROJECT_ROOT) && dune build benchmark/micro/micro_bench.exe
	cd $(PROJECT_ROOT) && dune build benchmark/memory/memory_bench.exe
	cd $(PROJECT_ROOT) && dune build benchmark/streaming/streaming_bench.exe
	@echo "✓ Native builds complete"

build-js:
	@echo "Building JavaScript frameworks..."
	cd $(FRAMEWORKS_DIR) && npm install
	@echo "✓ JavaScript frameworks ready"

clean:
	cd $(PROJECT_ROOT) && dune clean
	rm -rf $(RESULTS_DIR)/*.json $(RESULTS_DIR)/*.md
	rm -rf $(FRAMEWORKS_DIR)/node_modules
	@echo "✓ Cleaned"

# ============================================================================
# Benchmark Targets
# ============================================================================

# Run all benchmarks
bench: bench-micro bench-memory bench-streaming bench-http
	@echo "✓ All benchmarks complete"

# Microbenchmarks (Core_bench)
bench-micro: build-native
	@echo "\n=== Running Microbenchmarks ==="
	$(PROJECT_ROOT)/_build/default/benchmark/micro/micro_bench.exe all

bench-micro-suite: build-native
	@echo "Available suites: trivial, depth, width, table, props, realworld, primitives, all"
	@if [ -z "$(SUITE)" ]; then \
		echo "Usage: make bench-micro-suite SUITE=<name>"; \
	else \
		$(PROJECT_ROOT)/_build/default/benchmark/micro/micro_bench.exe $(SUITE); \
	fi

# Memory benchmarks
bench-memory: build-native
	@echo "\n=== Running Memory Benchmarks ==="
	$(PROJECT_ROOT)/_build/default/benchmark/memory/memory_bench.exe

bench-memory-json: build-native
	@mkdir -p $(RESULTS_DIR)
	$(PROJECT_ROOT)/_build/default/benchmark/memory/memory_bench.exe --json > $(RESULTS_DIR)/memory-$$(date +%Y%m%d-%H%M%S).json

# Streaming/render benchmarks
bench-streaming: build-native
	@echo "\n=== Running Streaming Benchmarks ==="
	$(PROJECT_ROOT)/_build/default/benchmark/streaming/streaming_bench.exe

# HTTP load testing (requires wrk)
bench-http: build
	@echo "\n=== Running HTTP Benchmarks ==="
	@mkdir -p $(RESULTS_DIR)
	cd $(BENCHMARK_DIR)/runner && node runner.mjs

bench-http-quick: build
	@echo "\n=== Running Quick HTTP Benchmarks ==="
	cd $(BENCHMARK_DIR)/runner && node runner.mjs --scenarios trivial,table100

# Framework-specific HTTP benchmarks
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

# Individual JS servers
node-express: build-js
	cd $(FRAMEWORKS_DIR) && npm run start:node-express

node-fastify: build-js
	cd $(FRAMEWORKS_DIR) && npm run start:node-fastify

hono-node: build-js
	cd $(FRAMEWORKS_DIR) && npm run start:hono-node

# ============================================================================
# Utility Targets
# ============================================================================

# Quick load test with wrk (requires running server)
wrk-test:
	@if [ -z "$(PORT)" ]; then \
		echo "Usage: make wrk-test PORT=3000 [SCENARIO=table100]"; \
	else \
		wrk -t4 -c100 -d10s "http://localhost:$(PORT)/?scenario=$${SCENARIO:-table100}"; \
	fi

# Show scenarios available
scenarios: build-native
	@$(PROJECT_ROOT)/_build/default/benchmark/native/server.exe &
	@sleep 1
	@curl -s http://localhost:3000/scenarios | jq .
	@pkill -f "server.exe" || true

# Open results
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
	@echo "  make bench-micro    - Run microbenchmarks (Core_bench)"
	@echo "  make bench-micro-suite SUITE=<name>"
	@echo "                      - Run specific suite (trivial|depth|width|table|props|realworld|primitives|all)"
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


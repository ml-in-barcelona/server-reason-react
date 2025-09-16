project_name = server-reason-react

DUNE = opam exec -- dune
opam_file = $(project_name).opam

.PHONY: help
help: ## Print this help message
	@echo "";
	@echo "List of available make commands";
	@echo "";
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}';
	@echo "";

.PHONY: build
build: ## Build the project, including non installable libraries and executables
	$(DUNE) build --profile=dev

.PHONY: build-prod
build-prod: ## Build for production (--profile=prod)
	$(DUNE) build --profile=prod

.PHONY: dev
dev: ## Build in watch mode
	$(DUNE) build -w --profile=dev

.PHONY: clean
clean: ## Clean artifacts
	$(DUNE) clean

.PHONY: test
test: ## Run the unit tests
	$(DUNE) build @runtest

.PHONY: test-watch
test-watch: ## Run the unit tests in watch mode
	$(DUNE) build @runtest -w

.PHONY: test-promote
test-promote: ## Updates snapshots and promotes it to correct
	$(DUNE) build @runtest --auto-promote

.PHONY: format
format: ## Format the codebase with ocamlformat
	@DUNE_CONFIG__GLOBAL_LOCK=disabled $(DUNE) build @fmt --auto-promote

.PHONY: format-check
format-check: ## Checks if format is correct
	@DUNE_CONFIG__GLOBAL_LOCK=disabled $(DUNE) build @fmt

.PHONY: init
setup-githooks: ## Setup githooks
	git config core.hooksPath .githooks

.PHONY: create-switch
create-switch: ## Create opam switch
	opam switch create . 5.2.0 --deps-only --with-test -y

.PHONY: install
install:
	opam install . --deps-only --with-test --with-doc --with-dev-setup -y

.PHONY: install-npm
install-npm:
	cd packages/esbuild-plugin && npm install;
	cd packages/react-server-dom-esbuild && npm install;
	cd demo && npm install;
	cd demo/client && npm install

.PHONY: pin
pin: ## Pin dependencies
	echo "Nothing to pin"

.PHONY: init
init: setup-githooks create-switch pin install install-npm ## Create a local dev enviroment

.PHONY: ppx-test
ppx-test: ## Run ppx tests
	$(DUNE) runtest packages/server-reason-react-ppx

.PHONY: ppx-test-watch
ppx-test-watch: ## Run ppx tests in watch mode
	$(DUNE) runtest packages/server-reason-react-ppx --watch

.PHONY: ppx-test-promote
ppx-test-promote: ## Prommote ppx tests snapshots
	$(DUNE) runtest packages/server-reason-react-ppx --auto-promote

.PHONY: lib-test
lib-test: ## Run library tests
	$(DUNE) exec test/test.exe

.PHONY: demo-build
demo-build: ## Build the project (client, server and universal)
	$(DUNE) build --profile=dev @demo

.PHONY: demo-build-watch
demo-build-watch: ## Watch demo (client, server and universal)
	$(DUNE) build --profile=dev @demo --force --watch

.PHONY: demo-serve
demo-serve: demo-build ## Serve the demo executable
	@opam exec -- _build/default/demo/server/server.exe

.PHONY: demo-serve-watch
demo-serve-watch: ## Run demo executable on watch mode (listening to built_at.txt changes)
	@watchexec --no-vcs-ignore -w demo/.running/built_at.txt -r -c -- "_build/default/demo/server/server.exe"

.PHONY: subst
subst: ## Run dune substitute
	$(DUNE) subst

.PHONY: docs
docs: ## Generate odoc documentation
	$(DUNE) build @install
	$(DUNE) exec -- odoc_driver server-reason-react --remap

# Because if the hack above, we can't have watch mode
.PHONY: docs-watch
docs-watch: ## Generate odoc docs
	$(DUNE) build --root . -w @doc-new --profile=prod

.PHONY: docs-open
docs-open: ## Open odoc docs with default web browser
# open _build/default/_doc_new/html/docs/local/server-reason-react/index.html
	open _html/server-reason-react/index.html

.PHONY: docs-serve
docs-serve: docs docs-open ## Open odoc docs with default web browser

.PHONY: build-bench
build-bench: ## Run benchmark
	$(DUNE) build --profile=release

.PHONY: bench
bench: build-bench ## Run benchmark
	@$(DUNE) exec benchmark/main.exe --profile=release --display-separate-messages --no-print-directory

.PHONY: bench-watch
bench-watch: build-bench ## Run benchmark in watch mode
	@$(DUNE) exec benchmark/main.exe --profile=release --display-separate-messages --no-print-directory --watch

.PHONY: once
bench-once: ## Run benchmark once
	@$(DUNE) exec _build/default/benchmark/once.exe

.PHONY: bench-once-watch
bench-once-watch: ## Run benchmark once in watch mode
	@$(DUNE) exec _build/default/benchmark/once.exe --watch

container_name = server-reason-react-demo
current_hash = $(shell git rev-parse HEAD | cut -c1-7)

.PHONY: docker-build
docker-build: ## docker build
	DOCKER_BUILDKIT=0 docker build . --tag "$(container_name):$(current_hash)" --platform linux/amd64

.PHONY: docker-run
docker-run: ## docker run
	@docker run -d --platform linux/amd64 $(container_name):$(current_hash)

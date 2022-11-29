project_name = server-reason-react

DUNE = opam exec -- dune
opam_file = $(project_name).opam
current_hash = $(shell git rev-parse HEAD | cut -c1-7)
MEL = opam exec -- mel

.PHONY: help
help: ## Print this help message
	@echo "List of available make commands";
	@echo "";
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}';
	@echo "";

.PHONY: help
build: ## Build the project, including non installable libraries and executables
	$(DUNE) build @@default

.PHONY: build-prod
build-prod: ## Build for production (--profile=prod)
	$(DUNE) build --profile=prod @@default

.PHONY: dev
dev: ## Build in watch mode
	$(DUNE) build -w @@default

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

.PHONY: deps
deps: $(opam_file) ## Alias to update the opam file and install the needed deps

.PHONY: format
format: ## Format the codebase with ocamlformat
	$(DUNE) build @fmt --auto-promote

.PHONY: format-check
format-check: ## Checks if format is correct
	$(DUNE) build @fmt

.PHONY: init
init: ## Create a local opam switch and setups githooks
	git config core.hooksPath .githooks
	opam switch create . --deps-only --with-test

.PHONY: ppx-test
ppx-test: ## Run ppx tests
	$(DUNE) runtest ppx

.PHONY: ppx-test-watch
ppx-test-watch: ## Run ppx tests in watch mode
	$(DUNE) runtest ppx --watch

.PHONY: lib-test
lib-test: ## Run library tests
	$(DUNE) exec test/test.exe

.PHONY: commit
commit:
	@echo "Copied hash in copy: $(current_hash)";
	@echo $(current_hash) | pbcopy;

$(opam_file): dune-project ## Update the package dependencies when new deps are added to dune-project
	$(DUNE) build @install
	opam install . --deps-only --with-test # Install the new dependencies

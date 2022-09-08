project_name = jsoo-react

DUNE = opam exec -- dune
opam_file = $(project_name).opam
current_hash = $(shell git rev-parse HEAD)

.PHONY: build build-prod dev test test-promote deps format format-check init publish-example

.PHONY: help
help: ## Print this help message
	@echo "List of available make commands";
	@echo "";
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}';
	@echo "";

build: ## Build the project, including non installable libraries and executables
	$(DUNE) build @@default

build-prod: ## Build for production (--profile=prod)
	$(DUNE) build --profile=prod @@default

dev: ## Build in watch mode
	$(DUNE) build -w @@default

test: ## Run the unit tests
	$(DUNE) build @runtest

test-watch: ## Run the unit tests in watch mode
	$(DUNE) build @runtest -w

test-promote: ## Updates snapshots and promotes it to correct
	$(DUNE) build @runtest --auto-promote

deps: $(opam_file) ## Alias to update the opam file and install the needed deps

format: ## Format the codebase with ocamlformat
	$(DUNE) build @fmt --auto-promote

format-check: ## Checks if format is correct
	$(DUNE) build @fmt

publish-example: ## Publish example/ to gh-pages
	git checkout main && $(DUNE) build --profile=prod @@default && cd example && yarn webpack:production \
	&& cd - && git checkout gh-pages && cp example/build/* . && git commit -am "$(current_hash)"

$(opam_file): dune-project ## Update the package dependencies when new deps are added to dune-project
	$(DUNE) build @install
	opam install . --deps-only --with-test # Install the new dependencies

init: ## Create a local opam switch and setups githooks
	git config core.hooksPath .githooks
	opam switch create . --deps-only --with-test

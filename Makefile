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
	$(DUNE) build packages --profile=dev

.PHONY: build-prod
build-prod: ## Build for production (--profile=prod)
	$(DUNE) build packages --profile=prod

.PHONY: dev
dev: ## Build in watch mode
	$(DUNE) build -w --profile=dev @all

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
setup-githooks: ## Setup githooks
	git config core.hooksPath .githooks

.PHONY: create-switch
create-switch: ## Create opam switch
	opam switch create . 5.1.1 --deps-only --with-test -y

.PHONY: install
install:
	$(DUNE) build @install
	opam install . --deps-only --with-test
	cd demo && npm install

.PHONY: pin
pin: ## Pin dependencies
	@echo "[Success] No pin dependencies needed"

.PHONY: init
init: setup-githooks create-switch pin install ## Create a local dev enviroment

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

.PHONY: demo
demo: build ## Run demo executable
	$(DUNE) exec demo/server/server.exe --display-separate-messages --no-print-directory --profile=dev

.PHONY: demo-watch
demo-watch: build ## Run demo executable in watch mode
	$(DUNE) exec demo/server/server.exe --display-separate-messages --no-print-directory --display=quiet --watch --profile=dev

.PHONY: subst
subst: ## Run dune substitute
	$(DUNE) subst

.PHONY: docs
docs: ## Generate odoc documentation
	$(DUNE) build --root . @doc-new --profile=prod

# Because if the hack above, we can't have watch mode
.PHONY: docs-watch
docs-watch: ## Generate odoc docs
	$(DUNE) build --root . -w @doc-new --profile=prod

.PHONY: docs-open
docs-open: ## Open odoc docs with default web browser
	open _build/default/_doc_new/html/docs/local/server-reason-react/index.html

.PHONY: docs-serve
docs-serve: docs docs-open ## Open odoc docs with default web browser

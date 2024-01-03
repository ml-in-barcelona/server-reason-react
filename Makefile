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
	$(DUNE) build @all

.PHONY: build-prod
build-prod: ## Build for production (--profile=prod)
	$(DUNE) build --profile=prod @all

.PHONY: dev
dev: ## Build in watch mode
	$(DUNE) build -w @all

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
	opam switch create . 5.1.0 --deps-only --with-test -y

.PHONY: install
install:
	$(DUNE) build @install
	opam install . --deps-only --with-test

.PHONY: pin
pin: ## Pin dependencies
	opam pin add dune.dev "https://github.com/ocaml/dune.git#4c9dec68fc776d808a36bb139230a2695c619d59" -y
	opam pin add melange.dev "https://github.com/melange-re/melange.git#2ff08be262f113fc8d28b66c272502c6f403399c" -y
	opam pin add reason-react-ppx.dev "https://github.com/reasonml/reason-react.git#7ca984c9a406b01e906fda1898f705f135fad202" -y
	opam pin add reason-react.dev "https://github.com/reasonml/reason-react.git#7ca984c9a406b01e906fda1898f705f135fad202" -y
	opam pin add melange-fetch.dev "git+https://github.com/melange-community/melange-fetch.git#master" -y
	opam pin add melange-webapi.dev "git+https://github.com/melange-community/melange-webapi.git#master" -y

.PHONY: init
init: setup-githooks create-switch install pin ## Create a local dev enviroment

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
demo: ## Run demo executable
	$(DUNE) exec demo/server/server.exe --display-separate-messages --no-print-directory

.PHONY: demo-watch
demo-watch: ## Run demo executable
	$(DUNE) exec demo/server/server.exe --display-separate-messages --no-print-directory --display=quiet --watch

.PHONY: subst
subst: ## Run dune substitute
	$(DUNE) subst

.PHONY: docs
docs: ## Generate odoc documentation
	$(DUNE) build --root . @doc-new

# Because if the hack above, we can't have watch mode
.PHONY: docs-watch
docs-watch: ## Generate odoc docs
	$(DUNE) build --root . -w @doc-new

.PHONY: docs-open
docs-open: ## Open odoc docs with default web browser
	open _build/default/_doc_new/html/docs/local/server-reason-react/index.html

.PHONY: docs-serve
docs-serve: docs docs-open ## Open odoc docs with default web browser

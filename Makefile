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
	@$(DUNE) build @@default

.PHONY: build-prod
build-prod: ## Build for production (--profile=prod)
	@$(DUNE) build --profile=prod @@default

.PHONY: dev
dev: ## Build in watch mode
	@$(DUNE) build -w @@default

.PHONY: clean
clean: ## Clean artifacts
	@$(DUNE) clean

.PHONY: test
test: ## Run the unit tests
	@$(DUNE) build @runtest

.PHONY: test-watch
test-watch: ## Run the unit tests in watch mode
	@$(DUNE) build @runtest -w

.PHONY: test-promote
test-promote: ## Updates snapshots and promotes it to correct
	@$(DUNE) build @runtest --auto-promote

.PHONY: deps
deps: $(opam_file) ## Alias to update the opam file and install the needed deps

.PHONY: format
format: ## Format the codebase with ocamlformat
	@$(DUNE) build @fmt --auto-promote

.PHONY: format-check
format-check: ## Checks if format is correct
	@$(DUNE) build @fmt

.PHONY: init
setup-githooks: ## Setup githooks
	@git config core.hooksPath .githooks

.PHONY: pin
pin: ## Pin dependencies
	@opam pin add melange "https://github.com/melange-re/melange.git#a01735398b5df5b90f0a567dd660847ae0e9da48" -y
	@opam pin add reason-react-ppx.dev "https://github.com/reasonml/reason-react.git#0ccff71796b60d6c32ab6cf01e31beccca4698b9" -y
	@opam pin add reason-react.dev "https://github.com/reasonml/reason-react.git#0ccff71796b60d6c32ab6cf01e31beccca4698b9" -y


.PHONY: create-switch
create-switch: ## Create opam switch
	@opam switch create . 5.1.0 --deps-only --with-test -y

.PHONY: install
install: create-switch pin ## Install dependencies

.PHONY: init
init: setup-githooks install ## Create a local dev enviroment

.PHONY: ppx-test
ppx-test: ## Run ppx tests
	@$(DUNE) runtest ppx

.PHONY: ppx-test-watch
ppx-test-watch: ## Run ppx tests in watch mode
	@$(DUNE) runtest ppx --watch

.PHONY: lib-test
lib-test: ## Run library tests
	@$(DUNE) exec test/test.exe

.PHONY: demo
demo: ## Run demo executable
	@$(DUNE) exec demo/index.exe

.PHONY: subst
subst: ## Run dune substitute
	@$(DUNE) subst

.PHONY: documentation
documentation: ## Generate odoc documentation
# Since odoc fails when 2 wrapped libraries have the same name,
# we need to ignore "promise" by adding an underscode in front of it
	@mv $(CURDIR)/packages/promise $(CURDIR)/packages/_promise
	@$(DUNE) build --root . @doc
# and rollback the rename, so the build continues to work
	@mv $(CURDIR)/packages/_promise $(CURDIR)/packages/promise

# Because if the hack above, we can't have watch mode
## .PHONY: documentation-watch
## documentation-watch: ## Generate odoc documentation
##	@$(DUNE) build --root . -w @doc

.PHONY: documentation-serve
documentation-serve: documentation ## Open odoc documentation with default web browser
	@open _build/default/_doc/_html/index.html

$(opam_file): dune-project ## Update the package dependencies when new deps are added to dune-project
	@$(DUNE) build @install
	@opam install . --deps-only --with-test # Install the new dependencies

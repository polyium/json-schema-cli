# ====================================================================================
# Project Specific Globals
# ------------------------------------------------------------------------------------
#
# - It's assumed the $(name) is the same literal as the compiled binary or executable.
# - Override the defaults if not available in a pipeline's environment variables.
#
# - Default GitHub environment variables: https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/store-information-in-variables#default-environment-variables
#

name := json-schema-cli
ifdef CI_PROJECT_NAME
    override name = $(CI_PROJECT_NAME)
endif

homebrew-tap := polyium/json-schema-cli
ifdef CI_HOMEBREW_TAP
    override homebrew-tap = $(CI_HOMEBREW_TAP)
endif

# homebrew-tap-repository := gitlab.com:example-organization/group-1/group-2/homebrew-taps.git
homebrew-tap-repository := https://github.com/polyium/homebrew-taps
ifdef CI_HOMEBREW_TAP_REPOSITORY
    override homebrew-tap-repository = $(CI_HOMEBREW_TAP_REPOSITORY)
endif

type := patch
ifdef CI_RELEASE_TYPE
    override type = $(CI_RELEASE_TYPE)
endif

type-title = $(shell printf "%s" "$(shell tr '[:lower:]' '[:upper:]' <<< "$(type)")")

ifeq (,$(shell go env GOBIN))
    GOBIN=$(shell go env GOPATH)/bin
else
    GOBIN=$(shell go env GOBIN)
endif

# Setting SHELL to bash allows bash commands to be executed by recipes.
SHELL = /usr/bin/env bash -o pipefail

.SHELLFLAGS = -ec

# ====================================================================================
# Colors
# ------------------------------------------------------------------------------------

black        := $(shell printf "\033[30m")
black-bold   := $(shell printf "\033[30;1m")
red          := $(shell printf "\033[31m")
red-bold     := $(shell printf "\033[31;1m")
green        := $(shell printf "\033[32m")
green-bold   := $(shell printf "\033[32;1m")
yellow       := $(shell printf "\033[33m")
yellow-bold  := $(shell printf "\033[33;1m")
blue         := $(shell printf "\033[34m")
blue-bold    := $(shell printf "\033[34;1m")
magenta      := $(shell printf "\033[35m")
magenta-bold := $(shell printf "\033[35;1m")
cyan         := $(shell printf "\033[36m")
cyan-bold    := $(shell printf "\033[36;1m")
white        := $(shell printf "\033[37m")
white-bold   := $(shell printf "\033[37;1m")

faint         := $(shell printf "\033[2m")
italic         := $(shell printf "\033[3m")
reset        := $(shell printf "\033[0m")

# ====================================================================================
# Logger
# ------------------------------------------------------------------------------------
#
# - Variables are declared with $@_ prefix that makes them "local" to the rule.
#

define format
    $(eval $@_COLOR = $(1))
    $(eval $@_RESET = $(2))
    $(eval $@_MESSAGE = $(3))

    @echo "${$@_COLOR}${$@_MESSAGE}${$@_RESET}"
endef

define info
    @$(call format,"$(blue-bold)","$(reset)","$(1)")
endef

define trace
    @$(call format,"$(faint)","$(reset)","$(1)")
endef

define step
    @$(call trace," - $(1)")
endef

# ====================================================================================
# Utility Command(s)
# ------------------------------------------------------------------------------------

url = $(shell git config --get remote.origin.url | sed -r 's/.*(\@|\/\/)(.*)(\:|\/)([^:\/]*)\/([^\/\.]*)\.git/https:\/\/\2\/\4\/\5/')

repository = $(shell basename -s .git $(shell git config --get remote.origin.url))
organization = $(shell git remote -v | grep "(fetch)" | sed 's/.*\/\([^ ]*\)\/.*/\1/')
package = $(shell git remote -v | grep "(fetch)" | sed 's/^origin[[:space:]]*//; s/[[:space:]]*(fetch)$$//' | sed 's/https:\/\///; s/git@//; s/\.git$$//; s/:/\//' | sed -E 's|^ssh/+||')

version = $(shell [ -f VERSION ] && head VERSION || echo "0.0.0")

major      		= $(shell echo $(version) | sed "s/^\([0-9]*\).*/\1/")
minor      		= $(shell echo $(version) | sed "s/[0-9]*\.\([0-9]*\).*/\1/")
patch      		= $(shell echo $(version) | sed "s/[0-9]*\.[0-9]*\.\([0-9]*\).*/\1/")

zero = $(shell printf "%s" "0")

major-upgrade 	= $(shell expr $(major) + 1).$(zero).$(zero)
minor-upgrade 	= $(major).$(shell expr $(minor) + 1).$(zero)
patch-upgrade 	= $(major).$(minor).$(shell expr $(patch) + 1)

dirty = $(shell git diff --quiet)
dirty-contents 			= $(shell git diff --shortstat 2>/dev/null 2>/dev/null | tail -n1)

# ====================================================================================
# AWS
# ------------------------------------------------------------------------------------

account-id 			= $(shell aws sts get-caller-identity --no-paginate --no-cli-pager | jq -r ".Account")
region 		= $(shell aws configure get region)

# ====================================================================================
# Default
# ------------------------------------------------------------------------------------

all :: pre-requisites

.PHONY: example-pip-install-command
example-pip-install-command:
	@echo "$(italic)    python3 -m venv .venv$(reset)"
	@echo "$(italic)    source .venv/bin/activate$(reset)"
	@echo "$(italic)    python -m pip install \".[all]\"$(reset)"

# ====================================================================================
# Pre-Requisites
# ------------------------------------------------------------------------------------

.PHONY: pre-requisites
pre-requisites:
	@echo "$(blue-bold)Checking Requirements ...$(reset)"
	@command -v brew 2>&1> /dev/null || bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	@$(call step,"Verified Homebrew Installation")
	@command -v pre-commit 2>&1> /dev/null || brew install pre-commit && pre-commit install 2>&1> /dev/null && pre-commit install-hooks 2>&1> /dev/null
	@$(call step,"Verified Pre-Commit Hooks")
	@if [[ -z "${VIRTUAL_ENV}" ]]; then \
    	echo ""; \
		echo "$(red-bold)Please Activate a Python Virtual Environment$(reset)"; \
		echo ""; \
		echo "$(italic)    python3 -m venv .venv$(reset)" ; \
		echo "$(italic)    source .venv/bin/activate$(reset)" ; \
		echo "$(italic)    python -m pip install --editable \".[all]\"$(reset)" ; \
		echo ""; \
		exit 1; \
	fi
	@$(call step,"Verified Virtual Environment") && echo

# ====================================================================================
# Brew
# ------------------------------------------------------------------------------------

.PHONY: uninstall
uninstall:
	@echo "$(blue-bold)Uninstalling Package$(reset): ($(name))"
	@rm -rf /opt/homebrew/etc/gitconfig
	@brew uninstall $(name) --force || true
	@brew untap $(homebrew-tap) --force || true
	@$(call step,"Uninstalled & Untapped") && echo

.PHONY: install
install: uninstall
	@echo "$(blue-bold)Installing Package$(reset): ($(name))"
	@brew tap $(homebrew-tap) $(homebrew-tap-repository) --force-auto-update --force
	@brew update
	@brew install $(name)
	@echo "$(green-bold)Successfully Installed Package$(reset)" && echo

.PHONY: overwrite-private-homebrew-download-strategy
overwrite-private-homebrew-download-strategy:
	@echo "$(blue-bold)Overwriting Private Homebrew Download Strategy$(reset): ($(name))"
	@rm -rf ./.upstreams
	@sed -i -e "s/using: GitDownloadStrategy/using: GitDownloadStrategy, tag: \"$(tag)\"/g" ./dist/homebrew/Formula/$(name).rb
	@mkdir -p .upstreams
	@git clone $(homebrew-tap-repository) ./.upstreams/homebrew-taps
	@rm -f ./.upstreams/homebrew-taps/Formula/$(name).rb
	@cp -f ./dist/homebrew/Formula/$(name).rb ./.upstreams/homebrew-taps/Formula/$(name).rb
	@cd ./.upstreams/homebrew-taps && git add ./Formula/$(name).rb && git commit -m "[Chore] - Overwrote URL + Tag" && git push -u origin main
	@cd "$(git rev-parse --show-toplevel)"
	@rm -rf ./.upstreams
	@echo "$(green-bold)Successfully Changed Upstream$(reset)" && echo

# ====================================================================================
# Testing
# ------------------------------------------------------------------------------------

unit-testing:
	@printf "$(blue-bold)%s$(reset)\n" "Running Unit Test(s)$(reset) ..." && echo
	@python -m pytest && echo
	@$(call step,"Complete") && echo

# ====================================================================================
# Git + Versioning
# ------------------------------------------------------------------------------------

.PHONY: git-check-tree
git-check-tree:
	@echo "$(blue-bold)"Checking Working Tree"$(reset) ..." && echo
	@if ! git diff --quiet --exit-code; then \
    	git status ; \
    	echo "" ; \
		echo "$(red-bold)Dirty Working Tree$(reset) - Commit Changes and Try Again"; \
		echo "" ; \
		exit 1; \
	fi
	@$(call step, "Clean Working Tree") && echo

.PHONY: bump
bump: pre-requisites unit-testing git-check-tree
	@echo "$(green-bold)Bumping Version: \"$(yellow-bold)$(package)$(reset)\" - $(white-bold)$(version)$(reset)"$(reset)"
	@echo "$($(type)-upgrade)" > VERSION
	@$(call step, "Updated Version Lock") && echo

.PHONY: commit
commit: bump
	@echo "$(blue-bold)Tag-Release$(reset) ($(type-title)): $(yellow-bold)$(package)$(reset) - $(white-bold)$(version)$(reset)"
	@git add VERSION
	@git commit --message "Chore ($(type-title)) - Tag Release: $(version)"
	@git push --set-upstream origin main
	@git tag "v$(version)"
	@git push origin "v$(version)"
	@$(call step,"Pushed Semantic Tag Version") && echo

.PHONY: release-patch
release-patch: bump

.PHONY: release-minor
release-minor: bump

.PHONY: release-major
release-major: bump

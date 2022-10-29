#/////////////////////////////////////////////////////////////////////////////#
#
# Copyright (c) 2022, Joshua Ford
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#/////////////////////////////////////////////////////////////////////////////#
#
# PREAMBLE
#//////////////////////////////////////////////////////////////////////////////
#
MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
.DELETE_ON_ERROR:
.SUFFIXES:

# VARIABLES, CONFIG, & SETTINGS
#//////////////////////////////////////////////////////////////////////////////
#
REGISTRY := ghcr.io
REPOSITORY := stonesoupkitchen/github-publisher

DATE       = $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
GIT_COMMIT = $(shell git rev-parse HEAD)
GIT_SHA    = $(shell git rev-parse --short HEAD)
GIT_BRANCH = $(shell git rev-parse --abbrev-ref HEAD)
GIT_TAG    = $(shell git describe --tags --abbrev=0 --exact-match 2>/dev/null)

VERSION ?= ${GIT_TAG}

LABELS :=
LABELS += --label maintainer=joshua.ford@proton.me
LABELS += --label org.opencontainers.image.created=$(DATE)
LABELS += --label org.opencontainers.image.title="stonesoupkitchen/github-publisher"
LABELS += --label org.opencontainers.image.description="Create and publish releases to GitHub"
LABELS += --label org.opencontainers.image.url="https://github.com/stonesoupkitchen/container-github-publisher"
LABELS += --label org.opencontainers.image.source="https://github.com/stonesoupkitchen/container-github-publisher"
LABELS += --label org.opencontainers.image.revision=$(GIT_COMMIT)

TAGS :=
TAGS += -t $(REGISTRY)/$(REPOSITORY):latest
TAGS += -t $(REGISTRY)/$(REPOSITORY):sha-${GIT_SHA}
ifneq ($(VERSION),)
	TAGS += -t $(REGISTRY)/$(REPOSITORY):${VERSION}
endif

# Helper variable to identify all images built by our container builder.
# Used in the `clean` target to remove all build artifacts.
#
CACHE = $(shell docker images --format '{{.Repository}}:{{.Tag}}' | \
   	grep "$(REGISTRY)/$(REPOSITORY)")

# TASKS
#//////////////////////////////////////////////////////////////////////////////
#
.PHONY: help
help: ## Show this help message.
	@grep -E '^[a-zA-Z_/-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "; printf "\nUsage:\n"}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo

.PHONY: clean
clean: ## Remove the built Docker image and its layers.
	@echo
	@echo "==> Removing stale images <=="
	docker rmi $(CACHE)

.PHONY: lint
lint: ## Run hadolint.
	@echo
	@echo "==> Running hadolint <=="
	@hadolint Dockerfile

.PHONY: build
build: ## Build the container.
	@echo
	@echo "==> Building container <=="
	@docker build ${TAGS} ${LABELS} .

.PHONY: release
release: build ## Release the container to a public registry.
	@echo
	@echo "==> Pushing container to registry <=="
	@docker image push --all-tags $(REGISTRY)/$(REPOSITORY)


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

# VARIABLES, CONFIG, & SETTINGS
#//////////////////////////////////////////////////////////////////////////////
#
# BUILDER:         The path to the binary used to build and push the image.
# HADOLINT:        The path to the hadolint binary.
# IMAGE:           The fully-qualified name of the container.
# IMAGE_NAMESPACE: The leading namespace of the container image.
# IMAGE_NAME:      The name of the container image.
# IMAGE_TAG:       The release tag of the built container image.
# REGISTRY:        The Docker registry to which to push the built image.
# SNAPSHOT_TAG:    A temporary tag for containers staged for release.
#
BUILDER := docker
HADOLINT := hadolint
IMAGE = $(REGISTRY)/$(IMAGE_NAMESPACE)/$(IMAGE_NAME)
IMAGE_NAMESPACE := stonesoupkitchen
IMAGE_NAME := github-publisher
IMAGE_TAG := 0.2.1
REGISTRY := ghcr.io
SNAPSHOT_TAG = $(IMAGE_TAG)-SNAPSHOT-$(GIT_REF)

# Arguments used to pass to the BUILDER when making containers.
#
# BUILD_DATE: The build date of the container in RFC 3339 format.
# GIT_REF:    The current Git commit sha1 of the repository.
#
BUILD_DATE = $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
GIT_REF = $(shell git rev-parse --verify HEAD)

# Helper variable to identify all images built by our container builder.
# Used in the `clean` target to remove all build artifacts.
#
CACHE = $(shell $(BUILDER) images --format '{{.Repository}}:{{.Tag}}' | \
   	grep "$(IMAGE_NAMESPACE)/$(IMAGE_NAME)")


# TASKS
#//////////////////////////////////////////////////////////////////////////////

.DEFAULT_GOAL := help

.PHONY: hadolint
hadolint: ## Run hadolint.
	@$(HADOLINT) Dockerfile

.PHONY: build
build: ## Build the container.
	$(BUILDER) build \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg GIT_REF=$(GIT_REF) \
		-t $(IMAGE):$(SNAPSHOT_TAG) .

.PHONY: release
release: build ## Release the container to a public registry.
	$(BUILDER) tag $(IMAGE):$(SNAPSHOT_TAG) $(IMAGE):$(IMAGE_TAG)
	$(BUILDER) tag $(IMAGE):$(SNAPSHOT_TAG) $(IMAGE):latest
	$(BUILDER) push $(IMAGE):$(IMAGE_TAG)
	$(BUILDER) push $(IMAGE):latest

.PHONY: clean
clean: ## Remove the built Docker image and its layers.
	$(BUILDER) rmi $(CACHE)

.PHONY: help
help: ## Show this help message.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "; printf "\nUsage:\n"}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo


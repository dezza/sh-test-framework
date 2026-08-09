# Makefile: GNU Make; target: Linux

TEST_FRAMEWORK ?= deps/test-framework
TEST_FRAMEWORK_TEST_DIR ?= tests
KCOV_OUTPUT_DIR ?= output/coverage
CONTAINER_ENGINE ?= podman
CONTAINER_RUN_ARGS ?=
KCOV_IMAGE ?= docker.io/kcov/kcov:latest-alpine

ifeq ($(abspath $(lastword $(MAKEFILE_LIST))),$(abspath $(CURDIR)/Makefile))
.DEFAULT_GOAL := ci

.PHONY: ci

ci:
	CONTAINER_ENGINE="$(CONTAINER_ENGINE)" \
		CONTAINER_RUN_ARGS="$(CONTAINER_RUN_ARGS)" \
		KCOV_IMAGE="$(KCOV_IMAGE)" \
		KCOV_OUTPUT_DIR="$(KCOV_OUTPUT_DIR)" \
		./sh/container/run.sh /workspace/coverage.sh examples

else
TEST_FRAMEWORK_DEFAULT_GOAL := $(.DEFAULT_GOAL)

.PHONY: test-framework-test test-framework-coverage \
	test-framework-check-submodule test-framework-update

test-framework-test test-framework-coverage: export CONTAINER_ENGINE := \
	$(CONTAINER_ENGINE)
test-framework-test test-framework-coverage: export CONTAINER_RUN_ARGS := \
	$(CONTAINER_RUN_ARGS)
test-framework-test test-framework-coverage: export KCOV_IMAGE := \
	$(KCOV_IMAGE)
test-framework-test test-framework-coverage: export KCOV_OUTPUT_DIR := \
	$(KCOV_OUTPUT_DIR)

test-framework-test:
	"$(TEST_FRAMEWORK)/sh/test/run.sh" "$(TEST_FRAMEWORK)" \
		"$(TEST_FRAMEWORK_TEST_DIR)"

test-framework-coverage:
	"$(TEST_FRAMEWORK)/coverage.sh" "$(TEST_FRAMEWORK_TEST_DIR)"

test-framework-check-submodule:
	@"$(TEST_FRAMEWORK)/sh/submodule/check.sh" "$(TEST_FRAMEWORK)"

test-framework-update: test-framework-check-submodule
	@"$(TEST_FRAMEWORK)/sh/submodule/update.sh" "$(TEST_FRAMEWORK)"

.DEFAULT_GOAL := $(TEST_FRAMEWORK_DEFAULT_GOAL)
endif

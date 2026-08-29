# Makefile: GNU Make; target: Linux

# Parent-repository overrides:
# TFW_TESTS: test directory, default tests/.
# TFW_COV: coverage output directory.
# TFW_COV_KEEP: retain coverage tmp output.
# TFW_CONT_CMD: override container binary (podman or docker)
# TFW_CONT_ARGS: extra container arguments.
# TFW_CONT_IMG: coverage container image.
# TFW_MODULE: module URL or local path for updates.

TFW_DIR ?= $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
TFW_TESTS ?= tests
TFW_MODULE ?=
TFW_CONT_CMD ?= $(shell command -v podman 2>/dev/null || command -v docker 2>/dev/null)

export TFW_DIR TFW_CONT_CMD TFW_CONT_ARGS TFW_CONT_IMG TFW_COV TFW_COV_KEEP

ifeq ($(abspath $(lastword $(MAKEFILE_LIST))),$(abspath $(CURDIR)/Makefile))
.DEFAULT_GOAL := ci

.PHONY: ci

ci:
	@if command -v kcov >/dev/null 2>&1 || \
		command -v "$(TFW_CONT_CMD)" >/dev/null 2>&1; then \
		./src/coverage.sh examples; \
	else \
		printf '%s\n' 'WARNING: kcov and container engine unavailable; skipping coverage.' >&2; \
		./src/run.sh examples; \
	fi
else
TFW_DEFAULT_GOAL := $(.DEFAULT_GOAL)

.PHONY: test coverage update tfw-test tfw-cov tfw-update

test: tfw-test
coverage: tfw-cov
update: tfw-update

tfw-test:
	@if command -v kcov >/dev/null 2>&1 || \
		command -v "$(TFW_CONT_CMD)" >/dev/null 2>&1; then \
		"$(TFW_DIR)/src/coverage.sh" "$(TFW_TESTS)"; \
	else \
		printf '%s\n' 'WARNING: kcov and container engine unavailable; skipping coverage.' >&2; \
		"$(TFW_DIR)/src/run.sh" "$(TFW_TESTS)"; \
	fi

tfw-cov:
	"$(TFW_DIR)/src/coverage.sh" "$(TFW_TESTS)"

tfw-update:
	@sh "$(TFW_DIR)/src/check-module.sh" "$(TFW_DIR)"
	@sh "$(TFW_DIR)/src/update-module.sh" \
		"$(TFW_DIR)" "$(TFW_MODULE)"

.DEFAULT_GOAL := $(TFW_DEFAULT_GOAL)
endif

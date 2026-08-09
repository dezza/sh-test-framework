#!/bin/sh
set -eu

TEST_FRAMEWORK_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
export TEST_FRAMEWORK_DIR

. "$TEST_FRAMEWORK_DIR/run.sh" "$@"

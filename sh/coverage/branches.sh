#!/bin/sh
set -eu

framework_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
fixture_dir=$framework_dir/sh/coverage/fixtures
branch_tmp=$(mktemp -d "${TMPDIR:-/tmp}/test-framework-coverage.XXXXXX")

trap 'rm -rf -- "$branch_tmp"' EXIT HUP INT TERM
mkdir -p "$branch_tmp/empty" "$branch_tmp/tmp"

TEST_FRAMEWORK_DIR=$framework_dir
TMPDIR=$branch_tmp/tmp
NO_COLOR=1
export TEST_FRAMEWORK_DIR TMPDIR NO_COLOR

run_tests() (
  . "$framework_dir/run.sh" "$@"
)

run_without_framework_override() (
  unset TEST_FRAMEWORK_DIR
  . "$framework_dir/run.sh" "$branch_tmp/empty"
)

expect_status() {
  expected=$1
  shift

  set +e
  "$@" >/dev/null 2>&1
  actual=$?
  set -e
  [ "$actual" -eq "$expected" ]
}

run_tests --help >/dev/null
expect_status 1 run_without_framework_override
expect_status 1 run_tests "$branch_tmp/empty"
expect_status 1 run_tests "$fixture_dir/pass" missing.sh
expect_status 1 run_tests "$fixture_dir/fail"
run_tests "$fixture_dir/pass" test-pass.sh >/dev/null
run_tests "$fixture_dir/pass" "$fixture_dir/pass/test-pass.sh" >/dev/null

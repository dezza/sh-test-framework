#!/bin/sh
set -eu

framework_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
branch_tmp=$(mktemp -d "${TMPDIR:-/tmp}/test-framework-coverage.XXXXXX")

trap 'rm -rf -- "$branch_tmp"' EXIT HUP INT TERM
mkdir -p "$branch_tmp/empty" "$branch_tmp/tmp"

TFW_DIR=$framework_dir
TEST_FRAMEWORK_DIR=$framework_dir
TMPDIR=$branch_tmp/tmp
NO_COLOR=1
export TFW_DIR TEST_FRAMEWORK_DIR TMPDIR NO_COLOR

run_tests() (
  . "$framework_dir/src/run.sh" "$@"
)

run_without_framework_override() (
  unset TFW_DIR TEST_FRAMEWORK_DIR
  "$framework_dir/src/run.sh" "$branch_tmp/empty"
)

run_with_bad_tmp() (
  TMPDIR=$branch_tmp/not-dir
  export TMPDIR
  . "$framework_dir/src/run.sh" "$fixture_dir" pass.sh
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

touch "$branch_tmp/not-dir"

run_tests --help >/dev/null
expect_status 2 run_tests --junit
expect_status 1 run_without_framework_override
expect_status 1 run_tests "$branch_tmp/empty"
expect_status 1 run_tests "$fixture_dir" missing.sh
expect_status 1 run_tests "$fixture_dir" fail.sh
expect_status 1 run_tests --junit "$branch_tmp/junit.xml" "$fixture_dir" fail.sh
expect_status 1 run_tests --junit "$branch_tmp/missing/junit.xml" \
  "$fixture_dir" pass.sh
expect_status 1 run_with_bad_tmp
NO_COLOR= TFW_FORCE_COLOR=1 \
  run_tests "$fixture_dir" pass.sh >/dev/null
run_tests "$fixture_dir" pass.sh >/dev/null
run_tests "$fixture_dir" "$fixture_dir/pass.sh" >/dev/null

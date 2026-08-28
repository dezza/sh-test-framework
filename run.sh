#!/bin/sh
set -eu

usage() {
  printf '%s\n' \
    "Usage: $0 [--junit FILE] [TEST-DIRECTORY] [TEST-FILE ...]" \
    'Discover and run test-*.sh files.'
}

TEST_JUNIT=
case ${1-} in
  -h|--help)
    usage; exit 0 ;;
  --junit)
    [ "$#" -ge 2 ] && [ -n "$2" ] || {
      usage >&2; exit 2
    }
    TEST_JUNIT=$2
    shift 2 ;;
esac

framework_dir=${TEST_FRAMEWORK_DIR:-}
if [ -z "$framework_dir" ]; then
  framework_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
fi
test_dir=${1:-.}
[ "$#" -eq 0 ] || shift

test_dir=$(CDPATH= cd -- "$test_dir" && pwd)
TEST_PROJECT_DIR=${TEST_PROJECT_DIR:-$(CDPATH= cd -- "$test_dir/.." && pwd)}
TEST_FRAMEWORK_DIR=$framework_dir
export TEST_PROJECT_DIR TEST_FRAMEWORK_DIR

if [ -n "$TEST_JUNIT" ]; then
  TEST_JUNIT_DATA=$(mktemp "${TMPDIR:-/tmp}/test-framework-junit.XXXXXX")
  export TEST_JUNIT TEST_JUNIT_DATA
  trap 'rm -f -- "$TEST_JUNIT_DATA"' 0
fi

. "$framework_dir/testlib.sh"

if [ "$#" -gt 0 ]; then
  for test_name; do
    case $test_name in
      /*) test_file=$test_name ;;
      *) test_file=$test_dir/$test_name ;;
    esac

    [ -f "$test_file" ] || {
      printf '%s: test file not found: %s\n' "$0" "$test_file" >&2
      exit 1
    }

    . "$test_file"
  done
else
  found=
  for test_file in "$test_dir"/test-*.sh; do
    [ -f "$test_file" ] || continue
    found=1
    . "$test_file"
  done

  [ -n "$found" ] || {
    printf '%s: no test-*.sh files found in %s\n' "$0" "$test_dir" >&2
    exit 1
  }
fi

test_finish

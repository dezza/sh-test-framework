#!/bin/sh
set -eu

usage() {
  printf '%s\n' \
    "Usage: $0 [TEST-DIRECTORY] [TEST-FILE ...]" \
    'Discover and run test-*.sh files.'
}

case ${1-} in
  -h|--help)
    usage; exit 0 ;;
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

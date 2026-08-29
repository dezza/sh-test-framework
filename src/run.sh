#!/bin/sh
set -eu

usage() {
  printf '%s\n' \
    "Usage: $0 [--junit FILE] [TEST-DIRECTORY] [TEST-FILE ...]" \
    'Discover and run test-*.sh files.'
}

TFW_JUNIT=
case ${1-} in
  -h|--help)
    usage; exit 0 ;;
  --junit)
    [ "$#" -ge 2 ] && [ -n "$2" ] || {
      usage >&2; exit 2
    }
    TFW_JUNIT=$2
    shift 2 ;;
esac

framework_dir=${TFW_DIR:-}
if [ -z "$framework_dir" ]; then
  framework_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
else
  framework_dir=$(CDPATH= cd -- "$framework_dir" && pwd)
fi
test_dir=${1:-.}

if [ "$#" -gt 0 ]; then
  shift
fi

test_dir=$(CDPATH= cd -- "$test_dir" && pwd)
TFW_PROJECT_DIR=${TFW_PROJECT_DIR:-$(pwd)}
TFW_DIR=$framework_dir

export TFW_PROJECT_DIR TFW_DIR

if [ -n "$TFW_JUNIT" ]; then
  TFW_JUNIT_DATA=$(mktemp "${TMPDIR:-/tmp}/test-framework-junit.XXXXXX")
  export TFW_JUNIT TFW_JUNIT_DATA
  trap 'rm -f -- "$TFW_JUNIT_DATA"' 0
fi

. "$framework_dir/src/testlib.sh"

if [ "$#" -gt 0 ]; then
  for test_name; do
    case $test_name in
      /*) test_file=$test_name ;;
      *) test_file=$test_dir/$test_name ;;
    esac

    if ! [ -f "$test_file" ]; then
      printf '%s: test file not found: %s\n' "$0" "$test_file" >&2
      exit 1
    fi

    . "$test_file"
  done
else
  found=
  for test_file in "$test_dir"/test-*.sh; do
    if ! [ -f "$test_file" ]; then
      continue
    fi

    found=1
    . "$test_file"
  done

  if [ -z "$found" ]; then
    printf '%s: no test-*.sh files found in %s\n' "$0" "$test_dir" >&2
    exit 1
  fi
fi

test_finish

#!/bin/sh
set -eu

framework_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
framework_root=$(CDPATH= cd -- "$framework_dir/.." && pwd)
project_dir=$(pwd)

case ${1-} in
  --junit) test_dir=${3:-.} ;;
  *) test_dir=${1:-.} ;;
esac
test_dir=$(CDPATH= cd -- "$test_dir" && pwd)

cleanup_dir=
if [ -n "${TFW_COV-}" ]; then
  output_dir=$TFW_COV
  temporary=${TFW_COV_TEMP:-0}
else
  cleanup_dir=$(mktemp -d "${TMPDIR:-/tmp}/tfw-coverage.XXXXXX")
  output_dir=$cleanup_dir
  temporary=1

  if [ -n "${TFW_COV_KEEP-}" ]; then
    printf 'COVERAGE DIR: %s\n' "$cleanup_dir" >&2
  else
    trap 'rm -rf -- "$cleanup_dir"' EXIT HUP INT TERM
  fi
fi

output_name=${output_dir##*/}
output_parent=${output_dir%/*}

case $output_name in
  ''|.|..)
    printf '%s: unsafe coverage output: %s\n' "$0" "$output_dir" >&2; exit 1 ;;
esac

if [ -z "$output_parent" ]; then
  output_parent=/
elif [ "$output_parent" = "$output_dir" ]; then
  output_parent=.
fi

mkdir -p -- "$output_parent"
output_parent=$(CDPATH= cd -- "$output_parent" && pwd)

if [ "$output_parent" = / ]; then
  output_dir=/$output_name
else
  output_dir=$output_parent/$output_name
fi
exclude_paths=$output_dir

if [ "$test_dir" != "$project_dir" ]; then
  exclude_paths=$exclude_paths,$test_dir
fi

if [ "$project_dir" = "$framework_root" ]; then
  exclude_paths=$exclude_paths,$framework_dir/coverage-run.sh
else
  exclude_paths=$exclude_paths,$framework_dir
fi

if [ "$temporary" -eq 0 ]; then
  case $output_dir in
    "$project_dir"/*) ;;
    *)
      printf '%s: coverage output must be inside project: %s\n' \
        "$0" "$output_dir" >&2; exit 1;;
  esac
fi

rm -rf -- "$output_dir"
mkdir -p -- "$output_dir"

main_dir=$output_dir/main
kcov \
  --bash-method=DEBUG \
  --bash-parser=/bin/bash \
  --include-path="$project_dir" \
  --exclude-path="$exclude_paths" \
  "$main_dir" "$framework_dir/run.sh" "$@"

report_dir=$main_dir
if [ "$project_dir" = "$framework_root" ]; then
  branch_dir=$output_dir/branches
  core_files=$framework_dir/run.sh,$framework_dir/testlib.sh

  kcov \
    --bash-method=DEBUG \
    --bash-parser=/bin/bash \
    --include-pattern="$core_files" \
    "$branch_dir" "$framework_root/tests/coverage/branches.sh"

  report_dir=$output_dir/merged
  kcov --merge --include-pattern="$core_files" \
    "$report_dir" "$main_dir" "$branch_dir"
fi

set -- "$report_dir"/*/coverage.json
report=$1

if [ ! -f "$report" ]; then
  printf '%s: kcov did not produce coverage.json\n' "$0" >&2
  exit 1
fi

awk -F '"' -f "$framework_dir/coverage-report.awk" "$report"

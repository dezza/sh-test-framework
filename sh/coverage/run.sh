#!/bin/sh
set -eu

framework_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
project_dir=$(pwd)
output_dir=${KCOV_OUTPUT_DIR:-$framework_dir/coverage}
output_name=${output_dir##*/}
output_parent=${output_dir%/*}

case $output_name in
  ''|.|..)
    printf '%s: unsafe coverage output: %s\n' "$0" "$output_dir" >&2; exit 1 ;;
esac

[ "$output_parent" != "$output_dir" ] || output_parent=.
mkdir -p -- "$output_parent"
output_parent=$(CDPATH= cd -- "$output_parent" && pwd)
output_dir=$output_parent/$output_name
exclude_paths=$output_dir
if [ "$project_dir" = "$framework_dir" ]; then
  exclude_paths=$exclude_paths,$framework_dir/sh/coverage
else
  exclude_paths=$exclude_paths,$framework_dir
fi

case $output_dir in
  "$project_dir"/*) ;;
  *)
    printf '%s: coverage output must be inside project: %s\n' \
      "$0" "$output_dir" >&2; exit 1;;
esac

rm -rf -- "$output_dir"
mkdir -p -- "$output_dir"

main_dir=$output_dir/main
kcov \
  --bash-method=DEBUG \
  --bash-parser=/bin/bash \
  --include-path="$project_dir" \
  --exclude-path="$exclude_paths" \
  "$main_dir" "$framework_dir/sh/coverage/test.sh" "$@"

report_dir=$main_dir
if [ "$project_dir" = "$framework_dir" ]; then
  branch_dir=$output_dir/branches
  core_files=$framework_dir/run.sh,$framework_dir/testlib.sh
  kcov \
    --bash-method=DEBUG \
    --bash-parser=/bin/bash \
    --include-pattern="$core_files" \
    "$branch_dir" "$framework_dir/sh/coverage/branches.sh"

  report_dir=$output_dir/merged
  kcov --merge "$report_dir" "$main_dir" "$branch_dir"
fi

set -- "$report_dir"/*/coverage.json
report=$1

if [ ! -f "$report" ]; then
  printf '%s: kcov did not produce coverage.json\n' "$0" >&2
  exit 1
fi

awk -F '"' -f "$framework_dir/sh/coverage/report.awk" "$report"

#!/bin/sh
set -eu

usage() {
  cat <<-EOF_USAGE
	Usage: $0 [TEST-DIRECTORY] [TEST-FILE ...]

	Run the test framework under kcov. Coverage output is written to coverage/.
	Set KCOV_OUTPUT_DIR to use another directory.
	EOF_USAGE
}

case ${1-} in
  -h|--help)
    usage; exit 0 ;;
esac

framework_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ -z "${KCOV_CONTAINER-}" ] && command -v kcov >/dev/null 2>&1; then
  exec "$framework_dir/sh/coverage/run.sh" "$@"
fi

: "${KCOV_OUTPUT_DIR:=output/coverage}"
export KCOV_OUTPUT_DIR

project_dir=$(pwd)
case $framework_dir in
  "$project_dir") relative= ;;
  "$project_dir"/*) relative=/${framework_dir#"$project_dir"/} ;;
  *)
    printf '%s: framework must be inside project: %s\n' \
      "$0" "$project_dir" >&2; exit 1 ;;
esac

CONTAINER_PROJECT_DIR=$project_dir
export CONTAINER_PROJECT_DIR
exec "$framework_dir/sh/container/run.sh" \
  "/workspace$relative/sh/coverage/run.sh" "$@"

#!/bin/sh
set -eu

usage() {
  cat <<-EOF_USAGE
	Usage: $0 [--junit FILE] [TEST-DIRECTORY] [TEST-FILE ...]

	Run the test framework under kcov. Coverage output is temporary by default.
	Set TFW_COV to retain reports in another directory.
	EOF_USAGE
}

case ${1-} in
  -h|--help)
    usage; exit 0 ;;
esac

source_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
framework_dir=$(CDPATH= cd -- "$source_dir/.." && pwd)

if [ -z "${TFW_CONT-}" ] && command -v kcov >/dev/null 2>&1; then
  exec sh "$source_dir/coverage-run.sh" "$@"
fi

project_dir=$(pwd)
case $framework_dir in
  "$project_dir") entrypoint=/workspace/src/coverage-run.sh ;;
  "$project_dir"/*)
    relative=/${framework_dir#"$project_dir"/}
    entrypoint=/workspace$relative/src/coverage-run.sh
    ;;
  *)
    TFW_FRAMEWORK_DIR=$framework_dir
    export TFW_FRAMEWORK_DIR
    entrypoint=/test-framework/src/coverage-run.sh
    ;;
esac

TFW_PROJECT_DIR=$project_dir
export TFW_PROJECT_DIR
exec sh "$source_dir/container.sh" "$entrypoint" "$@"

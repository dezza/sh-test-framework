#!/bin/sh
set -eu

entrypoint=$1
shift
project_dir=${TFW_PROJECT_DIR:-}

if [ -z "$project_dir" ]; then
  project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fi

engine=${TFW_CONT_CMD:-podman}
image=${TFW_CONT_IMG:-docker.io/kcov/kcov:latest-alpine}
cleanup_dir=

if [ -n "${TFW_COV-}" ]; then
  case $TFW_COV in
    "$project_dir"/*) output_dir=/workspace/${TFW_COV#"$project_dir"/} ;;
    *)
      printf '%s: coverage output must be inside project: %s\n' \
        "$0" "$TFW_COV" >&2
      exit 1
      ;;
  esac
else
  cleanup_dir=$(mktemp -d "${TMPDIR:-/tmp}/tfw-coverage.XXXXXX")
  output_dir=/coverage/data

  if [ -n "${TFW_COV_KEEP-}" ]; then
    printf 'COVERAGE DIR: %s/data\n' "$cleanup_dir" >&2
  else
    trap 'rm -rf -- "$cleanup_dir"' EXIT HUP INT TERM
  fi
fi

cd -- "$project_dir"

if [ -t 1 ]; then
  tty_args="-t -e TERM=${TERM:-xterm} -e TFW_FORCE_COLOR=1"
fi

case ${engine##*/} in
  podman) user_args=--userns=keep-id ;;
  *) user_args="--user=$(id -u):$(id -g)" ;;
esac

set -- "$image" "$entrypoint" "$@"
set -- -e TFW_COV="$output_dir" --entrypoint /bin/sh "$@"

if [ -n "${TFW_FRAMEWORK_DIR-}" ]; then
  set -- -v "$TFW_FRAMEWORK_DIR:/test-framework:Z" "$@"
fi

if [ -n "$cleanup_dir" ]; then
  set -- -e TFW_COV_TEMP=1 -v "$cleanup_dir:/coverage:Z" "$@"
fi

set -- \
  --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  -v "$project_dir:/workspace:Z" -w /workspace \
  "$@"

if "$engine" run --rm \
  $user_args \
  ${tty_args-} \
  ${TFW_CONT_ARGS-} \
  "$@"; then
  status=0
else
  status=$?
fi

exit "$status"

#!/bin/sh
set -eu

entrypoint=$1
shift
project_dir=${CONTAINER_PROJECT_DIR:-}

if [ -z "$project_dir" ]; then
  project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
fi

engine=${CONTAINER_ENGINE:-podman}
image=${KCOV_IMAGE:-docker.io/kcov/kcov:latest-alpine}
output_dir=${KCOV_OUTPUT_DIR:-output/coverage}

mkdir -p -- "$project_dir/$output_dir"
cd -- "$project_dir"

if [ -t 1 ]; then
  tty_args="-t -e TERM=${TERM:-xterm} -e TEST_FORCE_COLOR=1"
fi

case ${engine##*/} in
  podman) user_args=--userns=keep-id ;;
  *) user_args="--user=$(id -u):$(id -g)" ;;
esac

exec "$engine" run --rm \
  $user_args \
  ${tty_args-} \
  ${CONTAINER_RUN_ARGS-} \
  --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  -v "$project_dir:/workspace:Z" -w /workspace \
  -e KCOV_OUTPUT_DIR="$output_dir" \
  --entrypoint "$entrypoint" "$image" "$@"

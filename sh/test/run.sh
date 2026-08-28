#!/bin/sh
set -eu

framework_dir=$1
shift

if command -v kcov >/dev/null 2>&1 || \
  command -v "${CONTAINER_ENGINE:-podman}" >/dev/null 2>&1
then
  exec "$framework_dir/coverage.sh" "$@"
fi

exec "$framework_dir/run.sh" "$@"

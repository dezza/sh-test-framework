#!/bin/sh
set -eu

framework_dir=$1
test_dir=$2

if command -v kcov >/dev/null 2>&1 || \
  command -v "${CONTAINER_ENGINE:-podman}" >/dev/null 2>&1
then
  exec "$framework_dir/coverage.sh" "$test_dir"
fi

exec "$framework_dir/run.sh" "$test_dir"

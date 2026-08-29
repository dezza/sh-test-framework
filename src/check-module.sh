#!/bin/sh
set -eu

test_framework=$1

if [ -z "$(git -C "$test_framework" \
  rev-parse --show-superproject-working-tree 2>/dev/null)" ]; then

  printf '%s\n' \
    "error: $test_framework must be a Git submodule; see INSTALL.md" >&2
  exit 1
fi

#!/bin/sh
set -eu

test_framework=$1
source=${2-}
super=$(git -C "$test_framework" rev-parse --show-superproject-working-tree)
submodule=$(git -C "$test_framework" rev-parse --show-toplevel)

case $submodule in
  "$super"/*) relative=${submodule#"$super"/} ;;
  *)
    printf '%s: submodule is outside superproject: %s\n' \
      "$0" "$submodule" >&2; exit 1 ;;
esac

if [ -n "$(git -C "$submodule" status --porcelain)" ]; then
  printf 'Overwrite local changes in %s? [Y/n] ' "$relative"
  IFS= read -r answer || exit 1
  case $answer in
    ''|y|Y) ;;
    *) printf '%s\n' 'Cancelled.'; exit 1 ;;
  esac

  git -C "$submodule" reset --hard --quiet
  git -C "$submodule" clean -fd --quiet
fi

if [ -n "$source" ]; then
  git -C "$super" -c protocol.file.allow=always \
    submodule set-url -- "$relative" "$source"
fi

git -C "$super" -c protocol.file.allow=always \
  submodule update --init --remote --force --checkout -- "$relative"

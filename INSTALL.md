# Install

Run from the parent repository:

```sh
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || git init -b dev

git submodule add --force -b dev \
  https://codeberg.org/dza/test-framework.git \
  deps/test-framework

mkdir -p tests
```
If you prefer with local path:
```sh
# locally
git -c protocol.file.allow=always submodule add \
  -b dev \
  "$HOME/src/sh/test-framework" \
  deps/test-framework

```

Define targets in `Makefile`:

```make
-include deps/test-framework/Makefile
.PHONY: test coverage update-test-framework

test: tfw-test
update-test-framework: tfw-update
```

Test files must be named `tests/test-*.sh`. Run them with:

```sh
make test
```

The framework is only checked out in projects that run tests. A project that
includes another dependency using test-framework does not need to initialize
that dependency's test submodules.

Override locations before including the framework Makefile when needed:

```make
TFW_DIR = deps/test-framework
TFW_TESTS = path/to/tests
-include $(TFW_DIR)/Makefile
```

To update from a different module URL or local checkout, set
`TFW_MODULE` before including the framework Makefile.

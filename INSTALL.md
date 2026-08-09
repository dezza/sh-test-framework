# Install

Run from the parent repository:

```sh
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || git init -b dev

git submodule add -b dev \
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

test: test-framework-test
update-test-framework: test-framework-update
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
TEST_FRAMEWORK = deps/test-framework
TEST_FRAMEWORK_TEST_DIR = path/to/tests
-include $(TEST_FRAMEWORK)/Makefile
```

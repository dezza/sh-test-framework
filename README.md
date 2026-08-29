# Introduction

Small POSIX `sh` test framework with hooks, skips, JUnit output, and kcov coverage.

Requires: `make` (*GNU*), `POSIX sh`

Optional: `kcov` (*runs via podman/docker when N/A*)

## Use in a project

Install it as `deps/test-framework`; see [INSTALL.md](INSTALL.md).

Include its Makefile, place tests in `tests/test-*.sh`, then run:

```sh
make tfw-test
make tfw-cov
make tfw-update
```

Set `TFW_MODULE` to a module URL or local path when updating
from a source other than the submodule's configured URL.

Coverage uses `kcov` via a container image, if not installed on the host.

Coverage uses a temporary directory and cleans it after each run. Set
`TFW_COV` to write reports to a project directory, or `TFW_COV_KEEP=1`
to retain the automatic temporary report and print its path. The test target
uses coverage when kcov or the configured container engine is available.

## Write tests

```sh
#!/bin/sh

test_add() {
  assert_equal 'adds numbers' "$((1 + 1))" 2
  assert_success 'true succeeds' true
  assert_failure 'false fails' false
}

test_case 'addition' test_add
```

Available functions:

- `test_case DESCRIPTION FUNCTION`
- `assert_equal DESCRIPTION ACTUAL EXPECTED`
- `assert_status DESCRIPTION STATUS COMMAND [ARG ...]`
- `assert_success DESCRIPTION COMMAND [ARG ...]`
- `assert_failure DESCRIPTION COMMAND [ARG ...]`
- `test_tmpdir [PATH]`
- `test_skip REASON`

Optional environment variables:

- `TFW_DIR`: framework location when included from a parent Makefile
- `TFW_TESTS`: test directory; default `tests`
- `TFW_SETUP` and `TFW_TEARDOWN`: hook function names
- `TFW_TMP=1`: retain temporary files after an unexpected case failure
- `NO_COLOR=1`: disable color
- `TFW_COV`: coverage output directory
- `TFW_COV_KEEP=1`: retain automatic temporary coverage output
- `TFW_CONT=1`: force container coverage even when kcov is installed
- `TFW_CONT_CMD`: container command; default `podman`
- `TFW_CONT_IMG`: kcov image
- `TFW_CONT_ARGS`: extra container arguments
- `TFW_MODULE`: module URL or local path for `tfw-update`

`TEST_TMPDIR` remains exported as a compatibility alias for `TFW_TMPDIR`.

## Self-testing

```sh
make                     # Local CI: tests; coverage when available
make ci                  # Explicit local CI target

./src/run.sh examples        # Example tests only
./src/run.sh --junit junit.xml examples
./src/coverage.sh examples   # Coverage; local kcov or container
```

Forgejo runs the same CI through `.forgejo/workflows/ci.yml`.

For converting an existing parent Makefile, see
[migration_llm.md](migration_llm.md).

## Limits

Tests are sourced, run sequentially, and share top-level shell state.

There is no
* parallel execution
* timeout
* retry
* filtering
* mocking
* output capture

kcov measures executed lines, not test quality.

# Troubleshooting

When commands cannot be mocked extend kcov container with tools.

```dockerfile
FROM docker.io/kcov/kcov:latest-alpine
RUN apk add --no-cache foo bar baz # additions
```

# Shell test framework

Small POSIX `sh` test framework with hooks, skips, and kcov coverage.

Requires: `make` (*GNU*), `POSIX sh`

Optional: `kcov` (*runs via podman/docker when N/A*)

## Use in a project

Install it as `deps/test-framework`; see [INSTALL.md](INSTALL.md).

Include its Makefile, place tests in `tests/test-*.sh`, then run:

```sh
make test-framework-test
make test-framework-coverage
make test-framework-update
```

Coverage uses `kcov` via a container image, if not installed on the host.

Reports are written to `output/coverage` and cleaned before every run. The test target uses coverage when kcov or the configured container engine is available.

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

- `TEST_SETUP` and `TEST_TEARDOWN`: hook function names
- `TEST_KEEP_TMP=1`: retain temporary files after an unexpected case failure
- `NO_COLOR=1`: disable color
- `KCOV_OUTPUT_DIR`: coverage output directory
- `KCOV_CONTAINER=1`: force container coverage even when kcov is installed
- `CONTAINER_ENGINE`: container command; default `podman`
- `KCOV_IMAGE`: kcov image
- `CONTAINER_RUN_ARGS`: extra container arguments

## Self-testing

```sh
make                     # Local CI: tests and coverage
make ci                  # Explicit local CI target

./run.sh examples        # Example Tests only
./coverage.sh examples   # Coverage; local kcov or container
```

Forgejo runs the same CI through `.forgejo/workflows/ci.yml`.

## Limits

Tests are sourced, run sequentially, and share top-level shell state.

There is no
* parallel execution
* timeout
* retry
* filtering
* mocking
* output capture
* machine-readable test report

kcov measures executed lines, not test quality.

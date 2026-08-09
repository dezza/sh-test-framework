#!/bin/sh

TEST_FAILED=${TEST_FAILED:-0}
TEST_COUNT=${TEST_COUNT:-0}
TEST_ASSERTIONS=${TEST_ASSERTIONS:-0}
TEST_SKIPPED=${TEST_SKIPPED:-0}
TEST_KEEP_TMP=${TEST_KEEP_TMP:-}
TEST_COLOR=

if [ -z "${NO_COLOR-}${NOCOLOR-}" ] && \
  { [ -n "${TEST_FORCE_COLOR-}" ] || \
    { [ -t 1 ] && [ -n "${TERM-}" ] && [ "${TERM-}" != dumb ]; }; }; then
  TEST_COLOR=1
fi

_test_color() {
  code=$1
  shift

  if [ -z "$TEST_COLOR" ]; then
    printf '%s' "$*"
    return
  fi

  printf '\033[3%sm%s\033[0m' "$code" "$*"
}

_test_pass() {
  _test_color 2 PASS
}

_test_fail() {
  _test_color 1 FAIL
}

_test_skip_label() {
  _test_color 3 SKIP
}

_test_record_assertion() {
  printf '.\n' >>"$TEST_CASE_ASSERTIONS"
}

_test_record_failure() {
  printf '.\n' >>"$TEST_CASE_FAILURES"
}

assert_equal() {
  description=$1
  actual=$2
  expected=$3

  _test_record_assertion

  if [ "$actual" = "$expected" ]; then
    printf '  %s: %s\n' "$(_test_pass)" "$description"
    return 0
  fi

  printf '  %s: %s\n' "$(_test_fail)" "$description"
  printf '    expected: %s\n' "$expected"
  printf '    actual:   %s\n' "$actual"
  _test_record_failure
  return 0
}

assert_status() {
  description=$1
  expected=$2
  shift 2

  _test_record_assertion

  set +e
  "$@"
  actual=$?
  set -e

  if [ "$actual" -eq "$expected" ]; then
    printf '  %s: %s\n' "$(_test_pass)" "$description"
    return 0
  fi

  printf '  %s: %s\n' "$(_test_fail)" "$description"
  printf '    expected status: %s\n' "$expected"
  printf '    actual status:   %s\n' "$actual"
  _test_record_failure
  return 0
}

assert_success() {
  description=$1
  shift
  assert_status "$description" 0 "$@"
}

assert_failure() {
  description=$1
  shift

  _test_record_assertion

  set +e
  "$@"
  actual=$?
  set -e

  if [ "$actual" -ne 0 ]; then
    printf '  %s: %s\n' "$(_test_pass)" "$description"
    return 0
  fi

  printf '  %s: %s\n' "$(_test_fail)" "$description"
  printf '    expected nonzero status\n'
  printf '    actual status: 0\n'
  _test_record_failure
  return 0
}

test_tmpdir() {
  relative=${1-}

  if [ -n "$relative" ]; then
    mkdir -p "$TEST_TMPDIR/$relative" || return 1
    printf '%s\n' "$TEST_TMPDIR/$relative"
  else
    printf '%s\n' "$TEST_TMPDIR"
  fi
}

test_skip() {
  printf '%s\n' "$1" >"$TEST_CASE_SKIP_REASON"
  return 125
}

_test_line_count() {
  wc -l <"$1" | tr -d ' '
}

_test_cleanup() {
  status=$1

  if [ -z "$TEST_KEEP_TMP" ] || [ "$status" -eq 0 ]; then
    rm -rf "$TEST_TMPDIR"
  else
    printf '    temporary directory: %s\n' "$TEST_TMPDIR"
  fi

  unset TEST_TMPDIR TEST_CASE_ASSERTIONS TEST_CASE_FAILURES \
    TEST_CASE_SKIP_REASON
}

test_case() {
  description=$1
  shift

  TEST_COUNT=$((TEST_COUNT + 1))
  TEST_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/test-framework.XXXXXX") || return 1
  TEST_CASE_ASSERTIONS=$TEST_TMPDIR/assertions
  TEST_CASE_FAILURES=$TEST_TMPDIR/failures
  TEST_CASE_SKIP_REASON=$TEST_TMPDIR/skip-reason
  : >"$TEST_CASE_ASSERTIONS"
  : >"$TEST_CASE_FAILURES"
  export TEST_TMPDIR TEST_CASE_ASSERTIONS TEST_CASE_FAILURES \
    TEST_CASE_SKIP_REASON

  printf '[%s] %s\n' "$TEST_COUNT" "$description"

  set +e
  (
    set -e

    if [ -n "${TEST_SETUP-}" ]; then
      "$TEST_SETUP"
    fi

    "$@"

    if [ -n "${TEST_TEARDOWN-}" ]; then
      "$TEST_TEARDOWN"
    fi
  )
  status=$?
  set -e

  assertions=$(_test_line_count "$TEST_CASE_ASSERTIONS")
  failures=$(_test_line_count "$TEST_CASE_FAILURES")
  TEST_ASSERTIONS=$((TEST_ASSERTIONS + assertions))
  TEST_FAILED=$((TEST_FAILED + failures))

  case $status in
    0)
      ;;
    125)
      TEST_SKIPPED=$((TEST_SKIPPED + 1))
      if [ -s "$TEST_CASE_SKIP_REASON" ]; then
        reason=$(cat "$TEST_CASE_SKIP_REASON")
      else
        reason=skipped
      fi
      printf '  %s: %s\n' "$(_test_skip_label)" "$reason"
      ;;
    *)
      if [ "$failures" -eq 0 ]; then
        TEST_FAILED=$((TEST_FAILED + 1))
      fi
      printf '  %s: case exited with status %s\n' "$(_test_fail)" "$status"
      ;;
  esac

  _test_cleanup "$status"
}

test_finish() {
  printf '\n'

  if [ "$TEST_FAILED" -ne 0 ]; then
    printf 'TESTS: %s, ASSERTIONS: %s, SKIPPED: %s, %s: %s\n' \
      "$TEST_COUNT" "$TEST_ASSERTIONS" "$TEST_SKIPPED" \
      "$(_test_fail)" "$TEST_FAILED"
    return 1
  fi

  printf 'TESTS: %s, ASSERTIONS: %s, SKIPPED: %s, %s\n' \
    "$TEST_COUNT" "$TEST_ASSERTIONS" "$TEST_SKIPPED" "$(_test_pass)"
}

#!/bin/sh

TFW_FAILED=${TFW_FAILED:-0}
TFW_COUNT=${TFW_COUNT:-0}
TFW_ASSERTIONS=${TFW_ASSERTIONS:-0}
TFW_SKIPPED=${TFW_SKIPPED:-0}
TFW_TMP=${TFW_TMP:-}
TFW_COLOR=

if [ -z "${NO_COLOR-}${NOCOLOR-}" ] && \
  { [ -n "${TFW_FORCE_COLOR-}" ] || \
    { [ -t 1 ] && [ -n "${TERM-}" ] && [ "${TERM-}" != dumb ]; }; }; then
  TFW_COLOR=1
fi

_test_color() {
  code=$1
  shift

  if [ -z "$TFW_COLOR" ]; then
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
  printf '.\n' >>"$TFW_ASSERTIONS_FILE"
}

_test_record_failure() {
  printf '.\n' >>"$TFW_FAILURES_FILE"
}

_test_junit_case() {
  if [ -n "${TFW_JUNIT_DATA-}" ]; then
    printf 'C\t%s\t%s\n' "$TFW_COUNT" "$1" >>"$TFW_JUNIT_DATA"
  fi
}

_test_junit_assertion() {
  if [ -n "${TFW_JUNIT_DATA-}" ]; then
    printf 'A\t%s\t%s\t%s\n' \
      "$TFW_COUNT" "$1" "$2" >>"$TFW_JUNIT_DATA"
  fi
}

_test_junit_skip() {
  if [ -n "${TFW_JUNIT_DATA-}" ]; then
    printf 'S\t%s\t%s\n' "$TFW_COUNT" "$1" >>"$TFW_JUNIT_DATA"
  fi
}

_test_junit_error() {
  if [ -n "${TFW_JUNIT_DATA-}" ]; then
    printf 'E\t%s\t%s\n' "$TFW_COUNT" "$1" >>"$TFW_JUNIT_DATA"
  fi
}

_test_junit_finish() {
  if [ -z "${TFW_JUNIT-}" ]; then
    return 0
  fi

  awk -F '\t' -f "$TFW_DIR/src/junit.awk" \
    "$TFW_JUNIT_DATA" >"$TFW_JUNIT"
}

assert_equal() {
  description=$1
  actual=$2
  expected=$3

  _test_record_assertion

  if [ "$actual" = "$expected" ]; then
    _test_junit_assertion pass "$description"
    printf '  %s: %s\n' "$(_test_pass)" "$description"

    return 0
  fi

  _test_junit_assertion fail "$description"
  cat <<-EOF
	  $(_test_fail): $description
	    expected: $expected
	    actual:   $actual
	EOF
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
    _test_junit_assertion pass "$description"
    printf '  %s: %s\n' "$(_test_pass)" "$description"

    return 0
  fi

  _test_junit_assertion fail "$description"
  cat <<-EOF
	  $(_test_fail): $description
	    expected status: $expected
	    actual status:   $actual
	EOF
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
    _test_junit_assertion pass "$description"
    printf '  %s: %s\n' "$(_test_pass)" "$description"
    return 0
  fi

  _test_junit_assertion fail "$description"
  cat <<-EOF
	  $(_test_fail): $description
	    expected nonzero status
	    actual status: 0
	EOF

  _test_record_failure
  return 0
}

test_tmpdir() {
  relative=${1-}

  if [ -n "$relative" ]; then
    if ! mkdir -p "$TFW_TMPDIR/$relative"; then
      return 1
    fi

    printf '%s\n' "$TFW_TMPDIR/$relative"
  else
    printf '%s\n' "$TFW_TMPDIR"
  fi
}

test_skip() {
  printf '%s\n' "$1" >"$TFW_SKIP_FILE"
  return 125
}

_test_line_count() {
  wc -l <"$1" | tr -d ' '
}

_test_cleanup() {
  status=$1

  if [ -z "$TFW_TMP" ] || [ "$status" -eq 0 ]; then
    rm -rf "$TFW_TMPDIR"
  else
    printf '    temporary directory: %s\n' "$TFW_TMPDIR"
  fi

  unset TFW_TMPDIR TEST_TMPDIR TFW_ASSERTIONS_FILE TFW_FAILURES_FILE \
    TFW_SKIP_FILE
}

test_case() {
  description=$1
  shift

  TFW_COUNT=$((TFW_COUNT + 1))
  if ! TFW_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/test-framework.XXXXXX"); then
    return 1
  fi

  TEST_TMPDIR=$TFW_TMPDIR
  TFW_ASSERTIONS_FILE=$TFW_TMPDIR/assertions
  TFW_FAILURES_FILE=$TFW_TMPDIR/failures
  TFW_SKIP_FILE=$TFW_TMPDIR/skip-reason
  : >"$TFW_ASSERTIONS_FILE"
  : >"$TFW_FAILURES_FILE"
  export TFW_TMPDIR TEST_TMPDIR TFW_ASSERTIONS_FILE TFW_FAILURES_FILE \
    TFW_SKIP_FILE

  _test_junit_case "$description"
  printf '[%s] %s\n' "$TFW_COUNT" "$description"

  set +e
  (
    set -e

    if [ -n "${TFW_SETUP-}" ]; then
      "$TFW_SETUP"
    fi

    "$@"

    if [ -n "${TFW_TEARDOWN-}" ]; then
      "$TFW_TEARDOWN"
    fi
  )
  status=$?
  set -e

  assertions=$(_test_line_count "$TFW_ASSERTIONS_FILE")
  failures=$(_test_line_count "$TFW_FAILURES_FILE")
  TFW_ASSERTIONS=$((TFW_ASSERTIONS + assertions))
  TFW_FAILED=$((TFW_FAILED + failures))

  case $status in
    0)
      ;;
    125)
      TFW_SKIPPED=$((TFW_SKIPPED + 1))
      if [ -s "$TFW_SKIP_FILE" ]; then
        reason=$(cat "$TFW_SKIP_FILE")
      else
        reason=skipped
      fi
      _test_junit_skip "$reason"
      printf '  %s: %s\n' "$(_test_skip_label)" "$reason"
      ;;
    *)
      if [ "$failures" -eq 0 ]; then
        TFW_FAILED=$((TFW_FAILED + 1))
        _test_junit_error "$status"
      fi
      printf '  %s: case exited with status %s\n' "$(_test_fail)" "$status"
      ;;
  esac

  _test_cleanup "$status"
}

test_finish() {
  printf '\n'

  status=0
  if [ "$TFW_FAILED" -ne 0 ]; then
    printf 'TESTS: %s, ASSERTIONS: %s, SKIPPED: %s, %s: %s\n' \
      "$TFW_COUNT" "$TFW_ASSERTIONS" "$TFW_SKIPPED" \
      "$(_test_fail)" "$TFW_FAILED"
    status=1
  else
    printf 'TESTS: %s, ASSERTIONS: %s, SKIPPED: %s, %s\n' \
      "$TFW_COUNT" "$TFW_ASSERTIONS" "$TFW_SKIPPED" "$(_test_pass)"
  fi

  if ! _test_junit_finish; then
    return 1
  fi

  return "$status"
}

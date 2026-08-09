#!/bin/sh

fail_assertions() {
  assert_equal fail actual expected
  assert_status fail 0 false
  assert_failure fail true
  test_tmpdir >/dev/null
}

unexpected_failure() {
  return 3
}

skip_without_reason() {
  return 125
}

TEST_KEEP_TMP=1
test_case 'failed assertions' fail_assertions
test_case 'unexpected failure' unexpected_failure
test_case 'skip without reason' skip_without_reason

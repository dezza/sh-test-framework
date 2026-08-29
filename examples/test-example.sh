#!/bin/sh

sample_setup() {
  mkdir -p "$TFW_TMPDIR/setup"
}

sample_teardown() {
  rm -rf "$TFW_TMPDIR/setup"
}

sample_assertions() {
  assert_equal 'equal values' 'value' 'value'
  assert_status 'expected status' 2 sh -c 'exit 2'
  assert_success 'successful command' true
  assert_failure 'failing command' false
}

sample_tmpdir() {
  path=$(test_tmpdir data)
  touch "$path/file"

  assert_success 'temporary directory created' [ -f "$path/file" ]
  assert_equal 'temporary path returned' "$path" "$TFW_TMPDIR/data"
}

sample_skip() {
  test_skip 'skip example'
}

TFW_SETUP=sample_setup
TFW_TEARDOWN=sample_teardown

test_case 'assertions' sample_assertions
test_case 'temporary directory' sample_tmpdir
test_case 'skipped test' sample_skip

TFW_SETUP=
TFW_TEARDOWN=

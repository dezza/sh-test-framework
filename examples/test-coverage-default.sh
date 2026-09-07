#!/bin/sh

test_default_coverage_directory() {
  fake_dir=$(mktemp -d "${TMPDIR:-/tmp}/tfw-fake-kcov.XXXXXX")
  fake_tmp=$fake_dir/tmp
  fake_log=$fake_dir/paths
  fake_args=$fake_dir/args
  mkdir -p "$fake_tmp"
  trap 'rm -rf -- "$fake_dir"' 0 HUP INT TERM

  cat >"$fake_dir/kcov" <<-'EOF_KCOV'
	#!/bin/sh
	set -eu
	
	output=
	for argument do
	  case $argument in
	    --*) ;;
	    *) output=$argument; break ;;
	  esac
	done
	
	printf '%s\n' "$@" >>"$FAKE_KCOV_ARGS"
	printf '%s\n' "$output" >>"$FAKE_KCOV_LOG"
	mkdir -p "$output/fake"
	printf '%s\n' '{"percent_covered":"100"}' >"$output/fake/coverage.json"
	EOF_KCOV

  chmod +x "$fake_dir/kcov"

  PATH=$fake_dir:$PATH
  TMPDIR=$fake_tmp
  TFW_COV=
  FAKE_KCOV_LOG=$fake_log
  FAKE_KCOV_ARGS=$fake_args
  export PATH TMPDIR TFW_COV FAKE_KCOV_LOG FAKE_KCOV_ARGS

  report=$(
    sh "$TFW_DIR/src/coverage-run.sh" \
      "$TFW_DIR/examples" 2>&1
  )
  assert_equal 'temporary coverage report' "$report" \
    'COVERAGE: 100%'
  assert_success 'coverage parses project shell scripts' \
    grep -Fqx -- \
      "--bash-parse-files-in-dir=$TFW_PROJECT_DIR" "$fake_args"

  first_path=$(sed -n '1p' "$fake_log")
  case $first_path in
    "$fake_tmp"/tfw-coverage.*) ;;
    *)
      printf '  FAIL: coverage path was not temporary: %s\n' "$first_path"
      return 1
      ;;
  esac

  if [ -d "$first_path" ]; then
    printf '  FAIL: temporary coverage directory remains: %s\n' \
      "$first_path"
    return 1
  fi
}

test_case 'default coverage uses temporary output' test_default_coverage_directory

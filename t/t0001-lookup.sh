#!/usr/bin/env bash
# plain lookups, listing, errors and suggestions

. "$(dirname "$0")/test-lib.sh"

test_expect_success 'single lookup prints the bare value' '
	test_is linux "$(snoo sys platform)"
'

test_expect_success 'several lookups are labeled' '
	out=$(snoo sys platform byteorder) &&
	test_is "platform: linux
byteorder: little" "$out"
'

test_expect_success 'functions are called automatically' '
	out=$(snoo os cpu_count) &&
	test "$out" -gt 0
'

test_expect_success 'PYTHON_CPU_COUNT overrides os.cpu_count' '
	test_is 4 "$(PYTHON_CPU_COUNT=4 snoo os cpu_count)"
'

test_expect_success 'private names can still be looked up' '
	test_is -1 "$(env -u PYTHON_CPU_COUNT python3 "$SNOO" sys _get_cpu_count_config)" &&
	test_is 4 "$(PYTHON_CPU_COUNT=4 snoo sys _get_cpu_count_config)"
'

test_expect_success 'module only lists public attributes' '
	out=$(snoo sys) &&
	echo "$out" | grep -qx version &&
	! echo "$out" | grep -q "^_"
'

test_expect_success 'missing module argument is a usage error' '
	test_expect_code 2 snoo
'

test_expect_success 'unknown attribute exits 1 with a suggestion' '
	out=$(test_expect_code 1 snoo sys verison 2>&1) &&
	test_is "Error: unknown keys: sys.verison, did you mean: version, hexversion, api_version?" "$out"
'

test_expect_success 'unknown attribute without close match has no suggestion' '
	out=$(test_expect_code 1 snoo sys zzzzqq 2>&1) &&
	test_is "Error: unknown keys: sys.zzzzqq" "$out"
'

test_expect_success 'unknown module exits 1 with a suggestion' '
	out=$(test_expect_code 1 snoo paltform 2>&1) &&
	echo "$out" | grep -q "did you mean: platform"
'

test_expect_success 'missing dependency is not reported as unknown module' '
	dir=$(mktemp -d) &&
	echo "import snoo_missing_dep" >"$dir/snoo_hasdep.py" &&
	out=$(PYTHONPATH=$dir test_expect_code 1 snoo snoo_hasdep 2>&1)
	rc=$?
	rm -r "$dir"
	test $rc = 0 &&
	test_is "Error: ModuleNotFoundError: No module named '\''snoo_missing_dep'\''" "$out"
'

test_expect_success 'unknown module is caught before lookups' '
	out=$(test_expect_code 1 snoo paltform machine 2>&1) &&
	echo "$out" | grep -q "^Error: unknown module: paltform"
'

test_expect_success 'first bad lookup stops the rest' '
	out=$(test_expect_code 1 snoo sys platform nope maxsize 2>&1) &&
	! echo "$out" | grep -q maxsize
'

test_expect_success 'quoting two names makes one bad name' '
	out=$(test_expect_code 1 snoo sys "version platform" 2>&1) &&
	echo "$out" | grep -q "sys.version platform"
'

test_expect_success 'errors go to stderr, not stdout' '
	out=$(test_expect_code 1 snoo sys nope 2>/dev/null) &&
	test -z "$out"
'

test_done

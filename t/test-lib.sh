# Tiny git-style test library, source it from t/tNNNN-*.sh
#
#   test_expect_success 'description' 'shell commands'
#   test_expect_failure 'description' 'shell commands'   # known breakage, to fix
#
# Output is TAP, so `prove t/` works too.

SNOO="$(cd "$(dirname "$0")/.." && pwd)/snoo.py"
test_count=0
test_failed=0
test_fixed=0
test_broken=0

snoo() {
	python3 "$SNOO" "$@"
}

# test_expect_code <code> <command...>: command must exit with <code>
test_expect_code() {
	want=$1
	shift
	"$@"
	got=$?
	if test "$got" != "$want"; then
		echo "# expected exit $want, got $got: $*" >&2
		return 1
	fi
}

# test_is <expected> <actual>: show a diff-ish message on mismatch
test_is() {
	if test "$1" != "$2"; then
		printf '# expected: %s\n#      got: %s\n' "$1" "$2" >&2
		return 1
	fi
}

test_expect_success() {
	test_count=$((test_count + 1))
	if (eval "$2") >/dev/null 2>"${TMPDIR:-/tmp}/snoo-test.err"; then
		echo "ok $test_count - $1"
	else
		echo "not ok $test_count - $1"
		sed 's/^/#   /' "${TMPDIR:-/tmp}/snoo-test.err"
		test_failed=$((test_failed + 1))
	fi
}

test_expect_failure() {
	test_count=$((test_count + 1))
	if (eval "$2") >/dev/null 2>&1; then
		echo "ok $test_count - $1 # TODO known breakage vanished"
		test_fixed=$((test_fixed + 1))
	else
		echo "not ok $test_count - $1 # TODO known breakage"
		test_broken=$((test_broken + 1))
	fi
}

test_done() {
	echo "1..$test_count"
	test "$test_fixed" -gt 0 && echo "# fixed $test_fixed known breakage(s), move them to test_expect_success"
	test "$test_broken" -gt 0 && echo "# still have $test_broken known breakage(s)"
	if test "$test_failed" -gt 0; then
		echo "# failed $test_failed among $test_count test(s)"
		exit 1
	fi
	echo "# passed all $test_count test(s)"
	exit 0
}

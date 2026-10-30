#!/usr/bin/env bash
# calling functions with name:arg,arg

. "$(dirname "$0")/test-lib.sh"
unset SNOO_UNSET_VAR

test_expect_success 'one plain text argument' '
	test_is "$HOME" "$(snoo os getenv:HOME)"
'

test_expect_success 'two arguments, getenv default' '
	test_is fallback "$(snoo os getenv:SNOO_UNSET_VAR,fallback)"
'

test_expect_success 'unset variable without default prints None' '
	test_is None "$(snoo os getenv:SNOO_UNSET_VAR)"
'

test_expect_success 'numbers are converted' '
	test_is 28 "$(snoo sys getsizeof:42)"
'

test_expect_success 'several calls are labeled' '
	out=$(snoo os getenv:HOME cpu_count) &&
	echo "$out" | grep -qx "getenv:HOME: $HOME"
'

test_expect_success 'plain commas split arguments' '
	test_is usr/local/bin "$(snoo os.path join:usr,local,bin)"
'

test_expect_success 'quoted commas stay in one argument' '
	test_is "a,b" "$(snoo os getenv:SNOO_UNSET_VAR,\"a,b\")"
'

test_expect_success 'single quotes work too' '
	test_is "c,d" "$(snoo os "getenv:SNOO_UNSET_VAR,'\''c,d'\''")"
'

test_expect_success 'commas inside a list do not split' '
	test_is 2 "$(snoo statistics "mean:[1,2,3]")"
'

test_expect_success 'tuples as several arguments' '
	test_is 5.0 "$(snoo math "dist:(0,0),(3,4)")"
'

test_expect_success 'quoted commas inside a list stay in the string' '
	test_is 2 "$(snoo builtins "len:['\''a,b'\'','\''c'\'']")"
'

test_expect_success 'missing arguments exit 1 without traceback' '
	out=$(test_expect_code 1 snoo os getenv 2>&1) &&
	test_is "Error: os.getenv: getenv() missing 1 required positional argument: '\''key'\''" "$out"
'

test_expect_success 'arguments on a non-function exit 1' '
	out=$(test_expect_code 1 snoo sys version:1 2>&1) &&
	test_is "Error: sys.version is not a function, it takes no arguments" "$out"
'

test_expect_success 'unclosed quote exits 1' '
	out=$(test_expect_code 1 snoo os getenv:\"oops 2>&1) &&
	echo "$out" | grep -q "No closing quotation"
'

test_expect_success 'typo in function name gets a suggestion' '
	out=$(test_expect_code 1 snoo os getevn:HOME 2>&1) &&
	echo "$out" | grep -q "did you mean: getenv"
'

test_expect_success 'quoted number stays a string' '
	test_is "<class '\''str'\''>" "$(snoo builtins type:\"42\")"
'

test_expect_success 'quoted list stays a string (json.loads)' '
	test_is "[1, 2]" "$(snoo json loads:\"[1,2]\")"
'

test_expect_success 'unquoted number is converted' '
	test_is "<class '\''int'\''>" "$(snoo builtins type:42)"
'

test_done

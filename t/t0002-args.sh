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

test_expect_success 'bytes prefix makes a bytes argument' '
	test_is "<class '\''bytes'\''>" "$(snoo builtins type:b\"42\")" &&
	test_is "b'\''a,b'\''" "$(snoo builtins "repr:b'\''a,b'\''")"
'

test_expect_success 'other string prefixes are literals too' '
	test_is 4 "$(snoo builtins "len:r'\''\n\n'\''")" &&
	test_is x "$(snoo builtins "str:u'\''x'\''")"
'

test_expect_success 'callable from python' '
	out=$(python3 -c "
import sys, pathlib; sys.path.insert(0, \"${SNOO%/*}\")
from snoo import peek, run_chain
print(peek(pathlib, \"Path.home\"))
print(peek(\"ab\", \"upper\"))
print(run_chain(\"os\", [\"getcwd\", \".upper\"]))") &&
	test_is "$HOME
AB
${PWD^^}" "$out"
'

test_expect_success '.name runs on the previous result' '
	test_is 8f434346648f6b96df89dda901c5176b10a6d83961dd3c1ac88b59b2dc327aa4 \
		"$(snoo hashlib "sha256:b'\''hi'\''" .hexdigest)"
'

test_expect_success 'chains are labeled as one lookup' '
	out=$(snoo os getcwd .upper cpu_count) &&
	echo "$out" | grep -qx "getcwd .upper: ${PWD^^}"
'

test_expect_success 'bad name in a chain names the chain so far' '
	out=$(test_expect_code 1 snoo os getcwd .uper 2>&1) &&
	echo "$out" | grep -q "^Error: unknown keys: os.getcwd.uper, did you mean: upper"
'

test_expect_success 'dotted name is walked, only the end is called' '
	test_is "$HOME" "$(snoo pathlib Path.home)" &&
	test_is True "$(snoo pathlib Path.home .joinpath:snoo .is_relative_to:$HOME)"
'

test_expect_success 'bad part of a dotted name gets a suggestion' '
	out=$(test_expect_code 1 snoo pathlib Path.hom 2>&1) &&
	test_is "Error: unknown keys: pathlib.Path.hom, did you mean: home?" "$out"
'

test_expect_success 'chain without a lookup before it exits 1' '
	out=$(test_expect_code 1 snoo os .upper 2>&1) &&
	test_is "Error: nothing to chain .upper onto" "$out"
'

test_expect_success 'expressions are evaluated' '
	test_is 10 "$(snoo math "isqrt:10**2")" &&
	test_is 10 "$(snoo builtins "len:[0.1]*10")"
'

test_expect_success 'builtins and lambdas work as arguments' '
	test_is False "$(snoo math "isnan:float('\''inf'\'')")" &&
	test_is True "$(snoo abc "abstractmethod:lambda: 0" .__isabstractmethod__)"
'

test_expect_success 'bare names stay text, even builtins' '
	test_is "<class '\''str'\''>" "$(snoo builtins type:bin)" &&
	test_is "<class '\''NoneType'\''>" "$(snoo builtins type:None)"
'

test_expect_success 'maths-looking text needs quotes' '
	test_is 1985 "$(snoo builtins str:2026-10-31)" &&
	test_is 2026-10-31 "$(snoo builtins str:\"2026-10-31\")"
'

test_expect_success 'failing expression exits 1' '
	out=$(test_expect_code 1 snoo math isqrt:1/0 2>&1) &&
	test_is "Error: bad arguments in isqrt:1/0: division by zero" "$out"
'

test_expect_success 'unquoted number is converted' '
	test_is "<class '\''int'\''>" "$(snoo builtins type:42)"
'

test_done

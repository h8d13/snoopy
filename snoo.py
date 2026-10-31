#!/usr/bin/env python3
# get rdy this a very stupid tool.

import argparse
import difflib
import importlib
import keyword
import pkgutil
import sys

_VER = "0.0.5"

class SnooError(Exception):
	# unknown module/name or bad arguments, the CLI turns it into exit 1
	pass

def did_you_mean(word: str, options) -> str:
	# suggest close spellings, e.g. paltform -> platform
	matches = difflib.get_close_matches(word, options, n=3)
	return f', did you mean: {', '.join(matches)}?' if matches else ''

def known_modules():
	# stdlib plus anything installed on sys.path
	return set(sys.stdlib_module_names) | {m.name for m in pkgutil.iter_modules()}

def load_module(module: str):
	try:
		return importlib.import_module(module)
	except ModuleNotFoundError as e:
		# a missing dependency of the module is its own error, keep it
		if e.name != module:
			raise
		# print something helful on error
		raise SnooError(f'unknown module: {module}{did_you_mean(module, known_modules())}') from None

def list_attributes(module: str):
	# skip private names like _foo and __doc__
	return [name for name in dir(load_module(module)) if not name.startswith('_')]

def parse_arg(text: str):
	# Python expressions: 42, [0.1]*10, b'hi', float('nan'), lambda: 0
	# anything else is plain text: HOME, /usr/bin, %A
	# bare names stay text even if builtin: bin, id, type
	if text.isidentifier() and not keyword.iskeyword(text):
		return text
	try:
		return eval(text, {})
	except NameError, SyntaxError:
		return text

def split_args(raw: str) -> list:
	# split on commas, except inside quotes or brackets, each part then
	# goes through parse_arg: 'a,"b,c",42,[1,2]' -> ['a', 'b,c', 42, [1, 2]]
	args, part = [], ''
	quote, depth = None, 0
	for char in raw:
		if quote:
			quote = None if char == quote else quote
		elif char in '"\'':
			quote = char
		elif char == ',' and not depth:
			args.append(parse_arg(part))
			part = ''
			continue
		else:
			depth += (char in '([{') - (char in ')]}')
		part += char
	if quote:
		raise SnooError(f'No closing quotation in {raw}')
	if raw:
		args.append(parse_arg(part))
	return args

def peek(obj, name: str, *args, label: str = ''):
	# look up <obj>.<name>, extra args are passed if it's a function
	# label names obj in errors, e.g. 'hashlib.sha3_512', defaults to
	# its own name (os) or its type for plain values (str)
	# dotted names are walked, only the last part is called: Path.home()
	label = label or getattr(obj, '__name__', type(obj).__name__)
	path = f'{label}.{name}'
	value = obj
	for part in name.split('.'):
		try:
			value = getattr(value, part)
		except AttributeError:
			raise SnooError(f'unknown keys: {path}{did_you_mean(part, dir(value))}') from None

	if not callable(value):
		if args:
			raise SnooError(f'{path} is not a function, it takes no arguments')
		return value

	# call it if it's a function, its errors keep their own type
	return value(*args)

def group_chains(lookups: list) -> list:
	# '.name' continues on the previous result:
	# ['sha256:b"x"', '.hexdigest', 'name']
	#   -> [['sha256:b"x"', '.hexdigest'], ['name']]
	chains = []
	for lookup in lookups:
		if not lookup.startswith('.'):
			chains.append([lookup])
		elif chains:
			chains[-1].append(lookup)
		else:
			raise SnooError(f'nothing to chain {lookup} onto')
	return chains

def run_chain(module: str, chain: list):
	# each lookup runs on the previous value, starting from the module
	# CLI form: getenv:HOME passes 'HOME' as argument
	value, label = load_module(module), module
	for lookup in chain:
		lookup = lookup.removeprefix('.')
		name, _, raw_args = lookup.partition(':')
		value = peek(value, name, *split_args(raw_args), label=label)
		label += '.' + name
	return value

# print(run_chain('sys', ['version']))
# print(run_chain('sys', ['platform']))
# print(run_chain('sys', ['executable']))
# print(run_chain('sys', ['nopenope']))

# get all available fields
# import sys
# print(dir(sys))
# can do the same with 'os' or others...

# print(run_chain('platform', ['machine']))
# print(run_chain('sys', ['maxsize']))
# functions are called automatically
# print(run_chain('os', ['cpu_count']))


if __name__ == '__main__':
	parser = argparse.ArgumentParser(description=f'snoopy {_VER} - Look up modules/attributes/functions in CLI')
	parser.add_argument('module', help='module name, e.g. sys, os, platform')
	parser.add_argument('lookup', nargs='*', help='attribute names, e.g. version platform, or with arguments: getenv:HOME, .name runs on the previous result (none: list all)')
	args = parser.parse_args()

	try:
		# if only module is provided, list available 'dir' attributes
		if not args.lookup:
			for name in list_attributes(args.module):
				print(name)

		# lookups are then optional...
		# several lookups for one module is fine, another module needs another query
		# '.name' chains onto the lookup before it, e.g. sha3_512:b"x" .hexdigest
		chains = group_chains(args.lookup)
		for chain in chains:
			value = run_chain(args.module, chain)
			# label each value when there are several
			print(f'{' '.join(chain)}: {value}' if len(chains) > 1 else value)
	except SnooError as e:
		# errors go to stderr with exit 1
		sys.exit(f'Error: {e}')
	except Exception as e:
		# raised by the looked up code or an argument, e.g. 1/0
		sys.exit(f'Error: {type(e).__name__}: {e}')

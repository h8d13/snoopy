#!/usr/bin/env python3
# get rdy this a very stupid tool.

import argparse
import ast
import difflib
import importlib
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
	except ModuleNotFoundError:
		# print something helful on error
		raise SnooError(f'unknown module: {module}{did_you_mean(module, known_modules())}') from None

def list_attributes(module: str):
	# skip private names like _foo and __doc__
	return [name for name in dir(load_module(module)) if not name.startswith('_')]

def parse_arg(text: str):
	# 42 -> int, [1,2] -> list, HOME -> 'HOME' (plain text fallback)
	try:
		return ast.literal_eval(text)
	except ValueError, SyntaxError:
		return text

def split_args(raw: str) -> list:
	# split on commas, except inside quotes or brackets
	# quoted parts stay text, the rest goes through parse_arg:
	# 'a,"b,c",42,[1,2]' -> ['a', 'b,c', 42, [1, 2]]
	args, part = [], ''
	quote, quoted, depth = None, False, 0
	for char in raw:
		if quote or char in '"\'':
			if quote is None:
				quote = char
			elif char == quote:
				quote = None
			else:
				part += char
				continue
			# quotes inside brackets belong to the literal, e.g. ['a,b']
			if depth:
				part += char
			else:
				quoted = True
		elif char == ',' and not depth:
			args.append(part if quoted else parse_arg(part))
			part, quoted = '', False
		else:
			depth += (char in '([{') - (char in ')]}')
			part += char
	if quote:
		raise ValueError('No closing quotation')
	if raw:
		args.append(part if quoted else parse_arg(part))
	return args

def peek(module: str, name: str, *args):
	# look up <module>.<name> by name, extra args are passed if it's a function
	mod = load_module(module)
	try:
		value = getattr(mod, name)
	except AttributeError:
		raise SnooError(f'unknown keys: {module}.{name}{did_you_mean(name, dir(mod))}') from None

	if not callable(value):
		if args:
			raise SnooError(f'{module}.{name} is not a function, it takes no arguments')
		return value

	# call it if it's a function
	try:
		return value(*args)
	except TypeError as e:
		# wrong or missing arguments, e.g. os.getenv without a name
		raise SnooError(f'{module}.{name}: {e}') from None

def run_lookup(module: str, lookup: str):
	# CLI form: getenv:HOME passes 'HOME' as argument
	name, _, raw_args = lookup.partition(':')
	try:
		args = split_args(raw_args)
	except ValueError as e:
		# e.g. an unclosed quote
		raise SnooError(f'bad arguments in {lookup}: {e}') from None
	return peek(module, name, *args)

# print(peek('sys', 'version'))
# print(peek('sys', 'platform'))
# print(peek('sys', 'executable'))
# print(peek('sys', 'nopenope'))

# get all available fields
# import sys
# print(dir(sys))
# can do the same with 'os' or others...

# print(peek('platform', 'machine'))
# print(peek('sys', 'maxsize'))
# functions are called automatically
# print(peek('os', 'cpu_count'))


if __name__ == '__main__':
	parser = argparse.ArgumentParser(description=f'snoopy {_VER} - Look up modules/attributes/functions in CLI')
	parser.add_argument('module', help='module name, e.g. sys, os, platform')
	parser.add_argument('lookup', nargs='*', help='attribute names, e.g. version platform, or with arguments: getenv:HOME (none: list all)')
	args = parser.parse_args()

	try:
		# if only module is provided, list available 'dir' attributes
		if not args.lookup:
			for name in list_attributes(args.module):
				print(name)

		# lookups are then optional...
		# several lookups for one module is fine, another module needs another query
		for lookup in args.lookup:
			value = run_lookup(args.module, lookup)
			# label each value when there are several
			print(f'{lookup}: {value}' if len(args.lookup) > 1 else value)
	except SnooError as e:
		# errors go to stderr with exit 1
		sys.exit(f'Error: {e}')

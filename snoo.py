#!/usr/bin/env python3
# get rdy this a very stupid tool.

import argparse
import importlib

_VER = "0.0.2"

def list_attributes(module: str):
	try:
		mod = importlib.import_module(module)
		# skip private names like _foo and __doc__
		return [name for name in dir(mod) if not name.startswith('_')]
	except ModuleNotFoundError:
		# print something helful on error
		print(f'Error: unknown module: {module}')
		raise SystemExit(1)

def system_info(module: str, lookup: str):
	# look up <module>.<lookup> by name
	try:
		mod = importlib.import_module(module)
		value = getattr(mod, lookup)
		# call it if it's a function
		return value() if callable(value) else value
	except ModuleNotFoundError, AttributeError:
		# print something helful on error
		print(f'Error: unknown keys: {module}.{lookup}')
		raise SystemExit(1)

# print(system_info('sys', 'version'))
# print(system_info('sys', 'platform'))
# print(system_info('sys', 'executable'))
# print(system_info('sys', 'nopenope'))

# get all available fields
# import sys
# print(dir(sys))
# can do the same with 'os' or others...

# print(system_info('platform', 'machine'))
# print(system_info('sys', 'maxsize'))
# functions are called automatically
# print(system_info('os', 'cpu_count'))


if __name__ == '__main__':
	parser = argparse.ArgumentParser(description=f'snoopy {_VER} - Look up modules/attributes/functions in CLI')
	parser.add_argument('module', help='module name, e.g. sys, os, platform')
	parser.add_argument('lookup', nargs='*', help='attribute names, e.g. version platform (none: list all)')
	args = parser.parse_args()

	# if only module is provided, list available 'dir' attributes
	if not args.lookup:
		for name in list_attributes(args.module):
			print(name)

	# lookups are then optional...
	# several lookups for one module is fine, another module needs another query
	for lookup in args.lookup:
		value = system_info(args.module, lookup)
		# label each value when there are several
		print(f'{lookup}: {value}' if len(args.lookup) > 1 else value)

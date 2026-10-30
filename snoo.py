#!/usr/bin/env python3
import argparse
import importlib


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
	parser = argparse.ArgumentParser(description='Look up <module>.<lookup> by name')
	parser.add_argument('module', help='module name, e.g. sys, os, platform')
	parser.add_argument('lookup', help='attribute name, e.g. version, cpu_count')
	args = parser.parse_args()

	print(system_info(args.module, args.lookup))

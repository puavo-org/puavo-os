#!/usr/bin/python3

import optparse
import os
import sys


class Option(object):
    def __init__(self, name):
        self.name = name
        self.values = {}

    def add(self, value, filename):
        v = self.values.setdefault(value, set())
        v.add(filename)


class Main(object):
    def __init__(self, package, ignore_top_disabled=False):
        from kconfigeditor.package import Package

        package = Package(package)

        options = {}

        for filename, data in package.items():
            for name, value in data.file.items():
                option = options.setdefault(name, Option(name))
                option.add(value, filename)

        def filenames_sortkey(filename):
            if filename == 'config':
                return ''
            return filename

        for name, option in sorted(options.items()):
            if len(option.values) > 1:
                for entry, filenames in option.values.items():
                    if (ignore_top_disabled and
                        not entry.value and
                        filenames == frozenset(('config', ))):
                        continue

                    print(' '.join(sorted(filenames, key=filenames_sortkey)))
                    print('  ', entry)
                print()


if __name__ == '__main__':
    options = optparse.OptionParser(
        usage = "%prog [OPTION]... PACKAGE"
    )
    options.add_option('--ignore-top-disabled', action='store_true')

    opts, args = options.parse_args()

    if len(args) != 1:
        options.error("Too less arguments")

    Main(*args, ignore_top_disabled=opts.ignore_top_disabled)


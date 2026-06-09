#!/usr/bin/python3

import optparse
import os
import sys


class Main(object):
    def __init__(self, *filenames):
        from kconfigeditor.kconfig.config import File

        input_files = [frozenset(File(name=i).values()) for i in filenames]

        output_common = input_files[0].intersection(*input_files[1:])

        output_files = [i - output_common for i in input_files]

        self.write('output-common', output_common)

        for output, id in zip(output_files, range(1, len(output_files) + 1)):
            self.write('output-part-%d' % id, output)

    def write(self, filename, content):
        f = open(filename, 'w')

        items = [(i.name, i) for i in content]
        items.sort(key=lambda a: a[0])
        for key, value in items:
            f.write(str(value) + '\n')

        f.close()


if __name__ == '__main__':
    options = optparse.OptionParser(
        usage = "%prog [OPTION]... CONFIG..."
    )

    opts, args = options.parse_args()

    if len(args) < 1:
        options.error("Too less arguments")

    Main(*args)


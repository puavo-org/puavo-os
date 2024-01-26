#!/usr/bin/python3

import optparse
import os
import sys


class Main(object):
    def __init__(self, package, source, config_output):
        from kconfigeditor.kconfig.menu.all import All
        from kconfigeditor.package import Package

        package = Package(package)
        fs_menu = {'none': All(source, package.kernelarches)}

        for filename, data in package.items():
            featureset = data.featureset
            try:
                menu = fs_menu[featureset or 'none']
            except KeyError:
                menu = fs_menu[featureset] = All('%s/debian/build/source_%s' %
                                                 (source, featureset),
                                                 package.kernelarches)
            kernelarch = data.kernelarch
            if kernelarch:
                menufiles = menu.arch(kernelarch)
            else:
                menufiles = menu

            filename = os.path.join(config_output, filename)
            filename_tmp = filename + '.tmp'
            f = open(filename_tmp, 'w')
            try:
                data.file.write_menu(f, menufiles)
                f.close()
                os.rename(filename_tmp, filename)
            except:
                os.unlink(filename_tmp)
                raise


if __name__ == '__main__':
    options = optparse.OptionParser(
        usage = "%prog [OPTION]... PACKAGE"
    )
    options.add_option(
        "-c", "--config-output",
        dest = "config_output",
        help = "output directory for config [default: PACKAGE/debian/config]"
    )
    options.add_option(
        "-s", "--source",
        dest = "source",
        help = "location of linux source [default: PACKAGE]"
    )

    opts, args = options.parse_args()

    if len(args) > 1:
        options.error("Too much arguments.")
    elif len(args) < 1:
        options.error("Too less arguments")

    package = args[0]
    source = opts.source or package
    config_output = opts.config_output or os.path.join(package, 'debian/config')

    sys.path.append(os.path.join(package, "debian/lib/python"))

    Main(package, source, config_output)


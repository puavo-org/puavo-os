import os
import re

from . import MenuEntrySource
from .file import Parser


class All(object):
    _var_ref_re = re.compile(r'\$(?:\(([^\)]+)\)|([\w\-]+))')

    def __init__(self, root, arches):
        self.root = root

        files = self._files = {}
        files_global = files[None] = []

        cache = {}

        for arch in arches:
            files_arch = files[arch] = []
            env = {'SRCARCH': arch}

            work = ["Kconfig"]

            while work:
                filename = work.pop(0)
                filename_list = filename.split('/')

                f = cache.get(filename)
                if not f:
                    f = cache[filename] = self.read(filename)

                for i in f:
                    if isinstance(i, MenuEntrySource):
                        # XXX This expansion should really be done in the
                        # parser, but that will require big changes to
                        # the parser and to the caching here.
                        new_filename = All._var_ref_re.sub(
                            lambda match: env[match.group(1) or match.group(2)],
                            i.filename)
                        work.append(new_filename)

                files_arch.append(f)

                if not (len(filename_list) > 2 and
                        (filename_list[0] == 'arch' or
                         filename_list[1] in arches or
                         filename_list[2] in arches)):
                    files_global.append(f)

    def __iter__(self):
        for i in self._files[None]:
            yield i

    def arch(self, arch):
        for i in self._files[arch]:
            yield i

    def read(self, filename):
        return Parser()(open(os.path.join(self.root, filename)), filename)

import os
import re
import sys

from .menu import MenuEntryChoice, MenuEntryConfig


class File(dict):
    def __init__(self, content={}, name=None):
        super(File, self).__init__(content)
        if name:
            self.name = name
            with open(name) as fd:
                self.read(fd)
        else:
            self.name = '<unknown>'

    def _write(self, menufiles):
        processed = set()
        automatic = set()

        for file in menufiles:
            for i in self._write_file(processed, automatic, file):
                yield i

        unprocessed = set(self) - processed
        if unprocessed:
            yield '##'
            yield '## file: unknown'
            yield '##'
            for name in sorted(unprocessed):
                if name in automatic:
                    print(f"{self.name}: CONFIG_{name} is automatic and cannot be set explicitly",
                          file=sys.stderr)
                else:
                    print(f"{self.name}: Unknown setting {self[name]}",
                          file=sys.stderr)
                for i in self[name].write():
                    yield i
            yield ''

    def _write_file(self, processed, automatic, file):
        ret = []

        for entry in file:
            if isinstance(entry, MenuEntryConfig):
                ret.extend(self._write_entry_config(processed, automatic,
                                                    entry))
            elif isinstance(entry, MenuEntryChoice):
                ret.extend(self._write_entry_choice(processed, automatic,
                                                    entry))

        if ret:
            yield '##'
            yield f'## file: {file.filename}'
            yield '##'
            for i in ret:
                yield i
            yield ''

    def _write_entry_choice(self, processed, automatic, entry):
        ret = []

        for subentry in entry:
            if isinstance(subentry, MenuEntryConfig):
                ret.extend(self._write_entry_config(processed, automatic,
                                                    subentry))

        if ret:
            yield f'## choice: {entry.prompt}'
            for i in ret:
                yield i
            yield '## end choice'

    def _write_entry_config(self, processed, automatic, entry):
        if entry.name in processed:
            return

        value = self.get(entry.name)
        if value is None:
            return

        if not entry.prompt:
            automatic.add(entry.name)
            return

        if entry.type == MenuEntryConfig.TYPE_BOOL:
            valid = isinstance(value, FileEntryTristate) and \
                    value.value != FileEntryTristate.VALUE_MOD
            type_name = 'bool'
        elif entry.type == MenuEntryConfig.TYPE_TRISTATE:
            valid = isinstance(value, FileEntryTristate)
            type_name = 'tristate'
        elif entry.type == MenuEntryConfig.TYPE_STRING:
            valid = isinstance(value.value, str) and \
                re.match(r'"(?:\\.|[^"])*"$', value.value) is not None
            type_name = 'string'
        elif entry.type == MenuEntryConfig.TYPE_INT_DEC:
            valid = isinstance(value.value, str) and \
                re.match(r'-?(?:0|[1-9]\d*)$', value.value) is not None
            type_name = 'int'
        elif entry.type == MenuEntryConfig.TYPE_INT_HEX:
            valid = isinstance(value.value, str) and \
                re.match(r'(?:0x)?[0-9a-f]+$', value.value,
                         re.IGNORECASE) is not None
            type_name = 'hex'
        else:
            valid = False
            type_name = 'unknown'

        if not valid:
            print(f"{self.name}: Invalid setting {value} for {type_name} type",
                  file=sys.stderr)

        processed.add(entry.name)
        for i in value.write():
            yield i

    def write(self, fd):
        for name in sorted(self.keys()):
            fd.write(str(self.get(name)) + '\n')

    def write_menu(self, fd, menufiles, ignore_silent=False):
        def menufiles_cmp_key(entry):
            filename_list = entry.filename.split('/')
            filename_list[-1] = filename_list[-1].replace('Kconfig', '\0')
            return filename_list

        menufiles = sorted(menufiles, key=menufiles_cmp_key)

        fd.write('\n'.join(self._write(menufiles)))

    def read(self, f):
        for entry in FileReader.read(f):
            self[entry.name] = entry


class FileReader(object):
    class State(object):
        __slots__ = 'name', 'value', 'comments'

        def __init__(self):
            self.name = None
            self.value = None
            self.comments = []

        reset = __init__

        def entry(self):
            if self.value is None or self.value[0] in ('y', 'm', 'n'):
                return FileEntryTristate(self.name, self.value, self.comments)
            return FileEntry(self.name, self.value, self.comments)

        def entry_reset(self):
            ret = self.entry()
            self.reset()
            return ret

    rules = r'''
        ^
        (
            CONFIG_(?P<name>[^=]+)=(?P<value>.*)
            |
            \#\ CONFIG_(?P<name_disabled>[^ ]+)\ is\ not\ set
            |
            \#\.\ (?P<comment>.*)
            |
            \#\#.*
            |
        )
        $
    '''
    _re = re.compile(rules, re.X)

    @classmethod
    def read(cls, f):
        state = cls.State()

        for line in iter(f.readlines()):
            match = cls._re.match(line.strip())

            if match:
                name = match.group('name') or match.group('name_disabled')
                comment = match.group('comment')

                if name:
                    state.name = name
                    state.value = match.group('value')
                    yield state.entry_reset()

                elif comment:
                    state.comments.append(comment)

            else:
                raise RuntimeError(f"Can't recognize {line}")


class FileEntry(object):
    __slots__ = 'name', 'value', 'comments'

    def __init__(self, name, value, comments=None):
        self.name, self.value = name, value
        self.comments = comments or []

    def __eq__(self, other):
        return self.name == other.name and self.value == other.value

    def __hash__(self):
        return hash(self.name) | hash(self.value)

    def __repr__(self):
        return '<{}({!r}, {!r}, {!r})>'.format(self.__class__.__name__, self.name, self.value, self.comments)

    def __str__(self):
        return 'CONFIG_{}={}'.format(self.name, self.value)

    def write(self):
        for comment in self.comments:
            yield '#. ' + comment
        yield str(self)


class FileEntryTristate(FileEntry):
    VALUE_NO = False
    VALUE_YES = True
    VALUE_MOD = object()

    def __init__(self, name, value, comments=None):
        if value is None or value[0] == 'n':
            value = self.VALUE_NO
        elif value[0] == 'y':
            value = self.VALUE_YES
        elif value[0] == 'm':
            value = self.VALUE_MOD
        else:
            raise NotImplementedError
        super(FileEntryTristate, self).__init__(name, value, comments)

    def __str__(self):
        if self.value is self.VALUE_MOD:
            return 'CONFIG_{}=m'.format(self.name)
        if self.value:
            return 'CONFIG_{}=y'.format(self.name)
        return '# CONFIG_{} is not set'.format(self.name)


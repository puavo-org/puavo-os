import re

from . import MenuEntryChoice, MenuEntryConfig, MenuEntrySource


class ParseError(RuntimeError):
    def __init__(self, text, filename, lineno):
        self.text = text
        self.filename = filename
        self.lineno = lineno

    def __str__(self):
        return "%s:%d: %s" % (self.filename, self.lineno, self.text)

class File(list):
    def __init__(self, filename):
        self.filename = filename

class Parser(object):
    def __call__(self, fd, filename):
        lineno = 1
        line = ''

        stack = _Stack()
        _BlockRoot(stack, File(filename))

        for phys_line in fd:
            if not phys_line.lstrip().startswith('#'):
                # Check for continuation onto the next physical line
                cont = phys_line.endswith('\\\n')

                # Add current physical line (excluding continuation marker)
                # to the logical line
                if cont:
                    line += phys_line[:-2].rstrip() + ' '
                else:
                    line += phys_line.rstrip()

            # Process complete logical line
            if line and not cont:
                try:
                    stack.top().process_line(line)
                except Exception as e:
                    raise ParseError(str(e), filename, lineno) from e
                line = ''

            lineno += 1

        return stack.top().process_stop(lineno, 0)

class _Text(object):
    __slots__ = "text", "lineno", "column"

    def __init__(self, text, lineno, column):
        self.text = text
        self.lineno = lineno
        self.column = column

    def __getitem__(self, key):
        if isinstance(key, slice):
            return _text(self.text[key], self.lineno, self.column + key.start)
        raise TypeError

    def __len__(self):
        return len(self.text)

    def __str__(self):
        raise Exception

    def __unicode__(self):
        return self.text

class _Stack(object):
    __slots__ = '_list'

    def __init__(self, list = []):
        self._list = list

    def pop(self, check = None):
        if check is not None and self._list[-1] != check:
            raise Exception
        return self._list.pop()

    def push(self, item):
        self._list.append(item)

    def top(self):
        return self._list[-1]

class _Element(object):
    entry = None
    stack = None

    def __init__(self, parent):
        self.stack = parent.stack
        self.stack.push(self)

    def end(self):
        pass

    def pop(self):
        self.end()
        self.stack.pop(self)

    def recurse(self, name, *args):
        self.pop()
        return getattr(self.stack.top(), name)(*args)

class _BlockContainer(object):
    split_rules = r"""
^
    (?P<ind>\s*)
    (?:
        (?P<word>[A-Za-z_0-9_\-]+)
        (
            \s*(?P<rest2>["'].+)
            |
            \s*(?P<assign>[:+]?=)\s*(?P<assign_rhs>.*)
            |
            \s+(?P<rest1>.+)
        )?
    |
        \$\((?P<func>info|warning-if|error-if)\s*,(?P<func_params>.*)\)
    )
    \s*
$"""
    split_re = re.compile(split_rules, re.X)

    def process_line(self, text):
        match = self.split_re.match(text)
        if not match:
            raise RuntimeError("Can't find a command")
        if match.group('assign'):
            self.process_assign(match.group('word'), match.group('assign'),
                                match.group('assign_rhs'))
        elif match.group('func'):
            self.process_function(match.group('func'),
                                  match.group('func_params'))
        else:
            rest = match.group('rest1') or match.group('rest2')
            getattr(self, "process_%s" % match.group('word'))(rest, match.group('ind'))

class _BlockContainerChoice(_BlockContainer):
    def process_choice(self, text, ind):
        _BlockChoice(self)

class _BlockContainerCommon(_BlockContainer):
    def process_comment(self, text, ind):
        _BlockComment(self)

    def process_config(self, text, ind):
        _BlockConfig(self, text)

    def process_if(self, text, ind):
        _BlockIf(self, text)

    def process_menuconfig(self, text, ind):
        _BlockMenuconfig(self, text)

    def process_source(self, text, ind):
        text = text.strip('"')
        _BlockSource(self, text)

    def process_assign(self, lhs, flavor, rhs):
        pass

    def process_function(self, name, params):
        pass

class _BlockContainerDepends(_BlockContainer):
    def process_depends(self, text, ind):
        _Expression(self, text)

class _BlockContainerMenu(_BlockContainer):
    def process_menu(self, text, ind):
        _BlockMenu(self, text)

class _BlockObject(_Element):
    def __getattr__(self, name):
        if name.startswith('process_'):
            def ret(*args):
                return self.recurse(name, *args)
            return ret
        raise AttributeError(name)

class _BlockRoot(
    _BlockContainerChoice,
    _BlockContainerCommon,
    _BlockContainerMenu,
    ):
    def __init__(self, stack, entry):
        self.stack, self.entry = stack, entry
        stack.push(self)

    def __getattr__(self, name):
        raise AttributeError(name)

    def process_mainmenu(self, text, ind):
        pass

    def process_stop(self, lineno, column):
        self.stack.pop(self)
        return self.entry

class _BlockChoice(_BlockObject, _BlockContainerCommon):
    def __init__(self, parent):
        super(_BlockChoice, self).__init__(parent)
        self.entry = MenuEntryChoice()
        parent.entry.append(self.entry)
        self._parent = parent
        _BlockConfigData(self, self.entry)

    def process_default(self, text, ind):
        _Expression(self, text)

    def process_endchoice(self, text, ind):
        self.pop()

    def process_source(self, text, ind):
        # Push source statements up to the parent
        self._parent.process_source(text, ind)

class _BlockComment(_BlockObject, _BlockContainerDepends):
    pass

class _BlockConfigData(_BlockObject, _BlockContainerDepends):
    _prompt_rules = r"""
^
    (
        "(?P<text1>.*((?<=\\)".*)*)"
        |
        '(?P<text2>.*((?<=\\)".*)*)'
        |
        (?P<text3>\w+)
    )
    (
        \s*
        (?P<expression>.*)
    )?
    ;?
$"""
    _prompt_re = re.compile(_prompt_rules, re.X)

    def __init__(self, parent, entry):
        super(_BlockConfigData, self).__init__(parent)
        self.entry = entry

    def _process_prompt(self, text, ind):
        if text is not None:
            match = self._prompt_re.match(text)
            if match:
                self.entry.prompt = match.group('text1') or match.group('text2') or match.group('text3')
                text = match.group('expression')
                _Expression(self, text)

    def process_bool(self, text, ind):
        self.entry.type = MenuEntryConfig.TYPE_BOOL
        # TODO
        self._process_prompt(text, ind)

    process_boolean = process_bool

    def process_default(self, text, ind):
        _Expression(self, text)

    def process_def_bool(self, text, ind):
        self.entry.type = MenuEntryConfig.TYPE_BOOL
        _Expression(self, text)

    def process_def_tristate(self, text, ind):
        self.entry.type = MenuEntryConfig.TYPE_TRISTATE
        _Expression(self, text)

    def process_help(self, text, ind):
        _BlockHelp(self, ind)

    def process_hex(self, text, ind):
        self.entry.type = MenuEntryConfig.TYPE_INT_HEX
        self._process_prompt(text, ind)

    def process_imply(self, text, ind):
        _Expression(self, text)

    def process_int(self, text, ind):
        self.entry.type = MenuEntryConfig.TYPE_INT_DEC
        self._process_prompt(text, ind)

    def process_modules(self, text, ind):
        pass

    def process_option(self, text, ind):
        _Expression(self, text)

    def process_optional(self, text, ind):
        pass

    def process_prompt(self, text, ind):
        self._process_prompt(text, ind)

    def process_range(self, text, ind):
        _Expression(self, text)

    def process_select(self, text, ind):
        _Expression(self, text)

    def process_string(self, text, ind):
        self.entry.type = MenuEntryConfig.TYPE_STRING
        self._process_prompt(text, ind)

    def process_tristate(self, text, ind):
        self.entry.type = MenuEntryConfig.TYPE_TRISTATE
        # TODO
        self._process_prompt(text, ind)

setattr(_BlockConfigData, 'process_---help---', _BlockConfigData.process_help)

class _BlockConfig(_BlockConfigData):
    def __init__(self, parent, name):
        super(_BlockConfig, self).__init__(parent, MenuEntryConfig(name))
        parent.entry.append(self.entry)

class _BlockHelp(_BlockObject):
    split_rules = r"^(?P<ind>\s+)(?P<rest>.*)$"
    split_re = re.compile(split_rules)

    def __init__(self, parent, ind):
        super(_BlockHelp, self).__init__(parent)
        self.indentation_init = len(ind)
        self.indentation = None

    def process_line(self, text):
        match = self.split_re.match(text)
        if match:
            ind = match.group('ind').expandtabs()
            l = len(ind)
            if l >= self.indentation_init:
                if self.indentation is None:
                    self.indentation = l
                    return
                elif l >= self.indentation:
                    return

        return self.recurse('process_line', text)

class _BlockIf(_BlockObject,
    _BlockContainerChoice,
    _BlockContainerCommon,
    _BlockContainerMenu,
    ):
    def __init__(self, parent, expression):
        super(_BlockIf, self).__init__(parent)
        self.entry = parent.entry
        _Expression(self, expression)

    def process_endif(self, text, ind):
        self.pop()

class _BlockMenu(_BlockObject,
    _BlockContainerChoice,
    _BlockContainerCommon,
    _BlockContainerMenu,
    ):
    def __init__(self, parent, text):
        super(_BlockMenu, self).__init__(parent)
        # TODO
        self.entry = parent.entry

    def process_depends(self, text, ind):
        pass

    def process_endmenu(self, text, ind):
        self.pop()

    def process_visible(self, text, ind):
        pass

class _BlockMenuconfig(_BlockMenu):
    def __init__(self, parent, name):
        super(_BlockMenuconfig, self).__init__(parent, "")
        self.entry = parent.entry
        # TODO
        entry = MenuEntryConfig(name)
        parent.entry.append(entry)
        _BlockConfigData(self, entry)

class _BlockSource(_BlockObject):
    def __init__(self, parent, text):
        super(_BlockSource, self).__init__(parent)
        self.entry = MenuEntrySource(text)
        parent.entry.append(self.entry)

class _Expression(_Element):
    def __init__(self, parent, text):
        super(_Expression, self).__init__(parent)
        self.process_line(text)

    def process_line(self, text):
        if not text or not text.endswith('\\'):
            self.pop()


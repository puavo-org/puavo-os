import enum


class MenuEntryChoice(list):
    def __init__(self, prompt=None):
        self.prompt = prompt

    def __repr__(self):
        return f"<{self.__class__.__name__}({self.prompt!r})>"


class MenuEntryConfigType(enum.Enum):
    BOOL = enum.auto()
    TRISTATE = enum.auto()
    STRING = enum.auto()
    INT_DEC = enum.auto()
    INT_HEX = enum.auto()


class MenuEntryConfig:
    TYPE_BOOL = MenuEntryConfigType.BOOL
    TYPE_TRISTATE = MenuEntryConfigType.TRISTATE
    TYPE_STRING = MenuEntryConfigType.STRING
    TYPE_INT_DEC = MenuEntryConfigType.INT_DEC
    TYPE_INT_HEX = MenuEntryConfigType.INT_HEX

    def __init__(self, name, type=None, prompt=None):
        self.name, self.type, self.prompt = name, type, prompt

    def __repr__(self):
        return f"<self.__class__.__name__({self.name!r}, {self.type!r}, {self.prompt!r})>"


class MenuEntrySource(object):
    def __init__(self, filename):
        self.filename = filename

    def __repr__(self):
        return f"<{self.__class__.__name__}({self.filename!r})>"


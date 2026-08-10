class MenuEntryChoice(list):
    def __init__(self, prompt=None):
        self.prompt = prompt

    def __repr__(self):
        return "<%s(%r)>" % (self.__class__.__name__, self.prompt)


class MenuEntryConfig(object):
    TYPE_BOOL = 1
    TYPE_TRISTATE = 2
    TYPE_STRING = 3
    TYPE_INT_DEC = 4
    TYPE_INT_HEX = 5

    def __init__(self, name, type=None, prompt=None):
        self.name, self.type, self.prompt = name, type, prompt

    def __repr__(self):
        return "<%s(%r, %r, %r)>" % (self.__class__.__name__, self.name, self.type, self.prompt)


class MenuEntrySource(object):
    def __init__(self, filename):
        self.filename = filename

    def __repr__(self):
        return "<%s(%r)>" % (self.__class__.__name__, self.filename)


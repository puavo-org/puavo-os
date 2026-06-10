import curses
import enum
import re
import sys
import unicodedata


class Severity(enum.IntEnum):
    critical = 6
    grave = 5
    serious = 4
    important = 3
    normal = 2
    minor = 1
    wishlist = 0


class PlainText:
    def __init__(self, is_tty, enable_color, enable_links):
        self._enable_color = enable_color
        self._enable_links = enable_links

        if is_tty or enable_color:
            curses.setupterm()

        if enable_color:
            def term_attr(name, *params):
                return curses.tparm(curses.tigetstr(name), *params).decode('ascii')

            red_attr = term_attr('setaf', curses.COLOR_RED)
            yellow_attr = term_attr('setaf', curses.COLOR_YELLOW)
            white_attr = term_attr('setaf', curses.COLOR_WHITE)
            bold_attr = term_attr('bold')
            dim_attr = term_attr('dim')

            self._bold_attr = bold_attr
            self._severity_attr = [
                white_attr + dim_attr,
                white_attr + dim_attr + bold_attr,
                '',
                yellow_attr,
                yellow_attr + bold_attr,
                red_attr,
                red_attr + bold_attr
            ]
            self._reset_attr = term_attr('sgr0')
        else:
            self._bold_attr = ''
            self._severity_attr = [''] * 7
            self._reset_attr = ''

    @staticmethod
    def create_text(text):
        return PlainText.Text(text)

    def create_para(self, cont):
        return PlainText.Block('', '', cont)

    def create_heading(self, level, cont):
        heading = PlainText.Block(self._bold_attr, self._reset_attr, cont)
        heading.append(PlainText.Text(':'))
        return heading

    def create_severity_span(self, sev_num, cont):
        return PlainText.Span(self._severity_attr[sev_num], self._reset_attr, cont)

    def create_link(self, url, cont):
        if self._enable_links:
            # XXX Should use curses to look up the escape sequences,
            # but they don't seem to be in terminfo yet
            return PlainText.Span(f'\x1b]8;;{url}\x1b\\',
                                  f'\x1b]8;;\x1b\\',
                                  cont)
        return cont

    def create_table(self, cols):
        table = PlainText.Table()
        table.add_row([
            PlainText.Span(self._bold_attr, self._reset_attr, cell)
            for cell in cols
        ])
        return table

    @staticmethod
    def create_bulleted_list():
        return PlainText.BulletedList()

    class Text:
        def __init__(self, text):
            self._text = text

        def print(self):
            sys.stdout.write(self._text)

        def width(self):
            # https://stackoverflow.com/questions/23058564/checking-a-character-is-fullwidth-or-halfwidth-in-python
            return sum(2 if unicodedata.east_asian_width(ch) in 'AFW' else 1
                       for ch in self._text)

    class Block:
        def __init__(self, begin, end, cont):
            self._begin = begin
            self._end = end
            self._cont = [cont]

        def append(self, cont):
            self._cont.append(cont)

        def print(self):
            sys.stdout.write(self._begin)
            for cont in self._cont:
                cont.print()
            sys.stdout.write(self._end)
            sys.stdout.write('\n')

    class Span:
        def __init__(self, begin, end, cont):
            self._begin = begin
            self._end = end
            self._cont = cont

        def print(self):
            sys.stdout.write(self._begin)
            self._cont.print()
            sys.stdout.write(self._end)

        def width(self):
            return self._cont.width()

    class Table:
        def __init__(self):
            self._num_cols = 0
            self._rows = []

        def add_row(self, row):
            self._num_cols = max(self._num_cols, len(row))
            self._rows.append(row)

        def print(self):
            # TODO: implement maximum column widths and truncation

            col_widths = []
            for i in range(self._num_cols - 1):
                width = 0
                for row in self._rows:
                    if i < len(row):
                        width = max(width, row[i].width())
                col_widths.append(width)
            # Last column does not need padding
            col_widths.append(0)

            for row in self._rows:
                for cell, width in zip(row, col_widths):
                    cell.print()
                    if width:
                        sys.stdout.write(' ' * (1 + width - cell.width()))
                sys.stdout.write('\n')

    class BulletedList:
        def __init__(self):
            self._items = []

        def append(self, item):
            self._items.append(item)

        def print(self):
            for item in self._items:
                sys.stdout.write('\N{bullet} ')
                item.print()
                sys.stdout.write('\n')


class Markdown:
    # Only 3 levels of emphasis available :-(
    _severity_emph = ['', '', '', '*', '*', '**', '**']

    # Match special characters that need to be escaped with a
    # backslash.  This includes '.' after a digit, because at the
    # start of a line this could turn a paragraph into a numbered list
    # item.
    _special_re = re.compile(r'([\\`*_\[\]<&~$]'
                             r'|^[-+=#|>]'
                             r'|(?<=\d)\.)')

    @staticmethod
    def create_text(text):
        return Markdown.Text(text)

    @staticmethod
    def create_para(cont):
        return Markdown.Block('', cont)

    @staticmethod
    def create_heading(level, cont):
        return Markdown.Block(f'{"#" * level} ', cont)

    @staticmethod
    def create_severity_span(sev_num, cont):
        emph = Markdown._severity_emph[sev_num]
        return Markdown.Span(emph, emph, cont)

    @staticmethod
    def create_link(url, cont):
        if not isinstance(cont, Markdown.Text):
            raise ValueError('markup not supported in link text')
        return Markdown.Span('[', f']({url})', cont)

    @staticmethod
    def create_table(cols):
        return Markdown.Table(cols)

    @staticmethod
    def create_bulleted_list():
        return Markdown.BulletedList()

    class Text:
        def __init__(self, text):
            self._text = text

        def print(self):
            sys.stdout.write(Markdown._special_re.sub(r'\\\1', self._text))

    class Block:
        def __init__(self, begin, cont):
            self._begin = begin
            self._cont = [cont]

        def append(self, cont):
            self._cont.append(cont)

        def print(self):
            sys.stdout.write(self._begin)
            for cont in self._cont:
                cont.print()
            sys.stdout.write('\n\n')

    class Span:
        def __init__(self, begin, end, cont):
            self._begin = begin
            self._end = end
            self._cont = cont

        def print(self):
            sys.stdout.write(self._begin)
            self._cont.print()
            sys.stdout.write(self._end)

    class Table:
        def __init__(self, cols):
            self._cols = cols
            self._rows = []

        def add_row(self, row):
            if len(row) != len(self._cols):
                raise ValueError('row is wrong length')
            self._rows.append(row)

        def print(self):
            for col in self._cols:
                sys.stdout.write('|')
                col.print()
            sys.stdout.write('|\n')
            sys.stdout.write('|-' * len(self._cols))
            sys.stdout.write('|\n')
            for row in self._rows:
                for cell in row:
                    sys.stdout.write('|')
                    cell.print()
                sys.stdout.write('|\n')
            sys.stdout.write('\n')

    class BulletedList:
        def __init__(self):
            self._items = []

        def append(self, item):
            self._items.append(item)

        def print(self):
            for item in self._items:
                sys.stdout.write('* ')
                item.print()
                sys.stdout.write('\n')
            sys.stdout.write('\n')

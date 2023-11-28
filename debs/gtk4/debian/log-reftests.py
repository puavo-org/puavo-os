#!/usr/bin/python3
# Copyright 2021 Simon McVittie
# SPDX-License-Identifier: CC0-1.0

import base64
import sys
from pathlib import Path

if __name__ == '__main__':
    for node in Path('testsuite', 'gsk', 'compare').glob('*.node'):
        for outputs in (
            Path(
                'debian', 'build', 'deb', 'testsuite', 'gsk', 'compare',
                'cairo', 'x11',
            ),
            Path(
                'debian', 'build', 'deb', 'testsuite', 'gsk', 'compare',
                'gl', 'x11',
            ),
        ):
            diff = (outputs / (node.stem + '.diff.png'))

            if diff.exists():
                ref = Path('testsuite', 'gsk', 'compare', node.stem + '.png')
                out = (outputs / (node.stem + '.out.png'))

                for path in (ref, out, diff):
                    if path.exists():
                        print('begin-base64 644 %s' % path)
                        sys.stdout.flush()
                        with open(path, 'rb') as reader:
                            base64.encode(reader, sys.stdout.buffer)
                        print('====')
                        print('')

                print('')

    for ui in Path('testsuite', 'reftests').glob('*.ui'):
        for outputs in (
            Path(
                'debian', 'build', 'deb', 'testsuite', 'reftests',
                'output', 'x11',
            ),
        ):
            diff = (outputs / (ui.stem + '.diff.png'))

            if diff.exists():
                ref = (outputs / (ui.stem + '.ref.png'))
                out = (outputs / (ui.stem + '.out.png'))

                for path in (ref, out, diff):
                    if path.exists():
                        print('')
                        print('begin-base64 644 %s' % path)
                        sys.stdout.flush()
                        with open(path, 'rb') as reader:
                            base64.encode(reader, sys.stdout.buffer)
                        print('====')
                        print('')

                print('')

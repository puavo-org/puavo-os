#!/usr/bin/python3
# Copyright 2021 Simon McVittie
# SPDX-License-Identifier: CC0-1.0

import base64
import sys
from pathlib import Path

if __name__ == '__main__':
    for ui in Path('testsuite', 'reftests').glob('*.ui'):
        for outputs in (
            Path(
                'debian', 'build', 'deb', 'testsuite', 'reftests',
                'output',
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

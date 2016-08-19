#!/usr/bin/env python
# Paul Sladen 2011-09-27, Copyright 2011 Canonical Ltd.  Distributed under the terms of the GNU GPL v3

import sys

def main(codepoint_source = 'cp437.set'):
    try:
        codepoint_source = sys.argv[1]
    except IndexError: pass
    sampler = ''
    for codepoint,i in zip(open(codepoint_source, 'r').readlines(),xrange(1000)):
        try:
            sampler += (unichr(int(codepoint.split('+')[1],16)))
            if (i+1) % 16 == 0:
                sampler += '\n'
        except: break
    print sampler.encode('UTF-8'),

if __name__=='__main__':
    main()

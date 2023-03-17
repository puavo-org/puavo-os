'''Apport package hook for openjdk-11 packages.

Copyright (C) 2017 Canonical Ltd.
Author: Tiago Stürmer Daitx <tiago.daitx@canonical.com>'''

import os
import re
import sys
from apport.hookutils import *

def si_units(size):
    for unit in ['KiB', 'MiB', 'GiB']:
        size /= 1024
        if size < 1024:
            break
    return '{0:.1f} {1}'.format(size, unit)

def add_info(report, ui=None):
    attach_conffiles(report,'openjdk-11-jre-headless', ui=ui)

    if report['ProblemType'] == 'Crash' and 'ProcCwd' in report:
        # attach hs_err_<pid>.pid file
        cwd = report['ProcCwd']
        pid_line = re.search("Pid:\t(.*)\n", report["ProcStatus"])
        if pid_line:
            pid = pid_line.groups()[0]
            path = "%s/hs_err_pid%s.log" % (cwd, pid)
            # make sure if exists
            if os.path.exists(path):
                content = read_file(path)
                # truncate if bigger than 100 KB
                # see LP: #1696814
                max_length = 100*1024
                if sys.getsizeof(content) < max_length:
                    report['HotspotError'] = content
                    report['Tags'] += ' openjdk-hs-err'
                else:
                    report['HotspotError'] = content[:max_length] + \
                            "\n[truncated by openjdk-11 apport hook]" + \
                            "\n[max log size is %s, file size was %s]" % \
                            (si_units(max_length), si_units(sys.getsizeof(content)))
                    report['Tags'] += ' openjdk-hs-err'
            else:
                report['HotspotError'] = "File not found: %s" % path
        else:
            report['HotspotError'] = "PID not found in ProcStatus entry."

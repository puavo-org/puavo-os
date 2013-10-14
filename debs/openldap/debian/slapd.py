#!/usr/bin/python

'''apport hook for slapd

(c) 2010 Adam Sommer.
Author: Adam Sommer <asommer@ubuntu.com>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.  See http://www.gnu.org/copyleft/gpl.html for
the full text of the license.
'''

from apport.hookutils import *
import os

# Scrub olcRootPW attribute and credentials strings if necessary.
def scrub_pass_strings(config):
    olcrootpw_regex = re.compile('olcRootPW:.*')
    olcrootpw_string = olcrootpw_regex.search(config)
    if olcrootpw_string:
        config = config.replace(olcrootpw_string.group(0), 'olcRootPW: @@APPORTREPLACED@@') 

    credentials_regex = re.compile('credentials=.* ')
    credentials_string = credentials_regex.search(config)
    if credentials_string:
        config = config.replace(credentials_string.group(0), 'credentials=@@APPORTREPLACED@@ ') 

    return config

def add_info(report, ui):
    response = ui.yesno("The contents of your /etc/ldap/slapd.d directory "
                        "may help developers diagnose your bug more "
                        "quickly.  However, it may contain sensitive "
                        "information.  Do you want to include it in your "
                        "bug report?")

    if response == None: # user cancelled
        raise StopIteration

    elif response == True:
        # Get the cn=config tree.
        cn_config = root_command_output(['/usr/bin/ldapsearch', '-Q', '-LLL', '-Y EXTERNAL', '-H ldapi:///', '-b cn=config'])
        report['CNConfig'] = scrub_pass_strings(cn_config)

        # Get slapd messages from /var/log/syslog
        slapd_re = re.compile('slapd', re.IGNORECASE)
        report['SysLog'] = recent_syslog(slapd_re)

        attach_mac_events(report, '/usr/sbin/slapd')

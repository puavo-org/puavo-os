#!/usr/bin/env python
#
# Copyright (C) 2007 Jurij Smakov <jurij@debian.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

import re
import os
import sys
import glob
import stat
import datetime

pkgbase = '/org/ftp.debian.org/ftp/pool/main/l/linux-2.6/'
webbase = 'public_html'
master_template = '%s/sw/master.template' % webbase
arch_template = '%s/sw/arch.template' % webbase
arches = ('alpha', 'amd64', 'arm', 'armel', 'hppa', 'i386', 'ia64', 'm68k', 'mips',
          'mipsel', 'powerpc', 's390', 'sparc')

def openlog(logfile):
	global logfd
	try:
		logfd = open(logfile, 'w')
	except IOError:
		logfd = sys.stderr

def closelog():
	global logfd
	logfd.close()
	
def log(s):
	global logfd
	logfd.write('%s\n' % s)
	logfd.flush()

def make_row_main(file, count):
	color = (count % 2 == 0) and 'white' or 'grey'
	res = '<tr class="%s">\n' % color
	res += '<td><strong>%s</strong></td>\n' % file
	for a in arches:
		res += '<td><a href="%s/%s/">%s</a></td>\n' % (file, a, a)
	res += '</tr>\n'
	return res

def make_table_main(dir, files):
	versions = filter(lambda x: x[0:2] == '2.', files)
	if not versions: return ''
	versions.sort(lambda x, y: -cmp(x,y))
	res = ''
	count = 1
	for v in versions:
		res += make_row_main(v, count)
		count += 1
	return res

def make_table_arch(dir, files):
	configs = filter(lambda x: 'config' in x, files)
	if not configs:
		res = '<tr class="white"><td colspan=3>\n'
		res += 'No files available at this time.\n'
		res += 'This may happen if the binary package for this architecture\n'
		res += 'was not built yet, or the automatic build failed.\n'
		res += '</td></tr>\n'
		return res
	res = ''
	count = 1
	for c in configs:
		res += make_row_arch(dir, c, count)
		count += 1
	return res

def make_row_arch(dir, file, count):
	fstat = os.stat(os.path.join(dir, file))
	fsize = fstat[stat.ST_SIZE]
	ftime = datetime.datetime.fromtimestamp(fstat[stat.ST_MTIME])
	color = (count % 2 == 0) and 'grey' or 'white'
	res = '<tr class="%s">\n' % color
	res += '<td style="text-align:left"><a href="%s">%s</a></td>\n' % (file, file)
	res += '<td>%s</td>\n' % ftime.strftime('%a %b %d %H:%M:%S')
	res += '<td>%ld</td>\n' % fsize
	res += '</tr>\n'
	return res

def get_dict_arch(dir):
	res = {}
	t = dir.split('/')
	res['version'] = t[1]
	res['arch'] = t[2]
	return res

def time_now():
	return datetime.datetime.now().strftime('%a %b %d %H:%M:%S')

def write_html(dir, template, make_table, get_dict=None):
	dict = {}
	if get_dict: dict = get_dict(dir)
	dict['timestamp'] = time_now()
	dict['table'] = make_table(dir, os.listdir(dir))
	tmpl = open(template).read()
	open(os.path.join(dir, 'index.html'), 'w').write(tmpl % dict)

def extract_configs(basedir):
	res = []
	rdeb = re.compile('(linux-image|linux-modules)-(.+)?_(.+)?_(.+)\.deb')
	for pkgname in os.listdir(basedir):
		m = rdeb.match(pkgname)
		if not m: continue
		log('I: processing %s' % pkgname)
		t = m.group(2).split('-')
		uver = t[0]
		abi  = t[1]
		flavor = '-'.join(t[2:])
		ver  = m.group(3)
		arch = m.group(4)
		config_name = 'config-%s-%s-%s' % (uver, abi, flavor)
		config_deb  = './boot/%s' % config_name
		config_ver  = os.path.join(webbase, ver)
		config_dir  = os.path.join(config_ver, arch)
		config_file = os.path.join(config_dir, config_name)
		if os.path.isfile('%s.gz' % config_file):
			log('I: file %s already exists, skipping' % config_file)
			continue
		# Attempt to extract
		pkg = os.path.join(basedir, pkgname)
		cmd = 'ar p %s data.tar.gz | tar xzf - %s' % (pkg, config_deb)
		log('I: extracting config from %s' % pkg)
		status = os.system(cmd)
		if os.WEXITSTATUS(status) != 0:
			log('E: extraction failed, skipping')
			continue
		log('I: extracted %s' % config_deb)

		if not os.path.isdir(config_dir): os.makedirs(config_dir)
		os.rename(config_deb, config_file)
		os.system('gzip -9 %s' % config_file)
		log('I: wrote %s.gz' % config_file)
		if config_ver not in res: res.append(config_ver)
	return res

#
# Main routine
#
openlog('public_html/logs/getconfig.log')
log('I: commencing getconfig.py run at %s' % time_now())
update_needed = extract_configs(pkgbase)
if len(sys.argv) > 1 and sys.argv[1] == 'force-update':
	# Regenerate all HTML
	log('I: update forced, will regenerate all HTML')
	update_needed = glob.glob('%s/2.*' % webbase)
log('I: extraction finished, need updates in %d directories' % len(update_needed))
for verdir in update_needed:
	for a in arches:
		dir = os.path.join(verdir, a)
		if not os.path.isdir(dir): os.makedirs(dir)
		log('I: updating index.html in %s' % dir)
		write_html(dir, arch_template, make_table_arch, get_dict = get_dict_arch)
log('I: generating main index.html')
write_html(webbase, master_template, make_table_main) 
log('I: run finished at %s' % time_now())

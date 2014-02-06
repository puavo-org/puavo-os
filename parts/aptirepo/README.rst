==========
 Aptirepo
==========

Simple APT repository tools.

Author: Tuomas Räsänen <tuomasjjrasanen@tjjr.fi>
License: GPLv2+

Usage
=====

To create and initialize an empty repository, run::

  mkdir -p myrepo/conf
  cd myrepo
  cat <<EOF >conf/distributions
  Codename: wheezy
  Components: main contrib
  Architectures: i386 amd64 source
  EOF

Then, to import new packages to the repository in the current directory,
run::

  aptirepo-import /path/to/package.changes

It creates pool/ and copies packages into it and then generates
Contents, Packages, Sources and Release files to dists/ directory tree.

Optionally, if you want to import packages to a repository in some other
directory, run::

  APTIREPO_ROOTDIR=/path/to/repository aptirepo-import /path/to/packages.changes

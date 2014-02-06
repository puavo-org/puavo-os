==========
 Aptirepo
==========

Simple APT repository tools.

Authors:
 - Tuomas Räsänen <tuomasjjrasanen@tjjr.fi>
 - Esa-Matti Suuronen <esa-matti@suuronen.org>

License: GPLv2+

Overview
========

Aptirepo consists of three components: ``aptirepo``, ``http`` and
``upload``.

``aptirepo`` is the core of this project. It provides tools for creating
and maintaining APT repositories.

``http`` provides a Flask application which manages multiple independent
repositories as "branches" and makes package uploading easy via its HTTP
API.

``upload`` is the natural counterpart of ``http`` component: simple tool
for uploading packages to remote repositories.

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
  aptirepo updatedists

This gives you fully functional, albeit empty, APT repository.

To import packages to the repository, run::

  aptirepo importchanges /path/to/package.changes

It copies packages into ``pool/`` and then generates ``Contents``,
``Packages``, ``Sources`` and ``Release`` files to ``dists/`` directory
tree. If you want to create signed ``Release.gpg`` files, use
``--sign-releases`` option.

Optionally, if you want to import packages to a repository in some other
directory, run::

  APTIREPO_ROOTDIR=/path/to/repository aptirepo importchanges /path/to/packages.changes

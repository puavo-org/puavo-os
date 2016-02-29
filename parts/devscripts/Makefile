prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share
sharedir = $(datarootdir)/puavo-devscripts
sysconfdir = /etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

all:

bin/puavo-devscripts-env: Makefile
	echo "#!/bin/sh" > $@
	echo "export PUAVO_DEVSCRIPTS_SHAREDIR=$(sharedir)" >> $@

installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sharedir)/git-hooks

install: bin/puavo-devscripts-env installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		bin/adm-x \
		bin/adm-x11vnc \
		bin/adm-xrandr \
		bin/db2fig.kdc \
		bin/dpkg-diff-img \
		bin/log2db.kdc \
		bin/puavo-build-debian-dir \
		bin/puavo-dch \
		bin/puavo-debuild \
		bin/puavo-devscripts-env \
		bin/puavo-img-clone \
		bin/puavo-img-chroot \
		bin/puavo-install-deps \
		bin/puavo-install-git-hooks \
		bin/puavo-passwd

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sharedir)/git-hooks \
		share/git-hooks/*

	rm -f bin/puavo-devscripts-env

install-lxc-tools: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		bin/puavo-lxc-prepare \
		bin/puavo-lxc-run \
		bin/puavo-lxc-run-sudo-wrap

install-dch-suffix: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		bin/dch-suffix

clean:

.PHONY: all			 \
	bin/puavo-devscripts-env \
	clean			 \
	install			 \
	install-dch-suffix	 \
	install-lxc-tools	 \
	installdirs

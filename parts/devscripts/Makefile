prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

all:

installdirs:
	mkdir -p $(DESTDIR)$(bindir)

install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		bin/puavo-dch \
		bin/puavo-deb-release \
		bin/puavo-cp-debian-directory \
		bin/puavo-install-deps \
		bin/puavo-build-and-upload \
		bin/mkpkg \
		bin/mktar \
		bin/dpkg-diff-img

install-lxc-tools: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		bin/puavo-lxc-ci-prepare \
		bin/puavo-lxc-run \
		bin/puavo-lxc-run-sudo-wrap

clean:

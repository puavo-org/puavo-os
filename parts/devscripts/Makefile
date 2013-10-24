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
		bin/puavo-dch-legacy \
		bin/puavo-deb-release \
		bin/puavo-fetch-debian-dir \
		bin/puavo-install-deps \
		bin/puavo-debuild \
		bin/puavo-build-debian-dir \
		bin/puavo-deb-upload \
		bin/mkpkg \
		bin/mktar \
		bin/dpkg-diff-img

install-lxc-tools: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		bin/puavo-lxc-prepare \
		bin/puavo-lxc-run \
		bin/puavo-lxc-run-sudo-wrap

clean:

clean-deb:
	rm -f ../puavo-devscripts_*.deb
	rm -f ../puavo-devscripts_*.changes
	rm -f ../puavo-devscripts_*.dsc
	rm -f ../puavo-devscripts_*.tar.gz

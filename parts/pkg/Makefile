prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
sbindir = $(exec_prefix)/sbin
sysconfdir = /etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all:
	${MAKE} -C packages all

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-pkg
	${MAKE} -C packages installdirs

# XXX We do not install puavo-pkg-updater, puavo-pkg-updater.conf and
# XXX puavo-update-remote-pkginstaller-bundle because we probably
# XXX do not need them anymore.

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		puavo-pkg-wine-helper

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-pkg \
		puavo-test-puavo-pkg-installers

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/puavo-pkg \
		puavo-pkg.conf

	${MAKE} -C packages install

.PHONY: clean
clean:
	${MAKE} -C packages clean

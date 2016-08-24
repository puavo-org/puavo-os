prefix = /usr
exec_prefix = $(prefix)
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
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-pkg
	${MAKE} -C packages installdirs

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-pkg \
		puavo-pkg-updater \
		puavo-test-puavo-pkg-installers \
		puavo-update-remote-pkginstaller-bundle

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/puavo-pkg \
		puavo-pkg.conf puavo-pkg-updater.conf

	${MAKE} -C packages install

.PHONY: clean
clean:
	${MAKE} -C packages clean

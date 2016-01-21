prefix=/usr/local
exec_prefix=$(prefix)
bindir=$(prefix)/bin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) puavo-hw-log

.PHONY: install-build-deps
install-build-deps:
	mk-build-deps -i -t "apt-get --yes --force-yes" -r debian.default/control

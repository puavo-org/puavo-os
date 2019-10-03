prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share
sysconfdir = $(prefix)/etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 0644

.PHONY: all
all:

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ers
	mkdir -p $(DESTDIR)$(sysconfdir)/xdg/autostart

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) puavo-ers
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ers Vagrantfile
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/xdg/autostart puavo-ers.desktop

.PHONY: clean
clean:

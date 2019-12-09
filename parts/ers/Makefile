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
	mkdir -p $(DESTDIR)$(sysconfdir)/sudoers.d
	mkdir -p $(DESTDIR)$(sysconfdir)/xdg/autostart

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) puavo-ers-applet \
		puavo-ers-startup
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/sudoers.d \
		etc/sudoers.d/puavo-ers-applet
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/xdg/autostart \
		puavo-ers-startup.desktop

.PHONY: clean
clean:

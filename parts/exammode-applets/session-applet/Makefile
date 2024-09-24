prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share
sysconfdir = /etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all:

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/xdg/autostart

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) puavo-exammode-session-applet \
		start-puavo-exammode-session-applet
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/xdg/autostart \
		start-puavo-exammode-session-applet.desktop

.PHONY: clean
clean:

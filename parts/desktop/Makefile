prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
libdir = $(prefix)/lib
sbindir = $(exec_prefix)/sbin
datarootdir = $(prefix)/share
sysconfdir = $(prefix)/etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all:

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(datarootdir)/gdm/greeter/autostart
	mkdir -p $(DESTDIR)$(datarootdir)/wayland-sessions
	mkdir -p $(DESTDIR)$(datarootdir)/xsessions
	mkdir -p $(DESTDIR)$(libdir)/puavo-desktop
	mkdir -p $(DESTDIR)$(sysconfdir)/X11/Xsession.d
	mkdir -p $(DESTDIR)$(sysconfdir)/xdg/autostart
	mkdir -p $(DESTDIR)/var/lib/puavo-desktop/shared
	mkdir -p $(DESTDIR)/var/lib/puavo-desktop/users

.PHONY: install
install: installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/gdm/greeter/autostart \
		gdm/greeter/autostart/puavo-run-xrandr.desktop

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/wayland-sessions \
		wayland-sessions/*

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/xsessions \
		xsessions/*

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/X11/Xsession.d \
		etc/X11/Xsession.d/*

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/xdg/autostart \
		etc/xdg/autostart/*

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-desktop \
		lib/*

.PHONY: clean
clean:

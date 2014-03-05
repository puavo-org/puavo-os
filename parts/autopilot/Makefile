# XXX why set prefix /usr/local when we know that it must be /usr to work?!?
# XXX (ltsp/xinitrc.d)
prefix = /usr/local

exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
libdir = $(prefix)/lib
datarootdir = $(prefix)/share
sysconfdir = $(prefix)/etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all:

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(libdir)/puavo-autopilot
	mkdir -p $(DESTDIR)$(datarootdir)/ltsp/xinitrc.d
	mkdir -p $(DESTDIR)$(sysconfdir)/xdg/autostart

.PHONY: install
install: installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/ltsp/xinitrc.d \
		I99-lightdm-login

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/xdg/autostart \
		puavo-autopilot-session.desktop

	$(INSTALL) -t $(DESTDIR)$(bindir) \
		bin/puavo-autopilot-lightdm-login \
		bin/puavo-autopilot-lightdm-login-guest \
		bin/puavo-autopilot-session

	$(INSTALL) -t $(DESTDIR)$(libdir)/puavo-autopilot \
		lib/detect-png \
		lib/move-mouse-to-png \
		lib/switch-to-login-vt

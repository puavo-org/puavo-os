# XXX why set prefix /usr/local when we know that it must be /usr to work?!?
# XXX (ltsp/xinitrc.d)
prefix = /usr/local

exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share
sysconfdir = $(prefix)/etc

INSTALL = install -p
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all:

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)/ltsp/xinitrc.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-autopilot/tests
	mkdir -p $(DESTDIR)$(sysconfdir)/xdg/autostart

.PHONY: install
install: installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/ltsp/xinitrc.d \
		I99-lightdm-puavo-autopilot-login

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/xdg/autostart \
		puavo-autopilot-session.desktop

	$(INSTALL) -t $(DESTDIR)$(bindir) \
		bin/pnggrep \
		bin/puavo-autopilot-lightdm-login \
		bin/puavo-autopilot-lightdm-login-guest \
		bin/puavo-autopilot-logger \
		bin/puavo-autopilot-session

	cp -a -t $(DESTDIR)$(datarootdir)/puavo-autopilot/tests \
		tests/*

.PHONY : deb
deb :
	rm -rf debian
	cp -a debian.default debian
	puavo-dch $(shell cat VERSION)
	dpkg-buildpackage -us -uc

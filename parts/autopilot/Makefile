prefix = /usr

exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share
sysconfdir = /etc

INSTALL = install -p
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

all:

installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)/ltsp/xinitrc.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-autopilot/tests
	mkdir -p $(DESTDIR)$(sysconfdir)/xdg/autostart

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

install-deb-deps:
	mk-build-deps -i -r debian/control

deb:
	dpkg-buildpackage -us -uc

.PHONY: all		 \
	deb		 \
	install		 \
	install-deb-deps \
	installdirs

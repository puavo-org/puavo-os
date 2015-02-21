prefix = /usr

exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share
sysconfdir = /etc

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

.PHONY : clean
clean :
	rm -rf debian

.PHONY : install-deb-deps
install-deb-deps :
	mk-build-deps -i -r debian.default/control

.PHONY : debiandir
debiandir :
	rm -rf debian
	cp -a debian.default debian

.PHONY : deb-binary-arch
deb-binary-arch : debiandir
	dpkg-buildpackage -B -us -uc

.PHONY : deb
deb : debiandir
	dpkg-buildpackage -us -uc

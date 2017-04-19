prefix = /usr/local
exec_prefix = $(prefix)

bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share
libdir = $(prefix)/lib
sbindir = $(exec_prefix)/sbin
sysconfdir = $(prefix)/etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all : po/fi/puavo-client-updater-applet.mo po/sv/puavo-client-updater-applet.mo

po/puavo-client-updater-applet.pot : puavo-client-updater-applet
	xgettext --omit-header --language Python --keyword=_tr -o $@ $^

%.po : po/puavo-client-updater-applet.pot
	msgmerge --update --no-fuzzy-matching --backup=off $@ $<
	touch $@

%.mo : %.po
	msgfmt $< --output-file $@

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)/dbus-1/system-services
	mkdir -p $(DESTDIR)$(datarootdir)/icons/hicolor/scalable/status
	mkdir -p $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES
	mkdir -p $(DESTDIR)$(datarootdir)/locale/sv/LC_MESSAGES
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-install
	mkdir -p $(DESTDIR)$(libdir)/puavo-ltsp-install
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)/lib/systemd/system
	mkdir -p $(DESTDIR)$(sysconfdir)/dbus-1/system.d
	mkdir -p $(DESTDIR)$(sysconfdir)/xdg/autostart

.PHONY : install
install : installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		puavo-client-updater-applet

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-client-daemon \
		puavo-install \
		puavo-install-and-update-ltspimages \
		puavo-install-grub \
		puavo-make-install-disk \
		puavo-reset-laptop-to-factory-defaults \
		puavo-setup-filesystems \
		puavo-update-client \
		puavo-update-service-script

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/dbus-1/system-services \
		dbus-1/org.puavo.client.Daemon.service

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/icons/hicolor/scalable/status \
		icons/update-available.svg \
		icons/update-error.svg \
		icons/update-downloading.svg \
		icons/update-downloading-*.svg \
		icons/update-idle.svg \
		icons/update-installed.svg

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES \
		po/fi/puavo-client-updater-applet.mo

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(datarootdir)/locale/sv/LC_MESSAGES \
		po/sv/puavo-client-updater-applet.mo

	cp -R preseeds $(DESTDIR)$(datarootdir)/puavo-ltsp-install/

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-ltsp-install \
		lib/is-update-available \
		lib/ls-old-images \
		lib/puavo-image-preinst \
		lib/update-configuration \
		lib/update-images \
		lib/update-ltspimage-update-stats

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/dbus-1/system.d \
		dbus-1/org.puavo.client.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/xdg/autostart \
		xdg-autostart/*

	$(INSTALL_DATA) -t $(DESTDIR)/lib/systemd/system \
		dbus-1/puavo-update.service

	ln -s -f /lib/systemd/system/puavo-update.service \
		$(DESTDIR)/etc/systemd/system/multi-user.target.wants/puavo-update.service

.PHONY : clean
clean :
	rm -rf po/fi/*.mo
	rm -rf po/sv/*.mo
	rm -rf po/*.pot

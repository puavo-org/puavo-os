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
all:

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)/dbus-1/system-services
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-install
	mkdir -p $(DESTDIR)$(libdir)/puavo-ltsp-install
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)/boot/efi    # needed by puavo-install-grub
	mkdir -p $(DESTDIR)/images      # needed by puavo-image-preinst
	mkdir -p $(DESTDIR)/usr/lib/systemd/system
	mkdir -p $(DESTDIR)$(sysconfdir)/systemd/system/multi-user.target.wants
	mkdir -p $(DESTDIR)$(sysconfdir)/systemd/system/sockets.target.wants
	mkdir -p $(DESTDIR)$(sysconfdir)/xdg/autostart

.PHONY : install
install : installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-bios-config \
		puavo-client-daemon \
		puavo-disk-clone \
		puavo-install \
		puavo-install-and-update-ltspimages \
		puavo-install-grub \
		puavo-make-install-disk \
		puavo-reset-laptop-to-factory-defaults \
		puavo-set-root-password \
		puavo-setup-filesystems \
		puavo-update-client \
		puavo-update-service-script

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/dbus-1/system-services \
		dbus-1/org.puavo.client.Daemon.service

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-ltsp-install \
		lib/is-update-available \
		lib/ls-old-images-and-rdiffs \
		lib/puavo-image-preinst \
		lib/puavo-torrent-updated \
		lib/puavo-torrent-download-complete \
		lib/update-configuration \
		lib/update-images \
		lib/update-ltspimage-update-stats

	$(INSTALL_DATA) -t $(DESTDIR)/usr/lib/systemd/system \
		dbus-1/puavo-update.service

	$(INSTALL_DATA) -t $(DESTDIR)/usr/lib/systemd/system \
		systemd/*

	ln -fs -t $(DESTDIR)$(sysconfdir)/systemd/system/multi-user.target.wants \
		/usr/lib/systemd/system/puavo-torrent-updated.service

	ln -fs -t $(DESTDIR)$(sysconfdir)/systemd/system/sockets.target.wants \
		/usr/lib/systemd/system/puavo-torrent-updated.socket

	ln -fs /usr/lib/systemd/system/puavo-update.service \
		$(DESTDIR)$(sysconfdir)/systemd/system/multi-user.target.wants/puavo-update.service

.PHONY : clean
clean :

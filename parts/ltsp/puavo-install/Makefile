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
		puavo-change-hostname \
		puavo-client-daemon \
		puavo-disk-clone \
		puavo-cleanup-uki-installations \
		puavo-disk-erase \
		puavo-install \
		puavo-install-and-update-ltspimages \
		puavo-install-and-update-uki-image \
		puavo-install-and-update-uki-images \
		puavo-install-grub \
		puavo-install-uki \
		puavo-legacy-install \
		puavo-legacy-setup-filesystems \
		puavo-make-install-disk \
		puavo-manage-efi \
		puavo-reset-laptop-to-factory-defaults \
		puavo-reset-windows \
		puavo-set-root-password \
		puavo-setup-filesystems \
		puavo-update-boot-disks \
		puavo-update-client \
		puavo-update-service-script \
		puavo-update-uki-commandline

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/dbus-1/system-services \
		dbus-1/org.puavo.client.Daemon.service

	$(INSTALL_DATA) -t $(DESTDIR)$(libdir)/puavo-ltsp-install \
		lib/minimal-bcd

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-ltsp-install \
		lib/create-bcd \
		lib/is-encrypted-install \
		lib/is-uki-install \
		lib/is-update-available \
		lib/ls-old-images-and-rdiffs \
		lib/puavo-change-unlock-pin \
		lib/puavo-create-device-keys \
		lib/puavo-create-device-secure-boot-keys \
		lib/puavo-create-device-tpm-keys \
		lib/puavo-generate-recovery-bundle \
		lib/puavo-get-tpm-ek-public \
		lib/puavo-image-preinst \
		lib/puavo-prepare-secure-boot \
		lib/puavo-prepare-tpm-configuration \
		lib/puavo-read-recovery-bundle \
		lib/puavo-reset \
		lib/puavo-setup-secure-boot \
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
		/usr/lib/systemd/system/puavo-image-torrent-updated.service      \
		/usr/lib/systemd/system/puavo-rdiff-torrent-updated.service

	ln -fs -t $(DESTDIR)$(sysconfdir)/systemd/system/sockets.target.wants \
		/usr/lib/systemd/system/puavo-image-torrent-updated.socket    \
		/usr/lib/systemd/system/puavo-rdiff-torrent-updated.socket

	ln -fs /usr/lib/systemd/system/puavo-update.service \
		$(DESTDIR)$(sysconfdir)/systemd/system/multi-user.target.wants/puavo-update.service

.PHONY : clean
clean :

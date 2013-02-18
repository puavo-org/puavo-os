prefix = /usr/local
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin
datarootdir = $(prefix)/share
sysconfdir = $(prefix)/etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)/sbin
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/init
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/pam.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/init
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/ldap
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/sssd
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/ssh
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/default
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp/init-puavo.d
	mkdir -p $(DESTDIR)$(datarootdir)/initramfs-tools/scripts/init-premount
	mkdir -p $(DESTDIR)$(datarootdir)/initramfs-tools/scripts/init-bottom
	mkdir -p $(DESTDIR)$(datarootdir)/ltsp/screen.d

.PHONY : install
install : installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp/init-puavo.d \
		init-puavo.d/*-*

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/init \
		templates/etc/init/gssd.conf-userprincipal

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/ssh \
		templates/etc/ssh/sshd_config \
		templates/etc/ssh/ltspsshd_config

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/pam.d \
		templates/etc/pam.d/ltspsshd \
		templates/etc/pam.d/lightdm-fatclient \
		templates/etc/pam.d/lightdm-laptop \
		templates/etc/pam.d/lightdm-thinclient

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/ldap \
		templates/etc/ldap/ldap.conf \
		templates/etc/ldap/ldap.conf-laptop

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc \
		templates/etc/krb5.conf \
		templates/etc/idmapd.conf \
		templates/etc/nsswitch.conf-extrausers \
		templates/etc/nsswitch.conf-sss

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/default \
		templates/etc/default/nfs-common

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/sssd \
		templates/etc/sssd/sssd.conf

	$(INSTALL_PROGRAM) -t $(DESTDIR)/sbin \
		init-puavo 

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-dns-client \
		puavo-configure-client \
		puavo-ltsp-login \
		puavo-ltsp-mount-nfs-home

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(datarootdir)/initramfs-tools/scripts/init-premount \
		initramfs/puavo_udhcp
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(datarootdir)/initramfs-tools/scripts/init-bottom \
		initramfs/puavo_ltsp 

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(datarootdir)/ltsp/screen.d \
		screen.d/register

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/init \
		upstart/puavo-ltsp-client.conf \
		upstart/ltspssh.conf

	ln -fs /usr/sbin/sshd $(DESTDIR)$(sbindir)/ltspsshd

.PHONY : clean
clean :

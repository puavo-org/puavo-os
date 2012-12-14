prefix = /usr/local
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin
sysconfdir = $(prefix)/etc
datarootdir = $(prefix)/share

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all:

.PHONY: install-dirs
install-dirs:
	mkdir -p $(DESTDIR)/sbin
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)
	mkdir -p $(DESTDIR)$(sysconfdir)/init
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates
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

.PHONY: install
install: install-dirs
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp/init-puavo.d \
		client/init-puavo.d/*-*

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/init \
		client/templates/etc/init/gssd.conf-userprincipal

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/ssh \
		client/templates/etc/ssh/sshd_config \
		client/templates/etc/ssh/ltspsshd_config \

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/pam.d \
		client/templates/etc/pam.d/ltspsshd \
		client/templates/etc/pam.d/lightdm-thinclient \
		client/templates/etc/pam.d/lightdm-fatclient

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/ldap \
		client/templates/etc/ldap/ldap.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc \
		client/templates/etc/krb5.conf \
		client/templates/etc/idmapd.conf \
		client/templates/etc/nsswitch.conf-extrausers \
		client/templates/etc/nsswitch.conf-sss

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/default \
		client/templates/etc/default/nfs-common

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/templates/etc/sssd \
		client/templates/etc/sssd/sssd.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates \
		bootserver/templates/ltsp-server.xml

	$(INSTALL_PROGRAM) -t $(DESTDIR)/sbin \
		client/init-puavo 

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		client/puavo-dns-client \
		client/puavo-configure-client \
		client/puavo-ltsp-login \
		client/puavo-ltsp-mount-nfs-home \
		bootserver/puavo-create-kvm-ltsp-server \
		install/puavo-install \
		install/puavo-install-grub \
		install/puavo-install-ltspimages \
		install/puavo-setup-filesystems

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(datarootdir)/initramfs-tools/scripts/init-premount \
		client/initramfs/puavo_udhcp
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(datarootdir)/initramfs-tools/scripts/init-bottom \
		client/initramfs/puavo_ltsp 

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/ltsp/screen.d \
		client/screen.d/register

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/init \
		client/upstart/puavo-ltsp-client.conf \
		client/upstart/ltspssh.conf

	ln -fs /usr/sbin/sshd $(DESTDIR)$(sbindir)/ltspsshd

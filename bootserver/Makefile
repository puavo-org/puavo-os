prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
sbindir = $(exec_prefix)/sbin
datarootdir = $(prefix)/share

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/apparmor.d/local
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/bind
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/cups
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/default
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/dhcp
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/network
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/pam.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/samba
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/sssd
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/var/lib/bind

.PHONY : bin/puavo-bootserver-installdirs
bin/puavo-bootserver-installdirs :
	mkdir -p bin
	echo "PUAVO_BOOTSERVER_TEMPLATEDIR=$(datarootdir)/puavo-ltsp-bootserver/templates" > $@

.PHONY : install
install : bin/puavo-bootserver-installdirs installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates \
		templates/ltsp-server.xml

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/apparmor.d/local \
		templates/etc/apparmor.d/local/usr.sbin.dhcpd

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc \
		templates/etc/dnsmasq.conf \
		templates/etc/nsswitch.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/dhcp \
		templates/etc/dhcp/dhcpd.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/bind \
		templates/etc/bind/named.conf.local \
		templates/etc/bind/named.conf.options

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/samba \
		templates/etc/samba/smb.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/cups \
		templates/etc/cups/cupsd.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/pam.d \
		templates/etc/pam.d/common-password

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/sssd \
		templates/etc/sssd/sssd.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/network \
		templates/etc/network/interfaces

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/default \
		templates/etc/default/krb5-kdc \
		templates/etc/default/nfs-common.template \
		templates/etc/default/nfs-kernel-server.template \
		templates/etc/default/shorewall \
		templates/etc/default/slapd

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/init.d \
		templates/etc/init.d/krb5-kdc \
		templates/etc/init.d/slapd

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/init \
		templates/etc/init/puavo-krb5-kdc.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/var/lib/bind \
		templates/var/lib/bind/puavo_domain \
		templates/var/lib/bind/puavo_domain_reverse

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		sbin/*

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		bin/*

	rm bin/puavo-bootserver-installdirs

.PHONY : clean
clean :

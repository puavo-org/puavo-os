prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
sbindir = $(exec_prefix)/sbin
datarootdir = $(prefix)/share
templatedir = $(datarootdir)/puavo-ltsp-bootserver/templates
sysconfdir = $(prefix)/etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/sudoers.d
	mkdir -p $(DESTDIR)$(templatedir)/etc/apparmor.d/local
	mkdir -p $(DESTDIR)$(templatedir)/etc/bind
	mkdir -p $(DESTDIR)$(templatedir)/etc/default
	mkdir -p $(DESTDIR)$(templatedir)/etc/dhcp
	mkdir -p $(DESTDIR)$(templatedir)/etc/init
	mkdir -p $(DESTDIR)$(templatedir)/etc/init.d
	mkdir -p $(DESTDIR)$(templatedir)/etc/network
	mkdir -p $(DESTDIR)$(templatedir)/etc/pam.d
	mkdir -p $(DESTDIR)$(templatedir)/etc/samba
	mkdir -p $(DESTDIR)$(templatedir)/var/lib/bind

.PHONY : bin/puavo-bootserver-installdirs
bin/puavo-bootserver-installdirs :
	mkdir -p bin
	echo "PUAVO_BOOTSERVER_TEMPLATEDIR=$(templatedir)" > $@

.PHONY : install
install : bin/puavo-bootserver-installdirs installdirs
	$(INSTALL) -m 440 -t $(DESTDIR)$(sysconfdir)/sudoers.d \
		etc/sudoers.d/puavo-bootserver

	$(INSTALL_DATA) -t $(DESTDIR)$(templatedir) \
		templates/ltsp-server.xml

	$(INSTALL_DATA) -t $(DESTDIR)$(templatedir)/etc/apparmor.d/local \
		templates/etc/apparmor.d/local/usr.sbin.dhcpd

	$(INSTALL_DATA) -t $(DESTDIR)$(templatedir)/etc \
		templates/etc/dnsmasq.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(templatedir)/etc/dhcp \
		templates/etc/dhcp/dhcpd.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(templatedir)/etc/bind \
		templates/etc/bind/named.conf.local \
		templates/etc/bind/named.conf.options

	$(INSTALL_DATA) -t $(DESTDIR)$(templatedir)/etc/samba \
		templates/etc/samba/smb.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(templatedir)/etc/network \
		templates/etc/network/interfaces

	$(INSTALL_DATA) -t $(DESTDIR)$(templatedir)/etc/default \
		templates/etc/default/krb5-kdc \
		templates/etc/default/slapd

	$(INSTALL_DATA) -t $(DESTDIR)$(templatedir)/etc/init.d \
		templates/etc/init.d/krb5-kdc \
		templates/etc/init.d/slapd

	$(INSTALL_DATA) -t $(DESTDIR)$(templatedir)/etc/init \
		templates/etc/init/puavo-krb5-kdc.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(templatedir)/var/lib/bind \
		templates/var/lib/bind/puavo_domain \
		templates/var/lib/bind/puavo_domain_reverse

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		sbin/*

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		bin/*

	rm bin/puavo-bootserver-installdirs

.PHONY : clean
clean :

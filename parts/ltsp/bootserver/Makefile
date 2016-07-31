prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
sbindir = $(exec_prefix)/sbin
datarootdir = $(prefix)/share
templatedir = $(datarootdir)/puavo-ltsp-bootserver/templates
sysconfdir = $(prefix)/etc
libdir = $(prefix)/lib

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/logrotate.d
	mkdir -p $(DESTDIR)$(sysconfdir)/nginx/sites-available
	mkdir -p $(DESTDIR)$(sysconfdir)/sudoers.d
	mkdir -p $(DESTDIR)$(templatedir)/etc/apparmor.d/local
	mkdir -p $(DESTDIR)$(templatedir)/etc/bind
	mkdir -p $(DESTDIR)$(templatedir)/etc/default
	mkdir -p $(DESTDIR)$(templatedir)/etc/dhcp
	mkdir -p $(DESTDIR)$(templatedir)/etc/init.d
	mkdir -p $(DESTDIR)$(templatedir)/etc/network
	mkdir -p $(DESTDIR)$(templatedir)/etc/pam.d
	mkdir -p $(DESTDIR)$(templatedir)/etc/racoon
	mkdir -p $(DESTDIR)$(templatedir)/etc/samba
	mkdir -p $(DESTDIR)$(templatedir)/var/lib/bind
	mkdir -p $(DESTDIR)$(libdir)/puavo-ltsp-bootserver

.PHONY : install
install : installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/logrotate.d \
		etc/logrotate.d/hosts

	$(INSTALL) -m 440 -t $(DESTDIR)$(sysconfdir)/sudoers.d \
		etc/sudoers.d/puavo-bootserver

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/nginx/sites-available \
		etc/nginx/sites-available/ltsp-images

	$(INSTALL_DATA) -t $(DESTDIR)$(templatedir) \
		templates/ltsp-server.xml

	$(INSTALL_DATA) -t $(DESTDIR)$(templatedir)/etc/apparmor.d/local \
		templates/etc/apparmor.d/local/usr.sbin.dhcpd

	$(INSTALL_DATA) -t $(DESTDIR)$(templatedir)/etc \
		templates/etc/dnsmasq.conf \
		templates/etc/ntp.conf \
		templates/etc/rsyslog.conf \

	$(INSTALL_DATA) -t $(DESTDIR)$(templatedir)/etc/dhcp \
		templates/etc/dhcp/dhcpd.conf \
		templates/etc/dhcp/ubnt.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(templatedir)/etc/bind \
		templates/etc/bind/named.conf.local \
		templates/etc/bind/named.conf.options

	$(INSTALL_DATA) -t $(DESTDIR)$(templatedir)/etc/racoon \
		templates/etc/racoon/racoon.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(templatedir)/etc/samba \
		templates/etc/samba/smb.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(templatedir)/var/lib/bind \
		templates/var/lib/bind/puavo_domain \
		templates/var/lib/bind/puavo_domain_reverse

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		bin/*

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		sbin/*

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-ltsp-bootserver \
		lib/*

.PHONY : clean
clean :

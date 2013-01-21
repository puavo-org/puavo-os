prefix = /usr/local
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin
datarootdir = $(prefix)/share

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/apparmor.d/local
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/bind
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/dhcp
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/var/lib/bind

.PHONY : install
install : installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates \
		templates/ltsp-server.xml

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/apparmor.d/local \
		templates/etc/apparmor.d/local/usr.sbin.dhcpd

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc \
		templates/etc/dnsmasq.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/dhcp \
		templates/etc/dhcp/dhcpd.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/etc/bind \
		templates/etc/bind/named.conf.local \
		templates/etc/bind/named.conf.options

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ltsp-bootserver/templates/var/lib/bind \
		templates/var/lib/bind/puavo_domain \
		templates/var/lib/bind/puavo_domain_reverse

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		sbin/*

.PHONY : clean
clean :

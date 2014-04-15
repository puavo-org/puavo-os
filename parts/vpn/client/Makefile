prefix = /usr/local
exec_prefix = $(prefix)
libdir = $(exec_prefix)/lib
sysconfdir = $(prefix)/etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(sysconfdir)/dbus-1/system.d
	mkdir -p $(DESTDIR)$(sysconfdir)/init
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-vpn-client/scripts/route-up
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-vpn-client/scripts/dns-up
	mkdir -p $(DESTDIR)$(sysconfdir)/NetworkManager/dispatcher.d
	mkdir -p $(DESTDIR)$(libdir)/puavo-vpn-client

.PHONY : install
install : installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/dbus-1/system.d \
		dbus/org.puavo.VPN.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/init \
		upstart/puavo-vpn-client.conf \
		upstart/puavo-vpn-dnsmasq.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/puavo-vpn-client \
		openvpn.conf

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-vpn-client \
		lib/runme \
		lib/set-servers

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sysconfdir)/puavo-vpn-client/scripts/route-up \
		scripts/puavo-vpn-dnsmasq

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sysconfdir)/NetworkManager/dispatcher.d \
		dispatcher.d/puavo-vpn-dnsmasq

.PHONY : clean
clean :

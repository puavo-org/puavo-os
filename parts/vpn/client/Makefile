prefix = /usr/local
exec_prefix = $(prefix)
libdir = $(exec_prefix)/lib
sysconfdir = $(prefix)/etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

ifeq ($(prefix), /usr/local)
	systemdsystemunitdir='$(prefix)/lib/systemd/system'
else
	systemdsystemunitdir=$(shell pkg-config systemd --variable=systemdsystemunitdir)
endif

.PHONY : all
all : systemd/puavo-vpn-client-dnsmasq.service systemd/puavo-vpn-client-openvpn.service

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(sysconfdir)/dbus-1/system.d
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-vpn-client/scripts/route-up
	mkdir -p $(DESTDIR)$(libdir)/puavo-vpn-client

.PHONY : install
install : installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/dbus-1/system.d \
		dbus/org.puavo.VPN.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/puavo-vpn-client \
		openvpn.conf

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-vpn-client \
		lib/*

	install -D -m 644 -t '$(DESTDIR)$(systemdsystemunitdir)'	\
		systemd/puavo-vpn-client-dnsmasq.service		\
		systemd/puavo-vpn-client-openvpn.service

systemd/puavo-vpn-client-dnsmasq.service: systemd/puavo-vpn-client-dnsmasq.service.in
	sed -r 's|^ExecStart=.*$$|ExecStart=$(libdir)/puavo-vpn-client/dnsmasq-wrapper|' $< >$@

systemd/puavo-vpn-client-openvpn.service: systemd/puavo-vpn-client-openvpn.service.in
	sed -r 's|^ExecStart=.*$$|ExecStart=$(libdir)/puavo-vpn-client/openvpn-wrapper|' $< >$@

.PHONY : clean
clean :

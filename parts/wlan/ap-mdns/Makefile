prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
sbindir = $(exec_prefix)/sbin
datarootdir = $(prefix)/share
sysconfdir = $(prefix)/etc
localstatedir = $(prefix)/var

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : config
config : config.in
	sed -e "s|#{PWAP_MDNS_STATEDIR}|$(localstatedir)/lib/puavo-wlanap-mdns|g" \
	    config.in >$@
	chmod --reference=config.in $@

.PHONY : puavo-wlanap-mdns-env
puavo-wlanap-mdns-env :
	echo "#!/bin/sh" > $@
	echo "export PWAP_MDNS_CONFDIR=$(sysconfdir)/puavo-wlanap-mdns" >> $@
	echo "export PWAP_MDNS_DATADIR=$(datarootdir)/puavo-wlanap-mdns" >> $@

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-wlanap/vtun-up.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-wlanap/vtun-down.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-wlanap-mdns
	mkdir -p $(DESTDIR)$(localstatedir)/lib/puavo-wlanap-mdns
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-wlanap-mdns

.PHONY : install
install : installdirs puavo-wlanap-mdns-env config
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-wlanap-mdns
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(datarootdir)/puavo-wlanap/vtun-up.d \
		vtun-up.d/40-add-iface
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(datarootdir)/puavo-wlanap/vtun-down.d \
		vtun-down.d/40-del-iface
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-wlanap-mdns \
		config \
		printer.service.in \
		avahi-daemon.conf.in
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/puavo-wlanap-mdns \
		config
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		puavo-wlanap-mdns-env
	rm -f puavo-wlanap-mdns-env

.PHONY : clean
clean :

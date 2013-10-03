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
	sed -e "s|#{PWAP_DNSPROXY_STATEDIR}|$(localstatedir)/lib/puavo-wlanap-dnsproxy|g" \
	    config.in >$@
	chmod --reference=config.in $@

.PHONY : puavo-wlanap-dnsproxy-env
puavo-wlanap-dnsproxy-env :
	echo "#!/bin/sh" > $@
	echo "export PWAP_CONFDIR=$(sysconfdir)/puavo-wlanap-dnsproxy" >> $@
	echo "export PWAP_DATADIR=$(datarootdir)/puavo-wlanap-dnsproxy" >> $@

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-wlanap/vtun-up.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-wlanap/vtun-down.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-wlanap-dnsproxy
	mkdir -p $(DESTDIR)$(localstatedir)/lib/puavo-wlanap-dnsproxy
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-wlanap-dnsproxy

.PHONY : install
install : installdirs puavo-wlanap-dnsproxy-env config
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-wlanap-dnsproxy
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(datarootdir)/puavo-wlanap/vtun-up.d \
		vtun-up.d/40-enable-dns-capture
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(datarootdir)/puavo-wlanap/vtun-down.d \
		vtun-down.d/40-disable-dns-capture
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-wlanap-dnsproxy \
		config
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/puavo-wlanap-dnsproxy \
		config
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		puavo-wlanap-dnsproxy-env
	rm -f puavo-wlanap-dnsproxy-env

.PHONY : clean
clean :

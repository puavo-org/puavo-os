prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
sbindir = $(exec_prefix)/sbin
sysconfdir = $(prefix)/etc
datarootdir = $(prefix)/share
libdir = $(prefix)/lib

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : puavo-wlanap-env
puavo-wlanap-env :
	echo "#!/bin/sh" > $@
	echo "export PUAVO_WLANAP_CONFDIR=$(sysconfdir)/puavo-wlanap" >> $@
	echo "export PUAVO_WLANAP_DATADIR=$(datarootdir)/puavo-wlanap" >> $@
	echo "export PUAVO_WLANAP_LIBDIR=$(libdir)/puavo-wlanap" >> $@

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-wlanap
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-wlanap
	mkdir -p $(DESTDIR)$(libdir)/puavo-wlanap

.PHONY : install
install : puavo-wlanap-env installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		puavo-wlanap-env
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-wlanap
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-wlanap \
		config_defaults \
		vtund.conf \
		eap_hostapd.conf \
		psk_hostapd.conf \
		open_hostapd.conf
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/puavo-wlanap \
		config
	$(INSTALL_DATA) -t $(DESTDIR)$(libdir)/puavo-wlanap \
		lib/common.sh
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-wlanap \
		lib/write-runconf \
		lib/hostapd-event \
		lib/vtun-down \
		lib/vtun-up
	rm -f puavo-wlanap-env

.PHONY : clean
clean :

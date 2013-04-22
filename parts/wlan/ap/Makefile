prefix = /usr/local
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin
sysconfdir = $(prefix)/etc
datarootdir = $(prefix)/share
libdir = $(prefix)/lib

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : bin/puavo-wlanap-env
bin/puavo-wlanap-env :
	mkdir -p bin
	echo "#!/bin/sh" > $@
	echo "export PUAVO_WLANAP_CONFDIR=$(sysconfdir)/puavo-wlanap" >> $@
	echo "export PUAVO_WLANAP_DATADIR=$(datarootdir)/puavo-wlanap" >> $@
	echo "export PUAVO_WLANAP_LIBDIR=$(libdir)/puavo-wlanap" >> $@

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-wlanap
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-wlanap
	mkdir -p $(DESTDIR)$(libdir)/puavo-wlanap

.PHONY : install
install : installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-wlanap
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-wlanap \
		config \
		vtund.conf \
		eap_hostapd.conf \
		psk_hostapd.conf \
		open_hostapd.conf
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/puavo-wlanap \
		config \
		vtund.conf \
		eap_hostapd.conf \
		psk_hostapd.conf \
		open_hostapd.conf
	$(INSTALL_DATA) -t $(DESTDIR)$(libdir)/puavo-wlanap \
		lib/common.sh
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-wlanap \
		lib/write-runconf \
		lib/hostapd-event \
		lib/vtun-down \
		lib/vtun-up

.PHONY : clean
clean :

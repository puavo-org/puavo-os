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
	echo "export PWAP_CONFDIR=$(sysconfdir)/puavo-wlanap" >> $@
	echo "export PWAP_DATADIR=$(datarootdir)/puavo-wlanap" >> $@
	echo "export PWAP_LIBDIR=$(libdir)/puavo-wlanap" >> $@

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-wlanap
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-wlanap
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-wlanap/vtun-up.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-wlanap/vtun-down.d
	mkdir -p $(DESTDIR)$(libdir)/puavo-wlanap

.PHONY : install
install : puavo-wlanap-env installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-wlanap/vtun-up.d \
		vtun-up.d/README
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-wlanap/vtun-down.d \
		vtun-down.d/README
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(datarootdir)/puavo-wlanap/vtun-up.d \
		vtun-up.d/01-add-network
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(datarootdir)/puavo-wlanap/vtun-down.d \
		vtun-down.d/01-del-network
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		puavo-wlanap-env
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-wlanap
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-wlanap \
		config \
		templates/vtund.conf \
		templates/common.conf \
		templates/psk_hostapd.conf \
		templates/open_hostapd.conf \
		supported_drivers
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/puavo-wlanap \
		config
	$(INSTALL_DATA) -t $(DESTDIR)$(libdir)/puavo-wlanap \
		lib/common.sh
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-wlanap \
		lib/report-hostapd-event \
		lib/vtun-down \
		lib/vtun-up \
		lib/get-bssid \
		lib/find-ifaces \
		lib/fetch-nets \
		lib/scan-channels \
		lib/get-ht-capab \
		lib/get-bridge \
		lib/set-txpower
	rm -f puavo-wlanap-env

.PHONY : clean
clean :

prefix = /usr/local
sbindir= $(prefix)/sbin
datarootdir = $(prefix)/share

ifeq ($(prefix), /usr/local)
	systemdsystemunitdir='$(prefix)/lib/systemd/system'
else
	systemdsystemunitdir=$(shell pkg-config systemd --variable=systemdsystemunitdir)
endif

ifeq ($(prefix), /usr/local)
sysconfdir = $(prefix)/etc
else
sysconfdir = /etc
endif

all:

clean:

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-conf/definitions
	mkdir -p $(DESTDIR)$(sysconfdir)/systemd/network

install: installdirs puavo-wlanap.service
	install -D -m 755 -t '$(DESTDIR)$(sbindir)'	\
		puavo-wlanap				\
		puavo-wlanap-dhclient-script		\
		puavo-wlanap-hostapd-action		\
		puavo-wlanap-test			\
		puavo-wlanap-udev-action

	install -D -m 644 -t '$(DESTDIR)$(systemdsystemunitdir)' \
		puavo-wlanap.service

	install -D -m 644 -t $(DESTDIR)$(datarootdir)/puavo-conf/definitions \
		puavo-wlanap.json

	rm -f puavo-wlanap.service

puavo-wlanap.service: puavo-wlanap.service.in FORCE
	sed -r 's|^ExecStart=.*$$|ExecStart=$(sbindir)/puavo-wlanap|' $< >$@

FORCE:

.PHONY: all clean install

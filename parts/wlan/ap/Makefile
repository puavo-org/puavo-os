prefix = /usr/local
sbindir= $(prefix)/sbin

ifeq ($(prefix), /usr/local)
	systemdsystemunitdir='$(prefix)/lib/systemd/system'
else
	systemdsystemunitdir=$(shell pkg-config systemd --variable=systemdsystemunitdir)
endif

all:

clean:

install: puavo-wlanap.service
	install -D -m 755 -t '$(DESTDIR)$(sbindir)'	\
		puavo-wlanap				\
		puavo-wlanap-dhclient-script		\
		puavo-wlanap-hostapd-action		\
		puavo-wlanap-test			\
		puavo-wlanap-udev-action

	install -D -m 644 -t '$(DESTDIR)$(systemdsystemunitdir)' \
		puavo-wlanap.service

puavo-wlanap.service: puavo-wlanap.service.in FORCE
	sed -r 's|^ExecStart=.*$$|ExecStart=$(sbindir)/puavo-wlanap|' $< >$@

FORCE:

.PHONY: all clean install

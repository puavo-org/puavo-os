prefix = /usr/local

all:

clean:

install:
	install -D -m 755 -t '$(DESTDIR)$(prefix)/sbin' \
		puavo-wlanap				\
		puavo-wlanap-dhclient-script		\
		puavo-wlanap-hostapd-action		\
		puavo-wlanap-test			\
		puavo-wlanap-udev-action

	install -D -m 644 -t '$(DESTDIR)/lib/systemd/system' \
		puavo-wlanap.service

.PHONY: all clean install

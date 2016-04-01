prefix = /usr/local

all:

clean:

install:
	install -D -m 755 puavo-wlanap '$(DESTDIR)$(prefix)/sbin/puavo-wlanap'
	install -D -m 755 puavo-wlanap-test \
		'$(DESTDIR)$(prefix)/sbin/puavo-wlanap-test'
	install -D -m 755 puavo-wlanap-hostapd-action \
		'$(DESTDIR)$(prefix)/sbin/puavo-wlanap-hostapd-action'
	install -D -m 755 puavo-wlanap-udev-action \
		'$(DESTDIR)$(prefix)/sbin/puavo-wlanap-udev-action'
	install -D -m 755 puavo-wlanap-dhclient-script \
		'$(DESTDIR)$(prefix)/sbin/puavo-wlanap-dhclient-script'

	install -D -m 644 -t '$(DESTDIR)/lib/systemd/system' \
		puavo-wlanap.service

.PHONY: all clean install

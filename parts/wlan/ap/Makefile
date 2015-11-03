prefix = /usr/local

all:

clean:

install:
	install -D -m 755 puavo-wlanap '$(DESTDIR)$(prefix)/sbin/puavo-wlanap'
	install -D -m 755 puavo-wlanap-hostapd-action \
		'$(DESTDIR)$(prefix)/sbin/puavo-wlanap-hostapd-action'
	install -D -m 755 puavo-wlanap-udev-action \
		'$(DESTDIR)$(prefix)/sbin/puavo-wlanap-udev-action'

.PHONY: all clean install

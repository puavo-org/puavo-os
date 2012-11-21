prefix = /usr/local
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin
sysconfdir = $(prefix)/etc
localstatedir = $(prefix)/var

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : installdirs
installdirs : build-aux/mkinstalldirs
	build-aux/mkinstalldirs $(DESTDIR)$(sbindir)
	build-aux/mkinstalldirs $(DESTDIR)$(sysconfdir)/puavo-wlanap
	build-aux/mkinstalldirs $(DESTDIR)$(localstatedir)/tmp/puavo-wlanap

.PHONY : install
install : installdirs sbin share
	$(INSTALL_PROGRAM) sbin/puavo-wlanap $(DESTDIR)$(sbindir)/
	$(INSTALL_PROGRAM) sbin/puavo-wlanap-configure $(DESTDIR)$(sbindir)/
	$(INSTALL_PROGRAM) sbin/puavo-wlanap-send-event $(DESTDIR)$(sbindir)/
	$(INSTALL_PROGRAM) sbin/puavo-wlanap-send-status $(DESTDIR)$(sbindir)/
	$(INSTALL_DATA) etc/puavo-wlanap/open_hostapd.conf.template $(DESTDIR)$(sysconfdir)/puavo-wlanap
	$(INSTALL_DATA) etc/puavo-wlanap/eap_hostapd.conf.template $(DESTDIR)$(sysconfdir)/puavo-wlanap
	$(INSTALL_DATA) etc/puavo-wlanap/psk_hostapd.conf.template $(DESTDIR)$(sysconfdir)/puavo-wlanap
	$(INSTALL_DATA) etc/puavo-wlanap/vtund.conf.template $(DESTDIR)$(sysconfdir)/puavo-wlanap

.PHONY : clean
clean :

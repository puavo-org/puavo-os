prefix = /usr/local
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin
sysconfdir = /etc
localstatedir = /var

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : installdirs
installdirs : build-aux/mkinstalldirs
	build-aux/mkinstalldirs $(DESTDIR)$(sbindir)
	build-aux/mkinstalldirs $(DESTDIR)$(sysconfdir)/puavo-wlanap

.PHONY : install
install : installdirs sbin
	$(INSTALL_PROGRAM) sbin/* $(DESTDIR)$(sbindir)/
	$(INSTALL_DATA) etc/puavo-wlanap/* $(DESTDIR)$(sysconfdir)/puavo-wlanap

.PHONY : clean
clean :

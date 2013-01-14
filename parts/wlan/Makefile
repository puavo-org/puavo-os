prefix = /usr/local
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin
sysconfdir = $(prefix)/etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : installdirs
installdirs : build-aux/mkinstalldirs
	build-aux/mkinstalldirs $(DESTDIR)$(sbindir)
	build-aux/mkinstalldirs $(DESTDIR)$(sysconfdir)/puavo-wlanap
	build-aux/mkinstalldirs $(DESTDIR)$(sysconfdir)/default
	build-aux/mkinstalldirs $(DESTDIR)$(sysconfdir)/init.d

.PHONY : install
install : installdirs sbin
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		sbin/*
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/puavo-wlanap \
		etc/puavo-wlanap/*
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sysconfdir)/init.d \
		etc/init.d/puavo-wlanap

.PHONY : clean
clean :

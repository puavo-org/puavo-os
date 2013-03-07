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
installdirs :
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-wlangw

.PHONY : install
install : installdirs
	$(INSTALL_DATA) -m 0600 -t $(DESTDIR)$(sysconfdir)/puavo-wlangw \
		etc/puavo-wlangw/vtund.conf

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		sbin/*

.PHONY : clean
clean :

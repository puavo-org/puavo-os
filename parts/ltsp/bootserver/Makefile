prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
sbindir = $(exec_prefix)/sbin
datarootdir = $(prefix)/share
sysconfdir = $(prefix)/etc
libdir = $(prefix)/lib

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/logrotate.d
	mkdir -p $(DESTDIR)$(sysconfdir)/nginx/sites-available
	mkdir -p $(DESTDIR)$(sysconfdir)/sudoers.d
	mkdir -p $(DESTDIR)$(libdir)/puavo-ltsp-bootserver
	mkdir -p $(DESTDIR)/var/lib/puavo

.PHONY : install
install : installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/logrotate.d \
		etc/logrotate.d/hosts

	$(INSTALL) -m 440 -t $(DESTDIR)$(sysconfdir)/sudoers.d \
		etc/sudoers.d/puavo-bootserver

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		bin/*

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		sbin/*

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-ltsp-bootserver \
		lib/*

.PHONY : clean
clean :

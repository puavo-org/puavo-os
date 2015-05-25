prefix = /usr/local
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin
libdir = $(prefix)/lib

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(libdir)/puavo-ltsp-client/restricted-packages
	mkdir -p $(DESTDIR)$(libdir)/puavo-ltsp-client/restricted-packages/commands

.PHONY : install
install : installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-ltsp-client/restricted-packages \
		lib/common.bash

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-ltsp-client/restricted-packages/commands \
		lib/commands/*

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		sbin/puavo-restricted-package-tool

.PHONY : clean
clean :

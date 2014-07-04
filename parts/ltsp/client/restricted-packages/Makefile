prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
libdir = $(prefix)/lib
datarootdir = $(prefix)/share

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(libdir)/puavo-ltsp-client/restricted-packages
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ltsp-client/restricted-packages

.PHONY : install
install : installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		bin/puavo-restricted-package-tool

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-ltsp-client/restricted-packages \
		lib/*

	cp -r -t $(DESTDIR)$(datarootdir)/puavo-ltsp-client/restricted-packages \
		packages/*

.PHONY : clean
clean :

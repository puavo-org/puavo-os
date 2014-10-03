prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
libdir = $(prefix)/lib
sbindir = $(exec_prefix)/sbin
datarootdir = $(prefix)/share
sysconfdir = $(prefix)/etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-image-tools
	mkdir -p $(DESTDIR)$(libdir)/puavo-image-tools
	mkdir -p $(DESTDIR)$(sbindir)

.PHONY : install
install : installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-image-tools \
		puavo-ask-buildtarget-dir
	
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-build-image
	
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-image-tools \
		ImageBuildMakefile

.PHONY : clean
clean :

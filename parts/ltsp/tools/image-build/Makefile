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
	mkdir -p $(DESTDIR)$(libdir)/puavo-image-tools
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-image-tools

.PHONY : install
install : installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/puavo-image-tools \
		config/ltsp-image.excludes
	
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-image-tools \
		puavo-ask-buildtarget-dir \
		puavo-imgbuild-tool
	
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-build-image \
		puavo-build-rdiffs \
		puavo-setup-imagebuild

.PHONY : clean
clean :

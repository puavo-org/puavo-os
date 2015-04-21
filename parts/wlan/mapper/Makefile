prefix = /usr
libdir = $(prefix)/lib

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

all:

installdirs:
	mkdir -p $(DESTDIR)$(libdir)/puavo-wlanmapper

install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-wlanmapper \
		csv2png

.PHONY: all	    \
	install	    \
	installdirs

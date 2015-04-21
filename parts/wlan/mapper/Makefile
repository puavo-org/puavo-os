prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
libdir = $(prefix)/lib

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

all:

installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(libdir)/puavo-wlanmapper

install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		puavo-wlanmapper

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-wlanmapper \
		lib/draw-heatmap

.PHONY: all	    \
	install	    \
	installdirs

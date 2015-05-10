prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

all:

installdirs:
	mkdir -p $(DESTDIR)$(bindir)

install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		puavo-wlanmapper

.PHONY: all	    \
	install	    \
	installdirs

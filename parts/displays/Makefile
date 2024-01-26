prefix=/usr/local
bindir=$(prefix)/bin
libdir=$(prefix)/lib

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all:

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(libdir)
	mkdir -p $(DESTDIR)$(libdir)/puavo-displays


.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t '$(DESTDIR)$(bindir)'	\
		puavo-display-manager

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-displays \
		lib/*

.PHONY: clean
clean:

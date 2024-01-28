prefix=/usr/local
bindir=$(prefix)/bin
libdir=$(prefix)/lib
pylibdir=$(prefix)/lib/python3/dist-packages

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all:

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(libdir)/puavo-displays
	mkdir -p $(DESTDIR)$(pylibdir)/puavodisplays


.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t '$(DESTDIR)$(bindir)'	\
		puavo-display-manager 			\
		puavo-set-max-bpc

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-displays \
		lib/*

	$(INSTALL_DATA) -t '$(DESTDIR)$(pylibdir)/puavodisplays'	\
		puavodisplays/*.py

.PHONY: clean
clean:

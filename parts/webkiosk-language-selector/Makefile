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
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(libdir)
	mkdir -p $(DESTDIR)$(libdir)/webkiosk-language-selector
	mkdir -p $(DESTDIR)$(sysconfdir)

.PHONY : install
install : installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		webkiosk-language-selector

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/webkiosk-language-selector \
		app/index.html \
		app/index.js \
		app/style.css \
		app/background.png \
		app/package.json

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir) \
		webkiosk.menu

.PHONY : clean
clean :

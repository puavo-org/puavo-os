prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 0644

IMAGES = images/de.png \
         images/en.png \
         images/fi.png \
         images/sv.png

.PHONY: all
all:

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-webkiosk-language-selector

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		webkiosk-language-selector
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-webkiosk-language-selector \
		${IMAGES}

.PHONY: clean
clean:

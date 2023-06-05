prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all: po/de/puavo-laptop-setup.mo po/fi/puavo-laptop-setup.mo po/sv/puavo-laptop-setup.mo

po/puavo-laptop-setup.pot: puavo-laptop-setup
	xgettext --omit-header --language python --keyword=_tr -o $@ $^
	xgettext -j --omit-header --language Glade -o po/puavo-laptop-setup.pot puavo-laptop-setup.glade

%.po: po/puavo-laptop-setup.pot
	msgmerge --update --no-fuzzy-matching --backup=off $@ $<
	touch $@

%.mo: %.po
	msgfmt $< --output-file $@

.PHONY: i18nupdate
i18nupdate: po/puavo-laptop-setup.pot po/de/puavo-laptop-setup.po po/fi/puavo-laptop-setup.po po/sv/puavo-laptop-setup.po



.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)/applications
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-laptop-setup
	mkdir -p $(DESTDIR)$(datarootdir)/locale/de/LC_MESSAGES
	mkdir -p $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES
	mkdir -p $(DESTDIR)$(datarootdir)/locale/sv/LC_MESSAGES
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-conf/definitions


.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) puavo-laptop-setup
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/applications \
		puavo-laptop-setup.desktop
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-laptop-setup \
		puavo-laptop-setup.glade
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/de/LC_MESSAGES \
		po/de/puavo-laptop-setup.mo
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES \
		po/fi/puavo-laptop-setup.mo
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/sv/LC_MESSAGES \
		po/sv/puavo-laptop-setup.mo
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-conf/definitions \
		puavo-laptop-setup.json


.PHONY: clean
clean:
	rm -rf po/*/*.mo po/*.pot

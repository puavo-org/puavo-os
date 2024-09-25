prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share
sysconfdir = /etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all: po/fi/puavo-exammode.mo

po/puavo-exammode.pot: extension.js
	xgettext --omit-header --language Javascript --keyword=_ -o $@ $^

%.po: po/puavo-exammode.pot
	msgmerge --update --no-fuzzy-matching --backup=off $@ $<
	touch $@

%.mo: %.po
	msgfmt $< --output-file $@

.PHONY: i18nupdate
i18nupdate: po/puavo-exammode.pot po/fi/puavo-exammode.po

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(datarootdir)/gnome-shell/extensions/puavo-exammode@puavo.org
	mkdir -p $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES

.PHONY: install
install: installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/gnome-shell/extensions/puavo-exammode@puavo.org \
	    extension.js metadata.json
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES \
		po/fi/puavo-exammode.mo

.PHONY: clean
clean:
	rm -rf po/*/*.mo po/*.pot

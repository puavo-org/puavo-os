prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all: po/fi/puavo-laptop-setup.mo

puavo-laptop-setup.pot: puavo-laptop-setup
	xgettext --omit-header --language python --keyword=_tr -o $@ $^

%.po: po/puavo-laptop-setup.pot
	msgmerge --update --no-fuzzy-matching --backup=off $@ $<
	touch $@

%.mo: %.po
	msgfmt $< --output-file $@

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)/applications
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-laptop-setup
	mkdir -p $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) puavo-laptop-setup
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/applications \
		puavo-laptop-setup.desktop
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-laptop-setup \
		puavo-laptop-setup.glade
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES \
		po/fi/puavo-laptop-setup.mo

.PHONY: clean
clean:
	rm -rf po/*/*.mo po/*.pot

prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all: po/fi/puavo-user-registration.mo

puavo-user-registration.pot: puavo-user-registration
	xgettext --omit-header --language python --keyword=_tr -o $@ $^

%.po: po/puavo-user-registration.pot
	msgmerge --update --no-fuzzy-matching --backup=off $@ $<
	touch $@

%.mo: %.po
	msgfmt $< --output-file $@

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-conf/definitions
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-user-registration

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) puavo-user-registration
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-conf/definitions \
		puavo-user-registration.json
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-user-registration \
		puavo-user-registration.glade

.PHONY: clean
clean:
	rm -rf po/*/*.mo po/*.pot

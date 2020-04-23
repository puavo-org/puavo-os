prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all: po/fi/puavo-user-registration.mo

PY_FILES = page_account.py page_complete.py page_definition.py \
           page_network.py page_welcome.py privacy_policy.py utils.py
puavo-user-registration.pot: puavo-user-registration ${PY_FILES}
	xgettext --from-code UTF-8 --omit-header --language python \
            --keyword=_tr -o $@ $^

%.po: po/puavo-user-registration.pot
	msgmerge --update --no-fuzzy-matching --backup=off $@ $<
	touch $@

%.mo: %.po
	msgfmt $< --output-file $@

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)/applications
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-conf/definitions
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-user-registration/data
	mkdir -p $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) puavo-user-registration
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/applications \
		puavo-user-registration.desktop
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-conf/definitions \
		puavo-user-registration.json
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-user-registration *.py
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-user-registration/data \
		data/*
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES \
		po/fi/puavo-user-registration.mo

.PHONY: clean
clean:
	rm -rf po/*/*.mo po/*.pot

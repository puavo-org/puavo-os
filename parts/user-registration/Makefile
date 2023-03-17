prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share
sysconfdir = $(prefix)/etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all: po/de/puavo-user-registration.mo po/fi/puavo-user-registration.mo po/sv/puavo-user-registration.mo

PY_FILES = page_account.py page_complete.py page_definition.py \
           page_network.py page_welcome.py privacy_policy.py utils.py
po/puavo-user-registration.pot: puavo-user-registration ${PY_FILES}
	xgettext --from-code UTF-8 --omit-header --language python \
            --keyword=_tr -o $@ $^
	xgettext -j --omit-header --language Glade -o po/puavo-user-registration.pot data/account.glade \
            data/complete.glade data/login.glade data/main_window.glade data/network.glade data/welcome.glade

%.po: po/puavo-user-registration.pot
	msgmerge --update --no-fuzzy-matching --backup=off $@ $<
	touch $@

%.mo: %.po
	msgfmt $< --output-file $@

.PHONY: i18nupdate
i18nupdate: po/puavo-user-registration.pot po/de/puavo-user-registration.po po/fi/puavo-user-registration.po po/sv/puavo-user-registration.po


.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)/applications
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-conf/definitions
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-user-registration/data
	mkdir -p $(DESTDIR)$(datarootdir)/locale/de/LC_MESSAGES
	mkdir -p $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES
	mkdir -p $(DESTDIR)$(datarootdir)/locale/sv/LC_MESSAGES
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-external-files-actions.d

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) puavo-user-registration
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sysconfdir)/puavo-external-files-actions.d \
		puavo-external-files-actions.d/*
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/applications \
		puavo-user-registration.desktop
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-conf/definitions \
		puavo-user-registration.json
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-user-registration *.py
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-user-registration/data \
		data/*
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/de/LC_MESSAGES \
		po/de/puavo-user-registration.mo
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES \
		po/fi/puavo-user-registration.mo
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/sv/LC_MESSAGES \
		po/sv/puavo-user-registration.mo

.PHONY: clean
clean:
	rm -rf po/*/*.mo po/*.pot

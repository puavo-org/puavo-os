prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
sbindir = $(exec_prefix)/sbin
sysconfdir = /etc
datarootdir = $(prefix)/share

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all: po/de/puavo-pkgs-ui.mo po/fi/puavo-pkgs-ui.mo po/sv/puavo-pkgs-ui.mo
	${MAKE} -C packages all

po/puavo-pkgs-ui.pot: puavo-pkgs-ui
	xgettext --omit-header --language python --keyword=_tr -o $@ $^

%.po: po/puavo-pkgs-ui.pot
	msgmerge --update --no-fuzzy-matching --backup=off $@ $<
	touch $@

%.mo: %.po
	msgfmt $< --output-file $@

.PHONY: i18nupdate
i18nupdate: po/puavo-pkgs-ui.pot po/de/puavo-pkgs-ui.po po/fi/puavo-pkgs-ui.po po/sv/puavo-pkgs-ui.po


.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-pkg
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-conf/definitions
	mkdir -p $(DESTDIR)$(datarootdir)/locale/de/LC_MESSAGES
	mkdir -p $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES
	mkdir -p $(DESTDIR)$(datarootdir)/locale/sv/LC_MESSAGES
	${MAKE} -C packages installdirs

.PHONY: install
install: installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-conf/definitions \
                puavo-pkgs-ui.json
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		puavo-pkg-wine-helper

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-pkg \
		puavo-pkgs-ui \
		puavo-pkg-update \
		puavo-pkg-update-from-gui \
		puavo-test-puavo-pkg-installers

	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/puavo-pkg \
		puavo-pkg.conf

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/de/LC_MESSAGES \
		po/de/puavo-pkgs-ui.mo

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES \
		po/fi/puavo-pkgs-ui.mo

	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/sv/LC_MESSAGES \
		po/sv/puavo-pkgs-ui.mo

	${MAKE} -C packages install

.PHONY: clean
clean:
	${MAKE} -C packages clean
	rm -rf po/*/*.mo po/*.pot

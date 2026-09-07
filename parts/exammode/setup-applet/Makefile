prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share
sysconfdir = /etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all: po/de/puavo-exammode-setup-applet.mo po/fi/puavo-exammode-setup-applet.mo po/sv/puavo-exammode-setup-applet.mo

po/puavo-exammode-setup-applet.pot: puavo-exammode-setup-applet
	xgettext --omit-header --language Python --keyword=_tr -o $@ $^

%.po: po/puavo-exammode-setup-applet.pot
	msgmerge --update --no-fuzzy-matching --backup=off $@ $<
	touch $@

%.mo: %.po
	msgfmt $< --output-file $@

.PHONY: i18nupdate
i18nupdate: po/puavo-exammode-setup-applet.pot po/de/puavo-exammode-setup-applet.po po/fi/puavo-exammode-setup-applet.po po/sv/puavo-exammode-setup-applet.po

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-exammode
	mkdir -p $(DESTDIR)$(sysconfdir)/xdg/autostart
	mkdir -p $(DESTDIR)$(datarootdir)/locale/de/LC_MESSAGES
	mkdir -p $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES
	mkdir -p $(DESTDIR)$(datarootdir)/locale/sv/LC_MESSAGES

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) puavo-exammode-setup-applet \
		start-puavo-exammode-setup-applet
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-exammode \
		puavo-exammode-setup-applet.svg
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/xdg/autostart \
		start-puavo-exammode-setup-applet.desktop
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/de/LC_MESSAGES \
		po/de/puavo-exammode-setup-applet.mo
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES \
		po/fi/puavo-exammode-setup-applet.mo
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/sv/LC_MESSAGES \
		po/sv/puavo-exammode-setup-applet.mo

.PHONY: clean
clean:
	rm -rf po/*/*.mo po/*.pot

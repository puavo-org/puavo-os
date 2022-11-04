prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share
sysconfdir = $(prefix)/etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 0644

.PHONY: all
all: po/de/puavo-ers-applet.mo po/fi/puavo-ers-applet.mo po/sv/puavo-ers-applet.mo

po/puavo-ers-applet.pot: puavo-ers-applet
	xgettext --omit-header --language Python --keyword=_tr -o $@ $^

%.po: po/puavo-ers-applet.pot
	msgmerge --update --no-fuzzy-matching --backup=off $@ $<
	touch $@

%.mo: %.po
	msgfmt $< --output-file $@

.PHONY: i18nupdate
i18nupdate: po/puavo-ers-applet.pot po/de/puavo-ers-applet.po po/fi/puavo-ers-applet.po po/sv/puavo-ers-applet.po


.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)/locale/de/LC_MESSAGES
	mkdir -p $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES
	mkdir -p $(DESTDIR)$(datarootdir)/locale/sv/LC_MESSAGES
	mkdir -p $(DESTDIR)$(sysconfdir)/sudoers.d
	mkdir -p $(DESTDIR)$(sysconfdir)/xdg/autostart

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) puavo-ers-applet \
		puavo-ers-startup
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/sudoers.d \
		etc/sudoers.d/puavo-ers-applet
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/de/LC_MESSAGES \
		po/de/puavo-ers-applet.mo
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES \
		po/fi/puavo-ers-applet.mo
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/sv/LC_MESSAGES \
		po/sv/puavo-ers-applet.mo
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/xdg/autostart \
		puavo-ers-startup.desktop

.PHONY: clean
clean:
	rm -rf po/*/*.mo po/*.pot

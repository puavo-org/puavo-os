prefix = /usr
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share
sysconfdir = /etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all: po/fi/puavo-exammode-session-applet.mo

po/puavo-exammode-session-applet.pot: puavo-exammode-session-applet
	xgettext --omit-header --language Python --keyword=_tr -o $@ $^

%.po: po/puavo-exammode-session-applet.pot
	msgmerge --update --no-fuzzy-matching --backup=off $@ $<
	touch $@

%.mo: %.po
	msgfmt $< --output-file $@

.PHONY: i18nupdate
i18nupdate: po/puavo-exammode-session-applet.pot po/fi/puavo-exammode-session-applet.po

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/xdg/autostart
	mkdir -p $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) puavo-exammode-session-applet \
		start-puavo-exammode-session-applet
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/xdg/autostart \
		start-puavo-exammode-session-applet.desktop
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/locale/fi/LC_MESSAGES \
		po/fi/puavo-exammode-session-applet.mo

.PHONY: clean
clean:
	rm -rf po/*/*.mo po/*.pot

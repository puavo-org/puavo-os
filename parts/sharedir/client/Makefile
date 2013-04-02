prefix      = /usr/local
exec_prefix = $(prefix)
bindir      = $(exec_prefix)/bin
sysconfdir  = $(prefix)/etc

INSTALL         = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA    = $(INSTALL) -m 644

all:

install-dirs:
	mkdir -p $(DESTDIR)$(sysconfdir)/xdg/autostart
	mkdir -p $(DESTDIR)$(bindir)

install: install-dirs
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/xdg/autostart \
	  puavo-update-gtk-bookmarks.desktop

	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) puavo-update-gtk-bookmarks

clean:

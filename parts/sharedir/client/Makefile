prefix      = /usr/local
exec_prefix = $(prefix)
bindir      = $(exec_prefix)/bin
sbindir     = $(exec_prefix)/sbin
sysconfdir  = $(prefix)/etc

INSTALL         = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA    = $(INSTALL) -m 644

all:

install-dirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/xdg/autostart
	mkdir -p $(DESTDIR)$(sysconfdir)/X11/Xsession.d

install: install-dirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		puavo-remotemounts-helper \
		puavo-update-gtk-bookmarks
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/xdg/autostart \
		puavo-remotemounts-helper.desktop
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/X11/Xsession.d \
		etc/X11/Xsession.d/46puavo-update-gtk-bookmarks

clean:

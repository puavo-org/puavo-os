prefix      = /usr/local
exec_prefix = $(prefix)
bindir      = $(exec_prefix)/bin
sbindir     = $(exec_prefix)/sbin
sysconfdir  = $(prefix)/etc
datarootdir = $(prefix)/share

INSTALL         = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA    = $(INSTALL) -m 644

all:

install-dirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/network/if-post-down.d
	mkdir -p $(DESTDIR)$(sysconfdir)/network/if-up.d
	mkdir -p $(DESTDIR)$(sysconfdir)/xdg/autostart
	mkdir -p $(DESTDIR)$(sysconfdir)/X11/Xsession.d
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-conf/definitions

install: install-dirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		puavo-remotemounts-helper \
		puavo-update-gtk-bookmarks
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sysconfdir)/network/if-post-down.d \
		etc/network/if-post-down.d/ipsec
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sysconfdir)/network/if-up.d \
		etc/network/if-up.d/ipsec
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/xdg/autostart \
		puavo-remotemounts-helper.desktop
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-conf/definitions \
		share/puavo-conf/definitions/puavo-sharedir-client.json

clean:

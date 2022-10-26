prefix = /usr/local
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin
sysconfdir = $(prefix)/etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all:

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)/lib/systemd/system
	mkdir -p $(DESTDIR)$(sysconfdir)/systemd/system/multi-user.target.wants

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) puavo-samba-sync
	$(INSTALL_DATA) -t $(DESTDIR)/lib/systemd/system \
		puavo-samba-sync.service
	ln -fns /lib/systemd/system/puavo-samba-sync.service \
		$(DESTDIR)$(sysconfdir)/systemd/system/multi-user.target.wants/puavo-samba-sync.service

.PHONY: clean
clean:

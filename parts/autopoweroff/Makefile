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
	mkdir -p $(DESTDIR)$(sysconfdir)/systemd/system/multi-user.target.wants

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-autopoweroff
	$(INSTALL_DATA) -t $(DESTDIR)/lib/systemd/system \
		puavo-autopoweroff.service
	ln -fns /lib/systemd/system/puavo-autopoweroff.service \
		$(DESTDIR)$(sysconfdir)/systemd/system/multi-user.target.wants/puavo-autopoweroff.service

.PHONY: clean
clean:

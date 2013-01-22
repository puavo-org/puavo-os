prefix = /usr
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin
datarootdir = $(prefix)/share

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all:

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-ds-slave

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		slave/puavo-init-ldap-slave \
		slave/puavo-init-kdc-slave
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-ds-slave \
		slave/init_ldap_slave.ldif.erb \
		slave/krb5.conf.erb \
		slave/kdc.conf.erb

.PHONY: clean
clean:

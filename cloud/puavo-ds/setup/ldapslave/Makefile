prefix ?= /usr

all:

install:
	mkdir -p $(DESTDIR)$(prefix)/sbin
	mkdir -p $(DESTDIR)$(prefix)/share/puavotools
	install -o root -g root -m 755 init_ldap_slave \
	  $(DESTDIR)$(prefix)/sbin/init_ldap_slave
	install -o root -g root -m 644 init_ldap_slave.ldif.erb \
	  $(DESTDIR)$(prefix)/share/puavotools/init_ldap_slave.ldif.erb
	install -o root -g root -m 755 init_kdc_slave \
	  $(DESTDIR)$(prefix)/sbin/init_kdc_slave

clean:

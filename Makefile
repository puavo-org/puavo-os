prefix ?= /usr/local
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin
sysconfdir ?= $(prefix)/etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: build
build:
	@echo :\)

.PHONY: test
test:
	ruby1.9.3 test/run.rb

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(sysconfdir)
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(prefix)/lib/ruby/vendor_ruby/puavo-tftp

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-tftpd
	$(INSTALL_DATA) -t $(DESTDIR)$(prefix)/lib/ruby/vendor_ruby/puavo-tftp \
		puavo-tftp/*.rb
ifeq ($(INSTALL_HOOKS),yes)
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		hooks/puavo-ltspboot-config \
		hooks/puavo-lts-config
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir) \
		hooks/puavo-tftp.yml
	$(INSTALL_DATA) -t $(DESTDIR)$(prefix)/lib/ruby/vendor_ruby \
		hooks/puavo-ldap.rb
endif

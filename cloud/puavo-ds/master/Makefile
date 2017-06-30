prefix = /usr/local
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin

# For some reason ruby lib directory is different under /usr and /usr/local
ifeq ($(prefix),/usr/local)
	RUBY_LIB_DIR = $(prefix)/lib/site_ruby
else
	RUBY_LIB_DIR = $(prefix)/lib/ruby/vendor_ruby
endif

build:

install-dirs:
	mkdir -p $(DESTDIR)$(RUBY_LIB_DIR)
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)/etc/ldap/schema/
	mkdir -p $(DESTDIR)/etc/init.d/

install: install-dirs
	cp -r lib/* $(DESTDIR)$(RUBY_LIB_DIR)
	cp schema/*.ldif $(DESTDIR)/etc/ldap/schema/
	install -m 744 -t $(DESTDIR)$(sbindir) bin/puavo-add-new-organisation
	install -m 744 -t $(DESTDIR)$(sbindir) bin/puavo-clone-master
	install -m 744 -t $(DESTDIR)$(sbindir) bin/puavo-reset-kerberos-configurations
	install -m 744 -t $(DESTDIR)$(sbindir) bin/puavo-init-ldap
	install -m 744 -t $(DESTDIR)$(sbindir) bin/puavo-update-acl
	install -m 744 -t $(DESTDIR)$(sbindir) bin/puavo-dump-all-databases
	install -m 744 -t $(DESTDIR)$(sbindir) bin/puavo-restore-all-databases
	install -m 744 -t $(DESTDIR)/etc/init.d init/puavo-kadmind

clean:

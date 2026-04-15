prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
sbindir = $(exec_prefix)/sbin

# For some reason ruby lib directory is different under /usr and /usr/local
ifeq ($(prefix),/usr/local)
	RUBY_LIB_DIR = $(prefix)/lib/site_ruby
else
	RUBY_LIB_DIR = $(prefix)/lib/ruby/vendor_ruby
endif

build:
	bundle config set path lib/puavo-ds-master-vendor
	bundle install

install-dirs:
	mkdir -p $(DESTDIR)$(RUBY_LIB_DIR)
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)/etc/ldap/schema/
	mkdir -p $(DESTDIR)/etc/init.d/

install: install-dirs
	cp -r lib/* $(DESTDIR)$(RUBY_LIB_DIR)
	cp schema/*.ldif $(DESTDIR)/etc/ldap/schema/

	install -m 755 -t $(DESTDIR)$(bindir) bin/puavo-print-acls
	install -m 755 -t $(DESTDIR)$(bindir) bin/puavo-update-acl

	install -m 744 -t $(DESTDIR)$(sbindir) \
		bin/puavo-add-new-organisation \
		bin/puavo-dump-all-databases \
		bin/puavo-cleanup-kerberos-principals \
		bin/puavo-init-ldap \
		bin/puavo-reset-kerberos-configurations \
		bin/puavo-restore-all-databases

update-gemfile-lock: clean
	rm -f Gemfile.lock
	GEM_HOME=.tmpgem bundle install
	rm -rf .tmpgem
	bundle config set deployment true
	bundle install

clean:
	rm -rf .bundle

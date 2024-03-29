# puavo-client is a ruby-library with bundled dependencies. Specify any
# dependencies in the Gemfile and they will be installed as local dependencies
# of puavo-client during `make`. The idea is to avoid the work and possible
# conflicts creating Debian packages from every single Gem dependency.

prefix = /usr/local
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin

INSTALL         = install
INSTALL_PROGRAM = $(INSTALL)

# For some reason ruby lib directory is different under /usr and /usr/local
ifeq ($(prefix),/usr/local)
	RUBY_LIB_DIR = $(prefix)/lib/site_ruby
else
	RUBY_LIB_DIR = $(prefix)/lib/ruby/vendor_ruby
endif

all:
	bundle install --standalone --path lib/puavo-client-vendor

install-dirs:
	mkdir -p $(DESTDIR)$(RUBY_LIB_DIR)
	mkdir -p $(DESTDIR)$(sbindir)

install: install-dirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		bin/puavo-cert-tool \
		bin/puavo-register \
		bin/puavo-resolve-api-server \
		bin/puavo-rest-client \
		bin/puavo-sync-external-files \
		bin/puavo-sync-printers
	cp -r lib/* $(DESTDIR)$(RUBY_LIB_DIR)

update-gemfile-lock: clean
	rm -f Gemfile.lock
	GEM_HOME=.tmpgem bundle install
	rm -rf .tmpgem
	bundle install --deployment

clean:
	rm -rf .bundle

test-rest-client:
	bundle exec ruby -Ilib test/rest_client_test.rb


test-etc:
	ruby -Ilib test/etc_test.rb

.PHONY: test
test: test-rest-client

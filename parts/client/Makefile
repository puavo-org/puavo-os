# puavo-client is a ruby-library with bundled dependencies. Specify any
# dependencies in the Gemfile and they will be installed as local dependencies
# of puavo-client during `make`. The idea is to avoid the work and possible
# conflicts creating Debian packages from every single Gem dependency.

prefix ?= /usr/local

INSTALL         = install
INSTALL_PROGRAM = $(INSTALL)

# For some reason ruby lib directory is different under /usr and /usr/local
ifeq ($(prefix),/usr/local)
	RUBY_LIB_DIR = /usr/local/lib/site_ruby
else
	RUBY_LIB_DIR = $(prefix)/lib/ruby/vendor_ruby
endif

build:
	bundle install --standalone --path lib/puavo-client-vendor

install-dirs:
	mkdir -p $(DESTDIR)$(RUBY_LIB_DIR)

install: install-dirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-register
	cp -r lib/* $(DESTDIR)$(RUBY_LIB_DIR)

clean:
	rm -rf .bundle
	rm -rf lib/puavo-client-vendor

test:
	ruby test/*

.PHONY: test

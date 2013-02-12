# puavo-client is a ruby-library with bundled dependencies. Specify any
# dependencies in the Gemfile and they will be installed as local dependencies
# of puavo-client during `make`. The idea is to avoid the work and possible
# conflicts creating Debian packages from every single Gem dependency.

prefix ?= /usr/local

build:
	bundle install --standalone --path lib/puavo-client-vendor

install-dirs:
	mkdir -p $(DESTDIR)$(prefix)/lib/ruby/vendor_ruby/

install: install-dirs
	cp -r lib/* $(DESTDIR)$(prefix)/lib/ruby/vendor_ruby/

clean:
	rm -rf .bundle
	rm -rf lib/puavo-client-vendor

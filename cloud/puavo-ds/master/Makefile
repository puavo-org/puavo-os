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
	bundle install --standalone --path lib/puavo-ds-master-vendor

install-dirs:
	mkdir -p $(DESTDIR)$(RUBY_LIB_DIR)
	mkdir -p $(DESTDIR)$(sbindir)

install: install-dirs
	cp -r lib/* $(DESTDIR)$(RUBY_LIB_DIR)
	# TODO: bin etc...

clean:
	rm -rf .bundle
	rm -rf lib/puavo-ds-master-vendor



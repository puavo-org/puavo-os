prefix = /usr/local

INSTALL = install
INSTALL_DATA = $(INSTALL) -m 644

# For some reason ruby lib directory is different under /usr and /usr/local
ifeq ($(prefix),/usr/local)
        RUBY_LIB_DIR = $(prefix)/lib/site_ruby
else
        RUBY_LIB_DIR = $(prefix)/lib/ruby/vendor_ruby
endif

all:

installdirs:
	mkdir -p $(DESTDIR)$(RUBY_LIB_DIR)

install: installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(RUBY_LIB_DIR) puavobs.rb

clean:

.PHONY: all installdirs install clean

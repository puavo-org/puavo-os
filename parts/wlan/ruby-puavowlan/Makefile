prefix = /usr/local

INSTALL = install
INSTALL_DATA = $(INSTALL) -m 644

version = $(shell dpkg-parsechangelog -l../debian/changelog | sed -r -n 's/^Version: //p')
version_file = puavowlan/version.rb

# For some reason ruby lib directory is different under /usr and /usr/local
ifeq ($(prefix),/usr/local)
	RUBY_LIB_DIR = $(prefix)/lib/site_ruby
else
	RUBY_LIB_DIR = $(prefix)/lib/ruby/vendor_ruby
endif

all: version

version:
	mkdir -p puavowlan
	echo module PuavoWLAN >$(version_file)
	echo "  VERSION = \"$(version)\"" >>$(version_file)
	echo end >>$(version_file)

installdirs:
	mkdir -p $(DESTDIR)$(RUBY_LIB_DIR)/puavowlan

install: installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(RUBY_LIB_DIR) \
		puavowlan.rb
	$(INSTALL_DATA) -t $(DESTDIR)$(RUBY_LIB_DIR)/puavowlan \
		puavowlan/*

clean:

.PHONY: all installdirs install clean version

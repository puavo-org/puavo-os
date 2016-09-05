prefix = /usr/local

INSTALL = install
INSTALL_DATA = $(INSTALL) -m 644

git_root = $(shell git rev-parse --show-toplevel)
version = $(shell dpkg-parsechangelog -l$(git_root)/debs/puavo-os/debian/changelog | sed -r -n 's/^Version: //p')

# For some reason ruby lib directory is different under /usr and /usr/local
ifeq ($(prefix),/usr/local)
	RUBY_LIB_DIR = $(prefix)/lib/site_ruby
else
	RUBY_LIB_DIR = $(prefix)/lib/ruby/vendor_ruby
endif

all: version

version:
	echo module PuavoWLAN >version.rb
	echo "  VERSION = \"$(version)\"" >>version.rb
	echo end >>version.rb

installdirs:
	mkdir -p $(DESTDIR)$(RUBY_LIB_DIR)/puavowlan

install: installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(RUBY_LIB_DIR) \
		puavowlan.rb
	$(INSTALL_DATA) -t $(DESTDIR)$(RUBY_LIB_DIR)/puavowlan \
		version.rb

clean:
	rm -f version.rb

.PHONY: all installdirs install clean version

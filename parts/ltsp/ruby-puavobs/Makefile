prefix = /usr/local

libdir = $(prefix)/lib/ruby/vendor_ruby

INSTALL = install
INSTALL_DATA = $(INSTALL) -m 644

all :

installdirs :
	mkdir -p $(DESTDIR)$(libdir)

install : installdirs
	$(INSTALL_DATA) -t $(DESTDIR)$(libdir) \
		puavobs.rb

clean :

.PHONY : all installdirs install clean

prefix           = /usr/local
bindir           = $(prefix)/bin
libdir           = $(prefix)/lib
sbindir          = $(prefix)/sbin

libtool_binaries = libpuavoconf.la puavo-conf

ifeq ($(prefix), /usr/local)
rubylibdir = $(prefix)/lib/site_ruby
else
rubylibdir = $(prefix)/lib/ruby/vendor_ruby
endif

CPPFLAGS = -std=c99 -Wall -Wextra
CFLAGS   = -std=c99 -pedantic
LDFLAGS  = -g -O

.PHONY: all
all: $(libtool_binaries)

.PHONY: clean
clean:
	libtool --mode=clean \
		rm -f $(libtool_binaries) *.lo *.o
	$(MAKE) -C test clean

.PHONY: install
install: installdirs
	libtool --mode=install \
		install libpuavoconf.la $(DESTDIR)$(libdir)
	libtool --mode=install install puavo-conf $(DESTDIR)$(bindir)
	install -t $(DESTDIR)$(sbindir) puavo-conf-mkdb puavo-conf-daemon
	install -m 644 -t $(DESTDIR)$(rubylibdir)/puavo conf.rb

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(libdir)
	mkdir -p $(DESTDIR)$(rubylibdir)/puavo
	mkdir -p $(DESTDIR)$(sbindir)

.PHONY: test
test: all
	$(MAKE) -C test

puavo-conf: puavo-conf.o libpuavoconf.la
	libtool --mode=link gcc $(LDFLAGS) -o $@ $^

libpuavoconf.la: conf.lo
	libtool --mode=link \
		gcc $(LDFLAGS) -ldb -rpath $(libdir) -version-info 0:0:0 -o $@ $^

%.lo: %.c %.h
	libtool --mode=compile \
		gcc $(CPPFLAGS) $(CFLAGS) -c $<

deb:
	dpkg-buildpackage -us -uc

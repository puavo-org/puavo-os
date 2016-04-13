prefix           = /usr/local
bindir           = $(prefix)/bin
libdir           = $(prefix)/lib
sbindir          = $(prefix)/sbin
datarootdir      = $(prefix)/share

libtool_binaries = libpuavoconf.la puavo-conf

ifeq ($(prefix), /usr/local)
rubylibdir = $(prefix)/lib/site_ruby
sysconfdir = $(prefox)/etc
else
rubylibdir = $(prefix)/lib/ruby/vendor_ruby
sysconfdir = /etc
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

	install -m 644 -t $(DESTDIR)$(sysconfdir)/dbus-1/system.d \
		dbus/org.puavo.Conf1.conf

	install -m 644 -t $(DESTDIR)$(datarootdir)/dbus-1/interfaces \
		dbus/org.puavo.Conf1.xml

	install -m 644 -t $(DESTDIR)$(datarootdir)/dbus-1/system-services \
		dbus/org.puavo.Conf1.service

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)/dbus-1/interfaces
	mkdir -p $(DESTDIR)$(datarootdir)/dbus-1/system-services
	mkdir -p $(DESTDIR)$(libdir)
	mkdir -p $(DESTDIR)$(rubylibdir)/puavo
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/dbus-1/system.d

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

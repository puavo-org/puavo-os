prefix           = /usr/local
bindir           = $(prefix)/bin
libdir           = $(prefix)/lib
sbindir          = $(prefix)/sbin
datarootdir      = $(prefix)/share

libtool_binaries = libpuavoconf.la puavo-conf puavo-conf-update

ifeq ($(prefix), /usr/local)
rubylibdir = $(prefix)/lib/site_ruby
sysconfdir = $(prefix)/etc
else
rubylibdir = $(prefix)/lib/ruby/vendor_ruby
sysconfdir = /etc
endif

CPPFLAGS = -std=c99 -Wall -Wextra
CFLAGS   = -std=c99 -pedantic -g
LDFLAGS  =

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
	libtool --mode=install install puavo-conf-update $(DESTDIR)$(sbindir)
	install -t $(DESTDIR)$(sbindir) puavo-conf-daemon
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
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-conf/scripts

.PHONY: test
test: all
	$(MAKE) -C test

puavo-conf: puavo-conf.o libpuavoconf.la
	libtool --mode=link --tag=CC $(CC) $(LDFLAGS) -o $@ $^

puavo-conf-update: puavo-conf-update.o libpuavoconf.la
	libtool --mode=link --tag=CC $(CC) $(LDFLAGS) -ljansson -o $@ $^

libpuavoconf.la: conf.lo common.lo db.lo dbus.lo
	libtool --mode=link --tag=CC \
		$(CC) $(LDFLAGS) -ldb $(shell pkg-config --libs dbus-1) -rpath $(libdir) -version-info 0:0:0 -o $@ $^

%.lo: %.c %.h
	libtool --mode=compile --tag=CC \
		$(CC) $(CPPFLAGS) $(CFLAGS) $(shell pkg-config --cflags dbus-1) -c $<

deb:
	dpkg-buildpackage -us -uc

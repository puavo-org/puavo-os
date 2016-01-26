prefix   = /usr/local
libdir   = $(prefix)/lib
binaries = libpuavoconf.la

.PHONY: all
all: $(binaries)

.PHONY: clean
clean:
	libtool --mode=clean rm -f libpuavoconf.la *.lo

.PHONY: install
install: installdirs
	libtool --mode=install install libpuavoconf.la $(DESTDIR)$(libdir)

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(libdir)

libpuavoconf.la: conf.lo
	libtool --mode=link gcc -Wpedantic -Wall -Wextra -o $@ $^ \
		-rpath $(libdir) -version-info 0:0:0

%.lo: %.c
	libtool --mode=compile gcc -Wpedantic -Wall -Wextra -c $<

prefix           = /usr/local
libdir           = $(prefix)/lib
libtool_binaries = libpuavoconf.la example puavo-conf

CPPFLAGS = -Wall -Wextra
CFLAGS   = -Wpedantic
LDFLAGS  = -g -O

.PHONY: all
all: $(libtool_binaries)

.PHONY: clean
clean:
	libtool --mode=clean \
		rm -f $(libtool_binaries) *.lo *.o

.PHONY: install
install: installdirs
	libtool --mode=install \
		install $(libtool_binaries) $(DESTDIR)$(libdir)

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(libdir)

example: example.o libpuavoconf.la
	libtool --mode=link \
		gcc $(LDFLAGS) -o $@ $^

puavo-conf: puavo-conf.o libpuavoconf.la
	libtool --mode=link gcc -Wpedantic -Wall -Wextra -g -O -o $@ $^

libpuavoconf.la: conf.lo
	libtool --mode=link \
		gcc $(LDFLAGS) -ldb -rpath $(libdir) -version-info 0:0:0 -o $@ $^

%.lo: %.c %.h
	libtool --mode=compile \
		gcc $(CPPFLAGS) $(CFLAGS) -c $<

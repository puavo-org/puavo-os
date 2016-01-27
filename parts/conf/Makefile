prefix           = /usr/local
libdir           = $(prefix)/lib
libtool_binaries = libpuavoconf.la example puavo-conf

.PHONY: all
all: $(libtool_binaries)

.PHONY: clean
clean:
	libtool --mode=clean rm -f $(libtool_binaries) *.lo *.o

.PHONY: install
install: installdirs
	libtool --mode=install install $(libtool_binaries) $(DESTDIR)$(libdir)

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(libdir)

example: example.o libpuavoconf.la
	libtool --mode=link gcc -Wpedantic -Wall -Wextra -g -O -o $@ $^

puavo-conf: puavo-conf.o libpuavoconf.la
	libtool --mode=link gcc -Wpedantic -Wall -Wextra -g -O -o $@ $^

libpuavoconf.la: conf.lo
	libtool --mode=link gcc -ldb -Wpedantic -Wall -Wextra -g -o $@ $^ \
		-rpath $(libdir) -version-info 0:0:0

%.lo: %.c %.h
	libtool --mode=compile gcc -Wpedantic -Wall -Wextra -c $<

%.o: %.c %.h
	gcc -Wpedantic -Wall -Wextra -c $^

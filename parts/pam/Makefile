C        = gcc
CFLAGS   = -DHAVE_CONFIG_H -I. -Wdate-time -D_FORTIFY_SOURCE=2 -g -O2 -fstack-protector-strong -Wformat -Werror=format-security

DESTDIR   =
LIBDIR    = /lib
MODULEDIR = $(LIBDIR)/security

all: pam_puavo.so

pam_puavo.so: pam_puavo.o
	$(CC) -shared -o pam_puavo.so pam_puavo.o -lpam

pam_puavo.o: pam_puavo.c
	$(CC) $(CFLAGS) -c pam_puavo.c

install: pam_puavo.so
	mkdir -p $(DESTDIR)$(MODULEDIR)
	install -m 644 pam_puavo.so $(DESTDIR)$(MODULEDIR)

clean:
	rm -f pam_puavo.o pam_puavo.so

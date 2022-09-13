C        = gcc
CFLAGS   = -DHAVE_CONFIG_H -I. -Wdate-time -D_FORTIFY_SOURCE=2 -g -O2 -fstack-protector-strong -Wformat -Werror=format-security

DESTDIR   =
LIBDIR    = /lib
MODULEDIR = $(LIBDIR)/$(shell arch)-linux-gnu/security

all: pam_puavo.so pam_puavorolegroups.so

pam_puavo.so: pam_puavo.o
	$(CC) -shared -o pam_puavo.so pam_puavo.o -lpam

pam_puavo.o: pam_puavo.c
	$(CC) $(CFLAGS) -c pam_puavo.c

pam_puavorolegroups.so: pam_puavorolegroups.o
	$(CC) -shared -o pam_puavorolegroups.so pam_puavorolegroups.o \
                -ljansson -lpam

pam_puavorolegroups.o: pam_puavorolegroups.c
	$(CC) $(CFLAGS) -c pam_puavorolegroups.c

install: pam_puavo.so pam_puavorolegroups.so
	mkdir -p $(DESTDIR)$(MODULEDIR)
	install -o root -g root -m 644 pam_puavo.so pam_puavorolegroups.so \
		$(DESTDIR)$(MODULEDIR)

clean:
	rm -f pam_puavo.o pam_puavo.so

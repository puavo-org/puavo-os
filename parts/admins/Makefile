prefix = /usr/local
modules = libnss_puavoadmins.so.2

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

all: $(modules)

libnss_puavoadmins.so.2: passwd.o group.o orgjson.o
	gcc -shared -o $@ -Wl,-soname,$@ $^ -ljansson

%.o: %.c
	gcc -fPIC -std=c99 -pedantic -Wall -Wextra -c $< -o $@

installdirs:
	mkdir -p $(DESTDIR)$(prefix)/lib

install: installdirs all
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(prefix)/lib \
		libnss_puavoadmins.so.2

clean:
	rm -rf *.o
	rm -rf $(modules)

.PHONY: all installdirs install clean

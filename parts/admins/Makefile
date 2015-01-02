prefix = /usr/local
binaries = libnss_puavoadmins.so.2 get-ssh-public-keys

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

all: $(binaries)

get-ssh-public-keys: get-ssh-public-keys.o orgjson.o
	gcc -o $@ $^ -ljansson

libnss_puavoadmins.so.2: passwd.o group.o orgjson.o
	gcc -shared -o $@ -Wl,-soname,$@ $^ -ljansson

%.o: %.c %.h log.h
	gcc -fPIC -std=gnu99 -Wall -Wextra -c $< -o $@

%.o: %.c log.h
	gcc -fPIC -std=gnu99 -Wall -Wextra -c $< -o $@

installdirs:
	mkdir -p $(DESTDIR)$(prefix)/lib

install: installdirs all
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(prefix)/lib \
		libnss_puavoadmins.so.2 \
		get-ssh-public-keys

clean:
	rm -rf *.o
	rm -rf $(binaries)

.PHONY: all installdirs install clean

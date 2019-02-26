prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
libdir = $(prefix)/lib
sbindir = $(exec_prefix)/sbin
datarootdir = $(prefix)/share
sysconfdir = $(prefix)/etc

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)

.PHONY: all
all: add_entropy

add_entropy: add_entropy.c
	cc $(CFLAGS) -o $@ $<

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(libdir)/puavo-core

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-core \
		add_entropy

.PHONY: clean
clean:
	rm -f add_entropy

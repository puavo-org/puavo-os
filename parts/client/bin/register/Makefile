prefix      = /usr/local
exec_prefix = $(prefix)
sbindir     = $(exec_prefix)/sbin

INSTALL         = install
INSTALL_PROGRAM = $(INSTALL)

.PHONY: all
all:

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(sbindir)

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-register

.PHONY: clean
clean:

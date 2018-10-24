prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)

.PHONY: all
all:

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(bindir)

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) abitti_usb_factory

.PHONY: clean
clean:

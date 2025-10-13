prefix = /usr/local
exec_prefix = $(prefix)
libdir = $(prefix)/lib

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)

.PHONY: all
all:

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(libdir)/puavo-exammode

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-exammode \
		puavo-exammode-wifi-ctrl

prefix = /usr/local
exec_prefix = $(prefix)
datarootdir = $(prefix)/share

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY: all
all:

.PHONY: installdirs
installdirs:
	mkdir -p $(DESTDIR)$(datarootdir)/munin/plugins

.PHONY: install
install: installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(datarootdir)/munin/plugins	\
		puavo-wlan-elements_				\
		puavo-wlan-elements

.PHONY: clean
clean:

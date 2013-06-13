prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
sbindir = $(exec_prefix)/sbin
sysconfdir = $(prefix)/etc
datarootdir = $(prefix)/share
libdir = $(prefix)/lib

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : puavo-wlangw-env
puavo-wlangw-env :
	echo "#!/bin/sh" > $@
	echo "export PUAVO_WLANGW_CONFDIR=$(sysconfdir)/puavo-wlangw" >> $@
	echo "export PUAVO_WLANGW_DATADIR=$(datarootdir)/puavo-wlangw" >> $@
	echo "export PUAVO_WLANGW_LIBDIR=$(libdir)/puavo-wlangw" >> $@

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-wlangw
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-wlangw
	mkdir -p $(DESTDIR)$(libdir)/puavo-wlangw

.PHONY : install
install : puavo-wlangw-env installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(bindir) \
		puavo-wlangw-env
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-wlangw
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-wlangw \
		config \
		vtund.conf
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/puavo-wlangw \
		config
	$(INSTALL_DATA) -t $(DESTDIR)$(libdir)/puavo-wlangw \
		lib/common.sh
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-wlangw \
		lib/vtun-down \
		lib/vtun-up
	rm -f puavo-wlangw-env

.PHONY : clean
clean :

prefix = /usr/local
exec_prefix = $(prefix)
sbindir = $(exec_prefix)/sbin
sysconfdir = $(prefix)/etc
datarootdir = $(prefix)/share
libdir = $(prefix)/lib

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

.PHONY : all
all :

.PHONY : config
config :
	sed -e "s|#{PWGW_DATADIR}|$(datarootdir)/puavo-wlangw|g" \
	    -e "s|#{PWGW_LIBDIR}|$(libdir)/puavo-wlangw|g" \
	    config.in >$@
	chmod --reference=config.in $@

.PHONY : installdirs
installdirs :
	mkdir -p $(DESTDIR)$(sbindir)
	mkdir -p $(DESTDIR)$(sysconfdir)/puavo-wlangw
	mkdir -p $(DESTDIR)$(datarootdir)/puavo-wlangw
	mkdir -p $(DESTDIR)$(libdir)/puavo-wlangw

.PHONY : install
install : config installdirs
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(sbindir) \
		puavo-wlangw
	$(INSTALL_DATA) -t $(DESTDIR)$(datarootdir)/puavo-wlangw \
		vtund.conf
	$(INSTALL_DATA) -t $(DESTDIR)$(sysconfdir)/puavo-wlangw \
		config
	$(INSTALL_PROGRAM) -t $(DESTDIR)$(libdir)/puavo-wlangw \
		lib/vtun-down \
		lib/vtun-up \
		lib/add-network

.PHONY : clean
clean :
